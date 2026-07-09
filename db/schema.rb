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

ActiveRecord::Schema[8.1].define(version: 2026_07_09_152311) do
  create_table "admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_admins_on_username", unique: true
  end

  create_table "links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "links_shows", id: false, force: :cascade do |t|
    t.integer "link_id", null: false
    t.integer "show_id", null: false
    t.index ["link_id", "show_id"], name: "index_links_shows_on_link_id_and_show_id"
    t.index ["show_id", "link_id"], name: "index_links_shows_on_show_id_and_link_id"
  end

  create_table "shows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location"
    t.text "notes"
    t.string "price"
    t.datetime "time"
    t.datetime "updated_at", null: false
    t.integer "venue_id"
    t.index ["venue_id"], name: "index_shows_on_venue_id"
  end

  create_table "venues", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "map_url"
    t.string "name"
    t.string "state"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "shows", "venues"
end
