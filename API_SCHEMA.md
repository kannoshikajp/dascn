# Joppe Tech Store — API Schema Specification

> **Notice:** The API specification has been modularized into separate, pure HTML & Markdown documents located in the [`api_docs/`](api_docs/) directory.
>
> - Main Markdown Index: [`api_docs/INDEX.md`](api_docs/INDEX.md)
> - Pure HTML Interactive Index: [`api_docs/index.html`](api_docs/index.html)

---

## Documentation Directory

| Module | Base Route | Documentation Links |
|---|---|---|
| **Health & Liveness** | `/live`, `/api/v1/live` | [HTML](api_docs/health.html) |
| **Authentication & Profile** | `/api/v1/auth` | [HTML](api_docs/auth.html) |
| **Admin — Users** | `/api/v1/admin/users` | [HTML](api_docs/admin_users.html) |
| **Admin — RBAC Roles & Permissions** | `/api/v1/admin/roles` | [HTML](api_docs/admin_rbac.html) |
| **Categories** | `/api/v1/categories` | [HTML](api_docs/categories.html) |
| **Products & Variants** | `/api/v1/products` | [HTML](api_docs/products.html) |
| **Media & Uploads** | `/api/v1/media` | [HTML](api_docs/media.html) |
| **Customer Addresses** | `/api/v1/addresses` | [HTML](api_docs/addresses.html) |
| **Shopping Cart** | `/api/v1/cart` | [HTML](api_docs/cart.html) |
| **Customer Orders** | `/api/v1/orders` | [HTML](api_docs/orders.html) |
| **Admin — Orders & POS** | `/api/v1/admin/orders` | [HTML](api_docs/admin_orders.html) |
| **Admin — Inventory & Suppliers** | `/api/v1/admin/inventory` | [HTML](api_docs/admin_inventory.html) |
| **Payment — VNPAY Integration** | `/api/v1/payment/vnpay` | [HTML](api_docs/payment_vnpay.html) |
| **Admin — Analytics & KPIs** | `/api/v1/admin/analytics` | [HTML](api_docs/admin_analytics.html) |
| **PC Builder (Specification)** | `/api/v1/pc-builder` | [HTML](api_docs/pc_builder.html) |
| **Reviews & Ratings (Specification)** | `/api/v1/reviews` | [HTML](api_docs/reviews.html) |

---

## Environments & Base URLs
- **Production / Public:** `https://joppe.penguinlab.org/api/v1`
- **Local Development:** `http://localhost:8080/api/v1`
- **Swagger Documentation:** `https://joppe.penguinlab.org/swagger-ui.html`
- **OpenAPI 3.0 JSON:** `https://joppe.penguinlab.org/v3/api-docs`
