require "extface/engine"
require "extface/routes"
require "extface/mapping"
require "extface/extfaceable"
module Extface
  mattr_accessor :redis_connection_string
  
  mattr_reader :mappings
  @@mappings = ActiveSupport::OrderedHash.new
  
  class << self
    def setup
      yield self
    end

    def add_mapping(resource, options)
      mapping = Extface::Mapping.new(resource, options)
      @@mappings[mapping.name] = mapping
    end
    
    def redis_block
      r = redis_instance
      begin
        yield r
      ensure
        r.quit
      end
    end
    
    private
      def redis_instance
        if @@redis_connection_string
          uri = URI.parse(@@redis_connection_string)
          Redis.new(host: uri.host, port: uri.port, password: uri.password)
        else
          Redis.new
        end
      end
  end 
end
