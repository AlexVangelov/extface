module Extface
  module Driver::Datecs::CommandsV1
    STX = 0x01
    PA1 = 0x05
    PA2 = 0x04
    ETX = 0x03
    
    NAK = 0x15
    SYN = 0x16

    module Init
      SET_MEMORY_SWITCHES         = 0x29
      SET_FOOTER                  = 0x2B
      SET_HEADER                  = 0x2E
      DATE_AND_HOUR               = 0x3D
      FISCALIZATION               = 0x48
      SET_MUL_DP_TAX_VAT          = 0x53
      DEF_ADD_PAYMENT_TYPE_NAMES  = 0x55
    end

    module Info
      GET_DATE_HOUR               = 0x3E
      GET_STATUS                  = 0x4A
    end
    
    module Printer
      PAPER_MOVE                  = 0x2C
      PAPER_CUT                   = 0x2D
    end
    
    module Sales
      START_NON_FISCAL_DOC  = 0x26  #other
      END_NON_FISCAL_DOC    = 0x27  #other
      PRINT_NON_FISCAL_TEXT = 0x2a  #other
      START_FISCAL_DOC      = 0x30
      SALE                  = 0x31
      SUBTOTAL              = 0x33
      SALE_AND_SHOW         = 0x34
      TOTAL                 = 0x35
      PRINT_FISCAL_TEXT     = 0x36
      END_FISCAL_DOC        = 0x38
      PRINT_INFO_FOR_CLIENT = 0x39
      SALE_ITEM             = 0x3a
      CANCEL_FISCAL_DOC     = 0x3c
      PRINT_BARCODE         = 0x54
      PRINT_DUPLICATE_DOC   = 0x6d
    end
    
    module Reports
      REPORT_FP_BY_NUMBER         = 0x49
      COMPACT_REPORT_FP_BY_DATE   = 0x4f
      REPORT_FP_BY_DATE           = 0x5e
      COMPACT_REPORT_FP_BY_NUM    = 0x5f
      REPORT_BY_OPERATORS         = 0x69
      REPORT_BY_ITEMS             = 0x6F
    end
    
    module Closure
      DAY_FIN_REPORT                    = 0x45
      EXPANDED_DAY_FIN_REPORT           = 0x6c
      EXPANDED_DAY_FIN_REPORT_BY_DEPS   = 0x75
      EXPANDED_DAY_FIN_REPORT_BY_ITEMS  = 0x76
    end
    
    module Other
      PAYED_RECV_ACCOUNT  = 0x46
    end
  end
end