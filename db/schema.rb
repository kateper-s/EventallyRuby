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

ActiveRecord::Schema[7.1].define(version: 2026_10_06_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.bigint "organizer_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "category", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at"
    t.string "venue", null: false
    t.string "city", null: false
    t.boolean "published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_events_on_category"
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["starts_at"], name: "index_events_on_starts_at"
    t.check_constraint "ends_at IS NULL OR ends_at > starts_at", name: "events_ends_after_starts"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "event_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "event_key"], name: "index_favorites_on_user_id_and_event_key", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "total", default: 0, null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "total >= 0", name: "orders_total_non_negative"
  end

  create_table "ticket_types", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "name", null: false
    t.integer "price", default: 0, null: false
    t.integer "quota", null: false
    t.integer "sold_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "name"], name: "index_ticket_types_on_event_id_and_name", unique: true
    t.index ["event_id"], name: "index_ticket_types_on_event_id"
    t.check_constraint "price >= 0", name: "ticket_types_price_non_negative"
    t.check_constraint "quota > 0", name: "ticket_types_quota_positive"
    t.check_constraint "sold_count >= 0 AND sold_count <= quota", name: "ticket_types_sold_within_quota"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "ticket_type_id", null: false
    t.string "code", null: false
    t.integer "price", null: false
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tickets_on_code", unique: true
    t.index ["order_id"], name: "index_tickets_on_order_id"
    t.index ["ticket_type_id"], name: "index_tickets_on_ticket_type_id"
    t.check_constraint "price >= 0", name: "tickets_price_non_negative"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.integer "role", default: 0, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "favorites", "users"
  add_foreign_key "orders", "users"
  add_foreign_key "ticket_types", "events"
  add_foreign_key "tickets", "orders"
  add_foreign_key "tickets", "ticket_types"
end
