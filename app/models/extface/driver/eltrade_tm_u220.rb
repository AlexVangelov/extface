
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
    INVALID_FRAME_RETRIES = 6  #count
    BUSY_MAX_WAIT_CYCLES = 60  #count
    
    FLAG_TRUE = "\xff\xff"
    FLAG_FALSE = "\x00\x00"
    
    has_serial_config
    
    include Extface::Driver::Eltrade::CommandsFp4
    
    def handle(buffer)
      bytes_processed = 0
      if frame_match = buffer.match(/\xAA\x55.{3}(.{1}).*/nm) #m Treat \x0a as a character matched by .
        len = frame_match.captures.first.ord
        skip = frame_match.pre_match.length
        bytes_processed = skip + 7 + len # 6 pre + 1 check sum
        if bytes_processed <= buffer.length #packet in buffer
          rpush buffer[skip..bytes_processed]
        else
          bytes_processed = skip #not whole packet, just remove trail
        end
      end
      return bytes_processed
    end
    
    def open_receipt(variant = nil)
      fsend Receipt::OPEN_RECEIPT
      unless variant.blank?
        fsend Receipt::PRINT_RECEIPT, variant
      end
      status = get_printer_status
    end
    
    def close_receipt
      fsend Receipt::CLOSE_RECEIPT
      status = get_printer_status
    end
    
    def send_comment(text)
      fsend Receipt::PRINT_RECEIPT, Receipt::Variant::COMMENT + text
      status = get_printer_status
    end
    
    def send_plu(plu_data)
      fsend Receipt::PRINT_RECEIPT, Receipt::Variant::PLU + plu_data
      status = get_printer_status
    end
    
    def send_payment(type_num = 0, value = nil) # 0, 1, 2, 3
      value_bytes = "\x00\x00\x00\x00" # recalculate
      unless value.nil?
        value_units = (value * 100).to_i # !FIXME
        value_bytes = "".b
        4.times{ |shift| value_bytes.insert 0, ((value_units >> shift*8) & 0xff).chr }
      end
      fsend Receipt::PRINT_RECEIPT, "" << (9 + type_num).chr << value_bytes
      status = get_printer_status
    end
    
    def non_fiscal_test
      device.session("Non Fiscal Text") do |s|
        s.notify "Printing Non Fiscal Text"
        s.open_receipt Receipt::Variant::START_COMMENT_RECEIPT
        s.send_comment "********************************"
        s.send_comment "Extface Print Test".center(32)
        s.send_comment "********************************"
        s.send_comment ""
        s.send_comment "Driver: " + "#{self.class::NAME}".truncate(24)
        s.close_receipt
        s.notify "Printing finished"
      end
    end
    
    def fiscal_test
      sale_and_pay_items_session([
        { price: 0.01, text1: "Extface Test" }
      ])
    end
    
    def build_sale_data(price, text1 = "", text2 = nil, tax_group = 2, qty = 1, percent = nil, neto = nil, number = nil)
      "".b.tap() do |data|
        price_units = (price * 100).to_i # !FIXME
        price_bytes = "".b
        4.times{ |shift| price_bytes.insert 0, ((price_units >> shift*8) & 0xff).chr }
        data << price_bytes
        qty_units = ((qty || 1) * 1000).to_i # !FIXME
        qty_bytes = "".b
        4.times{ |shift| qty_bytes.insert 0, ((qty_units >> shift*8) & 0xff).chr }
        data << qty_bytes
        data << "\x00".b #number len FIXME
        data << "\xAA\xAA\xAA\xAA\xAA\xAA".b #number FIXME
        text = text1.truncate(20)
        data << text.length.chr
        data << text.ljust(20, " ").b
        data << (tax_group || 2).chr
      end
    end
    
    def sale_and_pay_items_session(items = [], operator = "1", password = "1")
      device.session("Fiscal Doc") do |s|
        s.notify "Fiscal Doc Start"
        s.open_receipt
        items.each do |item|
          s.send_plu build_sale_data(item[:price], item[:text1], nil, item[:tax_group], item[:qty], nil, nil, item[:number])
          s.send_comment(item[:text2]) unless item[:text2].blank?
        end
        s.send_payment
        s.close_receipt
        s.notify "Fiscal Doc End"
      end
    end
    
    def z_report_session
      device.session("Z Report") do |s|
        s.notify "Z Report Start"
        s.fsend Reports::DAILY_REPORT, FLAG_TRUE
        status = s.get_printer_status
        s.notify "Z Report End"
      end
    end
    
    def x_report_session
      device.session("Z Report") do |s|
        s.notify "X Report Start"
        s.fsend Reports::DAILY_REPORT, FLAG_FALSE
        status = s.get_printer_status
        s.notify "X Report End"
      end
    end
    
    def cancel_doc_session
      device.session("Doc cancel") do |s|
        s.notify "Doc Cancel Start"
        # cancel old one by open/close new one
        s.open_receipt
        s.close_receipt
        s.notify "Doc Cancel End"
      end
    end
    
    def check_ready!
      fsend Info::GET_STATUS
      raise errors.full_messages.join(", ") if errors.any?
    end
    
    def get_printer_status
      PrinterStatus.new(fsend(Info::GET_PRINTER_STATUS))
    end
    
    def check_status
      flush
      status = get_printer_status
      #TODO check for:
      #1. sold PLUs dangerously high -> solution PLU Report (0x32)
      #2. open bon and transaction count
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
      result = false
      status_invalid_responses = 0
      BUSY_MAX_WAIT_CYCLES.times do |retries|
        errors.clear
        push build_packet(Info::GET_STATUS)
        if stat_frame = frecv(RESPONSE_TIMEOUT)
          if stat_frame.valid?
            break if stat_frame.ready?
          else
            status_invalid_responses -= 1
            unless status_invalid_responses < INVALID_FRAME_RETRIES
              errors.add :base, "#{INVALID_FRAME_RETRIES} Broken Packets Received. Abort!"
            end
          end
        end
        errors.add :base, "#{BUSY_MAX_WAIT_CYCLES} Busy Packets Received. Abort!"
      end
      return(result) if errors.any?
      
      packet_data = build_packet(cmd, data)
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
          if match = buffer.match(/\xAA\x55(.{1})(.{1})(.{1})(.{1})(.*)(.{1})$/nm)
            @frame = match.to_a.first
            @addr, @seq, @cmd, @len, @data, @check_sum = match.captures
          end
        end
        
        def ready?
          @ready || true
        end
        
        def busy?
          !ready?
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
            p "############################### #{cmd.ord.to_s(16)}"
            case cmd.ord
            when 0x2c then
              case data[0] # printer error code
              when 1 then errors.add :base, "Opening of the cash register document is not requested"
              when 2 then errors.add :base, "Transaction code recognized (refer to command 0x2E)"
              when 3 then errors.add :base, "Transaction buffer overflow"
              when 4 then errors.add :base, "Transaction sequence error"
              when 5 then errors.add :base, "Multiplication overflow"
              when 6 then errors.add :base, "Cash register document overflow"
              when 7 then errors.add :base, "'0' length of code name"
              when 8 then errors.add :base, "Negative result"
              when 9 then errors.add :base, "Cash register document surcharge"
              when 10 then errors.add :base, "Out of range parameter"
              when 11 then errors.add :base, "Cash register document not paid"
              when 12 then errors.add :base, "'0' result"
              when 13 then errors.add :base, "Memory overflow because of too many PLUs"
              when 14 then errors.add :base, "Daily report overflow"
              end
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
      
      class PrinterStatus
      
        def initialize(status)
          @status = status
        end
        
        def start_bon_flag?
          @status[2,2] == "\xff\xff"
        end

        def end_bon_flag?
          @status[4,2] == "\xff\xff"
        end

        def last_transaction
          @status[8,2]
        end
        
        def transaction_count
          @status[10,2]
        end

        def last_transaction_sum
          @status[12,4]
        end

        def all_transaction_sum
          @status[16,4]
        end

        def total_sum
          @status[20,4]
        end

        def stl_discount_flag?
          @status[24,2] == '\xff\xff'
        end

        def last_recept_number
          @status[26,2]
        end

        def last_invoice_number
          @status[34,2] + @status[28,4]
        end

        def available_invoice_numbers
          @status[36,2]
        end

        def plu_count_in_memory
          @status[32,2]
        end
      end
  end
end