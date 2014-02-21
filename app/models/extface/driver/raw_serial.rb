module Extface
  class Driver::RawSerial < Extface::RawDriver
    NAME = 'RAW Serial'.freeze
    has_serial_config
    
    def push(buffer)
      Extface.redis.rpush(:key, buffer)
      Extface.redis.subscribe(:extface) do |on|
        on.message do |event, data|
          @return = "event: #{event} data: #{data}\n\n"
          Extface.redis.unsubscribe
        end
      end
    end
    
    def receive(timeout = nil)
      list, element = Extface.redis.blpop(:key, :timeout => timeout)
      # Extface.redis.subscribe(:extface) do |on|
        # on.message do |event, data|
          # @return = "event: #{event} data: #{data}\n\n"
          # Extface.redis.unsubscribe
        # end
      # end
      return element
    end
  end
end
