require_dependency "extface/application_controller"

module Extface
  class JobsController < ApplicationController
    include ActionController::Live
    
    skip_before_filter :include_extra_module
    before_action :allow_cross_origin

    def allow_cross_origin
      headers['Access-Control-Allow-Origin'] = '*'
    end

    def show
      response.headers['Content-Type'] = 'text/event-stream'
      @job = Job.find(params[:id])
      if @job.completed?
        response.stream.write("data: Job #{@job.id} completed!\n\n")
      elsif @job.failed?
        response.stream.write("data: Job #{@job.id} failed!\n\n")
      else
        #redis = Redis.new
        response.stream.write("data: Job #{@job.id} waiting for device connection...\n\n")
        Timeout.timeout(Extface.device_timeout) do #never stay too long, TODO add SSE option to reconnect
          Extface.redis_block do |r|
            r.subscribe(@job.id) do |on|
              on.message do |event, data|
                p "@@@@ #{event}: #{data}\n\n"
                response.stream.write("data: #{data}\n\n") unless data == 'OK'
                r.unsubscribe if data == "Job #{@job.id} completed!" || data == "Job #{@job.id} failed!" #FIXME stupid
              end
            end
          end
        end
      end
    rescue Timeout::Error
      #TODO invite reconnect
    ensure
      response.stream.close
    end

  end
end
