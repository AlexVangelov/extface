module Extface
  class RawDriver < Extface::DriverBase
    GROUP = 'RAW Communication'.freeze
    def push(data)
      raise "Not Impelmened"
    end
    
    def receive
      raise "Not Impelmened"
    end
    
    def raw?
      true
    end
  end
end
