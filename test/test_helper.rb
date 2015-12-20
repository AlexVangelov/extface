# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)


class ActiveSupport::TestCase
  # load db schema
  ActiveRecord::Schema.verbose = false
  load "#{Rails.root}/db/schema.rb"
  
  fixtures :all
  
  def simulate_device_pull(job)
    result = nil
    Extface.redis_block do |r|
      list, data = r.blpop(job.id, timeout: 1)
      while data
        result = data
        r.publish(job.id, "OK")
        list, data = r.blpop(job.id, timeout: 1)
      end
    end #simulate send to device
    result
  end
end
module Extface
  class ActionController::TestCase
    setup do
      @routes = Extface::Engine.routes
    end
    module Behavior
      def process_with_shop(action, http_method = 'GET', parameters = nil, session = nil, flash = nil)
        parameters = { shop_id: shops(:one) }.merge(parameters || {})
        process_without_shop(action, http_method, parameters, session, flash)
      end
      alias_method_chain :process, :shop
    end
  end
  class ActionDispatch::Routing::RouteSet
    def default_url_options(options={})
      options.merge(shop_id: Shop.first)
    end
  end
end
