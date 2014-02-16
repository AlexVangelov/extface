module Extface
  class FiscalPrintDriver < ActiveRecord::Base
    
    def fiscal?
      true
    end
  end
end
