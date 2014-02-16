module Extface
  class Device < ActiveRecord::Base
    belongs_to :extfaceable, polymorphic: true
    belongs_to :driveable, polymorphic: true
    accepts_nested_attributes_for :driveable
    
    validates_uniqueness_of :name, :uuid, scope: [:extfaceable_id, :extfaceable_type]
    
    before_create do
      self.uuid = SecureRandom.hex
      self.name = uuid unless name.present?
    end
    
    def fiscal?
      drivable.try(:fiscal?)
    end
  end
end
