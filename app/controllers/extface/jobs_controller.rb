require_dependency "extface/application_controller"

module Extface
  class JobsController < ApplicationController
    include ActionController::Live

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
        Extface.redis_block do |r|
          r.subscribe(@job.id) do |on|
            on.message do |event, data|
              #p "data: #{data}\n\n"
              response.stream.write("data: #{data}\n\n") unless data == 'OK'
              r.unsubscribe if data == "Job #{@job.id} completed!" || data == "Job #{@job.id} failed!"
            end
          end
        end
      end
    ensure
      response.stream.close
    end

  end
end
