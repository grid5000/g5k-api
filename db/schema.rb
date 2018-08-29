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

ActiveRecord::Schema.define(version: 20180821092321) do

  create_table "deployments", force: :cascade do |t|
    t.string  "uid",                        limit: 255
    t.string  "site_uid",                   limit: 255
    t.string  "user_uid",                   limit: 255
    t.string  "environment",                limit: 255
    t.string  "version",                    limit: 255
    t.string  "status",                     limit: 255,   default: "waiting"
    t.text    "key",                        limit: 65535
    t.text    "nodes",                      limit: 65535
    t.text    "notifications",              limit: 65535
    t.text    "result",                     limit: 65535
    t.text    "output",                     limit: 65535
    t.integer "partition_number",           limit: 4
    t.string  "block_device",               limit: 255
    t.string  "reformat_tmp",               limit: 255
    t.boolean "disable_disk_partitioning",                default: false
    t.boolean "disable_bootloader_install",               default: false
    t.boolean "ignore_nodes_deploying",                   default: false
    t.integer "vlan",                       limit: 4
    t.integer "created_at",                 limit: 4
    t.integer "updated_at",                 limit: 4
  end

  add_index "deployments", ["created_at"], name: "index_deployments_on_created_at", using: :btree
  add_index "deployments", ["environment"], name: "index_deployments_on_environment", using: :btree
  add_index "deployments", ["site_uid"], name: "index_deployments_on_site_uid", using: :btree
  add_index "deployments", ["status"], name: "index_deployments_on_status", using: :btree
  add_index "deployments", ["uid"], name: "index_deployments_on_uid", using: :btree
  add_index "deployments", ["updated_at"], name: "index_deployments_on_updated_at", using: :btree
  add_index "deployments", ["user_uid"], name: "index_deployments_on_user_uid", using: :btree

end
