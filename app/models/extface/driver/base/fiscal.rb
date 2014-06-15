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
    def add_payment(type_num, value = 0.00) raise_not_implemented end
    def total_payment() raise_not_implemented end #auto calculated total default payment
    def close_fiscal_doc() raise_not_implemented end
      
    def cancel_doc_session() raise_not_implemented end #repair from broken doc session
    
    #fiscal basket session of Extface::Driver::Base::Fiscal::SaleItem instances
    def sale_and_pay_items_session(sale_items = [], operator = '', password = '') raise_not_implemented end
    
    class SaleItem
      include ActiveModel::Validations
      attr_reader :price, # Float
                  :text1, :text2, # String
                  :tax_group, #Float
                  :qty, #Fixnum
                  :percent, #Float
                  :neto, 
                  :number #Fixnum
      def initialize(attributes)
        @price, @text1, @text2, @tax_group, @qty, @percent, @neto, @number = attributes[:price], attributes[:text1].to_s, attributes[:text2].to_s, attributes[:tax_group], attributes[:qty], attributes[:percent], attributes[:neto], attributes[:number]
        raise "invalid price" unless price.kind_of?(Float)
        raise "invalid tax group" if tax_group.present? && !tax_group.kind_of(Integer)
        raise "invalid qty" if qty.present? && !qty.kind_of(Float)
      end
    end

    private
      def raise_not_implemented
        raise "not implemented"
      end
  end
end