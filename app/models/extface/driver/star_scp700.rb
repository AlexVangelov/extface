module Extface
  class Driver::StarScp700 < Extface::Driver::StarTsp200
    NAME = 'Star SCP700 (Receipt only)'.freeze
    
    def autocut(partial = true)
      print "\r\n\r\n\r\n"
      print partial ? "\x1B\x64\x31" : "\x1B\x64\x30"
    end
  end
end
