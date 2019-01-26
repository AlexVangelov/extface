module Extface
  class Driver::Datecs::Fp550 < Extface::Driver::Base::Fiscal
    NAME = 'Datecs FP550 (Serial)'.freeze
    
    RESPONSE_TIMEOUT = 3  #seconds
    INVALID_FRAME_RETRIES = 6  #count (bad length, bad checksum)
    ACKS_MAX_WAIT = 60 #count / nothing is forever
    NAKS_MAX_COUNT = 3 #count
    BAD_SEQ_MAX_COUNT = 3
    NO_RESP_MAX_COUNT = 3
    
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
    
    PAYMENT_TYPE_MAP = {
      1 => "P",
      2 => "N",
      3 => "C",
      4 => "D",
      5 => "B"
    }

    include Extface::Driver::Datecs::CommandsV1

    def handle(buffer)
      #if i = buffer.index(/[\x03\x16\x15]/)   # find position of frame possible delimiter
      if i = buffer.index("\x03") || buffer.index("\x16") || buffer.index("\x15")
        rpush buffer[0..i]                    # this will make data available for #pull(timeout) method
        return i+1                            # return number of bytes processed
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
        s.fsend Printer::PAPER_MOVE, "1"
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
      device.session("Period Report #{ '(detailed)' if detailed }") do |s|
        s.notify "Period Report Start #{ '(detailed)' if detailed }"
        s.fsend detailed ? Reports::REPORT_FP_BY_DATE : Reports::COMPACT_REPORT_FP_BY_DATE, "#{from.strftime('%d%m%y')},#{to.strftime('%d%m%y')}"
        s.notify "Period Report End"
      end
    end
    
    #print
    def open_non_fiscal_doc
      fsend Sales::START_NON_FISCAL_DOC
      @print_session = true
    end
    
    def print(text) #up to 38 sybols, TODO check
      raise "Not in print session" unless @print_session
      fsend Sales::PRINT_NON_FISCAL_TEXT, text
    end
    
    def close_non_fiscal_doc
      fsend Sales::END_NON_FISCAL_DOC
      @print_session = false
    end
    
    def check_status
      flush #clear receive buffer
      fsend(Info::GET_STATUS, 'X') # get 6 bytes status
      errors.empty?
    end
    
    #fiscal
    def open_fiscal_doc(operator = "1", password = "000000")
      fsend Sales::START_FISCAL_DOC, "#{operator.presence || "1"},#{password.presence || "000000"},00001"
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
    
    def add_payment(value = nil, type_num = nil)
      raise "Not in fiscal session" unless @fiscal_session
      payment_data = "".tap() do |data|
                            data << "\t"
                            data << PAYMENT_TYPE_MAP[type_num || 1]
                            data << ("%.2f" % value) unless value.blank?
                          end
      fsend(Sales::TOTAL, payment_data)
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
        s.fsend Sales::CANCEL_FISCAL_DOC
        s.paper_cut
        s.notify "Doc Cancel End"
      end
    end
    
    #common
    def fsend(cmd, data = "") #return data or nil
      packet_data = build_packet(cmd, data) #store packet to be able to re-transmit it with the same sequence number
      result = false
      invalid_frames = 0 #counter for bad responses
      nak_messages = 0 #counter for rejected packets (should re-transmit the packet)
      no_resp = 0
      flush #prevent double packet response issue like daisy driver
      push packet_data #send packet
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
              if invalid_frames > INVALID_FRAME_RETRIES
                errors.add :base, "#{INVALID_FRAME_RETRIES} Broken Packets Received. Abort!"
                break
              end
            end
            push packet_data unless resp.ack?
          end
        else
          no_resp += 1
          if no_resp > NO_RESP_MAX_COUNT
            p "No reply in #{NO_RESP_MAX_COUNT * RESPONSE_TIMEOUT} seconds. Abort!"
            errors.add :base, "No reply in #{NO_RESP_MAX_COUNT * RESPONSE_TIMEOUT} seconds. Abort!"
            return result
          end
        end
        errors.add :base, "#{ACKS_MAX_WAIT} ACKs Received. Abort!"
      end
      return result
    end
    
    def frecv(timeout) # return Frame or nil
      rframe = nil
      BAD_SEQ_MAX_COUNT.times do
        errors.clear
        if frame_bytes = pull(timeout)
          rframe = Frame.new(frame_bytes.b)
          if rframe.seq.nil? || rframe.seq.ord == sequence_number(false) #accept only current sequence number as reply
            break
          else
            errors.add :base, "Sequence mismatch"
            p "Invalid sequence (expected: #{sequence_number(false).to_s(16)}, got: #{rframe.seq.ord.to_s(16)})"
            rframe = nil #invalidate mismatch sequence frame for the last retry
          end
        else
          errors.add :base, "No data received from device"
          break
        end
      end
      return rframe
    end
    
    def build_packet(cmd, data = "")
      "".b.tap() do |packet|
        packet << STX                     #Preamble. 1 byte long. Value: 01H.
        packet << 0x20 + 4 + data.b.length  #Number of bytes from <01> preamble (excluded) to <05> (included) plus the fixed offset of 20H
        packet << sequence_number         #Sequence number of the frame. Length : 1 byte. Value: 20H – FFH.
        packet << cmd                     #Length: 1 byte. Value: 20H - 7FH.
        packet << data.b                  #Length: 0 - 218 bytes for Host to printer
        packet << PA1                     #Post-amble. Length: 1 byte. Value: 05H.
        packet << Frame.bcc(packet[1..-1])#Control sum (0000H-FFFFH). Length: 4 bytes. Value of each byte: 30H-3FH
        packet << ETX                     #Terminator. Length: 1 byte. Value: 03H.
      end
    end
    
    def paper_cut
      device.session('Paper Cut') do |s|
        s.push build_packet(Printer::PAPER_CUT)
      end
    end
    
    def human_status_errors(status) #6 bytes status
      status_0 = status[0].ord
      errors.add :base, "Fiscal Device General Error" unless (status_0 & 0x20).zero?
      errors.add :base, "Invalid Command" unless (status_0 & 0x02).zero?
      errors.add :base, "Date & Time Not Set" unless (status_0 & 0x04).zero?
      errors.add :base, "Syntax Error" unless (status_0 & 0x01).zero?
      status_1 = status[1].ord
      errors.add :base, "Unpermitted Command In This Mode" unless (status_1 & 0x02).zero?
      errors.add :base, "Field Overflow" unless (status_1 & 0x01).zero?
    end
    
    def build_sale_data(item)
      # encoded_text1 = device.encoding.present? ? item.text1.encode(device.encoding).b : item.text1
      # encoded_text1 = encoded_text1.mb_chars.slice!(0..27).to_s.b + '...' if encoded_text1 && encoded_text1.b.length > 30

      # encoded_text2 = device.encoding.present? ? item.text2.encode(device.encoding).b : item.text2
      # encoded_text2 = encoded_text2.mb_chars.slice!(0..27).to_s.b + '...' if encoded_text2 && encoded_text2.b.length > 30
      
      #http://extface.com/pos/fpi/bills/171257
      encoded_text1 = device.encoding.present? ? item.text1.encode(device.encoding) : item.text1
      encoded_text1 = encoded_text1.mb_chars.limit(27).to_s + '...' if encoded_text1 && encoded_text1.b.length > 30

      encoded_text2 = device.encoding.present? ? item.text2.encode(device.encoding) : item.text2
      encoded_text2 = encoded_text1.mb_chars.limit(27).to_s + '...' if encoded_text2 && encoded_text2.b.length > 30

      "".b.tap() do |data|
        data << encoded_text1 unless encoded_text1.blank?
        data << "\x0a#{encoded_text2}" unless encoded_text2.blank?
        data << "\t"
        data << TAX_GROUPS_MAP[item.tax_group || 2].b
        data << ("%.2f" % item.price)
        data << "*#{item.qty.to_s}" unless item.qty.blank?
        data << ",#{item.percent}" unless item.percent.blank?
        data << ",;#{'%.2f' % item.neto}" unless item.neto.blank?
      end
    end

    private  
      def sequence_number(increment = true)
        @seq ||= 0x1f
        @seq += 1 if increment
        @seq = 0x1f if @seq == 0x7f
        @seq
      end
      
      class Frame
        include ActiveModel::Validations
        attr_reader :frame, :len, :seq, :cmd, :data, :status, :bcc
        
        validates_presence_of :frame#, unless: :unpacked?
        validate :bcc_validation
        validate :len_validation
        
        def initialize(buffer)
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
        
        def ack?; !!@ack; end #should wait, response is yet to come
        
        def nak?; !!@nak; end #should retry command with same seq
        
        private

          def unpacked? # is it packed or unpacked message?
            @ack || @nak
          end

          def bcc_validation
            unless unpacked? || frame.blank?
              calc_bcc = self.class.bcc frame[1..-6]
              errors.add(:bcc, I18n.t('errors.messages.invalid')) if bcc != calc_bcc
            end
          end
          
          def len_validation
            unless unpacked? || frame.blank?
              errors.add(:len, I18n.t('errors.messages.invalid')) if frame.nil? || len.ord != (frame[1..-6].length + 0x20)
            end
          end
        
          class << self
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
          end
      end

  end
end
