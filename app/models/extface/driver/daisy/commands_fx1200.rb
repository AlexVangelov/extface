module Extface
  module Driver::Daisy::CommandsFx1200
    module Init
      DATE_TIME           0x3d
      PRINT_OPTIONS       0x2b
      PRINT_LOGO          0x2b
      PROG_TAX_RATES      0x60
      OPERATOR_PASS       0x65   
      OPERATOR_NAME       0x66
      PROG_SYSTEM_PARAMS  0x96
      PROG_ITEM           0x6b
      DEL_ITEM            0x6b
      PROG_DEPARTAMENT    0x83
      LOGO_LOAD           0x73
      PROG_TEXT_FIELD     0x95
      PROG_PAYMENT        0x97
      SET_ID_AND_FP_NUM   0x5b
      SET_EIK_BULSTAT     0x62
      SET_FISCALIZATION   0x48
    end
    
    module Sales
      START_NON_FISCAL_DOC  0x26
      PRINT_NON_FISCAL_TEXT 0x2a
      END_NON_FISCAL_DOC    0x27
      START_FISCAL_DOC      0x30
      SALE                  0x31
      SALE_AND_SHOW         0x34
      SALE_ITEM             0x3a
      SALE_DEPARTAMENT      0x8a
      SUBTOTAL              0x33
      TOTAL                 0x35
      PRINT_FISCAL_TEXT     0x36
      CANCEL_DOC            0x82
      PRINT_INFO_FOR_CLIENT 0x39
      END_FISCAL_DOC        0x38
      PRINT_DUPLICATE_DOC   0x6d
    end
    
    module Reports
      REPORT_BY_ITEMS           0x6f
      REPORT_BY_OPERATORS       0x69
      GET_TAX_RATES             0x32
      REPORT_FP_BY_NUMBER       0x49
      COMPACT_REPORT_FP_BY_DATE 0x4f
      REPORT_FP_BY_DATE         0x5e
      COMPACT_REPORT_FP_BY_NUM  0x5f
      REPORT_BY_DEPARTAMENTS    0xa5
      REPORT_SYSTEM_PARAMS      0xa6
    end
    
    module Closure
      DAY_FIN_REPORT          0x45
      EXPANDED_DAY_FIN_REPORT 0x6c
      PRINT_EKL               0x45
      RESET_SALES_BY_OPERATOR 0x68
    end
    
    module Info
      DATE_TIME             0x3e
      STATUS                0x4a
      CURRENT_NET_AMMOUNTS  0x41
      LAST_FISCAL_RECORD    0x40
      FREE_FISCAL_RECORDS   0x44
      STATUS_FISCAL_DOC     0x4c
      DIAGNOSTIC_INFO       0x5a
      CURRENT_TAX_RATES     0x61
      EIK_BULSTAT           0x63
      ITEM                  0x6b
      DEPARTAMENT           0x83
      DOC                   0x67
      DAY                   0x6e
      PRINT_OPTIONS         0x2b
      OPERATOR              0x70
      LAST_DOC_NUMBER       0x71
      FP_BY_NUMBER          0x72
      FP_BY_DATE            0x92
      CONSTANTS             0x80
      PRINT_DIAGNOSTIC      0x47
      READ_EKL              0xb1
    end
    
    module Printer
      CUT   0x2c
      MOVE  0x2d
    end
    
    module Other
      ADD_SUB_SUMS    0x46
      OPEN_DRAWER     0x6a
      SHOW_DATE_TIME  0x3f
    end
  end
end