require_dependency "extface/application_controller"
# while RESULT=$(curl -u extface:extface -c extface -b extface -s localhost:3003/parking/demo/park_extface/d894db672bc916676d3d004394343031); do if [ -z "$RESULT" ]; then sleep 5; else echo -e "$RESULT"; sleep 1; fi  done
# while true; do RESULT=$(curl -u extface:extface -c extface -b extface -s localhost:3003/parking/demo/park_extface/d894db672bc916676d3d004394343031); if [ -z "$RESULT" ]; then sleep 5; else echo -e "$RESULT"; sleep 1; fi  done
require "timeout"
module Extface
  class HandlerController < ApplicationController
    include ActionController::Live
    skip_before_filter :include_extra_module
    #http_basic_authenticate_with name: "extface", password: "extface", except: :index
    before_action :require_device
    
    def pull
      # request.body.read usable?
      unless device.present?
        render nothing: true, status: :not_found
      else
        response.headers['Content-Type'] = 'text/event-stream'
        # find current job or get new one
        redis = Redis.new
        Timeout.timeout(2) do
          if job = device.jobs.active.find_by(id: cookies[:extface]) || device.jobs.active.try(:first)
            cookies.permanent[:extface] = job.id
            p "Processing job #{job.id}"
            list, data = redis.blpop(job.id, timeout: 1)
            while data
              response.stream.write data
              redis.publish(job.id, "OK")
              list, data = redis.blpop(job.id, timeout: 1)
            end
          end
        end #timeout  
      end
    rescue => e
      p "will continue next time #{e.message}"
    ensure
      redis.quit
      response.stream.close
    end
    
    def push
      # get  request.body.read
      # if it is push message, process it
      response.headers['Content-Type'] = 'text/event-stream'
      p request.body.read
      Extface.redis.subscribe(:alabala) do |on|
        on.message do |event, data|
          response.stream.write("event: #{event} data: #{data}\n\n")
          Extface.redis.unsubscribe
        end
      end
      response.stream.write "finish\n"
    ensure
      response.stream.write "failed\n"
      response.stream.close
    end
    
    private
      def device
        @device ||= extfaceable.extface_devices.find_by(uuid: params[:device_uuid])
      end
      
      def require_device
        render status: :not_found if device.nil?
      end
  end
end