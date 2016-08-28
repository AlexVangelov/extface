class AddEncodingToExtfaceDevice < ActiveRecord::Migration
  def change
    add_column :extface_devices, :encoding, :string
  end
end
