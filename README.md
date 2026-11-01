# Joppe Tech Store — Nền Tảng Thương Mại Điện Tử & Vận Hành Bán Lẻ

[English Documentation](README_EN.md)

Hệ thống thương mại điện tử chuyên sâu về linh kiện máy tính, xây dựng cấu hình PC (PC Builder), bán hàng tại quầy (POS Cashier), quản lý kho vận (Inbound/Outbound Goods Receipts), quản lý danh mục đa tầng và kiểm soát truy cập dựa trên vai trò (RBAC Matrix).

---

## Mục Lục

- [Tổng Quan Kiến Trúc](#tổng-quan-kiến-trúc)
- [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
- [Yêu Cầu Môi Trường](#yêu-cầu-môi-trường)
- [Cấu Hình Biến Môi Trường](#cấu-hình-biến-môi-trường)
- [Cài Đặt & Khởi Chạy Backend](#cài-đặt--khởi-chạy-backend)
- [Cài Đặt & Khởi Chạy Mail Server (MailHog)](#cài-đặt--khởi-chạy-mail-server-mailhog)
- [Cài Đặt & Khởi Chạy Frontend](#cài-đặt--khởi-chạy-frontend)
  - [Bảng Điều Khiển Quản Trị (Joppe Dashboard)](#bảng-điều-khiển-quản-trị-joppe-dashboard)
  - [Ứng Dụng Khách Hàng (Joppe App)](#ứng-dụng-khách-hàng-joppe-app)
- [Tài Khoản & Phân Quyền Mặc Định](#tài-khoản--phân-quyền-mặc-định)
- [Thanh Toán Trực Tuyến VNPay Sandbox](#thanh-toán-trực-tuyến-vnpay-sandbox)
- [Tài Liệu API](#tài-liệu-api)
- [Kiểm Thử Tự Động (Testing)](#kiểm-thử-tự-động-testing)

---

## Tổng Quan Kiến Trúc

Hệ sinh thái Joppe bao gồm 2 thành phần chính:

1. **Backend API Service:**
   - **Framework:** Spring Boot 4.1.1 (Java 21 LTS)
   - **Cơ sở dữ liệu:** PostgreSQL 15+
   - **Database Migration:** Flyway (V1 → V12)
   - **Bảo mật:** Spring Security + JWT Stateless Authentication + RBAC Method Security
   - **Thanh toán:** Cổng thanh toán VNPay Sandbox (HMAC-SHA512 checksum, IPN Webhook, Dynamic QR Code)
   - **Email:** Spring Mail (tích hợp SMTP server / MailHog)
   - **Tài liệu API:** Springdoc OpenAPI / Swagger UI và bộ tài liệu tĩnh `api_docs/`

2. **Frontend Monorepo (Flutter Workspace):**
   - **`joppe_dashboard`:** Ứng dụng Web quản trị vận hành trung tâm (Material 3, Dark/Light Mode, Collapsible Sidebar, POS Cashier, Export CSV, Quản lý kho & sản phẩm).
   - **`joppe_app`:** Ứng dụng mua sắm khách hàng (Cyberpunk-styled Storefront, PC Builder, Trợ lý AI Advisor, Giỏ hàng, Đặt hàng & Tra cứu).
   - **`joppe_core`:** Thư viện chia sẻ models, API client, HTTP interceptor và các domain services.
   - **`joppe_design_system`:** Thư viện giao diện Material 3, bảng màu JoppeTheme, layout responsive adaptive breakpoint.

---

## Cấu Trúc Dự Án

```text
joppe/
├── backend/                               # Spring Boot Application (Java 21)
│   ├── pom.xml                            # Maven dependencies & build config
│   └── src/
│       ├── main/
│       │   ├── java/joppe/backend/
│       │   │   ├── admin/                 # Quản trị sản phẩm, danh mục, kho, users, analytics
│       │   │   ├── auth/                  # JWT security, user registration & login
│       │   │   ├── common/                # Health check (/live), CSV export helpers
│       │   │   ├── domain/                # Cart, Catalog, Inventory, Order, User, VNPay
│       │   │   └── media/                 # Upload ảnh và quản lý media tập trung
│       │   └── resources/
│       │       ├── application.properties # Cấu hình Spring Boot mặc định
│       │       └── db/migration/          # 12 file Flyway SQL migrations (V1 -> V12)
│       └── test/                          # Unit & integration tests
├── frontend/                              # Flutter Workspace
│   ├── pubspec.yaml                       # Workspace root pubspec
│   ├── apps/
│   │   ├── joppe_dashboard/               # Web Operations Dashboard
│   │   └── joppe_app/                     # Customer Storefront App
│   └── packages/
│       ├── joppe_core/                    # Shared API Client, Services, Models
│       └── joppe_design_system/           # Shared Theme, Components, Scaffolds
├── api_docs/                              # Bộ tài liệu API tĩnh định dạng semantic HTML
│   ├── index.html                         # Trang chủ điều hướng tài liệu API
│   └── INDEX.md                           # Mục lục chi tiết các module API
├── .env.example                           # Mẫu cấu hình biến môi trường Backend
├── build-dashboard-dev.bat                # Script build Dashboard Web cho môi trường Dev
└── build-dashboard-prod.bat               # Script build Dashboard Web cho môi trường Prod
```

---

## Yêu Cầu Môi Trường

Trước khi cài đặt, hãy đảm bảo máy tính đã cài đặt các công cụ sau:

- **Java Development Kit (JDK):** Phiên bản **21 LTS** trở lên.
- **Apache Maven:** Phiên bản **3.9+** (hoặc sử dụng `./mvnw` đính kèm).
- **PostgreSQL Server:** Phiên bản **15+** (đang chạy cổng 5432).
- **Flutter SDK:** Phiên bản **3.19+** (kênh stable) với Dart SDK **3.13+**.
- **Google Chrome / Edge:** Dùng để chạy hoặc kiểm thử Flutter Web.
- **MailHog / Local SMTP Server (tùy chọn):** Dùng để bắt email xác thực khi chạy local.

---

## Cấu Hình Biến Môi Trường

### 1. Backend (`.env`)

Tạo file `.env` tại thư mục gốc của dự án bằng cách sao chép từ file mẫu `.env.example`:

```bash
# Trên Linux / macOS
cp .env.example .env

# Trên Windows PowerShell
Copy-Item .env.example .env
```

Điều chỉnh các tham số trong `.env` phù hợp với máy của bạn:

```env
# Kết nối PostgreSQL
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/joppe_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres

# Bảo mật JWT
JWT_SECRET=joppe-super-secret-jwt-key-with-minimum-256-bits-length-required-by-hmac-sha256
JWT_EXPIRATION_SECONDS=86400

# Cổng Backend
SERVER_PORT=8080

# Cấu hình Domain & CORS
APP_DOMAIN=localhost:8080
APP_BASE_URL=http://localhost:8080
APP_FRONTEND_URL=http://localhost:8888
APP_CORS_ALLOWED_ORIGINS=http://localhost:8888,http://localhost:3000,http://127.0.0.1:8888,http://127.0.0.1:3000
APP_CORS_ALLOWED_ORIGIN_PATTERNS=http://localhost:*,http://127.0.0.1:*

# Tự động tạo tài khoản quản trị hệ thống
APP_ADMIN_AUTO_CREATE=true
APP_ADMIN_EMAIL=admin@joppe.vn
APP_ADMIN_PASSWORD=Admin@123456
APP_ADMIN_FULL_NAME=System Administrator

# Cấu hình MailHog (SMTP Local)
SPRING_MAIL_HOST=localhost
SPRING_MAIL_PORT=1025
SPRING_MAIL_SMTP_AUTH=false
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false
APP_MAIL_FROM=noreply@joppe.vn
APP_MAIL_FROM_NAME=Joppe Tech Store

# Cấu hình VNPay Sandbox
VNPAY_TMN_CODE=H04KMMWQ
VNPAY_HASH_SECRET=QSRCXQVXSJPTZJDSAPEKSGMMUEPBOGSA
VNPAY_PAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:8080/api/v1/payment/vnpay/return
```

---

## Cài Đặt & Khởi Chạy Backend

### Bước 1: Tạo cơ sở dữ liệu PostgreSQL

Mở PostgreSQL client (psql, DBeaver, hoặc pgAdmin) và tạo database:

```sql
CREATE DATABASE joppe_db;
```

### Bước 2: Biên dịch và chạy ứng dụng

Di chuyển vào thư mục `backend/` và khởi chạy với Maven:

```bash
cd backend

# Linux / macOS
./mvnw clean spring-boot:run

# Windows PowerShell / CMD
.\mvnw clean spring-boot:run
```

Flyway sẽ tự động chạy các script migration từ `V1` đến `V12`:
- Khởi tạo bảng người dùng, vai trò, sản phẩm, biến thể (V1 -> V7).
- Khởi tạo kho lưu trữ media tập trung (V8).
- Cập nhật luồng trạng thái đơn hàng & thanh toán (V9).
- Tái cấu trúc phân cấp SKU cha - SKU biến thể (V10).
- Tính toán đồng bộ giá bán biến thể (V11).
- Tích hợp phiếu xuất kho tự động cho đơn hàng hoàn tất (V12).

### Bước 3: Xác minh trạng thái hoạt động

- **Kiểm tra liveness:**
  Truy cập `http://localhost:8080/live` → Phản hồi JSON: `{"status":"UP","timestamp":...}`.
- **Swagger UI:**
  Truy cập `http://localhost:8080/swagger-ui.html` để kiểm tra danh sách API trực quan.

---

## Cài Đặt & Khởi Chạy Mail Server (MailHog)

Để kiểm tra các tính năng gửi email (quên mật khẩu, thông báo đơn hàng), bạn có thể chạy MailHog qua Docker:

```bash
docker run -d -p 1025:1025 -p 8025:8025 --name mailhog mailhog/mailhog
```

- **SMTP Server:** `localhost:1025`
- **Web UI:** `http://localhost:8025` (mở trình duyệt để xem toàn bộ email được gửi ra).

---

## Cài Đặt & Khởi Chạy Frontend

Di chuyển vào thư mục `frontend/` và tải về toàn bộ dependencies cho toàn bộ workspace:

```bash
cd frontend
flutter pub get
```

### Bảng Điều Khiển Quản Trị (Joppe Dashboard)

Bảng điều khiển dành cho Admin/Nhân viên quản lý kho, POS thu ngân, đơn hàng, người dùng và phân quyền RBAC.

#### Chạy chế độ phát triển (Development Mode)

```bash
cd frontend/apps/joppe_dashboard
flutter run -d chrome --web-port=8888 --dart-define=API_BASE_URL=http://localhost:8080
```

> **Lưu ý:** Chạy tại cổng `8888` để khớp với cấu hình CORS của backend.

#### Biên dịch bản phát hành (Production / Staging Build)

Sử dụng các file batch script tự động tại thư mục gốc:

```cmd
# Build cho môi trường Local Dev:
build-dashboard-dev.bat

# Build cho môi trường Production:
build-dashboard-prod.bat
```

Các file web được đóng gói tại: `frontend/apps/joppe_dashboard/build/web/`.

### Ứng Dụng Khách Hàng (Joppe App)

Ứng dụng mua sắm linh kiện máy tính, PC Builder và tư vấn AI.

```bash
cd frontend/apps/joppe_app

# Chạy trên trình duyệt Web:
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080

# Chạy trên Windows Desktop:
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080

# Chạy trên thiết bị di động (Android / iOS):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

> **Mẹo Android Emulator:** Khi chạy trên Android Emulator, trỏ `API_BASE_URL` về `http://10.0.2.2:8080` thay cho `localhost`.

---

## Tài Khoản & Phân Quyền Mặc Định

Hệ thống tự động kích hoạt tài khoản Quản Trị Viên khi khởi động lần đầu:

| Thông Tin | Giá Trị Mặc Định | Ghi Chú |
|---|---|---|
| **Email** | `admin@joppe.vn` | Quyền `ROLE_ADMIN` cao nhất |
| **Mật khẩu** | `Admin@123456` | Có thể đổi sau khi đăng nhập |
| **Vai trò (Roles)** | `ROLE_ADMIN`, `ROLE_CUSTOMER` | Quản trị tại `Ma trận RBAC` |
| **Quyền hạn (Permissions)** | `USER_MANAGE`, `ROLE_MANAGE`, `CATALOG_MANAGE`, `ORDER_MANAGE`, `INVENTORY_MANAGE` | Được cấp đầy đủ cho Quản Trị Viên |

Khách hàng mới có thể tự đăng ký qua giao diện ứng dụng `joppe_app` hoặc tạo trực tiếp bởi Admin trong Dashboard.

---

## Thanh Toán Trực Tuyến VNPay Sandbox

Dự án đã tích hợp sẵn cổng thanh toán VNPay Sandbox với mã hash SHA512 và tự động tạo mã QR.

### Thông tin thẻ kiểm thử VNPay (NCB)

- **Ngân hàng:** `NCB`
- **Số thẻ:** `9704198526191432198`
- **Tên chủ thẻ:** `NGUYEN VAN A`
- **Ngày phát hành:** `07/15`
- **Mã OTP xác thực:** `123456`

### Quy trình nghiệp vụ đơn hàng & thanh toán

```text
[Đơn Hàng Trực Tuyến]
Tạo đơn -> Tự động ACCEPTED -> PACKAGING -> DELIVERY -> SHIPPED -> (Tùy chọn REFUND)
Thanh toán -> Tự động PAID (VNPay hoặc đã duyệt) -> (Tùy chọn REFUND nếu trong vòng 10 ngày)

[Bán Hàng Tại Quầy - POS]
Nhân viên chọn hàng -> Quét QR VNPay / Tiền mặt -> Tự động xuất kho OUTBOUND -> Hoàn tất
```

- **Điều kiện hoàn tiền:** Đơn hàng chỉ được phép hoàn tiền nếu trong vòng **10 ngày** kể từ ngày thanh toán hoặc ngày nhận hàng thành công.
- **Tiến trình trạng thái:** Trạng thái chỉ đi theo chiều tiến, không cho phép quay ngược về trạng thái cũ hơn.

---

## Tài Liệu API

Toàn bộ tài liệu chi tiết của từng endpoint được lưu trữ dưới dạng HTML độc lập, nhẹ và dễ tra cứu tại thư mục `api_docs/`:

- Mở file [`api_docs/index.html`](api_docs/index.html) bằng bất kỳ trình duyệt nào để tra cứu danh mục toàn bộ API.
- Xem tóm tắt bằng Markdown tại [`api_docs/INDEX.md`](api_docs/INDEX.md).
- Truy cập Swagger UI trực tiếp khi backend đang chạy tại: `http://localhost:8080/swagger-ui.html`.

---

## Kiểm Thử Tự Động (Testing)

### 1. Kiểm thử Backend

```bash
cd backend

# Chạy toàn bộ test suites (Admin, Cart, Orders, Inventory, VNPay, Media):
./mvnw test

# Trên Windows:
.\mvnw test
```

### 2. Kiểm thử Frontend

```bash
# Kiểm thử Bảng điều khiển Quản trị (85 tests):
cd frontend/apps/joppe_dashboard
flutter test

# Kiểm thử Thư viện Design System:
cd ../../packages/joppe_design_system
flutter test

# Kiểm thử Ứng dụng Khách Hàng:
cd ../../apps/joppe_app
flutter test
```

---

## Quản Lý Tác Vụ Tự Động (Taskfile & Scripts)

Bên cạnh các script batch (`.bat`) hiện hành dùng trong môi trường Windows, dự án cung cấp [`Taskfile.yml`](Taskfile.yml) cùng bộ công cụ tự động hóa:

### 1. Cài đặt tự động Task CLI (`bootstrap.bat`)
Chạy script để tự động tải phiên bản mới nhất của Task CLI (`task_windows_amd64.zip`) từ GitHub Releases và giải nén vào thư mục `.tools/`:
```cmd
bootstrap.bat
```

### 2. Bộ Wrapper tự kiểm tra công cụ (`check-tool.bat`)
Mỗi wrapper script đều tự động gọi `check-tool.bat`. Nếu máy chưa có Task CLI, script sẽ tự động gọi `bootstrap.bat` để cài đặt rồi tự chạy lại tác vụ ban đầu:
- **`task.bat`**: Wrapper đa năng (chạy `task.bat <tên-task>` hoặc nhấp đúp chuột để mở menu tương tác không cần mở cmd).
- **`task-backend-dev.bat`**: Khởi chạy nhanh Spring Boot Backend.
- **`task-dashboard-dev.bat`**: Khởi chạy nhanh Dashboard Web trên Chrome.
- **`task-dashboard-build.bat`**: Biên dịch bản phát hành Production cho Dashboard.
- **`task-app-dev.bat`**: Khởi chạy nhanh Storefront App trên Chrome.
- **`task-test-all.bat`**: Chạy toàn bộ test suites của cả Backend và Frontend.

```bash
# Sử dụng trực tiếp từ dòng lệnh:
task.bat --list
task.bat backend:dev
task.bat dashboard:dev
task.bat test:all
```

# Backend
task backend:dev           # Khởi chạy Spring Boot ở chế độ dev
task backend:build         # Biên dịch file JAR (bỏ qua tests)
task backend:test          # Chạy toàn bộ JUnit 5 test suites

# Frontend Dashboard (Admin Web)
task dashboard:dev         # Chạy dashboard web trên Chrome (cổng 8888)
task dashboard:build:dev   # Build web release cho môi trường Dev
task dashboard:build:prod  # Build web release cho môi trường Production
task dashboard:test        # Chạy test suite dashboard (85 tests)

# Frontend Storefront App (Khách hàng)
task app:dev:web           # Chạy storefront trên Chrome (cổng 3000)
task app:dev:windows       # Chạy storefront trên Windows Desktop
task app:build:apk:dev     # Build APK debug (split per ABI)
task app:build:apk:release # Build APK release (split per ABI)

# Tác vụ tổng hợp
task test:all              # Chạy toàn bộ test suites cả backend lẫn frontend
task build:all             # Biên dịch JAR backend và Dashboard Web production
```

---

## Giấy Phép & Đóng Góp

Dự án được xây dựng và duy trì bởi đội ngũ phát triển Joppe. Mọi đóng góp, báo cáo lỗi hoặc yêu cầu tính năng vui lòng tạo Issue hoặc Pull Request trên hệ thống Git repository.
