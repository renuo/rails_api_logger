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

ActiveRecord::Schema[8.0].define(version: 2024_11_18_205347) do
  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "author", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inbound_request_logs", force: :cascade do |t|
    t.string "method"
    t.string "path"
    t.text "request_body"
    t.text "response_body"
    t.integer "response_code"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string "loggable_type"
    t.integer "loggable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loggable_type", "loggable_id"], name: "index_inbound_request_logs_on_loggable"
  end

  create_table "outbound_request_logs", force: :cascade do |t|
    t.string "method"
    t.string "path"
    t.text "request_body"
    t.text "response_body"
    t.integer "response_code"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string "loggable_type"
    t.integer "loggable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loggable_type", "loggable_id"], name: "index_outbound_request_logs_on_loggable"
  end
end
