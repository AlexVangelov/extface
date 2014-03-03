module Extface
  module DevicesHelper
    
    def subdrivers(options, object)
      object.subclasses.each do |s|
        options << [s::NAME, s.name]
        subdrivers(options, s) if s.subclasses.any?
      end
      return options
    end
    
    def options_for_drivers
      Extface::Engine.eager_load!
      {}.tap do |drivers|
        Extface::Driver.subclasses.collect{ |type|
          drivers[type::GROUP] = subdrivers(Array.new, type)
        }
      end
    end
  end
end
