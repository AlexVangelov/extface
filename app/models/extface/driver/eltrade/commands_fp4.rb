module Extface
  module Driver::Epson::Fiscal
    STX = 0x02
    ETX = 0x03
    SEP = 0x1c
    DC2 = 0x12
    DC4 = 0x14
    NAK = 0x15
    
    module Control
      STATUS_IF             = 0x38
      X_Z_REPORTS           = 0x39
      FISC_MEM_REPORT_DATE  = 0x3a
      FISC_MEM_REPORT       = 0x3b
    end
    module Vouchers
      OPEN_FISCAL_VOUCHER   = 0x40
      PRINT_FISCAL_TEXT     = 0x41
      PRINT_FISCAL_ARTICLE  = 0x42
      SUBTOTAL_FISCAL       = 0x43
      FISCAL_VOUCHER        = 0x44  # pay / cancel / discount in
      CLOSE_FISCAL_VOUCHER  = 0x45
    end
    module NonFiscal
      OPEN_NON_FISCAL_DOC   = 0x48
      PRINT_NON_FISCAL_TEXT = 0x49
      CLOSE_NON_FISCAL_DOC  = 0x4a
    end
    module Printer
      CUT_PAPER         = 0x4b
      ADVANCE_PAPER     = 0x50
      ACTIVATE_SLIP     = 0xa0 #TMU950, TMU675
      DISABLE_SLIP      = 0xa1
      FORMAT_CHECKS     = 0xaa
      FORMAT_ENDOSEMENT = 0xab
    end
    module General
      SET_DATE_HOUR   = 0x58
      GET_DATE_HOUR   = 0x59
      HEADED          = 0x5d
      FOOT_OF_PAGE    = 0x5e
      OPEN_DRAWER_1   = 0x7b
      OPEN_DRAWER_2   = 0x7c
    end
    
    def handle(buffer)
      bytes_processed = 0
      if frame_match = buffer.match(/\x02.*\x03.{4}/n)
        frame_data = frame_match.to_s
        rpush frame_data
        bytes_processed = frame_match.pre_match.length + frame_data.length
      end
      return bytes_processed
    end

    def build_packet(cmd, fields = [])
      String.new.tap() do |frame|
        frame << STX
        frame << sequence_number
        frame << cmd
        fields.each do |field|
          frame << SEP
          frame << field
        end
        frame << ETX
        frame << bcc(frame)
      end
    end
    
    private
      def bcc(buffer)
        sum = 0
        buffer.each_byte do |b|
          sum += b
        end
        sum.to_s(16).rjust(4, '0')
      end
      
      def sequence_number(increment = true)
        @seq ||= 0x20
        @seq += 1 if increment
        @seq = 0x20 if @seq == 0x7f
        @seq
      end
      
      class Frame
        include ActiveModel::Validations
        attr_reader :frame, :seq, :cmd, :fields_data, :fields, :bcc

        def initialize(buffer)
          if match = buffer.match(/\x02([\x20-\x7F])([\x30-\xaf])\x1c(.*)\x03(.{4})/n)
            @frame = match.to_a.first
            @seq, @cmd, @fileds_data, @bcc = match.captures
            @fields = @fields_data.split("\x1c")
          end
        end
      end
  end
end