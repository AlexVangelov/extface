
# 1      2       3       4       5       6       6+n     
#STRT          ADDR     SEQ     CMD     LEN     DATA    CS
# 1      1       1       1       1       1       4       1
#AAh    55h    0–FFh   0–FFh  10h–70h  0-FFh  30h–3Fh  0-FFh

module Extface
  class Driver::EltradeTmU220 < Extface::Driver
    NAME = 'Eltrade TM-U220 (Serial)'.freeze
    GROUP = Extface::FISCAL_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = false #POS, slip printers
    FISCAL = true #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices 
    
    RESPONSE_TIMEOUT = 3  #seconds
    INVALID_FRAME_RETRIES = 6  #seconds   
    
    has_serial_config
    
    include Extface::Driver::Eltrade::CommandsFp4
    
    def handle(buffer)
      bytes_processed = 0
      if frame_match = buffer.match(/\xAA\x55.{3}(.{1}).*/n)
      p frame_match.to_a.first.bytes.collect{ |x| x.to_s(16)}
        len = frame_match.captures.first.ord
        skip = frame_match.pre_match.length
        bytes_processed = skip + 6 + len
        rpush buffer[skip..bytes_processed]
      end
      return bytes_processed
    end
    
    def non_fiscal_test
      device.session("Non Fiscal Text") do |s|
        s.notify "Printing Non Fiscal Text"
        #s.fsend Sales::START_NON_FISCAL_DOC
        #s.fsend Sales::PRINT_NON_FISCAL_TEXT, "********************************"
        #s.fsend Sales::PRINT_NON_FISCAL_TEXT, "Extface Print Test".center(32)
        #s.fsend Sales::PRINT_NON_FISCAL_TEXT, "********************************"
        #s.fsend Printer::MOVE, "1"
        #s.fsend Sales::PRINT_NON_FISCAL_TEXT, "Driver: " + "#{self.class::NAME}".truncate(24)
        #s.fsend Sales::END_NON_FISCAL_DOC
        s.notify "Printing finished"
      end
    end
    
    def check_status
      flush
      fsend(Info::GET_STATUS)
      errors.empty?
    end
    
    def build_packet(cmd, data = "")
      "".tap() do |packet|
        packet << STRT.b
        packet << 0x00 #address
        packet << sequence_number
        packet << cmd
        packet << data.length
        packet << data.b
        packet << check_sum(packet[2..-1])
      end
    end
    
    def fsend(cmd, data = "") #return data or nil
      packet_data = build_packet(cmd, data)
      result = false
      INVALID_FRAME_RETRIES.times do |retries|
        errors.clear
        push packet_data
        if resp = frecv(RESPONSE_TIMEOUT)
          if resp.valid?
            result = resp.data
            break
          else
            resp.errors.full_messages.each do |msg|
              errors.add :base, msg
            end
          end
        end
        errors.add :base, "#{INVALID_FRAME_RETRIES} Broken Packets Received. Abort!"
      end
      return result
    end
    
    def frecv(timeout) # return RespFrame or nil
      if frame_bytes = pull(timeout)
        return Frame.new(frame_bytes.b)
      else
        errors.add :base, "No data received from device"
        return nil
      end
    end
    
    def check_sum(buffer)
      sum = 0
      buffer.each_byte do |byte|
        sum -= byte
      end
      sum & 0xff
    end
    
    private
      def sequence_number(increment = true)
        @seq ||= 0
        @seq += 1 if increment
        @seq = 0 if @seq == 0xff
        @seq
      end
      
      class Frame
        include ActiveModel::Validations
        attr_reader :frame, :addr, :seq, :cmd, :len, :data, :check_sum
        
        validates_presence_of :frame
        validate :check_sum_validation
        validate :len_validation
        validate :response_code_validation
        
        def initialize(buffer)
          if match = buffer.match(/\xAA\x55(.{1})(.{1})(.{1})(.{1})(.*)(.{1})$/n)
            @frame = match.to_a.first
            @addr, @seq, @cmd, @len, @data, @check_sum = match.captures
          end
        end
        
        def ready?
          @ready || true
        end
        
        private
          def check_sum_validation
            sum = 0
            frame[2..-1].each_byte do |byte|
              sum += byte
            end
            errors.add(:check_sum, I18n.t('errors.messages.invalid')) if (sum & 0xff) != 0
          end
          
          def len_validation
            errors.add(:len, I18n.t('errors.messages.invalid')) if len.ord != data.length
          end
          
          def response_code_validation
            case cmd.ord
            when 0x6F then
              case data[1]
              when 1 then errors.add :base, "End of paper"
              when 2 then errors.add :base, "Printing error"
              when 16 then errors.add :base, "Fiscal error 0: Error at writing in FM"
              when 17 then errors.add :base, "Fiscal error 1: Attempt for writing in overflowing FM"
              when 18 then errors.add :base, "Fiscal error 2: Incorrect structure in fiscal part 1"
              when 19 then errors.add :base, "Fiscal error 3: Control sum error"
              when 20 then errors.add :base, "Fiscal error 4: Incorrect structure in fiscal part 2"
              when 21 then errors.add :base, "Fiscal error 5: No connection with the fiscal memory"
              when 22 then errors.add :base, "Fiscal error 6: Incorrect record structure"
              when 23 then errors.add :base, "Fiscal error 7: Fiscal memory overflow"
              
              when 32 then errors.add :base, "No connection with terminal"
              when 33 then errors.add :base, "No valid registration (IMSI on the SIM is different than the one recorded in fiscal memory"
              when 34 then errors.add :base, "Not used"
              when 35 then errors.add :base, "3 Daily reports with zeroing and no connection with NRA’s server"
              when 36 then errors.add :base, "Missing or invalid SIM card"
              when 37 then errors.add :base, "GSM module data reading error"
              when 38 then errors.add :base, "Terminal data memory error"
              when 39 then errors.add :base, "Terminal data memory damaged"
              when 40 then errors.add :base, "GSM module error (registration not possible, wrong PIN, damaged GSM module)"
              when 41 then errors.add :base, "KLEN SD card is not valid"
              when 42 then errors.add :base, "KLEN SD card is missing"
              when 43 then errors.add :base, "KLEN SD card data error"
              when 44 then errors.add :base, "New KLEN SD card is put in a terminal with sales registration in RAM memory (daily report with zeroing must be done before changing the KLEN SD cards)"
              when 45 then errors.add :base, "New KLEN SD card is not registered because some fiscal parameters cannot be changed"
              when 46 then errors.add :base, "New KLEN SD card is put and fiscalization must be done"
              when 47 then errors.add :base, "Recognized a KLEN SD card from a different device – only reports are available"
              end
            when 0x70 then @ready = true
            when 0x71 then @ready = false
            when 0x7E then errors.add :base, "Failed RAM"
            when 0x7F then errors.add :base, "Wrong command"
            end
          end
      end
  end
end