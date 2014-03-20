require 'extface/driver/epson/esc_pos'
require 'extface/driver/epson/fiscal'
module Extface
  class Driver::EpsonTmU220 < Driver::GenericPos
    NAME = 'Epson TM-U220 (Serial)'.freeze
    GROUP = Extface::FISCAL_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = true #POS, slip printers
    FISCAL = true #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices    
    
    has_serial_config
    
    include Extface::Driver::Epson::EscPos
    include Extface::Driver::Epson::Fiscal
  end
end