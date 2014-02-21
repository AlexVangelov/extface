module Extface
  class Driver::GenericPos < Extface::PosPrintDriver
    NAME = 'Generic Pos Printer (Serial)'.freeze
    has_serial_config
    alias_method :print, :push
  end
end
