module Extface
  class Driver::StarTsp200 < Extface::PosPrintDriver
    NAME = 'Star TSP200 (Base Receipt Protocol)'.freeze
    has_serial_config
  end
end
