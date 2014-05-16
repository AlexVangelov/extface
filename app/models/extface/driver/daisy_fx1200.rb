# SEND
# 1       2       3       4       5       6       7       8
#STX     LEN     SEQ     CMD     DATA    PA1     BCC     ETX
# 1       1       1       1     0–200     1       4       1
#01h   20h–FFh 20h–FFh 20h–FFh  20h–FFh  05h   30h–3Fh   03h

# RECV
# 1       2       3       4       5       6      7      8      9     10
#STX     LEN     SEQ     CMD     DATA    PA2   STATUS  PA1    BCC    ETX
# 1       1       1       1     0–200     1      6      1      4      1
#01h   20h–FFh 20h–FFh 20h–FFh  20h–FFh  04h  80h–FFh  05h  30h–3Fh  03h

module Extface
  class Driver::DaisyFx1200 < Extface::Driver
    NAME = 'Daisy FX1200 (Serial)'.freeze
    GROUP = Extface::FISCAL_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = false #POS, slip printers
    FISCAL = true #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices  
    
    RESPONSE_TIMEOUT = 6  #seconds
    
    has_serial_config
    
    include Extface::Driver::Daisy::CommandsFx1200

    def handle(buffer) #buffer is filled with multiple pushes, wait for full frame (ACKs)STX..PA2..PA1..ETX
      p "###################"
      p buffer.bytes
      if frame_len = buffer.index(ETX) || buffer.index(NAK)
        rpush buffer[0..packet_len]
      else
        #TODO check buffer.length
      end
      return frame_len # return number of bytes processed
    end
    
    def autocut(partial = true) # return "P" - success, "F" - failed
      resp = fsend(Printer::CUT)
      resp == "P"
    end
     
    def print_status
      device.session("Print Status") do |s|
        s.notify "Printing Test Page"
        s.fsend Sales::START_NON_FISCAL_DOC
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "********************************"
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "Extface Print Test".center(32)
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "********************************"
        s.fsend Printer::MOVE, "1"
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "Driver: " + "#{self.class::NAME}".truncate(24)
        s.fsend(Sales::END_NON_FISCAL_DOC)
        s.notify "Printing finished"
        s.autocut
      end
    end
    
    def check_status
      flush
      fsend(Info::STATUS) # return 6 byte status
      errors.empty?
    end
    
    def build_packet(cmd, data = "")
      String.new.tap() do |packet|
        packet << STX
        packet << 0x20 + 4 + data.length
        packet << sequence_number
        packet << cmd
        packet << data
        packet << PA1
        packet << bcc(packet[1..-1])
        packet << ETX
      end
    end
    
    def fsend!(cmd, data = "") # return data or raise
      push build_packet(cmd, data) # return 6 byte status
      if resp = recv(RESPONSE_TIMEOUT)
        return resp.data if resp.valid?
      else
        raise errors.full_messages.join(', ')
      end
    end
    
    def fsend(cmd, data = "") #return data or nil
      push build_packet(cmd, data)
      if resp = frecv(RESPONSE_TIMEOUT)
        return resp.data if resp.valid?
      else
        return false
      end
    end
    
    def frecv(timeout) # return RespFrame or nil
      if frame_bytes = pull(timeout)
        frame = RespFrame.new(frame_bytes)
        if frame.valid?
          human_status_errors(frame.status)
          return frame
        else
          errors.add :base, "Invalid frame received from device"
          return nil
        end
      else
        errors.add :base, "No data received from device"
        return nil
      end
    end
   
    #private 
      def bcc(buffer)
        sum = 0
        buffer.each_byte do |byte|
          sum += byte
        end
        "".tap() do |bcc|
          4.times do |halfbyte|
            bcc.insert 0, (0x30 + ((sum >> (halfbyte*4)) & 0x0f)).chr
          end
        end
      end
      
      def sequence_number(increment = true)
        @seq ||= 0x1f
        @seq += 1 if increment
        @seq = 0x1f if @seq == 0x7f
        @seq
      end
      
      def human_status_errors(status) #6 bytes status
        errors.add :base, "Fiscal Device General Error" unless (status[0].ord & 0x20).zero?
        errors.add :base, "Invalid Command" unless (status[0].ord & 0x02).zero?
        errors.add :base, "Date & Time Not Set" unless (status[0].ord & 0x04).zero?
        errors.add :base, "Syntax Error" unless (status[0].ord & 0x02).zero?
        
        errors.add :base, "Wrong Password" unless (status[1].ord & 0x40).zero?
        errors.add :base, "Cutter Error" unless (status[1].ord & 0x20).zero?
        errors.add :base, "Unpermitted Command In This Mode" unless (status[1].ord & 0x02).zero?
        errors.add :base, "Field Overflow" unless (status[1].ord & 0x01).zero?
        
        #errors.add :base, "Print Doc Allowed" unless (status[2].ord & 0x40).zero?
        #errors.add :base, "Non Fiscal Doc Open" unless (status[2].ord & 0x20).zero?
        errors.add :base, "Less Paper (Control)" unless (status[2].ord & 0x20).zero?
        #errors.add :base, "Fiscal Doc Open" unless (status[2].ord & 0x08).zero?
        errors.add :base, "No Paper (Control)" unless (status[2].ord & 0x04).zero?
        errors.add :base, "Less Paper" unless (status[2].ord & 0x02).zero?
        errors.add :base, "No Paper" unless (status[2].ord & 0x01).zero?
        
        case (status[3] & 0x7f)
          when 1 then errors.add :base, "Operation will result in the overflow"
          when 3 then errors.add :base, "No more sales for this doc"
          when 4 then errors.add :base, "No more payments for this doc"
          when 5 then errors.add :base, "Null transaction attempt"
          when 6 then errors.add :base, "Sale not allowed"
          when 7 then errors.add :base, "No rights for this operation"
          when 8 then errors.add :base, "Tax group forbidden"
          when 11 then errors.add :base, "Multiple decimal points"
          when 12 then errors.add :base, "Multiple sign symbols"
          when 13 then errors.add :base, "Sign not at first position"
          when 14 then errors.add :base, "Wrong symbol"
          when 15 then errors.add :base, "Too many symbols after decimal point"
          when 16 then errors.add :base, "Too many symbols"
          when 20 then errors.add :base, "Service not allowed"
          when 21 then errors.add :base, "Wrong Value"
          when 22 then errors.add :base, "Disabled operation"
          when 23 then errors.add :base, "Deep void after discount"
          when 24 then errors.add :base, "Deep void for not existing record"
          when 24 then errors.add :base, "Payment without sale"
        end
        
        errors.add :base, "General Fiscal Memory Error" unless (status[4].ord & 0x20).zero?
        errors.add :base, "Fiscal Memory Full" unless (status[4].ord & 0x10).zero?
        errors.add :base, "Less Than 50 Fiscal Records" unless (status[4].ord & 0x08).zero?
        errors.add :base, "Invalid Fiscal Records" unless (status[4].ord & 0x04).zero?
        errors.add :base, "Fiscal Write Error" unless (status[4].ord & 0x01).zero?
        
        #errors.add :base, "Fiscal Memory Ready" unless (status[5].ord & 0x40).zero?
        #errors.add :base, "Fiscal ID Set" unless (status[5].ord & 0x20).zero?
        #errors.add :base, "Fiscal Tax set" unless (status[5].ord & 0x10).zero?
        #errors.add :base, "Real Sales Mode" unless (status[5].ord & 0x80).zero?
        errors.add :base, "Fiscal Memory Full" unless (status[5].ord & 0x01).zero?
      end
      
      class RespFrame
        include ActiveModel::Validations
        attr_reader :frame, :len, :seq, :cmd, :data, :status, :bcc
        
        validates_presence_of :frame
        validate :bcc_validation
        validate :len_validation
        
        def initialize(buffer)
          # test Extface::Driver::DaisyFx1200::RespFrame.new("\x16\x16\x01\x2c\x20\x2dP\x04SSSSSS\x05\BBBB\x03")
          #                              LEN   SEQ   CMD DATA    STATUS      BCC
          if match = buffer.match(/\x01(.{1})(.{1})(.{1})(.+)\x04(.{6})\x05(.{4})\x03/n)
            @frame = match.string[match.pre_match.length..-1]
            @len, @seq, @cmd, @data, @status, @bcc = match.captures
          end
        end
        
        private
          def bcc_validation
            sum = 0
            frame[1..-6].each_byte do |byte|
              sum += byte
            end
            errors.add(:bcc, I18n.t('errors.messages.invalid')) if bcc != sum.to_s(16).rjust(4, '0')
          end
          
          def len_validation
            errors.add(:len, I18n.t('errors.messages.invalid')) if len.ord != (frame[1..-6].length + 0x20)
          end
      end
  end
end