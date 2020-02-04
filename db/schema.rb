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

ActiveRecord::Schema.define(version: 2020_02_03_001835) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "playlist_snapshots", force: :cascade do |t|
    t.string "playlist_id"
    t.string "channel_id"
    t.jsonb "playlist_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "playlists", force: :cascade do |t|
    t.string "channel_username"
    t.string "channel_id"
    t.string "youtube_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["youtube_id"], name: "index_playlists_on_youtube_id", unique: true
  end

  create_table "songs", force: :cascade do |t|
    t.string "video_id"
    t.string "title"
    t.string "uploader"
    t.datetime "video_uploaded_date"
    t.jsonb "description"
    t.string "playlist_id"
    t.string "playlist_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
