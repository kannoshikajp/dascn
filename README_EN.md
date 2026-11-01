# Joppe Tech Store — E-Commerce & Retail Operations Platform

[Tài liệu Tiếng Việt](README.md)

Enterprise e-commerce and retail operations platform specializing in computer hardware, custom PC building (PC Builder), point-of-sale checkout (POS Cashier), warehouse logistics (Inbound/Outbound Goods Receipts), multi-tier categories, and role-based access control (RBAC Matrix).

---

## Table of Contents

- [Architectural Overview](#architectural-overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Configuration](#environment-configuration)
- [Backend Setup & Run](#backend-setup--run)
- [Mail Server Setup (MailHog)](#mail-server-setup-mailhog)
- [Frontend Setup & Run](#frontend-setup--run)
  - [Operations Dashboard (Joppe Dashboard)](#operations-dashboard-joppe-dashboard)
  - [Customer Storefront (Joppe App)](#customer-storefront-joppe-app)
- [Default Accounts & Permissions](#default-accounts--permissions)
- [Online Payment with VNPay Sandbox](#online-payment-with-vnpay-sandbox)
- [API Documentation](#api-documentation)
- [Automated Testing](#automated-testing)

---

## Architectural Overview

The Joppe platform is organized into two primary pillars:

1. **Backend API Service:**
   - **Framework:** Spring Boot 4.1.1 (Java 21 LTS)
   - **Database:** PostgreSQL 15+
   - **Database Migrations:** Flyway (Migrations V1 through V12)
   - **Security:** Spring Security + Stateless JWT Authentication + RBAC Method Security
   - **Payments:** VNPay Sandbox Gateway (HMAC-SHA512 checksums, IPN Webhook verification, dynamic QR generation)
   - **Email:** Spring Mail (integrates with any standard SMTP server or local MailHog)
   - **API Docs:** Springdoc OpenAPI / Swagger UI and offline static HTML documentation suite (`api_docs/`)

2. **Frontend Monorepo (Flutter Workspace):**
   - **`joppe_dashboard`:** Central operations web app (Material 3, Dark/Light theme, Collapsible Sidebar, POS Cashier, CSV export, Inventory & Catalog management).
   - **`joppe_app`:** Customer-facing storefront (Cyberpunk-styled UI, Custom PC Builder, AI Advisor, Shopping Cart, Order Tracking).
   - **`joppe_core`:** Shared domain models, HTTP client, interceptors, and service layer.
   - **`joppe_design_system`:** Reusable UI library with responsive breakpoints, unified JoppeTheme, and custom adaptive widgets.

---

## Project Structure

```text
joppe/
├── backend/                               # Spring Boot Application (Java 21)
│   ├── pom.xml                            # Maven dependencies & build configuration
│   └── src/
│       ├── main/
│       │   ├── java/joppe/backend/
│       │   │   ├── admin/                 # Admin APIs: Products, Categories, Stock, Users, Analytics
│       │   │   ├── auth/                  # JWT security, user registration & login
│       │   │   ├── common/                # Health checks (/live), CSV export helpers
│       │   │   ├── domain/                # Cart, Catalog, Inventory, Order, User, VNPay
│       │   │   └── media/                 # Multipart upload & centralized asset repository
│       │   └── resources/
│       │       ├── application.properties # Default Spring Boot configuration
│       │       └── db/migration/          # 12 Flyway SQL migration scripts (V1 -> V12)
│       └── test/                          # Unit and integration test suites
├── frontend/                              # Flutter Multi-Package Workspace
│   ├── pubspec.yaml                       # Workspace root definition
│   ├── apps/
│   │   ├── joppe_dashboard/               # Web Operations Dashboard
│   │   └── joppe_app/                     # Customer Storefront App
│   └── packages/
│       ├── joppe_core/                    # Shared API Client, Services, Models
│       └── joppe_design_system/           # Shared Theme, Components, Scaffolds
├── api_docs/                              # Standalone Semantic HTML API documentation
│   ├── index.html                         # Interactive API documentation homepage
│   └── INDEX.md                           # Documentation modules overview
├── .env.example                           # Backend environment variables template
├── build-dashboard-dev.bat                # Build script for Dashboard Web (Dev environment)
└── build-dashboard-prod.bat               # Build script for Dashboard Web (Prod environment)
```

---

## Prerequisites

Ensure the following tools are installed before proceeding:

- **Java Development Kit (JDK):** Version **21 LTS** or newer.
- **Apache Maven:** Version **3.9+** (or use the included `./mvnw` wrapper).
- **PostgreSQL Server:** Version **15+** (running on port 5432).
- **Flutter SDK:** Version **3.19+** (stable channel) with Dart SDK **3.13+**.
- **Google Chrome / Microsoft Edge:** For running and testing Flutter Web.
- **MailHog / Local SMTP Server (optional):** For testing outgoing emails in local development.

---

## Environment Configuration

### 1. Backend (`.env`)

Copy the configuration template `.env.example` to `.env` in the project root:

```bash
# Linux / macOS
cp .env.example .env

# Windows PowerShell
Copy-Item .env.example .env
```

Adjust the parameters in `.env` to match your local setup:

```env
# PostgreSQL Database Connection
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/joppe_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres

# JWT Security
JWT_SECRET=joppe-super-secret-jwt-key-with-minimum-256-bits-length-required-by-hmac-sha256
JWT_EXPIRATION_SECONDS=86400

# Server Port
SERVER_PORT=8080

# Domain & CORS Configuration
APP_DOMAIN=localhost:8080
APP_BASE_URL=http://localhost:8080
APP_FRONTEND_URL=http://localhost:8888
APP_CORS_ALLOWED_ORIGINS=http://localhost:8888,http://localhost:3000,http://127.0.0.1:8888,http://127.0.0.1:3000
APP_CORS_ALLOWED_ORIGIN_PATTERNS=http://localhost:*,http://127.0.0.1:*

# Initial Admin Account Auto-Provisioning
APP_ADMIN_AUTO_CREATE=true
APP_ADMIN_EMAIL=admin@joppe.vn
APP_ADMIN_PASSWORD=Admin@123456
APP_ADMIN_FULL_NAME=System Administrator

# MailHog SMTP Configuration
SPRING_MAIL_HOST=localhost
SPRING_MAIL_PORT=1025
SPRING_MAIL_SMTP_AUTH=false
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false
APP_MAIL_FROM=noreply@joppe.vn
APP_MAIL_FROM_NAME=Joppe Tech Store

# VNPay Sandbox Configuration
VNPAY_TMN_CODE=H04KMMWQ
VNPAY_HASH_SECRET=QSRCXQVXSJPTZJDSAPEKSGMMUEPBOGSA
VNPAY_PAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:8080/api/v1/payment/vnpay/return
```

---

## Backend Setup & Run

### Step 1: Create the PostgreSQL Database

Using `psql`, pgAdmin, or any database client:

```sql
CREATE DATABASE joppe_db;
```

### Step 2: Compile and Run

Navigate into `backend/` and execute via Maven:

```bash
cd backend

# Linux / macOS
./mvnw clean spring-boot:run

# Windows PowerShell / Command Prompt
.\mvnw clean spring-boot:run
```

Flyway will automatically execute migrations `V1` through `V12`:
- Core schema, user entities, roles, catalog, and variants (V1 -> V7).
- Centralized uploaded media library (V8).
- Order and payment forward-only state machine (V9).
- Parent SKU and variant SKU hierarchy refactoring (V10).
- Variant sales price synchronization (V11).
- Automatic outbound inventory goods receipts on completed orders (V12).

### Step 3: Health Verification

- **Liveness probe:**
  `http://localhost:8080/live` → Responds with JSON: `{"status":"UP","timestamp":...}`.
- **Interactive Swagger UI:**
  `http://localhost:8080/swagger-ui.html` provides a complete sandbox to explore and execute endpoints.

---

## Mail Server Setup (MailHog)

To verify password resets and order notification emails locally, start MailHog via Docker:

```bash
docker run -d -p 1025:1025 -p 8025:8025 --name mailhog mailhog/mailhog
```

- **SMTP Server:** `localhost:1025`
- **Web UI:** `http://localhost:8025` (view captured outgoing emails in real-time).

---

## Frontend Setup & Run

From the `frontend/` directory, resolve dependencies for the entire monorepo workspace:

```bash
cd frontend
flutter pub get
```

### Operations Dashboard (Joppe Dashboard)

The administrative hub for warehouse operations, POS cashier register, order processing, user accounts, and RBAC matrix.

#### Development Mode

```bash
cd frontend/apps/joppe_dashboard
flutter run -d chrome --web-port=8888 --dart-define=API_BASE_URL=http://localhost:8080
```

> **Note:** Port `8888` is pre-configured in the backend's allowed CORS origins list.

#### Production / Staging Release Build

Use the automated batch scripts in the project root:

```cmd
# Build for local development target:
build-dashboard-dev.bat

# Build for production target:
build-dashboard-prod.bat
```

Compiled assets will be placed in: `frontend/apps/joppe_dashboard/build/web/`.

### Customer Storefront (Joppe App)

Customer-facing e-commerce app with hardware catalog, interactive PC Builder, and AI Advisor.

```bash
cd frontend/apps/joppe_app

# Run in Web Browser:
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080

# Run on Windows Desktop:
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080

# Run on Mobile (Android / iOS):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

> **Android Emulator Tip:** When running in the Android Emulator, use `http://10.0.2.2:8080` instead of `localhost`.

---

## Default Accounts & Permissions

The backend provisions an initial administrator upon first launch:

| Attribute | Default Value | Notes |
|---|---|---|
| **Email** | `admin@joppe.vn` | Superuser privileges |
| **Password** | `Admin@123456` | Can be changed in User Profile |
| **Roles** | `ROLE_ADMIN`, `ROLE_CUSTOMER` | Managed via the RBAC Matrix |
| **Permissions** | `USER_MANAGE`, `ROLE_MANAGE`, `CATALOG_MANAGE`, `ORDER_MANAGE`, `INVENTORY_MANAGE` | Full system access granted to Admin |

Customers can register freely via the storefront application (`joppe_app`) or be added by administrators in the dashboard.

---

## Online Payment with VNPay Sandbox

The platform includes a native VNPay Sandbox integration with HMAC-SHA512 checksums and dynamic QR generation.

### VNPay Test Card (NCB)

- **Bank:** `NCB`
- **Card Number:** `9704198526191432198`
- **Cardholder Name:** `NGUYEN VAN A`
- **Issue Date:** `07/15`
- **OTP:** `123456`

### Order & Payment State Machine Lifecycle

```text
[Online Customer Order]
Created -> Auto ACCEPTED -> PACKAGING -> DELIVERY -> SHIPPED -> (Optional REFUND)
Payment -> Auto PAID (VNPay or approved) -> (Optional REFUND within 10-day limit)

[Showroom / Walk-In POS]
Add items to register -> Scan VNPay QR / Cash -> Auto OUTBOUND inventory deduction -> Completed
```

- **Refund Constraint:** Orders cannot be refunded once **10 days** have elapsed since payment or successful shipment.
- **Strict Progression:** Statuses advance unidirectionally; rollbacks to lower lifecycle states are rejected.

---

## API Documentation

Modular, lightweight HTML documentation files with zero CSS/JS overhead are located in `api_docs/`:

- Open [`api_docs/index.html`](api_docs/index.html) in any browser to browse all modules.
- View Markdown summary at [`api_docs/INDEX.md`](api_docs/INDEX.md).
- Access live Swagger UI when the backend is running at: `http://localhost:8080/swagger-ui.html`.

---

## Automated Testing

### 1. Backend Test Suites

```bash
cd backend

# Execute all JUnit 5 test suites:
./mvnw test

# On Windows:
.\mvnw test
```

### 2. Frontend Test Suites

```bash
# Dashboard test suite (85 tests):
cd frontend/apps/joppe_dashboard
flutter test

# Design system package test suite:
cd ../../packages/joppe_design_system
flutter test

# Customer storefront test suite:
cd ../../apps/joppe_app
flutter test
```

---

## Automated Task Management (Taskfile & Scripts)

Alongside the existing Windows `.bat` scripts used for development, the repository provides [`Taskfile.yml`](Taskfile.yml) with automated bootstrapping and wrappers:

### 1. Automatic Task CLI Installation (`bootstrap.bat`)
Run the bootstrap script to automatically download `task_windows_amd64.zip` from GitHub Releases and extract `task.exe` into `.tools/`:
```cmd
bootstrap.bat
```

### 2. Self-Healing Wrapper Scripts (`check-tool.bat`)
Each wrapper script checks for the Task CLI via `check-tool.bat`. If missing, it invokes `bootstrap.bat` and automatically self re-runs the target task:
- **`task.bat`**: Universal wrapper (supports CLI arguments or double-click interactive menu without opening cmd).
- **`task-backend-dev.bat`**: Single-click launcher for Spring Boot Backend.
- **`task-dashboard-dev.bat`**: Single-click launcher for Dashboard Web on Chrome.
- **`task-dashboard-build.bat`**: Single-click build for Dashboard Production Web.
- **`task-app-dev.bat`**: Single-click launcher for Storefront App on Chrome.
- **`task-test-all.bat`**: Single-click runner for full system test suites.

```bash
# Command line usage:
task.bat --list
task.bat backend:dev
task.bat dashboard:dev
task.bat test:all
```

# Backend
task backend:dev           # Run Spring Boot in development mode
task backend:build         # Build executable JAR (skipping tests)
task backend:test          # Execute backend JUnit 5 test suites

# Frontend Dashboard (Admin Web)
task dashboard:dev         # Run dashboard on Chrome (port 8888)
task dashboard:build:dev   # Compile web release for Dev environment
task dashboard:build:prod  # Compile web release for Production environment
task dashboard:test        # Run dashboard test suite (85 tests)

# Frontend Storefront App (Customer)
task app:dev:web           # Run storefront on Chrome (port 3000)
task app:dev:windows       # Run storefront on Windows Desktop
task app:build:apk:dev     # Build debug APK (split per ABI)
task app:build:apk:release # Build release APK (split per ABI)

# Composite Orchestration
task test:all              # Run all test suites across backend and frontend
task build:all             # Build backend JAR and production Dashboard Web
```

---

## License & Support

Developed and maintained by the Joppe engineering team. For bug reports or feature requests, please submit an issue or pull request to the Git repository.
