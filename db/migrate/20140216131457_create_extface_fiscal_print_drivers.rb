class CreateExtfaceFiscalPrintDrivers < ActiveRecord::Migration
  def change
    create_table :extface_fiscal_print_drivers do |t|
      t.string :type

      t.timestamps
    end
  end
end
