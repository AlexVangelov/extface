require "extface/engine"
require "extface/routes"
require "extface/mapping"
require "extface/extfaceable"
module Extface
  mattr_accessor :redis_connection_string
  
  mattr_reader :mappings
  @@mappings = ActiveSupport::OrderedHash.new
  
  class << self
    def add_mapping(resource, options)
      mapping = Extface::Mapping.new(resource, options)
      @@mappings[mapping.name] = mapping
    end
    
    def redis_block
      r = Redis.new
      begin
        yield r
      ensure
        r.quit
      end
    end
    
    private
      def parse_redis_url
        if @@redis_connection_string
          uri = URI.parse(@@redis_connection_string)
          return {:host => uri.host, :port => uri.port, :password => uri.password}
        end
      end
  end 
end
