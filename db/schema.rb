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

  create_table "deployments", :force => true do |t|
    t.string  "uid"
    t.string  "site_uid"
    t.string  "user_uid"
    t.string  "environment"
    t.string  "version"
    t.string  "status",                     :default => "waiting"
    t.text    "key"
    t.text    "nodes"
    t.text    "notifications"
    t.text    "result"
    t.text    "output"
    t.integer "partition_number"
    t.string  "block_device"
    t.string  "reformat_tmp"
    t.boolean "disable_disk_partitioning",  :default => false
    t.boolean "disable_bootloader_install", :default => false
    t.boolean "ignore_nodes_deploying",     :default => false
    t.integer "vlan"
    t.integer "created_at"
    t.integer "updated_at"
  end

  add_index "deployments", ["created_at"], :name => "index_deployments_on_created_at"
  add_index "deployments", ["environment"], :name => "index_deployments_on_environment"
  add_index "deployments", ["site_uid"], :name => "index_deployments_on_site_uid"
  add_index "deployments", ["status"], :name => "index_deployments_on_status"
  add_index "deployments", ["uid"], :name => "index_deployments_on_uid"
  add_index "deployments", ["updated_at"], :name => "index_deployments_on_updated_at"
  add_index "deployments", ["user_uid"], :name => "index_deployments_on_user_uid"

end
