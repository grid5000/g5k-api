# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_21_092321) do

  create_table "deployments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "uid"
    t.string "site_uid"
    t.string "user_uid"
    t.string "environment"
    t.string "version"
    t.string "status", default: "waiting"
    t.text "key"
    t.text "nodes"
    t.text "notifications"
    t.text "result"
    t.text "output"
    t.integer "partition_number"
    t.string "block_device"
    t.string "reformat_tmp"
    t.boolean "disable_disk_partitioning", default: false
    t.boolean "disable_bootloader_install", default: false
    t.boolean "ignore_nodes_deploying", default: false
    t.integer "vlan"
    t.integer "created_at"
    t.integer "updated_at"
    t.index ["created_at"], name: "index_deployments_on_created_at"
    t.index ["environment"], name: "index_deployments_on_environment"
    t.index ["site_uid"], name: "index_deployments_on_site_uid"
    t.index ["status"], name: "index_deployments_on_status"
    t.index ["uid"], name: "index_deployments_on_uid"
    t.index ["updated_at"], name: "index_deployments_on_updated_at"
    t.index ["user_uid"], name: "index_deployments_on_user_uid"
  end

end
