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

ActiveRecord::Schema.define(version: 20160212135435) do

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true

  create_table "customers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "target_id"
    t.string   "language"
  end

  add_index "customers", ["target_id"], name: "index_customers_on_target_id"

  create_table "delayed_jobs", force: :cascade do |t|
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

  create_table "persistent_hashes", force: :cascade do |t|
    t.string   "name"
    t.text     "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provisionings", force: :cascade do |t|
    t.text     "action"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "customer_id"
    t.integer  "site_id"
    t.integer  "delayedjob_id"
    t.integer  "attempts"
    t.integer  "user_id"
    t.integer  "provisioningobject_id"
    t.string   "provisioningobject_type"
    t.string   "job_id"
  end

  add_index "provisionings", ["customer_id"], name: "index_provisionings_on_customer_id"
  add_index "provisionings", ["delayedjob_id"], name: "index_provisionings_on_delayedjob_id"
  add_index "provisionings", ["site_id"], name: "index_provisionings_on_site_id"
  add_index "provisionings", ["user_id"], name: "index_provisionings_on_user_id"

  create_table "sites", force: :cascade do |t|
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

  create_table "system_settings", force: :cascade do |t|
    t.string   "name"
    t.string   "value_type"
    t.string   "value_default"
    t.string   "value"
    t.string   "short_description"
    t.text     "description"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "targets", force: :cascade do |t|
    t.string   "name"
    t.text     "configuration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "status"
  end

  create_table "text_documents", force: :cascade do |t|
    t.text     "identifierhash"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
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
