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
    
    def handle(buffer)
      #expecting only 1 status byte, move it to receive_buffer
      rpush buffer
      return buffer.length # return number of bytes processed
    end
    
    def autocut(partial = true)
      # <ESC> “d” “0” - Full-cut command
      # <ESC> “d” “1” - Partial-cut command
      push "\r\n\r\n\r\n"
      push partial ? "\x1B\x64\x31" : "\x1B\x64\x30"
    end
    
    def check_status
      flush
      push "\x05" # <ENQ>   - Causes the printer to transmit a status byte
      if status = pull(3) #wait 3 sec for data
        human_status_errors(status)
        return errors.empty?
      else
        errors.add :base, "No data received from device"
        return false
      end
    end
    
    def human_status_errors(status_byte)
      errors.add :base, "Vertical parity error" unless (status_byte.ord & 0x01).zero?
      errors.add :base, "Framing error" unless (status_byte.ord & 0x02).zero?
      errors.add :base, "Mechanical error" unless (status_byte.ord & 0x04).zero?
      errors.add :base, "Receipt paper empty" unless (status_byte.ord & 0x08).zero?
      errors.add :base, "Buffer overflow" unless (status_byte.ord & 0x40).zero?
    end

  end
end
