module Extface
  module DevicesHelper
    
    def subdrivers(object)
      object.subclasses.collect{ |s|
        s.subclasses.any? ? [s.name, subdrivers(s)] : s.name
      }
    end
    
    def options_for_drivers
      Extface::Engine.eager_load!
      {}.tap do |drivers|
        Extface::DriverBase.subclasses.collect{ |type|
          drivers[type::GROUP] = subdrivers(type).flatten
        }
      end
    end
  end
end
