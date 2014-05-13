module Extface
  module Extfaceable
    extend ActiveSupport::Concern
    
    def composite_id
      "#{(self.class.try(:base_class) || self.class).send(:name)}##{self.id}"
    end
    
    module ClassMethods
      def has_extface_devices
        has_many :extface_devices, class_name: 'Extface::Device', as: :extfaceable
      end
    end

  end
end
ActiveRecord::Base.send :include, Extface::Extfaceable