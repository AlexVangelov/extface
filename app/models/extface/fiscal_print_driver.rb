module Extface
  class FiscalPrintDriver < Extface::DriverBase
    GROUP = 'Fiscal Printers'.freeze
    def fiscal?
      true
    end
  end
end
