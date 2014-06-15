module Extface
  module DevicesHelper
    
    def subdrivers(object)
      [].tap do |drivers|
        object.subclasses.each do |s|
          drivers << s unless s.abstract_class
          drivers << subdrivers(s) if s.subclasses.any?
        end
      end
    end
    
    def options_for_drivers
      Extface::Engine.eager_load! if Rails.env.development?
      [].tap do |drivers|
        Extface::Driver.subclasses.each do |s|
          drivers << s unless s.abstract_class
          drivers << subdrivers(s)
        end
      end.flatten.group_by{ |x| x::GROUP }.sort.collect{ |group, drivers| [group, drivers.collect{ |d| [d::NAME, d.to_s] }.sort ] }
    end
  end
end
