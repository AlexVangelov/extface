#Source: ELTRADE COMMUNICATION PROTOCOL for Fiscal Printers (ver 4.0.2.12)

module Extface
  module Driver::Eltrade::CommandsFp4
    STRT = "\xAA\x55"
    
    module Info
      GET_SERIAL_NUMBER     = 0x10
      GET_HEADING_ROWS_1_6  = 0x11
      GET_FISC_MEM_NUMBER   = 0x14
      GET_TAX_NUMBER        = 0x15
      GET_HEADING_ROWS_7_10 = 0x17
      GET_TAX_GROUPS        = 0x19
      GET_OPERATOR          = 0x1A
      GET_PAYMENTS          = 0x1B
      GET_PRINTER_STATUS    = 0x2C
      GET_FISCAL_STATUS     = 0x30
      GET_FISCAL_TYPE       = 0x3C
      GET_DATE_TIME         = 0x3E
      REQUEST_HARDWARE_STAT = 0x46
      GET_HARDWARE_STATUS   = 0x47
      GET_STATUS            = 0x70
    end
    module Receipt
      OPEN_RECEIPT          = 0x2D
      START_RECEIPT         = 0x2E
      CLOSE_RECEIPT         = 0x2F
      LAST_DOC_COPY         = 0x31
      SET_INVOICE_NUMBER    = 0x34
      PRINT_RECEIPT_HEADER  = 0x38
    end
    module Reports
      SILENT0_PLU           = 0x22
      SILENT_PRINTER        = 0x23
      PLU_REPORT            = 0x32
      DAILY_REPORT          = 0x33
    end
    module Init
      GRAPHIC_LOGO_PRINTING = 0x13
      SET_OPERATOR_INFO     = 0x2A
      SET_PAYMENT_TYPES     = 0x2B
      SET_FISCAL_DEV_NUM    = 0x35
      FISCAL_PARAMS_REC     = 0x36
      SET_PRINT_PLU_NUMBER  = 0x3A
      SET_SERIAL_NUMBER     = 0x3B
      SET_DATE_TIME         = 0x3D
    end
    module Other
      EXEC_PRINTER_TEST   = 0x24
      FISC_MEM_READ_TEST  = 0x25
      FISC_MEM_WRITE_TEST = 0x26
      PAYED_RECV_ACCOUNT  = 0x28  # ?
      GET_DATE_TIME       = 0x3E
      SET_DATE_TIME       = 0x3D
      OPEN_CASH_DRAWER    = 0x4B
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
  end
end