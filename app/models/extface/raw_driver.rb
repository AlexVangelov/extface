module Extface
  class RawDriver < ActiveRecord::Base
    
    def send(data)
      raise "Not Impelmened"
    end
    
    def receive
      raise "Not Impelmened"
    end
  end
end
