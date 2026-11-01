# Joppe Platform — Master Development Plan & Progress Tracker

**Project:** Joppe High-Performance PC & Tech Components E-Commerce Platform  
**Architecture:** Spring Boot Backend + Flutter Monorepo Frontend (`joppe_app`, `joppe_dashboard`, `joppe_core`, `joppe_design_system`)  
**Design Standard:** Google Material 3 (Material You)  
**Status Date:** October 2026

---

## 1. Executive Summary & Architecture Overview

Joppe is a modern high-performance hardware e-commerce and custom PC building system consisting of:
1. **Backend (`backend/`):** Java 21, Spring Boot 4.1.1, PostgreSQL, Flyway, Spring Security OAuth2 (JWT HS256), Spring Mail.
2. **Design System (`frontend/packages/joppe_design_system/`):** Material 3 color roles, tonal elevation, responsive layout breakpoints, and shared UI primitives.
3. **Core Library (`frontend/packages/joppe_core/`):** Universal Dart models, HTTP client, JWT auth interceptor, and backend service integrations.
4. **Staff/Admin Dashboard (`frontend/apps/joppe_dashboard/`):** Desktop & web-first control center for store operations, catalog, RBAC, and inventory.
5. **Customer Mobile/Web Store (`frontend/apps/joppe_app/`):** Customer shopping application with interactive PC Builder simulator.

---

## 2. High-Level Progress Dashboard

```
Overall Progress: [███████████████░░░░░] 78% Completed

Component                   Status       Done / Total Tasks   Progress
----------------------------------------------------------------------
Backend Core & Security     Completed    [12/12]              100%
Backend Catalog & Media     Completed    [12/12]              100%
Backend Orders & Checkout   In Progress  [ 8/10]               80%
Backend Inventory & Supply  Completed    [ 8/ 8]              100%
Backend PC Builder Engine   Pending      [ 2/ 7]               29%
Frontend Design System      Completed    [ 8/ 8]              100%
Frontend Core Package       Completed    [16/16]              100%
Frontend Dashboard App      Completed    [15/15]              100%
Frontend Customer App       Pending      [ 2/16]               13%
DevOps & Production Infra   In Progress  [ 4/ 8]               50%
----------------------------------------------------------------------
```

---

## 3. Detailed Progress by Domain

### 3.1 Backend Service Layer (`backend/`)

#### Finished
- [x] **Project Base & Framework Setup:** Spring Boot 4.1.1 parent POM, Java 21 toolchain, Flyway DB migration pipeline, Docker Compose setup for PostgreSQL and MailHog.
- [x] **Database Schema Initial Migration:** `V1__init_schema.sql` covering 18 relational tables with foreign keys and UUID IDs.
- [x] **RBAC & Granular Permissions:**
  - Migrations `V2`, `V3`, `V4`, `V5` seeding 4 roles (`ROLE_ADMIN`, `ROLE_STAFF`, `ROLE_CUSTOMER`, `ROLE_NON_LOGIN`) and 25 granular system permissions.
  - Role-to-permission mapping join table with cascade constraints.
- [x] **Stateless Security & JWT:**
  - Nimbus JOSE JWT encoder/decoder with HS256 algorithm.
  - Custom `JwtAuthenticationConverter` mapping JWT claims directly to `GrantedAuthority` tokens (`ROLE_*` and `PERM_*`).
  - Spring Method Security (`@EnableMethodSecurity`, `@PreAuthorize`).
  - Strict CORS policy with preflight configuration for dashboard and web apps.
- [x] **Authentication & Profile Management:**
  - User registration (`POST /api/v1/auth/register`) with automatic `ROLE_CUSTOMER` assignment.
  - Login authentication (`POST /api/v1/auth/login`) returning token, expiration, user info, and assigned permissions.
  - Current user profile endpoint (`GET /api/v1/auth/me`).
  - Profile self-update (`PUT /api/v1/auth/profile`) for name, phone, and avatar URL.
  - Password change with current password validation (`POST /api/v1/auth/change-password`).
  - `AdminAccountInitializer` auto-seeding system administrator account on first boot.
- [x] **Admin User Management:**
  - Full administrative CRUD (`/api/v1/admin/users`) with search, role filter, and active status toggle.
  - Administrative password hashing and role reassignment.
- [x] **Admin RBAC Management:**
  - Role list, detail, create, update permissions matrix, and role deletion (`/api/v1/admin/roles/**`).
  - Permission dictionary lookup (`/api/v1/admin/permissions`).
- [x] **Category Hierarchy Management:**
  - Self-referencing recursive parent-child tree mapping with cycle detection.
  - Flat and nested tree listing (`/api/v1/admin/categories`, `/api/v1/admin/categories/tree`).
  - Public category tree and slug lookup (`/api/v1/categories/**`).
  - Active status toggle and safe cascade deletion guards.
- [x] **Products & Hardware Spec Variants:**
  - Migration `V6__add_product_categories_table.sql` enabling multi-category product assignments.
  - Migration `V7__add_attributes_to_product_variants.sql` adding JSONB hardware specs.
  - Full product administrative CRUD (`/api/v1/admin/products/**`) with initial default variant generator.
  - Spec variant sub-resource CRUD (`/api/v1/admin/products/{productId}/variants/**`).
  - Public catalog browsing with keyword search, brand, and category filters (`/api/v1/products/**`).
- [x] **Catalog Architecture Refactor (`V8__central_uploaded_media_and_variant_refactor.sql`):**
  - Streamlined `Product` entity down to core identity: name, version family code (`versionCode`), URL slug, brand, categories, and active status.
  - Relocated thumbnails, Markdown descriptions, and specs from Product to `ProductVariant`.
  - Added `variantCode` (e.g. `OC-BLK-16G`) and `versionCode` (e.g. `Asus-ROG-Strix-G16-2025`) to `product_variants`.
  - Version code inheritance: variants inherit parent product's `versionCode`; updates to product version code automatically sync down to all variants.
  - Multi-image album support: join table `variant_media` with composite key `(variant_id, media_id)`, display ordering, and primary flag.
  - Composite slug generation `${product.slug}-${variant.variantCode}` for unique variant deep links.
- [x] **Central Media Repository (`uploaded_media`):**
  - Central media repository table replacing legacy product-specific tables.
  - Full metadata tracking (`file_url`, `file_name`, `file_size`, `content_type`, `folder`, `created_at`).
  - Multipart upload controller (`/api/v1/media/upload`) with MIME inspection and folder segregation (`products`, `avatars`, `categories`, `brands`, `descriptions`, `general`).
  - List & filter endpoint `GET /api/v1/media` supporting folder filter chips and case-insensitive filename search with in-memory stream filtering.
  - Static resource handler serving `/uploads/**` with permissive caching headers.
- [x] **Transactional Stock Reserve & Release:**
  - `ProductVariantService` methods for atomic stock reservation (`reserveStock`), release on order cancel (`releaseStock`), and stock decrement on shipment (`deductStockOnFulfillment`).
- [x] **Email & Notification Foundation:**
  - `EmailService` with Jakarta Mail, MIME multipart HTML formatting, connection timeouts, and MailHog local testing config.

#### Finished
- [x] **Customer Address Book API (`/api/v1/addresses`):**
  - REST endpoints for `UserAddressService` (create, update, delete, set default shipping address).
  - Secure ownership verification matching authenticated user ID via JWT.
  - Automatic default address selection for initial address creation.
- [x] **Shopping Cart REST API (`/api/v1/cart`):**
  - Expose `CartService` methods via `CartController` with `CART_MANAGE` authority.
  - Enriched response with variant name, SKU, variant code, composite deep link slug, thumbnail, and live stock availability.
  - Add to cart with atomic variant availability and stock limit validation.
  - Update line item quantities, remove item, clear cart.
  - Merge guest cart items into customer account upon login (`/api/v1/cart/merge`).
- [x] **Order Placement & Checkout REST API (`/api/v1/orders`):**
  - Expose `OrderService` via `OrderController` with `ORDER_CREATE` and `ORDER_READ_OWN` authorities.
  - Checkout from active cart or explicit item selection.
  - Unique order code generation (`ORD-YYYYMMDD-XXXXX`).
  - Atomic variant stock reservation (`ProductVariantService.reserveStock`).
  - Customer order history (`/api/v1/orders/my`) and order detail view (`/api/v1/orders/{id}`).
  - Customer self-cancellation for `PENDING` orders with automatic stock rollback (`ProductVariantService.releaseStock`).
- [x] **Administrative Order Management (`/api/v1/admin/orders`):**
  - Expose `AdminOrderController` with `ORDER_MANAGE` authority.
  - Order search and status filtering (order status, payment status, keyword).
  - Order detail inspection including line items and thumbnails.
  - Administrative order lifecycle management (`PENDING` → `CONFIRMED` → `PACKING` → `SHIPPED` → `DELIVERED` / `CANCELLED`).
  - Lifecycle inventory side-effects: transitioning to `SHIPPED` calls `deductStockOnFulfillment`, cancelling calls `releaseStock`.
  - Payment status state machine updates (`UNPAID` → `PAID` / `REFUNDED`).
- [x] **Inventory & Goods Receipts REST API (`/api/v1/admin/inventory`):**
  - Expose `SupplierService` and `GoodReceiptService` via `AdminInventoryController` with `INVENTORY_READ` and `INVENTORY_WRITE` authorities.
  - Supplier CRUD, contact details, active status toggle.
  - Goods receipts drafting, item entry, auto-code generation (`REC-YYYYMMDD-XXXX`), immediate or deferred stock increment (`ProductVariantService.addStock`).
  - Warehouse stock inspection and low stock alert querying.
  - Manual physical inventory adjustment (`quantityOnHand` and `reorderLevel`).
  - Optimized case-insensitive wildcard search filtering in Java (`%query%`) resolving PostgreSQL `lower(bytea)` type inference issues across orders, receipts, and suppliers.

#### In Progress / Not Done
- [ ] **Payment Integration:**
  - Payment intent creation (`/api/v1/payments/create-intent`).
  - VNPay / MoMo IPN (Instant Payment Notification) callback webhook handlers.
  - COD (Cash On Delivery) confirmation flow.
  - Payment status state machine updates (`UNPAID` → `PAID` / `REFUNDED`).
- [ ] **Shipment & Carrier Management:**
  - Integration with delivery providers (GHTK / GHN / ViettelPost).
  - Shipping label generation and tracking code updates (`/api/v1/shipments/**`).
  - Public guest order tracking by tracking code and phone number (`/api/v1/orders/track`).
- [ ] **Promotion & Coupon Voucher Engine:**
  - REST endpoints for `PromotionService`.
  - Coupon code validation, expiration date checks, minimum order value checks, and usage limits.
- [ ] **PC Builder Compatibility Simulation Engine:**
  - Validation rules for hardware parts:
    - CPU Socket vs Motherboard Socket (e.g. LGA1700, AM5).
    - RAM Generation (DDR4 vs DDR5) and slot availability.
    - Power Supply (PSU) total wattage calculation vs estimated system TDP + headroom.
    - GPU length vs PC Case maximum VGA clearance.
    - Form factor compatibility (ATX, Micro-ATX, Mini-ITX).
  - Simulation endpoint (`POST /api/v1/pc-builder/simulate`) and save build endpoint (`POST /api/v1/pc-builder/save`).
- [ ] **Product Reviews & Rating API:**
  - Customer review submission with verified purchase check (`POST /api/v1/products/{id}/reviews`).
  - Public review listing and rating calculation.
  - Staff moderation endpoints (`PATCH /api/v1/admin/reviews/{id}/visibility`).

---

### 3.2 Frontend Design System (`frontend/packages/joppe_design_system/`)

#### Finished
- [x] **Material 3 Tonal Color Schemes:** Complete Light and Dark palettes utilizing Tech Sapphire (`#1E40AF`), Hyper Sky (`#0284C7`), Amber Circuit (`#F97316`), and structured container elevation levels.
- [x] **Adaptive Breakpoints & Window Size Classes:** Compact (<600dp), Medium (600-840dp), Expanded (>840dp).
- [x] **Responsive Layout Scaffold:** `JoppeResponsiveScaffold` automatically switching between Bottom Navigation Bar (Mobile), Navigation Rail (Tablet/Desktop), and Permanent Drawer (Expanded).
- [x] **Geometry & Shapes:** Corner radii system (Extra Small 4dp to Full Pill 9999dp).
- [x] **Spacing & Layout Tokens:** Consistent 4dp/8dp grid spacing system (`JoppeSpacing`).

#### In Progress / Not Done
- [ ] Reusable Hardware Spec Badges (e.g., DDR5, PCIe 4.0, 16GB VRAM pills).
- [ ] Interactive Step-by-Step Stepper Component for Checkout and PC Builder flows.
- [ ] Advanced Data Grid component with column sorting, inline filtering, and row bulk actions.

---

### 3.3 Frontend Core Library (`frontend/packages/joppe_core/`)

#### Finished
- [x] `ApiClient`: HTTP client wrapper with automatic Bearer token injection, multipart form uploads, and centralized error parsing.
- [x] Models: `AuthSession`, `UserProfile`, `UserSummary`, `RoleItem`, `PermissionItem`, `CategoryItem`, `CategoryNode`, `ProductCategorySummary`.
- [x] **Refactored Catalog & Media Models:**
  - `ProductItem`: Added `versionCode` (product family code) with variant-based fallback getters for `thumbnailUrl` and `description`.
  - `ProductVariantSummary`: Added `versionCode`, `variantCode`, `compositeSlug` (`${productSlug}-${variantCode}`), `thumbnailUrl`, `description`, `albumUrls`, and `albumMediaIds`.
  - `UploadedMedia`: Central media asset model (`id`, `fileUrl`, `fileName`, `fileSize`, `contentType`, `folder`, `createdAt`).
- [x] Services: `AuthService`, `UserManagementService`, `RbacManagementService`, `CategoryManagementService`, `ProductManagementService`.
- [x] `MediaUploadService`: Multipart upload (`uploadImage`) and central library lookup (`listMedia({folder, search})`).

- [x] `AddressItem` & `AddressService`: Customer shipping address book CRUD and default address toggling.
- [x] `CartItemModel`, `CartResponseModel` & `CartService`: Full cart fetch, add item with stock limits, quantity update, item delete, cart clear, and guest cart merge.
- [x] `OrderItemModel`, `OrderSummaryModel`, `OrderDetailModel` & `OrderService`: Customer checkout, my orders feed, order cancellation, and administrative order lifecycle (`listAdminOrders`, `updateOrderStatus`, `updatePaymentStatus`).
- [x] `SupplierItem`, `GoodReceiptSummary`, `GoodReceiptDetail`, `ReceiptItemModel`, `InventoryStockItem` & `InventoryService`: Supplier management, inbound batch receipts, and warehouse physical stock audits.

#### In Progress / Not Done
- [ ] `PcBuildModel` & `PcBuilderService`: Component slots, wattage accumulator, and compatibility evaluator.

---

### 3.4 Admin / Staff Control Center (`frontend/apps/joppe_dashboard/`)

#### Finished
- [x] **Authentication Flow:** Secure Login screen with form validation, error banners, JWT session persistence in `SharedPreferences`, and auto-login on refresh.
- [x] **Dashboard Shell:** Responsive navigation rail, active route selection, top app bar with breadcrumbs, current administrator profile popup, and dark/light theme switcher.
- [x] **Overview View:** KPI metrics summary cards, system status indicators, and quick action navigation.
- [x] **RBAC Management View:**
  - Interactive roles table displaying assigned permission counts.
  - Create Role modal dialog with searchable permission checkbox grid.
  - Edit Role dialog with dynamic permission toggling.
  - Delete role confirmation guards.
- [x] **User Management View:**
  - Real-time search query and role-based filtering.
  - User detail presentation (email, role chip, active status pill, creation date).
  - Add User modal dialog with role dropdown and validation.
  - Edit User modal for profile and status updates.
  - One-click account activation / suspension toggle.
- [x] **Category Management View:**
  - Dual-mode view: Hierarchical Nested Tree view and Flat Table view.
  - Create & Edit Category dialogs with parent category selection and icon URL support.
  - Instant status toggle and deletion with constraint checks.
- [x] **Product & Variant Catalog View:**
  - Product catalog table with thumbnail preview, pricing range, brand name, and total stock.
  - Streamlined Product modal: Product Name, Product Version Code, URL slug, and category assignment.
  - Product table displays variant thumbnails, product version code badge, and variant code chips.
  - Markdown product description editor (`MarkdownEditorField`) with live preview tab.
  - Hardware Spec Variant sub-manager: Add, edit, and delete SKU variants with JSONB hardware attributes (RAM, GPU clock, socket, color, etc.).
  - Variant modal with "Inherited Version Code" banner, Variant Code input, and multi-image album picker.
- [x] **Central Media Library & Asset Reuse:**
  - `MediaLibraryDialog`: Responsive 5-column modal grid with folder filter chips (`all`, `products`, `categories`, `brands`, `descriptions`, `avatars`, `general`), real-time search, live file upload tab, and single/multi-selection modes.
  - `VariantAlbumField`: Horizontal album manager supporting multiple product images with instant deletion and direct connection to `MediaLibraryDialog`.
  - `ImageUploadField`: Added "Library" selector button to reuse existing uploaded media without re-uploading.
- [x] **Profile & Password Dialog:** Self-service modal for logged-in administrator to change display name, phone, and password without leaving the dashboard.
- [x] **Orders & Fulfillment View (`OrdersView`):**
  - Live order feed sorted by priority and date.
  - KPI metric cards: Total Orders, Pending Action, In Transit, and Delivered Revenue.
  - Granular filtering: search by Order Code, Recipient Name, or Phone Number; filter chips for Order Status (`PENDING`, `CONFIRMED`, `PACKING`, `SHIPPED`, `DELIVERED`, `CANCELLED`) and Payment Status (`UNPAID`, `PAID`, `REFUNDED`).
  - Order detail inspection dialog (`_OrderDetailDialog`): line items with image thumbnails, SKU snapshots, warranty info, full customer shipping address, and customer notes.
  - Interactive staff order state transitions (Order status dropdown & Payment status dropdown).
  - **Employee POS & Assisted Cart (`_CreateOrderDialog`):** Staff can create carts and place orders on behalf of walk-in or phone-in customers without requiring the customer mobile app; supports auto-linking or provisioning `ROLE_CUSTOMER` account, product/spec variant picker with live stock inspection, quantity controls, counter pickup vs. delivery presets, and atomic stock deduction (`POST /api/v1/admin/orders`).
  - Navigation rail integration in `DashboardShell` and KPI widget in `OverviewView`.
- [x] **Inventory & Supply Chain View (`InventoryView`):**
  - 3-tab unified management: Warehouse Stock & Alerts, Goods Receipts (Inbound), and Suppliers Directory.
  - Warehouse stock inspection with low-stock badges, out-of-stock highlights, and manual stock adjustment modal (`adjustStock`).
  - Inbound goods receipt batch creator (`_CreateReceiptDialog`) with instant physical stock increment (`ProductVariantService.addStock`).
  - Receipt detail inspector (`_ReceiptDetailDialog`) with line items, SKU, import cost, and total batch value.
  - Suppliers directory with add/edit modal and active status toggle.
  - Integrated in `DashboardShell` (navigation rail) and `OverviewView` (KPI card link).

#### In Progress / Not Done
- [ ] **Promotion & Campaign View:**
  - Coupon creation form (Discount percentage vs fixed amount, usage cap, date range).
  - Active campaigns table and disable switch.
- [ ] **Review Moderation View:**
  - Review moderation feed with star rating, customer comments, and reported flags.
  - Approve, reject, or hide review buttons.
- [ ] **Analytics & Business Intelligence Dashboard:**
  - Daily, weekly, and monthly revenue charts.
  - Best-selling hardware components and categories breakdown.
  - Total inventory valuation calculator.

---

### 3.5 Customer Storefront Application (`frontend/apps/joppe_app/`)

#### Finished
- [x] Application runner with Material 3 theme configuration (System / Light / Dark modes).
- [x] Four-tab bottom navigation scaffold (`Catalog`, `PC Builder`, `Cart`, `Profile`).

#### In Progress / Not Done
- [ ] **Customer Authentication & Onboarding:**
  - Customer login and registration screens.
  - Password recovery flow via email OTP / reset link.
  - User profile view and edit screen.
  - Shipping address book management (Saved addresses, default address pill).
- [ ] **Product Catalog Browsing:**
  - Home screen: Hero banners, featured categories carousel, flash sale section, best-selling hardware.
  - Category navigation view with recursive sub-category filter.
  - Product grid with sorting (Price low-to-high, new arrivals, popularity) and brand filters.
  - Product detail screen:
    - Multi-image zoomable gallery.
    - Hardware spec variant switcher (e.g. 16GB vs 32GB RAM, OC vs Non-OC GPU) updating price and stock in real time.
    - Rich Markdown description viewer.
    - Verified customer reviews and rating list.
    - "Add to Cart" and "Buy Now" action buttons.
- [ ] **Interactive PC Builder:**
  - Component slot selector (CPU, Cooler, Motherboard, RAM, Storage, GPU, Case, PSU, Case Fans).
  - Real-time compatibility engine:
    - Visual checkmarks and warning banners (e.g., "Socket LGA1700 matched", "RAM requires DDR5 motherboard").
    - Real-time estimated system wattage bar vs chosen PSU capacity.
  - Build summary bar with total price calculation and "Add All to Cart" CTA.
  - Save build to account / Share build URL functionality.
- [ ] **Shopping Cart & Checkout Flow:**
  - Cart screen: Item list with quantity steppers, price updates, out-of-stock warnings.
  - Promo code input box with immediate discount calculation.
  - Checkout screen:
    - Delivery address selection / quick-entry.
    - Shipping method selection (Standard, Express, Store Pickup).
    - Payment method selection (Cash on Delivery, VNPay QR, Bank Transfer).
  - Order success confirmation screen with order tracking code.
- [ ] **Order Management & Tracking:**
  - Customer order history tab (`Pending`, `Shipping`, `Completed`, `Cancelled`).
  - Real-time shipment tracking timeline with delivery status updates.
  - Guest order tracking screen (Query by Order Code + Phone Number).
  - Post-purchase review submission dialog with star ratings and photo attachments.

---

## 4. Milestone Roadmap & Timeline

```
Milestone 1: Foundations & Catalog Management    [COMPLETED]
├── Spring Boot 4 + PostgreSQL + Flyway Setup
├── Nimbus JWT Auth & RBAC Permissions Matrix
├── Product & Variant Catalog Refactor (V8 migration)
├── Version Code Inheritance & Composite Slug Routing
├── Central Media Asset Repository (`uploaded_media`)
├── Variant Multi-Image Album Support (`variant_media`)
└── Dashboard: RBAC, User Management, Categories, Products & Media Library Dialog

Milestone 2: Cart, Orders & Checkout Engine       [COMPLETED]
├── Backend Cart & Order REST Controllers
├── Transactional Stock Reservation & Fulfillment
├── Delivery Address Book API
├── POS Walk-in Counter Sale Flow (Staff Assisted Ordering)
└── Dashboard: Orders Processing Feed, Detail Dialog & POS Counter Order

Milestone 3: Warehouse & Inventory Control        [COMPLETED]
├── Backend Goods Receipt & Supplier Management API
├── Inbound Batch Processing with Live Stock Increment
├── Manual Stock Adjustment & Low-Stock Alerts
└── Dashboard: Unified 3-Tab Inventory, Receipts & Suppliers View

Milestone 4: Customer Storefront & PC Builder     [CURRENT SPRINT]
├── Backend PC Builder Compatibility Rule Engine (`/api/v1/pc-builder`)
├── App: Interactive PC Builder UI & Wattage Calculator
├── App: Product Catalog Browsing, Detail Screen & Variant Switcher
└── App: Shopping Cart, Address Selection & Multi-Step Checkout

Milestone 5: Payment Gateway, Carrier & Marketing [UPCOMING]
├── Payment Gateway Webhooks (VNPay / MoMo / COD)
├── Order Fulfillment & Shipping Carrier Tracking
├── Promotion Engine & Voucher Redemption
├── Customer Review Submission & Admin Moderation
└── Dashboard: BI Analytics & Revenue Charts
```

---

## 5. Risk Assessment & Technical Considerations

| Risk Area | Severity | Mitigation Strategy |
|---|---|---|
| **Inventory Overselling on High Demand** | High | Pessimistic locking / database row locking on `ProductVariant` during `reserveStock` transaction. |
| **PC Builder Incompatible Configurations** | Medium | Comprehensive hardware attributes schema stored in variant `attributes` JSONB; rule engine validates CPU socket, chipset, RAM standard, and PSU wattage. |
| **Large Media Uploads Disk Exhaustion** | Low | Max file size capped at 15MB; image extension and MIME whitelist enforced; ready to swap local storage with AWS S3 / Cloudflare R2 via `MediaStorageService` interface. |
| **State Desynchronization on Checkout** | High | Atomic database transactions spanning order creation, line item insertion, and stock reservation. Any failure triggers total rollback. |

---

## 6. Action Items for Next Session

1. **PC Builder Engine:** Implement compatibility validation rules in `joppe.backend.domain.interaction` (CPU socket vs Motherboard socket, DDR4 vs DDR5 RAM, PSU headroom calculator, GPU clearance).
2. **Customer App:** Build `joppe_app` storefront screens (catalog browsing, hardware variant switcher, customer cart, address book, checkout).
3. **Payments & Carriers:** Implement VNPay / MoMo payment intent callbacks and shipment carrier integration.
