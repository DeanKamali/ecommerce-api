# E-commerce API

A REST API for a small e-commerce backend on Ruby on Rails 8 (API mode): products with variants, services, categories, reviews, carts, checkout, orders, sales/markdowns, and coupons. All responses are JSON.

## Setup

```sh
bundle install
bin/rails db:prepare   # create + migrate the database
bin/rails db:seed      # optional: sample catalog, coupons, sales
bin/rails server
```

Requires Ruby 3.x, Rails 8.1, and SQLite 3.

## API docs

Interactive Swagger UI, served by the running app:

- **Swagger UI**: <http://localhost:3000/swagger/>
- **OpenAPI 3 spec**: <http://localhost:3000/api-docs/swagger.yaml>

Endpoints, parameters, request/response schemas, and error codes are all documented there.

## Authentication

Bearer tokens. Register or log in to get one:

```
Authorization: Bearer <api_token>
```

- **Public:** reading the catalog (categories, products, services, variants, reviews).
- **Authenticated:** carts, orders, reviews, applying coupons. Users only see their own records.
- **Admin** (`admin: true`): create/update/delete catalog entries.

**Seeded accounts** (via `bin/rails db:seed`):

- Admin: `admin@shop.local` / `admin-password-123`
- Shopper: `demo@shop.local` / `demo-password-123`

## Admin dashboard

Admin-only KPI and reporting endpoints (bearer token for an admin user):

- `GET /admin/overview` — live KPI snapshot: order counts by status, revenue, AOV, catalog health (incl. low stock), active coupons, and this-week/this-month activity.
- `GET /admin/reports` — precomputed report snapshots (paginated; filter with `?period=weekly|monthly`).
- `GET /admin/reports/{id}` — a single report snapshot.
- `GET /admin/top_items` — catalog items ranked by lifetime revenue from non-cancelled orders (`?limit=`, 1-50).
- `POST /admin/reports/generate` — (re)generate a report for a period: `{ "period": "weekly" | "monthly" }`.

Reports are precomputed snapshots so dashboards stay cheap; `generate` recomputes them on demand.

## Pricing

- **Sales** — a catalog item carries a fixed `sale_price_cents` and a `sale_starts_at`/`sale_ends_at` window.
- **Markdowns** — an item can be configured to drop in percentage steps (`markdown_step_days`, `markdown_step_percent`) as it stays unsold, capped at `max_discount_percent`.
- **Coupons** — `percent` or `fixed` discounts, with optional minimum subtotal, validity window, and redemption limit. Applied to a cart, and snapshotted onto the order at checkout.

Prices shown on catalog items, carts, and orders are always the effective discounted amounts.
