module Extface
  class Driver::GenericEscPos < Extface::Driver::Base::Print
    NAME = 'Generic ESC/POS Printer'.freeze
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)

  end
end
