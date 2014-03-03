class ChangeDriverPolymorphicToBelongsToExtfaceDevices < ActiveRecord::Migration
  def up
    remove_index :extface_devices, [:driveable_id, :driveable_type]
    remove_column :extface_devices, :driveable_type
    rename_column :extface_devices, :driveable_id, :driver_id
  end
  
  def down
    rename_column :extface_devices, :driver_id, :driveable_id
    add_column :extface_devices, :driveable_type, :string
    add_index :extface_devices, [:driveable_id, :driveable_type]
  end
end
