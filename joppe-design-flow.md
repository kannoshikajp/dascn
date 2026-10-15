# Joppe Design System & User Flow Guidelines

**Standard:** Google Material 3 (Material You / M3)  
**Target Applications:** `joppe_app` (Customer Store & PC Builder), `joppe_dashboard` (Control Center)  
**Architecture:** Dart/Flutter Monorepo Workspace (`frontend/`)

---

## 1. System Philosophy & Foundations

Joppe utilizes **Google Material 3** as its unified design language across consumer mobile/web applications and enterprise management dashboards.

### Core Principles
1. **Dynamic & Tonal Color System:** Interfaces derive visual hierarchy through tonal luminance rather than arbitrary contrasting colors or heavy drop-shadows.
2. **Adaptive Surface Architecture:** Components transition smoothly across standard Material 3 Window Size Classes (Compact, Medium, Expanded).
3. **Intentional Motion:** Animations communicate state changes and spatial hierarchy via M3 emphasized easing curves.
4. **Universal Accessibility (WCAG 2.1 AA+):** Minimum contrast ratio of 4.5:1 for normal text and 3:1 for large text and critical UI elements across both Light and Dark themes.

---

## 2. Color System & Tonal Palettes

### 2.1 Seed Colors
| Role | Color Name | Hex Code | Purpose |
| :--- | :--- | :--- | :--- |
| **Primary** | Tech Sapphire | `#1E40AF` | Main brand identity, key CTAs, active states |
| **Secondary** | Hyper Sky | `#0284C7` | Accent components, selection indicators, sub-navigation |
| **Tertiary** | Amber Circuit | `#F97316` | Promotional badges, sale alerts, PC Builder warnings |
| **Neutral** | Slate Foundation| `#64748B` | Backgrounds, surface elevation tinting, dividers |
| **Neutral Variant** | Cool Slate | `#64748B` | Unselected icons, subtle borders, input outlines |

### 2.2 Semantic Status Colors
- **Success:** `#16A34A` (In stock, Order paid, PC components 100% compatible)
- **Warning:** `#CA8A04` (Low stock alert, Wattage near PSU limit, Pending verification)
- **Error:** `#DC2626` (Out of stock, Socket mismatch, Payment failed, Auth error)
- **Info:** `#2563EB` (Informational notice, shipping updates)

### 2.3 Surface Container Roles (Material 3)
Material 3 replaces arbitrary grey shades with structured container elevation levels:

| Surface Level | Light Tone | Dark Tone | Usage |
| :--- | :--- | :--- | :--- |
| **Surface** | `#F8FAFC` | `#0F172A` | Base scaffold background |
| **Surface Container Lowest** | `#FFFFFF` | `#090D16` | Bottom sheets, cards over elevated surfaces |
| **Surface Container Low** | `#F1F5F9` | `#1E293B` | Default product cards, data table rows |
| **Surface Container** | `#E2E8F0` | `#334155` | Search bars, filter chips, navigation bars |
| **Surface Container High** | `#CBD5E1` | `#475569` | Dialog backgrounds, floating menus |
| **Surface Container Highest**| `#94A3B8` | `#64748B` | Text field fill states, disabled elements |

---

## 3. Typography Scale (Material 3)

The typography system follows the official Material 3 typescale using high-readability sans-serif fonts (`Roboto` / `Inter`).

| Token | Size | Line Height | Weight | Tracking | Primary Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 57sp | 64sp | Regular (400) | -0.25 | Splash banners, marketing headlines |
| `displayMedium` | 45sp | 52sp | Regular (400) | 0.0 | High-impact product showcase |
| `displaySmall` | 36sp | 44sp | Regular (400) | 0.0 | PC Builder total cost counter |
| `headlineLarge` | 32sp | 40sp | Regular (400) | 0.0 | Screen page titles (Desktop) |
| `headlineMedium` | 28sp | 36sp | Medium (500) | 0.0 | Section headers, card titles |
| `headlineSmall` | 24sp | 32sp | Medium (500) | 0.0 | Modal dialog titles |
| `titleLarge` | 22sp | 28sp | Medium (500) | 0.0 | App bar title, major widget titles |
| `titleMedium` | 16sp | 24sp | Medium (500) | 0.15 | Product title in grid, list headers |
| `titleSmall` | 14sp | 20sp | Medium (500) | 0.1 | Subsection titles, table column headers |
| `bodyLarge` | 16sp | 24sp | Regular (400) | 0.5 | Product descriptions, long-form text |
| `bodyMedium` | 14sp | 20sp | Regular (400) | 0.25 | Standard UI text, list item subtitles |
| `bodySmall` | 12sp | 16sp | Regular (400) | 0.4 | Footnotes, timestamps, helper text |
| `labelLarge` | 14sp | 20sp | SemiBold (600)| 0.1 | Button labels, tabs, chip text |
| `labelMedium` | 12sp | 16sp | Medium (500) | 0.5 | Badges, stock tags, input counters |
| `labelSmall` | 11sp | 16sp | Medium (500) | 0.5 | Micro badges, status pills |

---

## 4. Elevation, Surfaces & Shape Geometry

### 4.1 Tonal Elevation
Material 3 indicates elevation via surface tint overlay from the primary color:
- **Level 0 (0dp):** Plain background surface (0% tint).
- **Level 1 (1dp):** Standard cards, search bar (+5% primary tint).
- **Level 2 (3dp):** Elevated cards on hover, small popovers (+8% primary tint).
- **Level 3 (6dp):** Floating action buttons (FAB), bottom sheets (+11% primary tint).
- **Level 4 (8dp):** Navigation rail/drawer floating state (+12% primary tint).
- **Level 5 (12dp):** Modal dialogs (+14% primary tint).

### 4.2 Shape Corner Radii
- **Extra Small (4dp):** Badges, compact chips, tooltips.
- **Small (8dp):** Buttons, text fields, snackbars, alert banners.
- **Medium (12dp):** Product cards, dashboard widgets, dropdown menus.
- **Large (16dp):** Navigation drawer panels, bottom sheets.
- **Extra Large (28dp):** Modal dialogs, floating action sheets.
- **Full (Pill / 9999dp):** Search input bars, filter chips, pill avatars.

---

## 5. Responsive Layout Architecture

Material 3 breaks viewports into three primary **Window Size Classes**:

```
+---------------------------------------------------------------------------------+
| Compact (<600dp)       | Medium (600-840dp)          | Expanded (>840dp)        |
| Mobile Phones          | Foldables / Small Tablets   | Desktops / Web Dashboards|
|------------------------+-----------------------------+--------------------------|
| Bottom Navigation Bar  | Navigation Rail (Collapsed) | Permanent Nav Drawer     |
| 1-Column Feed          | 2-Column Responsive Grid    | Multi-pane Master/Detail |
| Modal Bottom Sheets    | Side Sheet / Modal Dialog   | Side Panels / Data Tables|
+---------------------------------------------------------------------------------+
```

---

## 6. App User Flows (`joppe_app`)

The consumer application covers the end-to-end purchasing and hardware building lifecycle.

### 6.1 Authentication & Profile Flow
```
[Launch App]
    │
    ├── Authenticated ──────> [Home Screen / Catalog]
    └── Guest / Expired ───> [Login Dialog / Screen]
                                 │
                                 ├── Email + Password ──> JWT Token (Stored Securely)
                                 ├── Register New ──────> Role: ROLE_CUSTOMER
                                 └── View as Guest ─────> Read-only Catalog
```

### 6.2 Product Discovery & Catalog Flow
1. **Explore:** Homepage showcases promotions, recommended PC parts, and trending builds.
2. **Search & Filter:** Search bar with instant suggestion chips. Filters by Category, Brand, Price Range, and In-Stock switch.
3. **Variant Selection:** On product details, users select Color, Storage, or Specification with real-time stock and price adjustments.

### 6.3 Interactive PC Builder Studio Flow
A dedicated custom configurator ensuring component compatibility:
```
[Start New PC Build]
   │
   ├── 1. Select CPU (e.g., LGA1700 or AM5)
   │       └── Filters Motherboards to matching socket!
   ├── 2. Select Motherboard (e.g., DDR5)
   │       └── Filters RAM to DDR5 type!
   ├── 3. Select RAM & GPU
   │       └── Calculates Total Estimated Wattage!
   ├── 4. Select Storage & Power Supply (PSU)
   │       └── Validates PSU Wattage >= Recommended Wattage!
   ├── 5. Compatibility Verification Pass:
   │       ├── PASS (Green): Proceed to Cart
   │       └── WARN (Amber): Dimension / clearance notices
   └── 6. One-Click Add All Components to Cart / Save PC Build
```

### 6.4 Cart, Voucher & Checkout Flow
1. **Cart:** Quantity adjustments, stock reservation check, voucher code application.
2. **Checkout:** Select saved address (or add new via modal), select shipping provider, choose payment method (VNPAY, MoMo, Bank Transfer, COD).
3. **Order Placed:** Displays M3 animated success illustration with real-time order tracking timeline (`PENDING` -> `PAID` -> `PROCESSING` -> `SHIPPING` -> `DELIVERED`).

---

## 7. Dashboard User Flows (`joppe_dashboard`)

The administrative dashboard provides operations for staff, inventory managers, and admins.

### 7.1 RBAC-Gated Navigation Tree
The dashboard evaluates user authorities dynamically:
- **`ROLE_ADMIN`:** Full system access (Users, RBAC, Financials, Catalog, Inventory, Orders).
- **`ROLE_MANAGER`:** Catalog CRUD, Inventory Stocking, Order Processing, Promotions.
- **`ROLE_STAFF`:** Order Fulfillment, Good Receipts, Customer Inquiries.

### 7.2 Inventory & Good Receipt Flow
```
[Stock Arrival] ──> [Create Good Receipt] ──> [Select Supplier]
                          │
                          ├── Add Line Items (SKU, Cost Price, Quantity)
                          ├── Verify Physical Delivery vs PO
                          └── [Confirm Receipt] ──> Auto-updates inventory quantity in DB
```

### 7.3 Order Processing Flow
1. **Orders Table:** Filter by status, payment method, date range.
2. **Order Detail Drawer:** View purchased variants, customer shipping address, payment status.
3. **Action Pipeline:**
   - Verify payment -> Assign shipment carrier -> Print shipping label -> Mark `SHIPPED`.

---

## 8. Monorepo Package Integration Standards

The frontend workspace is organized under `frontend/` into modular packages:

```
frontend/
├── pubspec.yaml                     <-- Dart Workspace Root
├── apps/
│   ├── joppe_app/                  <-- Customer Mobile & Web App
│   └── joppe_dashboard/            <-- Enterprise Management Dashboard
└── packages/
    ├── joppe_core/                 <-- Business Logic, API Models, Auth State
    └── joppe_design_system/        <-- Material 3 Themes, Tokens, Widgets
```

### Development Guidelines
1. **Zero Hardcoded Colors:** Never write `Colors.blue` or `Color(0xFF...)` in UI screens. Always reference `Theme.of(context).colorScheme.*` or `JoppeColors.*`.
2. **Consistent Spacing:** Use `JoppeSpacing.sm`, `JoppeSpacing.md`, `JoppeSpacing.lg` instead of magic numbers.
3. **Adaptive First:** Use `JoppeResponsiveScaffold` or check `JoppeBreakpoints.getWindowSizeClass(context)` for multi-device support.
4. **All Tests Clean:** Every new package must include widget and unit test coverage matching M3 behavior.
