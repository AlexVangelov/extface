class CreateExtfaceDevices < ActiveRecord::Migration
  def change
    create_table :extface_devices do |t|
      t.string :uuid
      t.string :name
      t.references :extfaceable, polymorphic: true
      t.references :driveable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
