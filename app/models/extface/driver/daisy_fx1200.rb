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
  class Driver::DaisyFx1200 < Extface::Driver::Base::Fiscal
    NAME = 'Daisy FX1200 (Serial)'.freeze
    
    RESPONSE_TIMEOUT = 3  #seconds
    INVALID_FRAME_RETRIES = 6  #count (bad length, bad checksum)
    ACKS_MAX_WAIT = 60 #count / nothing is forever
    NAKS_MAX_COUNT = 3 #count
    
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
      if frame_len = buffer.index("\x03") || buffer.index("\x16") || buffer.index("\x15")
        rpush buffer[0..frame_len]
        return frame_len+1 # return number of bytes processed
      else
        #TODO check buffer.length
        return 0 #no bytes processed
      end
    end
    
    #tests
    def non_fiscal_test
      device.session("Non Fiscal Text") do |s|
        s.notify "Printing Non Fiscal Text"
        s.open_non_fiscal_doc
        s.print "********************************"
        s.print "Extface Print Test".center(32)
        s.print "********************************"
        s.fsend Printer::MOVE, "1"
        s.print "Driver: " + "#{self.class::NAME}".truncate(24)
        s.close_non_fiscal_doc
        s.notify "Printing finished"
      end
    end
    
    def fiscal_test
      sale_and_pay_items_session([
        SaleItem.new( price: 0.01, text1: "Extface Test" )
      ])
    end
    
    #reports
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
    
    def period_report_session(from, to, detailed = true)
    end
    
    #print
    def open_non_fiscal_doc
      fsend Sales::START_NON_FISCAL_DOC
      @print_session = true
    end
    
    def print(text)
      raise "Not in print session" unless @print_session
      fsend Sales::PRINT_NON_FISCAL_TEXT, text
    end
    
    def close_non_fiscal_doc
      fsend Sales::END_NON_FISCAL_DOC
      @print_session = false
    end
    
    #fiscal
    def open_fiscal_doc(operator = "1", password = "1")
      fsend Sales::START_FISCAL_DOC, "#{operator.presence || "1"},#{password.presence || "1"},00001"
      @fiscal_session = true
    end
    
    def close_fiscal_doc
      raise "Not in fiscal session" unless @fiscal_session
      fsend Sales::END_FISCAL_DOC
      @fiscal_session = false
    end
    
    def add_sale(sale_item)
      raise "Not in fiscal session" unless @fiscal_session
      fsend Sales::SALE_AND_SHOW, build_sale_data(sale_item)
    end
    
    def add_comment(text)
      raise "Not in fiscal session" unless @fiscal_session
    end
    
    def add_payment(type_num)
      raise "Not in fiscal session" unless @fiscal_session
    end
    
    def total_payment
      raise "Not in fiscal session" unless @fiscal_session
      fsend(Sales::TOTAL, "\t")
    end
    
    #basket
    def sale_and_pay_items_session(items = [], operator = "1", password = "1")
      device.session("Fiscal Doc") do |s|
        s.notify "Fiscal Doc Start"
        s.open_fiscal_doc
        s.notify "Register Sale"
        items.each do |item|
          s.add_sale(item)
        end
        s.notify "Register Payment"
        s.total_payment
        s.notify "Close Fiscal Receipt"
        s.close_fiscal_doc
        s.notify "Fiscal Doc End"
      end
    end
    
    def cancel_doc_session
      device.session("Doc cancel") do |s|
        s.notify "Doc Cancel Start"
        s.fsend Sales::CANCEL_DOC
        s.autocut
        s.notify "Doc Cancel End"
      end
    end

    #other
    def autocut(partial = true) # return "P" - success, "F" - failed
      resp = fsend(Printer::CUT)
      resp == "P"
    end

    # auto called for session, return true for OK
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

    def fsend(cmd, data = "") #return data or nil
      packet_data = build_packet(cmd, data)
      result = false
      invalid_frames = 0
      nak_messages = 0
      push packet_data
      ACKS_MAX_WAIT.times do |retries|
        errors.clear
        if resp = frecv(RESPONSE_TIMEOUT)
          if resp.valid?
            human_status_errors(resp.status)
            if errors.empty?
              result = resp.data
              break
            else
              raise errors.full_messages.join(',')
            end
          else #ack, nak or bad
            if resp.nak?
              nak_messages += 1
              if nak_messages > NAKS_MAX_COUNT
                errors.add :base, "#{NAKS_MAX_COUNT} NAKs Received. Abort!"
                break
              end
            elsif !resp.ack?
              invalid_frames += 1
              if nak_messages > INVALID_FRAME_RETRIES
                errors.add :base, "#{INVALID_FRAME_RETRIES} Broken Packets Received. Abort!"
                break
              end
            end
            push packet_data unless resp.ack?
          end
        end
        errors.add :base, "#{ACKS_MAX_WAIT} ACKs Received. Abort!"
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
      def build_sale_data(item)
        "".tap() do |data|
          data << item.text1 unless item.text1.blank?
          data << "\x0a#{text2}" unless item.text2.blank?
          data << "\t"
          data << TAX_GROUPS_MAP[item.tax_group || 2]
          data << item.price.to_s
          data << "*#{item.qty.to_s}" unless item.qty.blank?
          data << ",#{item.percent}" unless item.percent.blank?
          data << "$#{neto}" unless item.neto.blank?
        end
      end
    
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
        #errors.add :base, "Less Paper (Control)" unless (status[2].ord & 0x20).zero?
        #errors.add :base, "Fiscal Doc Open" unless (status[2].ord & 0x08).zero?
        errors.add :base, "No Paper (Control)" unless (status[2].ord & 0x04).zero?
        errors.add :base, "Less Paper" unless (status[2].ord & 0x02).zero?
        errors.add :base, "No Paper" unless (status[2].ord & 0x01).zero?
        
        case (status[3].ord & 0x7f)
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
          if match = buffer.match(/\x01(.{1})(.{1})(.{1})(.*)\x04(.{6})\x05(.{4})\x03/nm)
            @frame = match.to_a.first
            @len, @seq, @cmd, @data, @status, @bcc = match.captures
          else
            if buffer[/^\x16+$/] # only ACKs
              @ack = true
            elsif buffer.index("\x15")
              @nak = true
            end
          end
        end
        
        def ack?  #should wait, response is yet to come
          !!@ack
        end
        
        def nak?  #should retry command with same seq
          !!@nak
        end
        
        private
          def unpacked_msg?
            ack? || nak?
          end
 
          def bcc_validation
            unless unpacked_msg?
              sum = 0
              frame[1..-6].each_byte do |byte|
                sum += byte
              end unless frame.nil?
              calc_bcc = "".tap() do |tbcc|
                4.times do |halfbyte|
                  tbcc.insert 0, (0x30 + ((sum >> (halfbyte*4)) & 0x0f)).chr
                end
              end
              errors.add(:bcc, I18n.t('errors.messages.invalid')) if bcc != calc_bcc
            end
          end
          
          def len_validation
            unless unpacked_msg?
              errors.add(:len, I18n.t('errors.messages.invalid')) if frame.nil? || len.ord != (frame[1..-6].length + 0x20)
            end
          end
      end
  end
end