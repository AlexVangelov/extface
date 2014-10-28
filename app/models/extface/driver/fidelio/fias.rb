module Extface
  class Driver::Fidelio::Fias < Extface::Driver
    NAME = 'Fidelio FIAS Simple Posting (TCP/IP)'.freeze
    GROUP = Extface::RAW_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = false #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices
    
    STX = 0x02
    ETX = 0x03
    
    def handle(buffer)
      if i = buffer.index(/\x03/)   # find position of frame possible delimiter
        rpush buffer[0..i]                    # this will make data available for #pull(timeout) method
        return i+1                            # return number of bytes processed
      end
    end
    
    def ps(room, price)
      push build_packet("PS|RN#{room}|PTC|TA#{(price*100).to_i}")
      if status = pull(3)
        tags = inspect_frame(status)
        if tags.include? "ASUR"
          err_tag = tags.find{ |t| t.starts_with? "CT" } 
          errors.add :base, "FIAS ERROR: #{err_tag[2..-1]}"
        end
      else
        errors.add :base, "No data received from device"
      end
      errors.empty?
    end
    
    def test(params = {})
      device.session("Simple Post") do |s|
        s.push build_packet("PS|RN101|PTC|TA200")
        if status = pull(3)
          tags = inspect_frame(status)
          if tags.include? "ASUR"
            err_tag = tags.find{ |t| t.starts_with? "CT" } 
            raise "FIAS ERROR: #{err_tag[2..-1]}"
          end
        else
          raise "No data received from device"
        end
      end
    end
    
    def check_status
      flush
      push build_packet("LS")
      if status = pull(3)
        tags = inspect_frame(status)
        if tags.include? "ASUR"
          err_tag = tags.find{ |t| t.starts_with? "CT" } 
          errors.add :base, err_tag[2..-1]
        end
        errors.empty?
      else
        errors.add :base, "No data received from device"
        return false
      end
    end
    
    def build_packet(data = "")
      "".b.tap() do |packet|
        packet << STX
        packet << data
        packet << "|DA#{Date.today.strftime("%y%m%d")}|TI#{Time.now.strftime("%H%M%S")}|"
        packet << ETX
      end
    end
    
    private
      def inspect_frame(buffer)
        if match = buffer.match(/\x02(.+)\x03/nm)
          return match[1].split("|")
        else
          errors.add :base, "Invalid data received from device"
        end
        return nil
      end
  end
end