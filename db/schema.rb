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

ActiveRecord::Schema[8.1].define(version: 2025_11_26_135155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "interpretations", force: :cascade do |t|
    t.boolean "cached", default: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.text "detailed_content"
    t.integer "generation_time_ms"
    t.string "llm_model"
    t.integer "llm_tokens_used"
    t.jsonb "metadata", default: {}
    t.bigint "news_story_id", null: false
    t.bigint "persona_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_interpretations_on_created_at"
    t.index ["news_story_id", "persona_id"], name: "index_interpretations_on_news_story_id_and_persona_id", unique: true
    t.index ["news_story_id"], name: "index_interpretations_on_news_story_id"
    t.index ["persona_id"], name: "index_interpretations_on_persona_id"
  end

  create_table "news_stories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.boolean "featured", default: false, null: false
    t.text "full_content"
    t.string "headline", null: false
    t.string "image_url"
    t.jsonb "metadata", default: {}
    t.datetime "published_at"
    t.string "source", null: false
    t.string "source_url"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_news_stories_on_category"
    t.index ["created_at"], name: "index_news_stories_on_created_at"
    t.index ["external_id"], name: "index_news_stories_on_external_id", unique: true
    t.index ["featured", "active"], name: "index_news_stories_on_featured_and_active"
    t.index ["published_at"], name: "index_news_stories_on_published_at"
  end

  create_table "persona_follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "email_notifications", default: true, null: false
    t.datetime "last_email_sent_at"
    t.bigint "persona_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["persona_id"], name: "index_persona_follows_on_persona_id"
    t.index ["user_id", "persona_id"], name: "index_persona_follows_on_user_id_and_persona_id", unique: true
    t.index ["user_id"], name: "index_persona_follows_on_user_id"
  end

  create_table "personas", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "avatar_url"
    t.string "color_primary"
    t.string "color_secondary"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0
    t.string "name", null: false
    t.boolean "official", default: false, null: false
    t.string "slug", null: false
    t.text "system_prompt", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "visibility", default: "public", null: false
    t.index ["active"], name: "index_personas_on_active"
    t.index ["display_order"], name: "index_personas_on_display_order"
    t.index ["slug"], name: "index_personas_on_slug", unique: true
    t.index ["user_id"], name: "index_personas_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "interpretations", "news_stories"
  add_foreign_key "interpretations", "personas"
  add_foreign_key "persona_follows", "personas"
  add_foreign_key "persona_follows", "users"
  add_foreign_key "personas", "users"
end
