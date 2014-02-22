$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "extface/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "extface"
  s.version     = Extface::VERSION
  s.authors     = ["Alex Vangelov"]
  s.email       = ["email@data.bg"]
  s.homepage    = "http://github.com/AlexVangelov/extface"
  s.summary     = "External Interfaces for Cloud-Based Applications (Rails 4)"
  s.description = "Extface allows use of Cash Registers, Fiscal and POS printers without physical connection between the device, application server and the end user. Can also be used for remotely reading CDR logs from PBX systems and actually supports data exchange with all low-speed devices having serial, parallel or USB* interface"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.2"
  s.add_dependency "rdoc"
  s.add_dependency "redis"
  s.add_dependency "redis-namespace"

  s.add_development_dependency "sqlite3"
end
