# Joppe Tech Store — API Documentation Index

All API documentation files have been modularized into pure semantic HTML files located in this directory (`api_docs/`), with zero CSS and zero JavaScript for clean, lightweight viewing across all browsers, editors, and environments.

Open [`index.html`](index.html) in any browser to navigate the complete interactive documentation.

---

## Documentation Modules Directory

| Module | Base Route | HTML Documentation File | Description |
|---|---|---|---|
| **Health & Liveness** | `/live`, `/api/v1/live` | [`health.html`](health.html) | Service uptime, database connectivity probe |
| **Authentication & Profile** | `/api/v1/auth` | [`auth.html`](auth.html) | Register, login, profile edit, change password |
| **Admin — Users** | `/api/v1/admin/users` | [`admin_users.html`](admin_users.html) | Account management, role assignment, status toggles |
| **Admin — RBAC Roles** | `/api/v1/admin/roles` | [`admin_rbac.html`](admin_rbac.html) | System roles and permission mappings dictionary |
| **Categories** | `/api/v1/categories` | [`categories.html`](categories.html) | Category tree, admin flat list, category CRUD |
| **Products & Variants** | `/api/v1/products` | [`products.html`](products.html) | Product catalog, SKU & parentSku traversal, hardware variants |
| **Media & Uploads** | `/api/v1/media` | [`media.html`](media.html) | Multipart image upload, central media repository, asset reuse |
| **Customer Addresses** | `/api/v1/addresses` | [`addresses.html`](addresses.html) | Personal shipping address book management |
| **Shopping Cart** | `/api/v1/cart` | [`cart.html`](cart.html) | Line item CRUD, atomic stock checks, guest cart merge |
| **Customer Orders** | `/api/v1/orders` | [`orders.html`](orders.html) | Checkout, order tracking, forward state machine lifecycle |
| **Admin — Orders & POS** | `/api/v1/admin/orders` | [`admin_orders.html`](admin_orders.html) | Status advancement, 10-day refund constraint, walk-in POS sales |
| **Admin — Inventory** | `/api/v1/admin/inventory` | [`admin_inventory.html`](admin_inventory.html) | Suppliers, goods receipt batches, stock audits |
| **Payment — VNPAY** | `/api/v1/payment/vnpay` | [`payment_vnpay.html`](payment_vnpay.html) | Signed payment URLs, IPN webhook, browser return handler |
| **Admin — Analytics** | `/api/v1/admin/analytics` | [`admin_analytics.html`](admin_analytics.html) | Store revenue KPIs, sales velocity trend, inventory health |
| **PC Builder (Spec)** | `/api/v1/pc-builder` | [`pc_builder.html`](pc_builder.html) | Hardware compatibility evaluation and saved builds |
| **Reviews & Ratings (Spec)** | `/api/v1/reviews` | [`reviews.html`](reviews.html) | Verified customer ratings, feedback, and moderation |

---

## Environments & Base URLs

- **Framework:** Spring Boot 4.1.1 (Java 21 LTS)
- **Production API:** `https://joppe.penguinlab.org/api/v1`
- **Local Development API:** `http://localhost:8080/api/v1`
- **Swagger UI:** `http://localhost:8080/swagger-ui.html` | `https://joppe.penguinlab.org/swagger-ui.html`
- **OpenAPI JSON Spec:** `http://localhost:8080/v3/api-docs` | `https://joppe.penguinlab.org/v3/api-docs`
