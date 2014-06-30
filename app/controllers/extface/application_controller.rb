module Extface
  class ApplicationController < ActionController::Base
    prepend_before_filter :include_extra_module
    
    helper_method :extface
    
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
      
      def extface
        try(extface_mapping.mount_point) || super # rails 4.1 fixed named route for engines mounted for resources
      end
  end
end
