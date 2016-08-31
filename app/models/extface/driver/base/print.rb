module Extface
  class Driver::Base::Print < Extface::Driver
    self.abstract_class = true
    
    NAME = 'Print Device Name'.freeze
    GROUP = Extface::PRINT_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = true #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices
    
    CHAR_COLUMNS = 30
    
    #alias_method :print, :push
    def print(text)
      if device.encoding.present?
        push text.encode(device.encoding)
      else
        push text
      end
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
        
        s.try :autocut
        end
      end
    end
    
    def check_status
      return true #just pass
    end
    
    def print_edges_row(text1, text2)
      print "#{text1} #{text2.rjust(CHAR_COLUMNS - text1.length - 1)}\r\n"
    end
    
    def print_text_price_row(text, price)
      rtext = ("%.2f" % price.to_f)
      lsize = CHAR_COLUMNS - rtext.length - 1
      print "#{text.truncate(lsize).ljust(lsize)} #{rtext}\r\n"
    end
    
    def print_fill_row(pattern)
      print "\r\n".rjust(CHAR_COLUMNS+2, pattern)
    end
    
    def print_rjust_row(text, padstr=' ')
      print "#{text.truncate(CHAR_COLUMNS).rjust(CHAR_COLUMNS, padstr)}\r\n"
    end
    
    def print_ljust_row(text, padstr = ' ', margin=0)
      print "#{text.truncate(CHAR_COLUMNS - margin).ljust(CHAR_COLUMNS - margin)}\r\n"
    end
    
    def print_center_row(text, padstr = ' ')
      print "#{text.truncate(CHAR_COLUMNS).center(CHAR_COLUMNS, padstr)}\r\n"
    end
    
    def printize(bill, detailed = false, payments = true)
      if detailed
        device.session("Fiscal Doc") do |s|
          s.notify "Print Doc Start"
          s.print "******************************\r\n*"
          s.print "Extface Print Bill".center(28)
          s.print "*\r\n******************************\r\n"
          s.notify "Print Sale"
          bill.charges.each do |charge|
          end
        end
      else
        
      end
    end
    
  end
end