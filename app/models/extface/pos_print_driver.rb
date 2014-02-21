module Extface
  class PosPrintDriver < Extface::DriverBase
    GROUP = 'POS Printers'.freeze
    def print(buffer)
      raise "Not Impelmented"
    end
    
    def print_test_page
      device.session("Print Test Page") do |s|
        sleep 1
        s.notify "Printing Test Page"
        s.print "******************************\r\n"
        s.print "*  Extface Print Test Page   *\r\n"
        s.print "******************************\r\n"

        s.notify "Printing driver information"
        s.print "\r\nDriver:\r\n"
        s.print "------------------------------\r\n"
        s.print "#{self.class::NAME}".truncate(30)
        s.print "\r\n"

        if try(:serial?)
          s.notify "Printing serial settings"
          s.print "\r\nSerial Port Settings:\r\n"
          s.print "------------------------------\r\n"
        end

        s.print "\r\n"
        s.print "------------------------------\r\n"
        s.print Time.now.strftime("Printed on %m/%d/%Y %T\r\n").rjust(32)
        s.print "\r\n\r\n"
        s.notify "Printing finished"
        
        if s.try(:autocutter?)
          s.autocut
        end
      end
    end
    
    def print?
      true
    end
    
  end
end
