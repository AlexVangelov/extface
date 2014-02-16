module Extface
  module Extfaceable
    def has_extface_devices
      has_many :extface_devices, class_name: 'Extface::Device', as: :extfaceable
    end
  end
end
ActiveRecord::Base.extend Extface::Extfaceable