class CreateExtfaceSerialConfigs < ActiveRecord::Migration
  def change
    create_table :extface_serial_configs do |t|
      t.references :s_configureable, polymorphic: true
      t.integer :serial_boud_rate
      t.integer :serial_data_length
      t.integer :serial_parity_check
      t.integer :serial_stop_bits
      t.integer :serial_handshake

      t.timestamps
    end
  end
end
