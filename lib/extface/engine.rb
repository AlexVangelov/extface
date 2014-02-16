require "redis"
module Extface
  class Engine < ::Rails::Engine
    isolate_namespace Extface
  
    config.to_prepare do
      # Thread.new do
        # $redis.subscribe("extface") do |on|
          # on.message do |channel, msg|
            # #data = JSON.parse(msg)
            # p "##{channel} - #{msg}"
          # end
        # end
      # end
    end
  end
end
