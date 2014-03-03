module Extface
  class Driver::StarScp700 < Extface::Driver::StarTsp200
    NAME = 'Star SCP700 (Receipt only)'.freeze
    GROUP = Extface::PRINT_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = true #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices    
    
    def autocut(partial = true)
      print "\r\n\r\n\r\n"
      print partial ? "\x1B\x64\x31" : "\x1B\x64\x30"
    end
  end
end
