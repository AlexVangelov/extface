require "extface/engine"
require "extface/routes"
require "extface/mapping"
require "extface/extfaceable"
module Extface
  mattr_accessor :redis
  
  mattr_reader :mappings
  @@mappings = ActiveSupport::OrderedHash.new
  
  class << self
    def add_mapping(resource, options)
      mapping = Extface::Mapping.new(resource, options)
      @@mappings[mapping.name] = mapping
    end
  end 
end
