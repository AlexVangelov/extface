module Extface
  class Driver::DatecsFp550 < Extface::FiscalPrintDriver
    NAME = 'Datecs FP550'.freeze
    has_serial_config
  end
end
