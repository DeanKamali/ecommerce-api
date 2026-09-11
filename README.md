# E-commerce API

A REST API for an e-commerce backend built on Ruby on Rails 8 (API mode).

## Domain model

- **Category** — tree of categories (self-referencing `parent_id`), referenced by catalog items.
- **CatalogItem** — STI base (table `catalog_items`) shared by:
  - **Product** — physical goods with price, SKU, optional inventory tracking and **variants** (size/color/switch options, each with its own price, stock, and JSON `options`).
  - **Service** — bookable services with duration, bookability, and capacity (no stock).
- **Review** — 1..5 star ratings with author + body, per catalog item.
- **Cart** — per-user shopping cart (auth required), holds **CartItems** (item + optional variant + quantity + locked-in unit price).
- **Order** — immutable-ish purchase record with a status machine:
  `pending → confirmed → shipped → delivered`, with `cancelled` reachable from `pending`/`confirmed` (restocks sellable inventory).

## Requirements

- Ruby 3.x, Rails 8.1 (Bundled via Gemfile)
- SQLite 3

## Setup

```sh
bundle install
bin/rails db:prepare   # creates + migrates the database
bin/rails db:seed      # optional: sample catalog
bin/rails server
```

## API docs (Swagger UI)

Interactive OpenAPI docs, served by the running app:

- **Swagger UI**: <http://localhost:3000/swagger/>
- **OpenAPI 3 spec (YAML)**: <http://localhost:3000/api-docs/swagger.yaml>

The spec is authored by hand in `swagger/swagger.yaml` and served by `rswag-api`; the UI is `rswag-ui`.

## Authentication

The API uses **bearer-token** authentication.

1. **Register** to get an account and an `api_token` — `POST /auth/register` with `{"email", "password", "name"}` — or log in with an existing account at `POST /auth/login`.
2. **Authenticate** each protected request with the header:

   ```
   Authorization: Bearer <api_token>
   ```

**Access levels**
- **Public (no auth):** read the catalog — `GET /categories`, `/products`, `/services`, and their variants and reviews.
- **Authenticated user:** carts, orders, and writing reviews. A user can only read/modify their own carts, orders, and reviews; another user's records return `404`.
- **Admin** (`admin: true`): additionally create/update/delete categories, products, and services. Non-admins receive `403` on these writes.

**Seeded accounts** (created by `bin/rails db:seed`):
- Admin: `admin@shop.local` / `admin-password-123`
- Shopper: `demo@shop.local` / `demo-password-123`

## Endpoints

### Catalog

| Method | Path | Description |
|---|---|---|
| GET | `/categories` | List categories (`?parent_id=` to filter) |
| GET | `/categories/:id` | Show with its items |
| POST / PATCH / DELETE | `/categories[/:id]` | Manage |
| GET | `/products` | List products; filters: `?category=slug`, `?q=`, `?min_price=`, `?max_price=`, `?featured=true`, `?sort=price_asc\|price_desc\|newest\|name`, `?page=`, `?per=` |
| GET | `/products/:id` | Show (includes variants + reviews) |
| POST / PATCH / DELETE | `/products[/:id]` | Manage |
| GET | `/services` | Same filters as products |
| GET | `/services/:id` | Show |
| POST / PATCH / DELETE | `/services[/:id]` | Manage |

### Variants (under a product)

| Method | Path |
|---|---|
| GET | `/products/:product_id/variants` |
| GET | `/products/:product_id/variants/:id` |
| POST / PATCH / DELETE | as above |

### Reviews (under a product or service)

| Method | Path |
|---|---|
| GET | `/products/:product_id/reviews` |
| POST | `/products/:product_id/reviews` |
| DELETE | `/products/:product_id/reviews/:id` |
| GET / POST / DELETE | same under `/services/:service_id/reviews` |

### Carts

| Method | Path | Description |
|---|---|---|
| POST | `/carts` | Create cart (returns `token`) |
| GET | `/carts/:id` | Full cart with items + totals |
| POST / PATCH / DELETE | `/carts/:id/cart_items` | Add / update line items (`{"cart_item": {"variant_id": N, "quantity": 2}}` — `catalog_item_id` optional when a variant is given) |
| POST | `/carts/:id/checkout` | Convert cart to order (consumes stock) |

### Orders

| Method | Path | Description |
|---|---|---|
| GET | `/orders` | List; `?status=pending`, `?page=` |
| GET | `/orders/:id` | Show full order |
| POST | `/orders` | Create directly (items array) |
| PATCH | `/orders/:id` | `{ "order": { "status": "confirmed" } }` — validates the state machine |
| POST | `/orders/:id/cancel` | Cancel + restock |

## Error handling

- `404` — unknown resource (or another user's cart/order/review)
- `422` — validation failure, invalid order transition, or insufficient stock
- `400` — missing required parameters
- `401` — missing or invalid bearer token
- `403` — authenticated but not allowed (e.g. a non-admin writing to the catalog)

## Sample flow

```sh
# 0. Log in to get a bearer token (or POST /auth/register for a new account)
TOKEN=$(curl -s -X POST localhost:3000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@shop.local","password":"demo-password-123"}' | jq -r .api_token)
AUTH="Authorization: Bearer $TOKEN"

# 1. Find a product (public, no auth)
curl -s localhost:3000/products | jq '.data[0]'

# 2. Create a cart
CART=$(curl -s -X POST localhost:3000/carts -H "$AUTH" \
  -H 'Content-Type: application/json' -d '{}' | jq -r .id)

# 3. Add the first variant of product 1
curl -s -X POST localhost:3000/carts/$CART/cart_items \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"cart_item": {"variant_id": 1, "quantity": 2}}'

# 4. Checkout
curl -s -X POST localhost:3000/carts/$CART/checkout \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"order": {"customer_name": "Dean", "email": "dean@example.com"}}'

# 5. Confirm the order
curl -s -X PATCH localhost:3000/orders/1 \
  -H "$AUTH" -H 'Content-Type: application/json' -d '{"order": {"status": "confirmed"}}'
```
