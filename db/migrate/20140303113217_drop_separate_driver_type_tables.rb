class DropSeparateDriverTypeTables < ActiveRecord::Migration
  def up
    drop_table :extface_pos_print_drivers
    drop_table :extface_raw_drivers
    drop_table :extface_fiscal_print_drivers
    drop_table :extface_pbx_cdr_drivers
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
