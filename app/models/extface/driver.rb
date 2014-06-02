require'timeout'
module Extface
  class Driver < ActiveRecord::Base
    
    NAME = 'Extface Driver Base' #human driver name
    GROUP = Extface::RAW_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = false #POS, slip printers
    FISCAL = false #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices

    DRIVER_TYPES = ['RAW', 'PRINT', 'FISCAL', 'REPORT'].freeze
    
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
    
    # called on every push message received, buffer contains all not processed data
    def handle(buffer)
      $stdout.puts "Extface:#{device.uuid} PUSH #{buffer}"
      return buffer.length # return number of bytes processed
    end
    
    def pre_handle(buffer)
      logger.debug "<-- #{buffer.bytes.map{ |b| '%02X' % b }.join(' ')}" if development?
      handle(buffer)
    end
    
    def push(buffer)
      if @job
        Timeout.timeout(Extface.device_timeout) do
          Extface.redis_block do |r|
            r.subscribe(@job.id) do |on| #blocking until delivered
              on.subscribe do |channel, subscriptions|
                @job.rpush buffer
                logger.debug "--> #{buffer.bytes.map{ |b| '%02X' % b }.join(' ')}" if development?
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
      element = nil
      Extface.redis_block do |r|
        list, element = r.blpop(buffer_key, :timeout => timeout)
      end
      element
    end
    
    def flush
      Extface.redis_block do |r| 
        r.del device.uuid
        r.del buffer_key
      end
    end
    
    def rpush(buffer)
      Extface.redis_block do |r|
        r.rpush buffer_key, buffer
      end
    end
    
    def notify(message)
      raise "No job given" unless @job
      @job.notify(message)
    end
    
    def set_job(job)
      @job = job
      return check_status
    end
    
    def check_status
      errors.add :base, :not_implemented
      false
    end

    private
      def buffer_key
        "#{device.uuid}:#{self.id}"
      end
      
      def logger
        @logger ||= begin
          dir = "#{Rails.root}/log/extface/#{device.id}"
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
          Logger.new("#{dir}/#{self.class.name.demodulize.underscore}.log", 'daily')
        end
      end
      
      def development?
        self.class::DEVELOPMENT
      end
  end
end
