class ChangePolymorphicToHasOneToExtfaceSerialConfigs < ActiveRecord::Migration
  def up
    remove_column :extface_serial_configs, :s_configureable_type
    rename_column :extface_serial_configs, :s_configureable_id, :driver_id
  end
  
  def down
    add_column :extface_serial_configs, :s_configureable_type, :string
    rename_column :extface_serial_configs, :driver_id, :s_configureable_id
  end
end
