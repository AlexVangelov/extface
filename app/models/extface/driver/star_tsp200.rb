module Extface
  class Driver::StarTsp200 < Driver::GenericPos
    NAME = 'Star TSP200 (Base Receipt Protocol)'.freeze
    GROUP = Extface::PRINT_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = true #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices

    has_serial_config
    
    def autocut(partial = true)
      # <ESC> “d” “0” - Full-cut command
      # <ESC> “d” “1” - Partial-cut command
      push "\r\n\r\n\r\n"
      push partial ? "\x1B\x64\x31" : "\x1B\x64\x30"
    end
    
    def status_request
      push "\x05" # <ENQ>   - Causes the printer to transmit a status byte
    end
    
    def human_status_errors(status_byte)
      [].tap do |errors|
        errors << "Vertical parity error" if status_byte & 0x01
        errors << "Framing error" if status_byte & 0x02
        errors << "Mechanical error" if status_byte & 0x04
        errors << "Receipt paper empty" if status_byte & 0x08
        errors << "Buffer overflow" if status_byte & 0x40
      end
    end
  end
end
