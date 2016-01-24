module Extface
  class Job < ActiveRecord::Base
    attr_accessor :thread
    
    belongs_to :device, inverse_of: :jobs
    
    scope :active, ->{ where(arel_table[:completed_at].eq(nil).and(arel_table[:failed_at].eq(nil)).and(arel_table[:started_at].not_eq(nil))) }
    scope :completed, ->{ where(arel_table[:completed_at].not_eq(nil)) }
    scope :failed, ->{ where(arel_table[:failed_at].not_eq(nil)) }
    
    def runtime(description = nil)
      update!(description: description, started_at: Time.now)
      begin
        raise 'No device assigned' unless device.present?
        raise 'No driver configured' unless device.driver.present?
        if device.driver.set_job(self)
          yield device.driver
          complete!
        else
          raise device.driver.errors.full_messages.join(', ')
        end
      rescue => e
        STDERR.puts e.message
        e.backtrace.each do |line|
          p line
        end
        failed! e.message
      end
    end
    
    def complete!
      self.completed_at = Time.now
      save!
      notify("Job #{self.id} completed!")
    end
    
    def completed?
      !!completed_at
    end
    
    def connected!
      unless connected?
        self.connected_at = Time.now
        save! unless Rails.env.test?
        notify("Job #{self.id} device connected!")
      end
    end
    
    def connected?
      !!connected_at?
    end
    
    def failed!(message)
      self.error = message
      self.failed_at = Time.now
      save!
      notify(message)
      notify("Job #{self.id} failed!")
    end
    
    def failed?
      !!failed_at
    end
    
    def notify(message)
      Extface.redis_block do |r|
        r.publish(self.id, message)
      end
    end
    
    def rpush(buffer)
      Extface.redis_block do |r|
        r.rpush self.id, buffer
      end
    end
    
  end
end
