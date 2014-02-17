module Extface
  class Driver::FixedWidthSerialCdr < Extface::PbxCdrDriver
    NAME = 'PBX CDR Fixed Width Parser'.freeze
    has_serial_config
  end
end