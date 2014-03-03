module Extface
  class Device < ActiveRecord::Base
    attr_writer :driver_class
    belongs_to :extfaceable, polymorphic: true
    belongs_to :driver, inverse_of: :device
    has_many :jobs, inverse_of: :device
    
    accepts_nested_attributes_for :driver
    
    delegate :print?, :fiscal?, :raw?, :report?, to: :driver, allow_nil: true
    
    validates_uniqueness_of :name, :uuid, scope: [:extfaceable_id, :extfaceable_type]
    
    before_create do
      self.uuid = SecureRandom.hex
      self.name = uuid unless name.present?
      self.driver = @driver_class.constantize.create if @driver_class.present?
    end
    
    def driver_class
      driver.try(:class)
    end
    
    def driver_name
      driver_class::NAME if driver_class
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
        ensure
          ActiveRecord::Base.connection.close
        end
      end
      job
    end
  end
end
