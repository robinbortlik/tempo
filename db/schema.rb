# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_12_214239) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.text "address"
    t.text "bank_details"
    t.string "company_registration"
    t.string "contact_person"
    t.datetime "created_at", null: false
    t.string "currency"
    t.decimal "default_vat_rate", precision: 5, scale: 2
    t.string "email"
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.string "locale", default: "en", null: false
    t.string "name", null: false
    t.text "payment_terms"
    t.string "share_token", null: false
    t.boolean "sharing_enabled", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "vat_id"
    t.index ["share_token"], name: "index_clients_on_share_token", unique: true
  end

  create_table "invoice_line_item_work_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "invoice_line_item_id", null: false
    t.datetime "updated_at", null: false
    t.integer "work_entry_id", null: false
    t.index ["invoice_line_item_id", "work_entry_id"], name: "index_line_item_work_entries_uniqueness", unique: true
    t.index ["invoice_line_item_id"], name: "index_invoice_line_item_work_entries_on_invoice_line_item_id"
    t.index ["work_entry_id"], name: "index_invoice_line_item_work_entries_on_work_entry_id"
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "invoice_id", null: false
    t.integer "line_type", default: 0, null: false
    t.integer "position", null: false
    t.decimal "quantity", precision: 8, scale: 2
    t.decimal "unit_price", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.decimal "vat_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.date "due_date"
    t.date "issue_date"
    t.text "notes"
    t.string "number", null: false
    t.date "period_end"
    t.date "period_start"
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 12, scale: 2
    t.decimal "total_hours", precision: 8, scale: 2
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "money_transactions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "counterparty"
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.text "description"
    t.string "external_id"
    t.integer "invoice_id"
    t.text "raw_data"
    t.string "reference"
    t.string "source", null: false
    t.date "transacted_on", null: false
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_money_transactions_on_external_id"
    t.index ["invoice_id"], name: "index_money_transactions_on_invoice_id"
    t.index ["source"], name: "index_money_transactions_on_source"
    t.index ["transacted_on"], name: "index_money_transactions_on_transacted_on"
  end

  create_table "plugin_configurations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "credentials"
    t.boolean "enabled", default: false, null: false
    t.string "plugin_name", null: false
    t.text "settings"
    t.datetime "updated_at", null: false
    t.index ["plugin_name"], name: "index_plugin_configurations_on_plugin_name", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "client_id", null: false
    t.datetime "created_at", null: false
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_projects_on_client_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.text "address"
    t.string "bank_account"
    t.string "bank_name"
    t.string "bank_swift"
    t.string "company_name"
    t.string "company_registration"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "iban"
    t.text "invoice_message"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "vat_id"
  end

  create_table "sync_histories", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_backtrace"
    t.text "error_message"
    t.text "metadata"
    t.string "plugin_name", null: false
    t.integer "records_created", default: 0
    t.integer "records_processed", default: 0
    t.integer "records_updated", default: 0
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["plugin_name"], name: "index_sync_histories_on_plugin_name"
    t.index ["status"], name: "index_sync_histories_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale", default: "en", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "work_entries", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "description"
    t.integer "entry_type", default: 0, null: false
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "hours", precision: 6, scale: 2
    t.integer "invoice_id"
    t.integer "project_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_work_entries_on_date"
    t.index ["entry_type"], name: "index_work_entries_on_entry_type"
    t.index ["invoice_id"], name: "index_work_entries_on_invoice_id"
    t.index ["project_id", "date"], name: "index_work_entries_on_project_id_and_date"
    t.index ["project_id"], name: "index_work_entries_on_project_id"
    t.index ["status"], name: "index_work_entries_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "invoice_line_item_work_entries", "invoice_line_items"
  add_foreign_key "invoice_line_item_work_entries", "work_entries"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "clients"
  add_foreign_key "money_transactions", "invoices"
  add_foreign_key "projects", "clients"
  add_foreign_key "sessions", "users"
  add_foreign_key "work_entries", "projects"
end
