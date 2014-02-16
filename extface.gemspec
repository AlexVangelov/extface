$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "extface/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "extface"
  s.version     = Extface::VERSION
  s.authors     = ["Alex Vangelov"]
  s.email       = ["alexandervangelov@gmail.com"]
  s.homepage    = "http://matrixdoc.net"
  s.summary     = "External interfaces for Rails"
  s.description = "ActionController::Live + SSE + Redis"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.2"
  s.add_dependency "redis"

  s.add_development_dependency "sqlite3"
end
