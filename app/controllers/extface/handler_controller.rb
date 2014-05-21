require_dependency "extface/application_controller"
# while RESULT=$(curl -u extface:extface -c extface -b extface -s localhost:3003/parking/demo/park_extface/d894db672bc916676d3d004394343031); do if [ -z "$RESULT" ]; then sleep 5; else echo -e "$RESULT"; sleep 1; fi  done
# while true; do RESULT=$(curl -u extface:extface -c extface -b extface -s localhost:3003/parking/demo/park_extface/d894db672bc916676d3d004394343031); if [ -z "$RESULT" ]; then sleep 5; else echo -e "$RESULT"; sleep 1; fi  done
module Extface
  class HandlerController < ApplicationController
    include ActionController::Live
    skip_before_filter :include_extra_module
    #http_basic_authenticate_with name: "extface", password: "extface", except: :index
    before_action :require_device
    
    def pull
      # request.body.read usable? : YES! return number of bytes received by device
      unless device.present?
        render nothing: true, status: :not_found
      else
        stream_job
      end
    rescue => e
      p e.message
      render nothing: true, status: :internal_server_error
    ensure
      response.stream.close
    end

    def push
      # get  request.body.read
      # if it is push message, process it
      status = :not_implemented
      unless device.present?
        status = :not_found
      else
        Extface.redis_block do |r|
          r.append device.uuid, request.body.read
          @full_buffer = r.get device.uuid
        end
        if bytes_porcessed = device.driver.handle(@full_buffer.b)
          Extface.redis_block do |r|
            r.set device.uuid, @full_buffer.b[bytes_porcessed..-1]
          end
        end
        #stream_job # stream right now :)
        status = :ok
      end
    rescue => e
      p e.message
      render nothing: true, status: :internal_server_error
    ensure
      response.stream.close
    end
    
    def settings
      render text: 'settings'
    end
    
    private
      def device
        @device ||= extfaceable.extface_devices.find_by(uuid: params[:device_uuid])
      end
      
      def require_device
        render status: :not_found if device.nil?
      end
      
      def stream_job
        response.headers['Content-Type'] = 'text/event-stream'
        # find current job or get new one
        Extface.redis_block do |r|
            start = Time.now
            if job = device.jobs.active.find_by(id: cookies[:extface]) || device.jobs.active.try(:first)
              cookies.permanent[:extface] = job.id
              p "Processing job #{job.id}"
              list, data = r.blpop(job.id, timeout: 1)
              while data
                response.stream.write data
                r.publish(job.id, "OK")
                if (Time.now - start) > 3.seconds
                  p "Will continue next time"
                  #break
                end
                list, data = r.blpop(job.id, timeout: 1)
              end
            end
        end #redis block
      end
  end
end
