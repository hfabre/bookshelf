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

ActiveRecord::Schema[8.0].define(version: 2025_11_21_194327) do
  create_table "authors", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_authors_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_authors_on_user_id"
  end

  create_table "authors_books", force: :cascade do |t|
    t.integer "book_id", null: false
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_authors_books_on_author_id"
    t.index ["book_id", "author_id"], name: "index_authors_books_on_book_id_and_author_id", unique: true
    t.index ["book_id"], name: "index_authors_books_on_book_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "language"
    t.date "date"
    t.string "publisher"
    t.integer "serie_id"
    t.integer "user_id", null: false
    t.integer "serie_index", default: 1
    t.binary "epub_content"
    t.string "filename"
    t.binary "cover_bytes"
    t.string "cover_type"
    t.string "processing_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["serie_id"], name: "index_books_on_serie_id"
    t.index ["user_id", "serie_id", "serie_index"], name: "index_books_on_user_id_and_serie_id_and_serie_index", unique: true
    t.index ["user_id"], name: "index_books_on_user_id"
  end

  create_table "series", force: :cascade do |t|
    t.string "name"
    t.integer "user_id", null: false
    t.string "completion_state"
    t.string "reading_state"
    t.integer "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_series_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_series_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "authors", "users"
  add_foreign_key "authors_books", "authors"
  add_foreign_key "authors_books", "books"
  add_foreign_key "books", "series", column: "serie_id"
  add_foreign_key "books", "users"
  add_foreign_key "series", "users"
  add_foreign_key "sessions", "users"
end
