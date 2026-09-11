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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_230000) do
  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "catalog_item_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.integer "variant_id"
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["catalog_item_id"], name: "index_cart_items_on_catalog_item_id"
    t.index ["variant_id"], name: "index_cart_items_on_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.integer "applied_coupon_id"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["applied_coupon_id"], name: "index_carts_on_applied_coupon_id"
    t.index ["token"], name: "index_carts_on_token", unique: true
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "catalog_items", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "bookable", default: true
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.text "description"
    t.integer "duration_minutes"
    t.boolean "featured", default: false, null: false
    t.integer "markdown_step_days"
    t.integer "markdown_step_percent", default: 0
    t.integer "max_capacity"
    t.integer "max_discount_percent", default: 0
    t.string "name", null: false
    t.integer "price_cents", default: 0, null: false
    t.datetime "sale_ends_at"
    t.integer "sale_price_cents"
    t.datetime "sale_starts_at"
    t.string "sku"
    t.string "slug", null: false
    t.integer "stock_quantity", default: 0
    t.boolean "track_inventory", default: true
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_catalog_items_on_category_id"
    t.index ["slug"], name: "index_catalog_items_on_slug", unique: true
    t.index ["type"], name: "index_catalog_items_on_type"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "parent_id"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "coupons", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "kind", default: "percent", null: false
    t.integer "max_redemptions"
    t.integer "min_subtotal_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "used_count", default: 0, null: false
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.integer "value", null: false
    t.index ["code"], name: "index_coupons_on_code", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "catalog_item_id", null: false
    t.datetime "created_at", null: false
    t.integer "line_total_cents", null: false
    t.string "name", null: false
    t.integer "order_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.integer "variant_id"
    t.string "variant_name"
    t.index ["catalog_item_id"], name: "index_order_items_on_catalog_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["variant_id"], name: "index_order_items_on_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "cart_id"
    t.string "coupon_code"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "customer_name"
    t.integer "discount_cents", default: 0, null: false
    t.string "email"
    t.text "notes"
    t.string "number", null: false
    t.string "shipping_city"
    t.string "shipping_country"
    t.string "shipping_line1"
    t.string "status", default: "pending", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["cart_id"], name: "index_orders_on_cart_id"
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "average_order_value_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "discount_cents", default: 0, null: false
    t.integer "new_customers", default: 0, null: false
    t.integer "order_count", default: 0, null: false
    t.string "period", null: false
    t.datetime "period_end", null: false
    t.datetime "period_start", null: false
    t.bigint "revenue_cents", default: 0, null: false
    t.json "top_items", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["period", "created_at"], name: "index_reports_on_period_and_created_at"
    t.index ["period", "period_start"], name: "index_reports_on_period_and_period_start", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.string "author", null: false
    t.text "body"
    t.integer "catalog_item_id", null: false
    t.datetime "created_at", null: false
    t.integer "rating", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["catalog_item_id"], name: "index_reviews_on_catalog_item_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "variants", force: :cascade do |t|
    t.integer "catalog_item_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.json "options"
    t.integer "price_cents", null: false
    t.string "sku", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["catalog_item_id"], name: "index_variants_on_catalog_item_id"
    t.index ["sku"], name: "index_variants_on_sku", unique: true
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "catalog_items"
  add_foreign_key "cart_items", "variants"
  add_foreign_key "carts", "coupons", column: "applied_coupon_id"
  add_foreign_key "carts", "users"
  add_foreign_key "catalog_items", "categories"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "order_items", "catalog_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "variants"
  add_foreign_key "orders", "carts"
  add_foreign_key "orders", "users"
  add_foreign_key "reviews", "catalog_items"
  add_foreign_key "reviews", "users"
  add_foreign_key "variants", "catalog_items"
end
