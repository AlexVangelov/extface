module Extface
  class PbxCdrDriver < Extface::DriverBase
    GROUP = 'PBX CDR Loggers (Call Detail Record)'.freeze
    def calls
      raise "Not Impelmened"
    end
    
    def crd?
      true
    end
  end
end
