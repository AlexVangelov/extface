module Extface
  class DriverBase < ActiveRecord::Base
    self.abstract_class = true
    
    class << self
      def has_serial_config
        has_one :serial_config, as: :s_configureable
        accepts_nested_attributes_for :serial_config
        define_method :serial? do
          true
        end
      end
    end
  end
end
