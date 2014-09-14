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

ActiveRecord::Schema.define(version: 20140821221257) do

  create_table "accounts", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "campaigns", force: true do |t|
    t.string   "name"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "campaigns", ["account_id"], name: "index_campaigns_on_account_id"

  create_table "customers", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "target_id"
  end

  add_index "customers", ["target_id"], name: "index_customers_on_target_id"

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

# Could not dump table "provisionings" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "resourcepools", force: true do |t|
    t.string   "name"
    t.string   "resource"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", force: true do |t|
    t.string   "name"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.string   "sitecode"
    t.string   "countrycode"
    t.string   "areacode"
    t.string   "localofficecode"
    t.string   "extensionlength"
    t.string   "mainextension"
    t.string   "gatewayIP"
  end

  add_index "sites", ["customer_id"], name: "index_sites_on_customer_id"

  create_table "targets", force: true do |t|
    t.string   "name"
    t.text     "configuration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.integer  "site_id"
    t.string   "extension"
    t.string   "givenname"
    t.string   "familyname"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
  end

  add_index "users", ["site_id"], name: "index_users_on_site_id"

end
