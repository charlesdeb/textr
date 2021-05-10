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

ActiveRecord::Schema.define(version: 2021_05_09_202550) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chunks", force: :cascade do |t|
    t.integer "size", null: false
    t.integer "count", null: false
    t.bigint "language_id", null: false
    t.integer "token_ids", null: false, array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["language_id", "token_ids"], name: "index_chunks_on_language_id_and_token_ids", unique: true
    t.index ["language_id"], name: "index_chunks_on_language_id"
    t.index ["size"], name: "index_chunks_on_size"
    t.index ["token_ids"], name: "index_chunks_on_token_ids"
  end

  create_table "languages", force: :cascade do |t|
    t.string "language"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["language"], name: "index_languages_on_language", unique: true
  end

  create_table "text_messages", force: :cascade do |t|
    t.text "text"
    t.bigint "language_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["language_id"], name: "index_text_messages_on_language_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "text"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["text"], name: "index_tokens_on_text", unique: true
  end

  add_foreign_key "chunks", "languages"
  add_foreign_key "text_messages", "languages"
end
