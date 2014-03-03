class CreateExtfaceDrivers < ActiveRecord::Migration
  def change
    create_table :extface_drivers do |t|
      t.string :type
      t.text :settings
      t.timestamps
    end
  end
end
