module Extface
  class SerialConfig < ActiveRecord::Base
    BOUD_RATES = [2400, 4800, 9600, 19200, 38400].freeze
    DATA_LENGTHS = [7, 8].freeze
    PARITY_CHECKS = [0, 1, 2].freeze
    STOP_BITS = [1, 2].freeze
    HANDSHAKE = [0, 1, 2].freeze
    belongs_to :driver, inverse_of: :serial_config
  end
end
