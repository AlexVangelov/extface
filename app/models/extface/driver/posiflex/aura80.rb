module Extface
  class Driver::Posiflex::Aura80 < Extface::Driver::Base::Print
    NAME = 'Posiflex (Aura 80mm)'.freeze
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    CHAR_COLUMNS = 49

    include Extface::Driver::Posiflex::AuraCommands
    
    def handle(buffer)
      #expecting only 1 status byte, move it to receive_buffer
      rpush buffer
      return buffer.length # return number of bytes processed
    end
    
    def autocut(partial = true)
      push "\r\n\r\n\r\n"
      push Printer::PAPER_CUT
    end
    
    def check_status
      flush
      push Info::GET_PAPER_STATUS
      if status = pull(3) #wait 3 sec for data
        human_status_errors(status)
        return errors.empty?
      else
        errors.add :base, "No data received from device"
        return false
      end
    end
    
    private
    
      def human_status_errors(status_byte)
        errors.add :base, "Paper out" unless (status_byte.ord & 0x0C).zero?
      end
  end
end
