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
  end
end