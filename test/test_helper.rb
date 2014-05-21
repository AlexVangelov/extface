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
end
module Extface
  class ActionController::TestCase
    setup do
      @routes = Engine.routes
    end
  end
end