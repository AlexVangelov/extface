module Extface
  class Driver::Base::Fiscal < Extface::Driver
    self.abstract_class = true
    
    NAME = 'Fiscal Device Name'.freeze
    
    GROUP = Extface::FISCAL_DRIVER
    
    DEVELOPMENT = true #driver is not ready for production (not passing all tests or has major bugs)
    
    # Select driver features
    RAW = true  #responds to #push(data) and #pull
    PRINT = false #POS, slip printers
    FISCAL = true #cash registers, fiscal printers
    REPORT = false #only transmit data that must be parsed by handler, CDR, report devices  
    
    def handle(buffer) raise_not_implemented end
    
    #tests
    def non_fiscal_test() raise_not_implemented end
    def fiscal_test() raise_not_implemented end

    #reports
    def z_report_session() raise_not_implemented end
    def x_report_session() raise_not_implemented end
    def period_report_session(from, to, detailed = true) raise_not_implemented end
    
    #repair interrupted doc
    def cancel_doc_session() raise_not_implemented end

    #print driver compatibility session
    # device.session do |s|
      # s.open_non_fiscal_doc if device.fiscal?
      # s.print
      # s.print
      # ...
      # s.close_non_fiscal_doc if device.fiscal?
    # end
    def open_non_fiscal_doc() raise_not_implemented end
    def print() raise_not_implemented end
    def close_non_fiscal_doc() raise_not_implemented end
      
    #fiscal wild session
    def open_fiscal_doc(operator = '', password = '') raise_not_implemented end
    def add_sale(sale_item) raise_not_implemented end #instance of Extface::Driver::Base::Fiscal::SaleItem
    def add_comment(text = '') raise_not_implemented end
    def add_payment(value = nil, type_num = nil) raise_not_implemented end
    def add_total_modifier(fixed_value = nil, percent_ratio = nil) raise_not_implemented end
    def total_payment() raise_not_implemented end #auto calculated total default payment
    def close_fiscal_doc() raise_not_implemented end
    
    #fiscal basket session of Extface::Driver::Base::Fiscal::SaleItem instances
    def sale_and_pay_items_session(sale_items = [], operator = '', password = '') raise_not_implemented end
      
    #other
    def payed_recv_account(value = 0.00, payment_type_num = 0) raise_not_implemented end
    
    class SaleItem
      include ActiveModel::Validations
      attr_reader :price, # Float
                  :text1, :text2, # String
                  :tax_group, #Integer
                  :qty, #Fixnum
                  :percent, #Float
                  :neto, 
                  :number #Fixnum (Eltrade PLU code)
      def initialize(attributes)
        @price, @text1, @text2, @tax_group, @qty, @percent, @neto, @number = attributes[:price], attributes[:text1].to_s, attributes[:text2].to_s, attributes[:tax_group], attributes[:qty], attributes[:percent], attributes[:neto], attributes[:number]
        raise "invalid price" unless price.kind_of?(Float)
        raise "invalid tax group" if tax_group.present? && !tax_group.kind_of(Integer)
        raise "invalid qty" if qty.present? && !qty.kind_of(Float)
      end
    end
    
    def fiscalize(bill, detailed = false)
      return nil unless bill.kind_of?(Billing::Bill) && bill.valid?
      operator_mapping = bill.find_operator_mapping_for(self)
      if detailed
        device.session("Fiscal Doc") do |s|
          s.notify "Fiscal Doc Start"
          s.open_fiscal_doc(operator_mapping.try(:mapping), operator_mapping.try(:pwd))
          s.notify "Register Sale"
          bill.charges.each do |charge|
            neto, percent_ratio = nil, nil, nil
            if modifier = charge.modifier
              neto = modifier.fixed_value
              percent_ratio = modifier.percent_ratio unless neto.present?
            end
            if charge.price.zero? #printing comments with zero charges (TODO check zero charges allowed?)
              s.add_comment charge.text
            else
              s.add_sale(
                SaleItem.new(
                  price: charge.price.to_f, 
                  text1: charge.name,
                  text2: charge.description,
                  tax_group: charge.find_tax_group_mapping_for(self), #find tax group mapping by ratio , not nice
                  qty: charge.qty,
                  neto: neto,
                  percent_ratio: percent_ratio #TODO check format
                )
              )
            end
          end
          if global_modifier_value = bill.global_modifier_value
            s.notify "Register Global Modifier"
            s.add_total_modifier global_modifier_value.to_f 
          end
          s.notify "Register Payment"
          bill.payments.each do |payment|
            s.add_payment payment.value.to_f, payment.find_payment_type_mapping_for(self)
          end
          s.notify "Close Fiscal Receipt"
          s.close_fiscal_doc
          s.notify "Fiscal Doc End"
        end
      else #not detailed
        device.session("Fiscal Doc") do |s|
          s.notify "Fiscal Doc Start"
          s.open_fiscal_doc(operator_mapping.try(:mapping), operator_mapping.try(:pwd))
          s.notify "Register Sale"
          s.add_sale(
            SaleItem.new(
              price: bill.payments_sum.to_f, 
              text1: bill.name,
              tax_group: bill.charges.first.find_tax_group_mapping_for(self), #find tax group mapping by ratio , not nice
            )
          )
          if global_modifier_value = bill.global_modifier_value
            s.notify "Register Global Modifier"
            s.add_total_modifier global_modifier_value.to_f 
          end
          s.notify "Register Payment"
          bill.payments.each do |payment|
            s.add_payment payment.value.to_f, payment.find_payment_type_mapping_for(self)
          end
          #s.total_payment #TODO fix payment and remove me
          s.notify "Close Fiscal Receipt"
          s.close_fiscal_doc
          s.notify "Fiscal Doc End"
        end
      end
    end

    private
      def raise_not_implemented
        raise "not implemented"
      end
  end
end