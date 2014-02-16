module Extface
  class Mapping
    attr_reader :name, :i_klass, :i_param, :i_find_key, :i_extra_module
    def initialize(resource, options)
      @name = options[:as] || resource.to_s
      
      @i_klass = (options[:interfaceable_type] || name.to_s.classify).to_s.constantize
      
      @i_param = options[:interfaceable_param] || "#{name}_id" #default #{resource}_id

      # key to find interfaceable in controller, when
      # :uuid then find_by! :uuid => params[:uuid]
      # :shop_uuid then find_by! :uuid => params[:shop_uuid]
      # :shop_id then find_by! :id => params[:shop_id]
      @i_find_key = @i_param[/^(#{@name}_|)(\w+)/,2]
      raise "#{@i_klass.name} has no method #{@i_find_key}" unless @i_klass.new.respond_to? @i_find_key
      
      @i_extra_module = options[:controller_include].to_s.constantize if options[:controller_include].present?
    end
    
    def mount_point
      "#{name}_extface"
    end
    
    class << self
      def find(fullpath)
        Extface.mappings[fullpath[%r{/(\w+)_extface\/}, 1]]
      end
    end
  end
end