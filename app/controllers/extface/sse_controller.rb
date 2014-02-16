require_dependency "extface/application_controller"

module Extface
  class SseController < ApplicationController
    include ActionController::Live
    
    def index
      response.headers['Content-Type'] = 'text/event-stream'
      Extface.redis.subscribe([params[:channel]]) do |on|
        on.message do |event, data|
          response.stream.write("event: #{event} data: #{data}\n\n")
          Extface.redis.unsubscribe
        end
      end
      response.stream.write "finish\n"
    ensure
      response.stream.close
    end
  end
end
