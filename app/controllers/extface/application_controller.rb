module Extface
  class ApplicationController < ActionController::Base
    prepend_before_filter :include_extra_module
    
    def index
    end
    
    def extfaceable
      @extfaceable ||= extface_mapping.i_klass.find_by(extface_mapping.i_find_key => params[extface_mapping.i_param])
    end

    private
      def extface_mapping
        @extface_mapping ||= Extface::Mapping.find(request.fullpath)
      end
      
      def include_extra_module
        self.class.send(:include, extface_mapping.i_extra_module) if extface_mapping.i_extra_module.present?
      end
  end
end