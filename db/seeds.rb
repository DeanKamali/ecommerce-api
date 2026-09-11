# Sample data: categories, products (with variants), services, reviews.


# Users: an admin (manages the catalog) and a demo shopper (owns carts/orders/reviews).
admin = User.find_or_create_by!(email: "admin@shop.local") do |u|
  u.name = "Admin"
  u.password = "admin-password-123"
  u.admin = true
  u.api_token = User.generate_token
end
demo = User.find_or_create_by!(email: "demo@shop.local") do |u|
  u.name = "Demo Shopper"
  u.password = "demo-password-123"
  u.admin = false
  u.api_token = User.generate_token
end
electronics = Category.create!(name: "Electronics", description: "Gadgets and gear")
apparel = Category.create!(name: "Apparel", description: "Clothing and accessories")
home = Category.create!(name: "Home & Kitchen")
phone = Category.create!(name: "Phones", parent: electronics, slug: "phones")
creative = Category.create!(name: "Creative Services")
it_services = Category.create!(name: "IT Services")

headphones = Product.create!(
  name: "Wireless Headphones",
  category: electronics,
  description: "Over-ear noise-cancelling headphones with 30h battery.",
  price_cents: 199_99,
  sku: "HPH-001",
  stock_quantity: 0,
  featured: true
)
headphones.variants.create!(name: "Black", sku: "HPH-001-BLK", price_cents: 199_99, stock_quantity: 25, options: { color: "black" })
headphones.variants.create!(name: "White", sku: "HPH-001-WHT", price_cents: 199_99, stock_quantity: 10, options: { color: "white" })

keyboard = Product.create!(
  name: "Mechanical Keyboard",
  category: electronics,
  description: "Hot-swappable 75% mechanical keyboard, gasket mount.",
  price_cents: 149_00,
  sku: "KB-750"
)
keyboard.variants.create!(name: "Brown switches", sku: "KB-750-BRN", price_cents: 149_00, stock_quantity: 40, options: { switches: "browns" })
keyboard.variants.create!(name: "Blue switches", sku: "KB-750-BLU", price_cents: 149_00, stock_quantity: 5, options: { switches: "blues" })

grinder = Product.create!(
  name: "Burr Coffee Grinder",
  category: home,
  description: "40mm conical burr grinder, 40 grind settings.",
  price_cents: 89_50,
  sku: "GRD-40",
  stock_quantity: 15
)

tee = Product.create!(
  name: "Classic Tee",
  category: apparel,
  description: "Heavyweight cotton t-shirt, pre-shrunk.",
  price_cents: 29_99,
  sku: "TEE-CLS",
  stock_quantity: 0
)
%w[S M L XL].each_with_index do |size, i|
  tee.variants.create!(name: size, sku: "TEE-CLS-#{size}", price_cents: 29_99, stock_quantity: [120, 200, 150, 60][i], options: { size: size })
end

logo = Service.create!(
  name: "Logo Design",
  category: creative,
  description: "Custom logo design with 3 concepts and unlimited revisions.",
  price_cents: 450_00,
  duration_minutes: 480,
  bookable: true,
  featured: true
)

maintenance = Service.create!(
  name: "Website Maintenance (monthly)",
  category: it_services,
  description: "Updates, backups, monitoring, and 2h of dev time per month.",
  price_cents: 250_00,
  duration_minutes: 60,
  bookable: true,
  max_capacity: 20
)

seo = Service.create!(
  name: "SEO Audit",
  category: it_services,
  description: "Full technical + content SEO audit with prioritized action plan.",
  price_cents: 800_00,
  duration_minutes: 240,
  bookable: true
)

# --- Pricing demo: one item on a sale, one on a markdown path -------------

# Headphones: 20% sale, active now, ends in 3 weeks.
headphones.update!(
  sale_price_cents: 159_99,
  sale_starts_at: 7.days.ago,
  sale_ends_at: 21.days.from_now
)

# Grinder: 15% off per 30 days unsold, capped at 60%. Backdated 95 days
# so the demo shows a 30% markdown already applied.
grinder.update!(markdown_step_days: 30, markdown_step_percent: 15, max_discount_percent: 60)
grinder.update_column(:created_at, 95.days.ago)

# --- Coupons ----------------------------------------------------------------

if Coupon.count.zero?
  Coupon.create!(code: "SAVE10", kind: "percent", value: 10)
  Coupon.create!(code: "WELCOME20", kind: "percent", value: 20,
                 min_subtotal_cents: 5_000, max_redemptions: 100,
                 valid_from: 1.day.ago, valid_until: 30.days.from_now)
  Coupon.create!(code: "FLAT50", kind: "fixed", value: 5_000, min_subtotal_cents: 3_000)
  # Expired: should be rejected with 422.
  Coupon.create!(code: "SUMMER25", kind: "percent", value: 25,
                 valid_from: 90.days.ago, valid_until: 30.days.ago)
  # Redeemed out: should be rejected with 422.
  Coupon.create!(code: "OLD15", kind: "percent", value: 15, max_redemptions: 5, used_count: 5)
end
[
  [headphones, "Ava", 5, "Battery life is incredible, ANC is the best I've used."],
  [headphones, "Marcus", 4, "Great sound. Slightly tight fit for large heads."],
  [keyboard, "Jin", 5, "Build quality is superb for the price."],
  [grinder, "Priya", 4, "Consistent grind, easy to clean."],
  [logo, "Studio North", 5, "Nailed the brief on the first round."],
  [maintenance, "Fleet Ops", 4, "Reports are clear and updates land without drama."],
].each do |item, author, rating, body|
  item.reviews.create!(author: author, rating: rating, body: body, user: demo)
end

puts "Seeded: #{User.count} users, #{Category.count} categories, #{Product.count} products, #{Service.count} services, #{Variant.count} variants, #{Review.count} reviews, #{Coupon.count} coupons"
