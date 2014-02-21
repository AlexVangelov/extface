module Extface
  class Device < ActiveRecord::Base
    attr_writer :driver
    belongs_to :extfaceable, polymorphic: true
    belongs_to :driveable, polymorphic: true
    has_many :jobs, inverse_of: :device
    
    accepts_nested_attributes_for :driveable
    
    delegate :print?, :fiscal?, :raw?, :cdr?, to: :driveable, allow_nil: true
    
    validates_uniqueness_of :name, :uuid, scope: [:extfaceable_id, :extfaceable_type]
    
    before_create do
      self.uuid = SecureRandom.hex
      self.name = uuid unless name.present?
      self.driveable = @driver.constantize.create if @driver.present?
    end
    
    def driver
      driveable.try(:class)
    end
    
    def driver_name
      driver::NAME if driver
    end

    def session(description = nil)
      job = jobs.create!(description: description)
      Thread.new do
        begin
          raise 'No driver configured' unless driveable.present?
          driveable.set_job(job)
          yield driveable
          job.complete!
        rescue => e
          STDERR.puts e.message
          e.backtrace.each do |line|
            p line
          end
          job.failed! e.message
        end
      end
      job
    end
  end
end
