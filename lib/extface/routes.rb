module ActionDispatch::Routing
  class Mapper
    def extface_for(resource, options = {})
      mapping = Extface.add_mapping(resource, options)
      mount Extface::Engine, at: mapping.mount_point, as: [options[:as],:extface].compact.join('_')
      get "#{mapping.mount_point}/:device_uuid", to: "extface/handler#pull", as: :extface_device_pull
      get "#{mapping.mount_point}/jobs/:id", to: "extface/jobs#show", as: :extface_job
    end
  end
end