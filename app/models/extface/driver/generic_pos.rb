module Extface
  class Driver::GenericPos < Extface::Driver
    NAME = 'Generic Pos Printer (Serial)'.freeze
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)

    CAN_RECEСVE_DATA = true #pull from server
    CAN_TRANSMIT_DATA = true #push to server
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = true #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices    
    
    has_serial_config
    alias_method :print, :push
    
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
        
        s.try :autocut
        end
      end
    end
    
  end
end
