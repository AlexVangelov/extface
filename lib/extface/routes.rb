module ActionDispatch::Routing
  class Mapper
    def extface_for(resource, options = {})
      mapping = Extface.add_mapping(resource, options)
      mount Extface::Engine, at: mapping.mount_point
    end
  end
end