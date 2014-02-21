require'timeout'
module Extface
  class DriverBase < ActiveRecord::Base
    self.abstract_class = true
    
    has_one :device, :as => :driveable
    
    [:raw?, :print?, :fiscal?, :cdr?].each do |driver_type|
      define_method driver_type do
        false
      end
    end

    class << self
      def has_serial_config
        has_one :serial_config, as: :s_configureable
        accepts_nested_attributes_for :serial_config
        define_method :serial? do
          true
        end
      end
    end
    
    def handle(buffer) # handle push messages from device outside active session
      return false
    end
    
    def push(buffer)
      
        if @job
          Timeout.timeout(10) do
            Extface.redis_block do |r|
              r.subscribe(@job.id) do |on| #blocking until delivered
                on.subscribe do |channel, subscriptions|
                  @job.rpush buffer
                end
                on.message do |event, data|
                  r.unsubscribe
                  @job.connected!
                end
              end
            end
          end
        else
          raise "No job given"
        end
      
    end
    
    def pull(timeout = nil)
      Extface.redis_block do |r|
        list, element = r.blpop(device.uuid, :timeout => timeout)
      end
      element
    end
    
    def notify(message)
      raise "No job given" unless @job
      @job.notify(message)
    end
    
    def set_job(job)
      @job = job
    end

  end
end
