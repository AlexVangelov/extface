module Extface
  class PosPrintDriver < Extface::DriverBase
    GROUP = 'POS Printers'.freeze
    def print(buffer)
      raise "Not Impelmented"
    end
    
    def print_test_page(times = 1)
      device.session("Print Test Page") do |s|
        times.times do |t|
        s.notify "Printing Test Page #{t}"
        s.print "******************************\r\n*"
        s.print "Extface Print Test #{t}".center(28)
        s.print "*\r\n******************************\r\n"

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
    end
    
    def print?
      true
    end
    
  end
end
