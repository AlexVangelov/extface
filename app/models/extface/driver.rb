require'timeout'
module Extface
  class Driver < ActiveRecord::Base
    
    NAME = 'Extface Driver Base' #human driver name
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)

    CAN_RECEСVE_DATA = true #pull from server
    CAN_TRANSMIT_DATA = true #push to server
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = false #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices

    DRIVER_TYPES = ['RAW', 'PRINT', 'FISCAL', 'REPORT'].freeze
    
    GROUP = "Raw"
    
    has_one :device, inverse_of: :driver
    
    DRIVER_TYPES.each do |driver_type|
      define_method "#{driver_type.downcase}?" do
        self.class.const_get driver_type
      end
    end

    class << self
      def has_serial_config #helper for serial devices, provides config for speed, boud rate, parity etc..
        has_one :serial_config, inverse_of: :driver
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
          Timeout.timeout(Extface.device_timeout) do
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
