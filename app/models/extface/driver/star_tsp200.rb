module Extface
  class Driver::StarTsp200 < Driver::GenericPos
    NAME = 'Star TSP200 (Base Receipt Protocol)'.freeze
    has_serial_config
  end
end
