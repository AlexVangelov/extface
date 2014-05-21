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
    
    RESPONSE_TIMEOUT = 3  #seconds
    INVALID_FRAME_RETRIES = 6  #seconds
    
    TAX_GROUPS_MAP = {
      1 => "\xc0",
      2 => "\xc1",
      3 => "\xc2",
      4 => "\xc3",
      5 => "\xc4",
      6 => "\xc5",
      7 => "\xc6",
      8 => "\xc7"
    }
    
    has_serial_config
    
    include Extface::Driver::Daisy::CommandsFx1200

    def handle(buffer) #buffer is filled with multiple pushes, wait for full frame (ACKs)STX..PA2..PA1..ETX
      if buffer[/^\x16+$/] # skip if only ACKs
        return buffer.length 
      else
        if frame_len = buffer.index("\x03") || buffer.index("\x15")
          rpush buffer[0..frame_len]
          return frame_len+1 # return number of bytes processed
        else
          #TODO check buffer.length
          return 0 #no bytes processed
        end
      end
    end
    
    def autocut(partial = true) # return "P" - success, "F" - failed
      resp = fsend(Printer::CUT)
      resp == "P"
    end
     
    def non_fiscal_test
      device.session("Non Fiscal Text") do |s|
        s.notify "Printing Non Fiscal Text"
        s.fsend Sales::START_NON_FISCAL_DOC
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "********************************"
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "Extface Print Test".center(32)
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "********************************"
        s.fsend Printer::MOVE, "1"
        s.fsend Sales::PRINT_NON_FISCAL_TEXT, "Driver: " + "#{self.class::NAME}".truncate(24)
        s.fsend Sales::END_NON_FISCAL_DOC
        s.notify "Printing finished"
      end
    end
    
    def fiscal_test
      sale_and_pay_items_session([
        { price: 0.01, text1: "Extface Test" }
      ])
    end
    
    def build_sale_data(price, text1 = nil, text2 = nil, tax_group = 2, qty = nil, percent = nil, neto = nil)
      "".tap() do |data|
        data << text1 unless text1.blank?
        data << "\x0a#{text2}" unless text2.blank?
        data << "\t"
        data << TAX_GROUPS_MAP[tax_group || 2]
        data << price.to_s
        data << "*#{qty.to_s}" unless qty.blank?
        data << ",#{percent}" unless percent.blank?
        data << "$#{neto}" unless neto.blank?
      end
    end
    
    def sale_and_pay_items_session(items = [], operator = "1", password = "1")
      device.session("Fiscal Doc") do |s|
        s.notify "Fiscal Doc Start"
        s.fsend Sales::START_FISCAL_DOC, "#{operator || "1"},#{password || "1"},00001"
        items.each do |item|
          s.fsend Sales::SALE_AND_SHOW, build_sale_data(item[:price], item[:text1], item[:text2], item[:tax_group], item[:qty], item[:percent], item[:neto])
        end
        s.fsend(Sales::TOTAL, "\t")
        s.fsend(Sales::END_FISCAL_DOC)
        s.notify "Fiscal Doc End"
      end
    end
    
    def z_report_session
      device.session("Z Report") do |s|
        s.notify "Z Report Start"
        s.fsend Closure::DAY_FIN_REPORT, "0"
        s.notify "Z Report End"
      end
    end
    
    def x_report_session
      device.session("X Report") do |s|
        s.notify "X Report Start"
        s.fsend Closure::DAY_FIN_REPORT, "2"
        s.notify "X Report End"
      end
    end
    
    def cancel_doc_session
      device.session("Doc cancel") do |s|
        s.notify "Doc Cancel Start"
        s.fsend Sales::CANCEL_DOC
        s.notify "Doc Cancel End"
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
      if resp = frecv(RESPONSE_TIMEOUT)
        return resp.data if resp.valid?
      else
        raise errors.full_messages.join(', ')
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
          end
        end
        errors.add :base, "#{INVALID_FRAME_RETRIES} Broken Packets Received. Abort!"
      end
      return result
    end
    
    def frecv(timeout) # return RespFrame or nil
      if frame_bytes = pull(timeout)
        return RespFrame.new(frame_bytes.b)
      else
        errors.add :base, "No data received from device"
        return nil
      end
    end
   
    private 
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
          if match = buffer.match(/\x01(.{1})(.{1})(.{1})(.*)\x04(.{6})\x05(.{4})\x03/n)
            @frame = match.to_a.first
            @len, @seq, @cmd, @data, @status, @bcc = match.captures
          else
            #TODO look for NAK
          end
        end
        
        private
          def bcc_validation
            sum = 0
            frame[1..-6].each_byte do |byte|
              sum += byte
            end
            calc_bcc = "".tap() do |tbcc|
              4.times do |halfbyte|
                tbcc.insert 0, (0x30 + ((sum >> (halfbyte*4)) & 0x0f)).chr
              end
            end
            errors.add(:bcc, I18n.t('errors.messages.invalid')) if bcc != calc_bcc
          end
          
          def len_validation
            errors.add(:len, I18n.t('errors.messages.invalid')) if len.ord != (frame[1..-6].length + 0x20)
          end
      end
  end
end