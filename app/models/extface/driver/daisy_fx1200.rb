# SEND
# 1       2       3       4       5       6       7       8
#STX     LEN     SEQ     CMD     DATA    PA1     BCC     ETX
# 1       1       1       1     0–200     1       4       1
#01h   20h–FFh 20h–FFh 20h–FFh  20h–FFh  05h   30h–3Fh   03h

# RECV
# 1       2       3       4       5       6      7      8      9     10
#STX     LEN     SEQ     CMD     DATA    PA2   STATUS  PA1    BCC    ETX
# 1       1       1       1     0–200     1      6      1      4      1
#01h   20h–FFh 20h–FFh 20h–FFh  20h–FFh  04h  80h–FFh  05h  30h–3Fh  03h

module Extface
  class Driver::DaisyFx1200 < Extface::Driver
    NAME = 'Daisy FX1200 (Serial)'.freeze
    GROUP = Extface::FISCAL_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = false #POS, slip printers
    FISCAL = true #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices    
    
    has_serial_config

    def handle(buffer)
      rpush buffer
      return buffer.length # return number of bytes processed
    end
    
    def autocut(partial = true)
      # <ESC> “d” “0” - Full-cut command
      # <ESC> “d” “1” - Partial-cut command
      #push build_packet(CMD)
      #push partial ? "\x1B\x64\x31" : "\x1B\x64\x30"
    end
    
    private
      def build_packet(cmd, data)
        
      end
      
      def bcc(data)
        bcc = 0
        data.each_byte do |byte|
          bcc += byte
        end
      end
  end
end