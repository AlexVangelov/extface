module Extface
  class Driver::StarTsp200 < Driver::GenericPos
    NAME = 'Star TSP200 (Base Receipt Protocol)'.freeze
    GROUP = Extface::PRINT_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)

    CAN_RECEСVE_DATA = true #pull from server
    CAN_TRANSMIT_DATA = true #push to server
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = true #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices

    has_serial_config
  end
end
