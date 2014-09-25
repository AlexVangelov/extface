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
    end
    
    before_save do
      if @driver_class.present? and @driver_class != driver_class.try(:to_s)
        driver.try(:destroy)
        self.driver = @driver_class.constantize.create if @driver_class.present?
      end
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
          raise 'No driver configured' unless driver.present?
          if driver.set_job(job)
            yield driver
            job.complete!
          else
            raise driver.errors.full_messages.join(', ')
          end
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
    
    #initial billing module fiscalization support
    def fiscalize(billing_account, detailed = false)
      if billing_account.instance_of?(Billing::Bill) && billing_account.valid?
        driver.sale_and_pay_items_session(
          [].tap() do |payments|
            billing_account.payments.each do |payment|
              payments << Extface::Driver::Base::Fiscal::SaleItem.new(price: payment.value.to_f, text1: payment.description)
            end
          end
        )
      end
    end
  end
end
