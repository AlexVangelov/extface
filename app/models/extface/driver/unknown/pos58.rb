module Extface
  class Driver::Unknown::Pos58 < Extface::Driver::Base::Print
    NAME = 'POS58'.freeze
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    CHAR_COLUMNS = 32
  end
end
