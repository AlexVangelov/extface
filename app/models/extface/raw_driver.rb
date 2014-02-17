module Extface
  class RawDriver < Extface::DriverBase
    GROUP = 'RAW Communication'.freeze
    def send(data)
      raise "Not Impelmened"
    end
    
    def receive
      raise "Not Impelmened"
    end
  end
end
