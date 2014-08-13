module Extface
  class Driver::Datecs::Fp550 < Extface::Driver::Base::Fiscal
    NAME = 'Datecs FP550 (Serial)'.freeze

    include Extface::Driver::Datecs::CommandsV1

    def handle(buffer)
      if i = buffer.index(/[\x03\x16\x15]/)   # find position of frame possible delimiter
        rpush buffer[0..i]                    # this will make data available for #pull(timeout) method
        return i+1                            # return number of bytes processed
      end
    end
    
    def check_status
      flush #clear receive buffer
      fsend(Info::GET_STATUS, 'X') # get 6 bytes status
      errors.empty?
    end
    
    def fsend(cmd, data = "") #return data or nil
      packet_data = build_packet(cmd, data) #store packet to be able to re-transmit it with the same sequence number
      invalid_frames = 0 #counter for bad responses
      nak_messages = 0 #counter for rejected packets (should re-transmit the packet)
      push packet_data #send packet
      begin
        errors.clear #start with slate clean
        if resp = frecv(RESPONSE_TIMEOUT)
          
        end
      end
    end
    
    def build_packet(cmd, data = "")
      "".b.tap() do |packet|
        packet << STX                     #Preamble. 1 byte long. Value: 01H.
        packet << 0x20 + 4 + data.length  #Number of bytes from <01> preamble (excluded) to <05> (included) plus the fixed offset of 20H
        packet << sequence_number         #Sequence number of the frame. Length : 1 byte. Value: 20H – FFH.
        packet << cmd                     #Length: 1 byte. Value: 20H - 7FH.
        packet << data                    #Length: 0 - 218 bytes for Host to printer
        packet << PA1                     #Post-amble. Length: 1 byte. Value: 05H.
        packet << bcc(packet[1..-1])      #Control sum (0000H-FFFFH). Length: 4 bytes. Value of each byte: 30H-3FH
        packet << ETX                     #Terminator. Length: 1 byte. Value: 03H.
      end
    end
    
    private
      def bcc(buffer)
        sum = 0
        buffer.each_byte do |byte|
          sum += byte
        end
        "".tap() do |bcc|
          4.times do |halfbyte|
            bcc.insert 0, (0x30 + ((sum >> (halfbyte*4)) & 0x0f)).chr
          end
        end
      end
      
      def sequence_number
        @seq ||= 0x1f
        @seq += 1
        @seq = 0x1f if @seq == 0x7f
        @seq
      end

  end
end