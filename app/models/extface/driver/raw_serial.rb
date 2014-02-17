module Extface
  class Driver::RawSerial < Extface::RawDriver
    NAME = 'RAW Serial'.freeze
    has_serial_config
  end
end
