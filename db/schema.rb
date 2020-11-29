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

ActiveRecord::Schema.define(version: 2020_02_23_213623) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "lockbox_actions", force: :cascade do |t|
    t.date "eff_date"
    t.string "action_type"
    t.string "status"
    t.bigint "lockbox_partner_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "support_request_id"
    t.index ["lockbox_partner_id"], name: "index_lockbox_actions_on_lockbox_partner_id"
    t.index ["support_request_id"], name: "index_lockbox_actions_on_support_request_id"
  end

  create_table "lockbox_partners", force: :cascade do |t|
    t.string "name"
    t.string "phone_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "phone_ext"
  end

  create_table "lockbox_transactions", force: :cascade do |t|
    t.string "balance_effect"
    t.string "category"
    t.integer "amount_cents"
    t.bigint "lockbox_action_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "distance"
    t.index ["lockbox_action_id"], name: "index_lockbox_transactions_on_lockbox_action_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "text"
    t.bigint "notable_id"
    t.string "notable_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.string "notable_action", default: "annotate"
    t.index ["notable_type", "notable_id"], name: "index_notes_on_notable_type_and_notable_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "support_requests", force: :cascade do |t|
    t.string "client_ref_id"
    t.string "name_or_alias"
    t.string "urgency_flag"
    t.bigint "lockbox_partner_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.index ["lockbox_partner_id"], name: "index_support_requests_on_lockbox_partner_id"
    t.index ["user_id"], name: "index_support_requests_on_user_id"
  end

  create_table "tracking_infos", force: :cascade do |t|
    t.string "tracking_number"
    t.string "delivery_method"
    t.bigint "lockbox_action_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["lockbox_action_id"], name: "index_tracking_infos_on_lockbox_action_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "name"
    t.bigint "lockbox_partner_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "role"
    t.bigint "invited_by_id"
    t.string "time_zone"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["lockbox_partner_id"], name: "index_users_on_lockbox_partner_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "lockbox_transactions", "lockbox_actions"
  add_foreign_key "support_requests", "lockbox_partners"
  add_foreign_key "tracking_infos", "lockbox_actions"
  add_foreign_key "users", "users", column: "invited_by_id"
end
