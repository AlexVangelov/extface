module Extface
  class Job < ActiveRecord::Base
    belongs_to :device, inverse_of: :jobs
    
    scope :active, ->{ where(arel_table[:completed_at].eq(nil).and(arel_table[:failed_at].eq(nil))) }
    
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
        save!
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
