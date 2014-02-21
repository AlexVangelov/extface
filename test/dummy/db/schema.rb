# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140221203517) do

  create_table "extface_devices", force: true do |t|
    t.string   "uuid"
    t.string   "name"
    t.integer  "extfaceable_id"
    t.string   "extfaceable_type"
    t.integer  "driveable_id"
    t.string   "driveable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "extface_devices", ["driveable_id", "driveable_type"], name: "index_extface_devices_on_driveable_id_and_driveable_type"

  create_table "extface_fiscal_print_drivers", force: true do |t|
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "extface_jobs", force: true do |t|
    t.integer  "device_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.string   "error"
    t.datetime "failed_at"
    t.datetime "completed_at"
    t.datetime "connected_at"
  end

  add_index "extface_jobs", ["device_id"], name: "index_extface_jobs_on_device_id"

  create_table "extface_pbx_cdr_drivers", force: true do |t|
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "extface_pos_print_drivers", force: true do |t|
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "extface_raw_drivers", force: true do |t|
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "extface_serial_configs", force: true do |t|
    t.integer  "s_configureable_id"
    t.string   "s_configureable_type"
    t.integer  "serial_boud_rate"
    t.integer  "serial_data_length"
    t.integer  "serial_parity_check"
    t.integer  "serial_stop_bits"
    t.integer  "serial_handshake"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shops", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
