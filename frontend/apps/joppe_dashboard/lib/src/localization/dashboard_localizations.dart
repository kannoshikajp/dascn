import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DashboardLocalizations {
  final Locale locale;

  const DashboardLocalizations(this.locale);

  static DashboardLocalizations of(BuildContext context) {
    return Localizations.of<DashboardLocalizations>(context, DashboardLocalizations) ??
        DashboardLocalizations(Localizations.maybeLocaleOf(context) ?? const Locale('vi'));
  }

  static const LocalizationsDelegate<DashboardLocalizations> delegate =
      _DashboardLocalizationsDelegate();

  bool get isVi => locale.languageCode == 'vi';

  // Shell & Navigation
  String get appTitle => isVi ? 'Quản trị Joppe' : 'Joppe Admin';
  String get controlCenter => isVi ? 'Trung tâm điều khiển Joppe' : 'Joppe Control Center';
  String get mainGroup => isVi ? 'Chính' : 'Main';
  String get commerceGroup => isVi ? 'Thương mại' : 'Commerce';
  String get catalogGroup => isVi ? 'Danh mục' : 'Catalog';
  String get inventoryGroup => isVi ? 'Kho & Cung ứng' : 'Inventory & Supply';
  String get accessControlGroup => isVi ? 'Kiểm soát truy cập' : 'Access Control';

  // Section Groups (Sidebar Navigation)
  String get groupSales => isVi ? 'QUẢN LÝ BÁN HÀNG' : 'SALES MANAGEMENT';
  String get groupGoodsAndWarehouse => isVi ? 'HÀNG HÓA & KHO' : 'GOODS & WAREHOUSE';
  String get groupPartners => isVi ? 'ĐỐI TÁC' : 'PARTNERS';
  String get groupSystemConfig => isVi ? 'CẤU HÌNH HỆ THỐNG' : 'SYSTEM CONFIGURATION';

  String get navOverview => isVi ? 'Tổng quan' : 'Overview';
  String get navOrders => isVi ? 'Đơn hàng' : 'Orders';
  String get navPosCashier => isVi ? 'Bán hàng (POS)' : 'POS Cashier';
  String get navProducts => isVi ? 'Sản phẩm' : 'Products';
  String get navCategories => isVi ? 'Danh mục' : 'Categories';
  String get navWarehouse => isVi ? 'Tồn kho' : 'Warehouse';
  String get navWarehouseStock => navWarehouse;
  String get navGoodsReceipts => isVi ? 'Phiếu nhập kho' : 'Goods Receipts';
  String get navSuppliers => isVi ? 'Nhà cung cấp' : 'Suppliers';
  String get navUsers => isVi ? 'Người dùng' : 'Users';
  String get navRbacMatrix => isVi ? 'Phân quyền RBAC' : 'RBAC Matrix';
  String get navSettings => isVi ? 'Cài đặt' : 'Settings';
  String get navAiAssistant => isVi ? 'Trợ lý AI' : 'AI Assistant';
  String get aiAssistantTitle => isVi ? 'Trợ lý AI Vận hành Joppe' : 'Joppe AI Operations Advisor';
  String get aiAssistantSubtitle => isVi
      ? 'Tra cứu linh kiện, kiểm tra hàng tồn và phân tích dữ liệu sàn qua 9Router'
      : 'Query hardware products, audit stock levels, and analyze business performance via 9Router';
  String get aiWelcomePrompt => isVi
      ? 'Xin chào! Tôi là trợ lý AI vận hành Joppe. Bạn cần tra cứu sản phẩm, kiểm kho hay xem thống kê kinh doanh?'
      : 'Hello! I am your Joppe AI operations advisor. How can I help you with catalog search, stock audits, or sales metrics today?';
  String get aiInputHint => isVi
      ? 'Đặt câu hỏi cho AI (ví dụ: Tìm CPU dưới 7 triệu, kiểm tra hàng sắp hết...)'
      : 'Ask AI a question (e.g., Find CPUs under 7M VND, check low stock...)...';
  String get aiToolsExecuted => isVi ? 'Công cụ đã gọi' : 'Tools Executed';
  String get aiReferencedProducts => isVi ? 'Linh kiện liên quan' : 'Referenced Hardware';
  String get aiQuickPrompt1 => isVi ? 'Kiểm tra linh kiện sắp hết hàng' : 'Check low stock components';
  String get aiQuickPrompt2 => isVi ? 'Thống kê doanh thu & đơn hàng' : 'Sales & order performance';
  String get aiQuickPrompt3 => isVi ? 'Tìm card đồ họa RTX 4070' : 'Find RTX 4070 graphics cards';
  String get settingsSubtitle => isVi
      ? 'Tùy chỉnh ngôn ngữ và chế độ giao diện hệ thống'
      : 'Customize system language and color theme';
  String get languageSettingTitle => isVi ? 'Ngôn ngữ hiển thị' : 'Display Language';
  String get languageSettingDesc => isVi
      ? 'Chọn ngôn ngữ giao diện cho toàn bộ bảng điều khiển'
      : 'Choose interface language for the entire dashboard';
  String get themeSettingTitle => isVi ? 'Chế độ giao diện (Màu sắc)' : 'Color Mode (Theme)';
  String get themeSettingDesc => isVi
      ? 'Tùy chọn giao diện sáng, tối hoặc đồng bộ theo hệ điều hành'
      : 'Choose light, dark, or system appearance';

  // Common Actions & Dialogs
  String get accountProfile => isVi ? 'Hồ sơ tài khoản' : 'Account Profile';
  String get signOut => isVi ? 'Đăng xuất' : 'Sign Out';
  String get signOutConfirmMessage => isVi
      ? 'Bạn có chắc chắn muốn đăng xuất khỏi Joppe Dashboard?'
      : 'Are you sure you want to sign out of Joppe Dashboard?';
  String get cancel => isVi ? 'Hủy' : 'Cancel';
  String get save => isVi ? 'Lưu' : 'Save';
  String get saveChanges => isVi ? 'Lưu thay đổi' : 'Save Changes';
  String get delete => isVi ? 'Xóa' : 'Delete';
  String get edit => isVi ? 'Chỉnh sửa' : 'Edit';
  String get close => isVi ? 'Đóng' : 'Close';
  String get notificationTitle => isVi ? 'Thông báo' : 'Notification';
  String get successTitle => isVi ? 'Thành công' : 'Success';
  String get errorTitle => isVi ? 'Thông báo lỗi' : 'Error';
  String get retry => isVi ? 'Thử lại' : 'Retry';
  String get retryConnection => isVi ? 'Thử lại kết nối' : 'Retry Connection';
  String get exportCsv => isVi ? 'Xuất CSV' : 'Export CSV';
  String get exportCsvSuccess => isVi ? 'Xuất file CSV thành công' : 'CSV exported successfully';
  String get exportCsvFailed => isVi ? 'Xuất file CSV thất bại' : 'Failed to export CSV';
  String get search => isVi ? 'Tìm kiếm...' : 'Search...';
  String get language => isVi ? 'Ngôn ngữ' : 'Language';
  String get vietnamese => 'Tiếng Việt';
  String get english => 'English';
  String get systemUser => isVi ? 'Người dùng hệ thống' : 'System User';
  String get themeMode => isVi ? 'Giao diện' : 'Theme';
  String get themeLight => isVi ? 'Sáng' : 'Light';
  String get themeDark => isVi ? 'Tối' : 'Dark';
  String get themeSystem => isVi ? 'Hệ thống' : 'System';
  String get collapseSidebar => isVi ? 'Thu gọn' : 'Collapse';
  String get expandSidebar => isVi ? 'Mở rộng' : 'Expand';

  // Login
  String get loginSubtitle => isVi
      ? 'Đăng nhập để quản lý hệ thống, người dùng & phân quyền'
      : 'Sign in to manage backend, users & RBAC';
  String get emailAddress => isVi ? 'Địa chỉ Email' : 'Email Address';
  String get password => isVi ? 'Mật khẩu' : 'Password';
  String get signIn => isVi ? 'Đăng nhập' : 'Sign In';
  String get validEmailRequired => isVi ? 'Nhập email hợp lệ' : 'Enter a valid email';
  String get passwordRequired => isVi ? 'Vui lòng nhập mật khẩu' : 'Password is required';

  // Liveness / Server Offline
  String get verifyingBackendHealth => isVi
      ? 'Đang kiểm tra kết nối máy chủ trên /live...'
      : 'Verifying backend health on /live...';
  String get serverUnavailable => isVi ? 'Máy chủ không khả dụng' : 'Server Unavailable';
  String get backendNotReachable => isVi
      ? 'Dịch vụ backend chưa sẵn sàng hoặc không thể kết nối.'
      : 'Backend service is not live or cannot be reached.';
  String get serverLockedWarning => isVi
      ? 'Màn hình này bị khóa cho đến khi kết nối /live thành công.'
      : 'This screen is locked and cannot be dismissed until /live is reachable.';

  // Overview View
  String get overviewTitle => isVi ? 'Trung tâm vận hành Joppe Admin' : 'Joppe Admin Operations Center';
  String get overviewSubtitle => isVi
      ? 'Quản trị cửa hàng phần cứng, kiểm soát kho và xử lý đơn hàng'
      : 'Hardware store administration, inventory control, and order fulfillment';
  String get refreshStats => isVi ? 'Làm mới thống kê' : 'Refresh Stats';
  String get totalProducts => isVi ? 'Tổng sản phẩm' : 'Total Products';
  String activeCatalogItems(int count) => isVi ? '$count mặt hàng đang hoạt động' : '$count active catalog items';
  String get activeCategories => isVi ? 'Danh mục hoạt động' : 'Active Categories';
  String activeTreeNodes(int count) => isVi ? '$count danh mục đang mở' : '$count active tree nodes';
  String get systemUsers => isVi ? 'Người dùng hệ thống' : 'System Users';
  String activeAccounts(int count) => isVi ? '$count tài khoản đang hoạt động' : '$count active accounts';
  String get rbacOverview => isVi ? 'Ma trận RBAC' : 'Roles & Matrix';
  String rbacSummary(int roles, int perms) => isVi ? '$roles vai trò, $perms quyền' : '$roles roles, $perms permissions';
  String get totalOrders => isVi ? 'Tổng đơn hàng' : 'Total Orders';
  String pendingOrdersCount(int count) => isVi ? '$count đơn chờ xử lý' : '$count orders pending';
  String get inventoryAlerts => isVi ? 'Cảnh báo kho' : 'Inventory Alerts';
  String outOfStockCount(int count) => isVi ? '$count mặt hàng hết hàng' : '$count items out of stock';
  String get lowStockWarning => isVi ? 'Cảnh báo sắp hết hàng & Hết hàng' : 'Low Stock & Out of Stock Warnings';
  String get lowStockSubtitle => isVi
      ? 'Các sản phẩm dưới 10 đơn vị tồn kho cần nhập thêm'
      : 'Products with <= 10 units remaining in warehouse';
  String get productNameCol => isVi ? 'Tên sản phẩm' : 'Product Name';
  String get brandCol => isVi ? 'Thương hiệu' : 'Brand';
  String get priceRangeCol => isVi ? 'Khoảng giá' : 'Price Range';
  String get remainingStockCol => isVi ? 'Tồn kho còn lại' : 'Remaining Stock';
  String get statusCol => isVi ? 'Trạng thái' : 'Status';
  String get outOfStockBadge => isVi ? 'HẾT HÀNG' : 'OUT OF STOCK';
  String unitsRemaining(int count) => isVi ? '$count cái còn lại' : '$count left';
  String get stockHealthyMessage => isVi
      ? 'Tất cả mức tồn kho đang ở trạng thái tốt. Không có cảnh báo tồn kho thấp!'
      : 'All inventory stock levels are healthy. No low stock warnings!';
  String couldNotLoadStats(String err) => isVi ? 'Không thể tải thống kê: $err' : 'Could not load statistics: $err';

  // Products View
  String get productsManagement => isVi ? 'Quản lý Sản phẩm' : 'Product Management';
  String get refreshProducts => isVi ? 'Làm mới sản phẩm' : 'Refresh products';
  String get addProduct => isVi ? 'Thêm sản phẩm' : 'Add Product';
  String get addNewProductTitle => isVi ? 'Thêm sản phẩm mới' : 'Add New Product';
  String editProductTitle(String name) => isVi ? 'Chỉnh sửa "$name"' : 'Edit "$name"';
  String get searchProducts => isVi ? 'Tìm kiếm sản phẩm...' : 'Search products...';
  String get searchProductHint => isVi ? 'Tìm theo tên sản phẩm, SKU...' : 'Search by product name, SKU...';
  String get stock => isVi ? 'Tồn kho' : 'Stock';
  String stockCount(int count) => isVi ? 'Tồn kho: $count' : 'Stock: $count';
  String get brand => isVi ? 'Thương hiệu' : 'Brand';
  String get warranty => isVi ? 'Bảo hành' : 'Warranty';
  String get noProductsFound => isVi ? 'Không tìm thấy sản phẩm' : 'No products found';
  String get addVariant => isVi ? 'Thêm biến thể' : 'Add Variant';
  String get editProduct => isVi ? 'Chỉnh sửa sản phẩm' : 'Edit Product';
  String get deleteProduct => isVi ? 'Xóa sản phẩm' : 'Delete Product';
  String get deleteProductConfirm => isVi
      ? 'Bạn có chắc chắn muốn xóa sản phẩm này?'
      : 'Are you sure you want to delete this product?';
  String deleteProductConfirmMsg(String name) => isVi
      ? 'Bạn có chắc chắn muốn xóa "$name"? Thao tác này không thể hoàn tác.'
      : 'Are you sure you want to delete "$name"? This cannot be undone.';
  String get productCreatedSuccess => isVi ? 'Tạo sản phẩm thành công' : 'Product created successfully';
  String get productUpdatedSuccess => isVi ? 'Cập nhật sản phẩm thành công' : 'Product updated successfully';
  String get productDeletedSuccess => isVi ? 'Đã xóa sản phẩm' : 'Product deleted';
  String get productCoreInfo => isVi ? 'Thông tin sản phẩm' : 'Product Information';
  String get productNameLabel => isVi ? 'Tên sản phẩm *' : 'Product Name *';
  String get productNameRequired => isVi ? 'Vui lòng nhập tên sản phẩm' : 'Product name is required';
  String get skuLabel => isVi ? 'Mã SKU *' : 'SKU *';
  String get skuRequired => isVi ? 'Vui lòng nhập SKU' : 'SKU is required';
  String get isVariantOfLabel => isVi ? 'Thuộc nhóm biến thể của (isVariantOf)' : 'Variant of (isVariantOf)';
  String get isVariantOfHelper => isVi
      ? 'Để trống nếu là sản phẩm gốc / độc lập. Chọn nếu đây là biến thể của một sản phẩm khác.'
      : 'Leave empty if parent product. Select if this is a variant of another product.';
  String get standaloneProductOption => isVi ? 'Không (Là sản phẩm gốc / độc lập)' : 'None (Standalone / Parent Product)';
  String get baseUrlSlugLabel => isVi ? 'Đường dẫn URL Slug' : 'Base URL Slug';
  String get baseUrlSlugLockedLabel => isVi ? 'Đường dẫn URL Slug (Khóa - Không thể sửa)' : 'Base URL Slug (Locked)';
  String get slugLockedHelper => isVi
      ? 'Đường dẫn slug cố định để đảm bảo liên kết và hệ thống không bị lỗi'
      : 'Fixed slug path to preserve persistent routing and links';
  String get slugAutoHelper => isVi
      ? 'Để trống sẽ tự động lấy từ SKU (thay khoảng trắng bằng -)'
      : 'Auto-generated from SKU if empty (spaces replaced with -)';
  String get categoriesLabel => isVi ? 'Danh mục' : 'Categories';
  String get noCategoriesAvailable => isVi ? 'Chưa có danh mục nào.' : 'No categories available.';
  String get primaryBadge => isVi ? 'Chính' : 'Primary';
  String get makePrimaryBtn => isVi ? 'Đặt làm chính' : 'Make Primary';
  String get priceAndInventorySection => isVi ? 'Giá & Tồn kho' : 'Price & Inventory';
  String get listPriceLabel => isVi ? 'Giá niêm yết (VND)' : 'List Price (VND)';
  String get salePriceLabel => isVi ? 'Giá bán / Khuyến mãi (VND)' : 'Sale Price (VND)';
  String get stockQuantityLabel => isVi ? 'Số lượng tồn kho' : 'Stock Quantity';
  String get initialStockLabel => isVi ? 'Tồn kho ban đầu' : 'Initial Stock';
  String get thumbnailOptionalLabel => isVi ? 'Đường dẫn ảnh thu nhỏ (tùy chọn)' : 'Thumbnail URL (optional)';
  String get markdownDescOptionalLabel => isVi ? 'Mô tả chi tiết Markdown (tùy chọn)' : 'Markdown Description (optional)';
  String get productActiveSwitch => isVi ? 'Kích hoạt kinh doanh' : 'Product Active';
  String get createProductSubmit => isVi ? 'Tạo sản phẩm' : 'Create Product';
  String variantOfBadge(String parentSku) => isVi ? 'Biến thể của: $parentSku' : 'Variant of: $parentSku';
  String parentVariantBadge(int count) => isVi ? 'Gốc ($count biến thể)' : 'Parent ($count variants)';

  // Product Filters
  String get priceRangeFilterLabel => isVi ? 'Khoảng giá: ' : 'Price Range: ';
  String get allPricesOption => isVi ? 'Tất cả giá' : 'All Prices';
  String get under5mOption => isVi ? '< 5 Triệu' : '< 5M';
  String get from5mTo15mOption => isVi ? '5 - 15 Triệu' : '5M - 15M';
  String get from15mTo30mOption => isVi ? '15 - 30 Triệu' : '15M - 30M';
  String get over30mOption => isVi ? '> 30 Triệu' : '> 30M';
  String get categoryFilterLabel => isVi ? 'Danh mục: ' : 'Categories: ';
  String get allCategoriesOption => isVi ? 'Tất cả' : 'All';
  String get statusFilterLabel => isVi ? 'Trạng thái: ' : 'Status: ';
  String get allStatusOption => isVi ? 'Tất cả' : 'All';
  String get activeOnlyOption => isVi ? 'Đang bán' : 'Active';
  String get inactiveOnlyOption => isVi ? 'Ngừng bán' : 'Inactive';

  // Categories View
  String get addCategory => isVi ? 'Thêm danh mục' : 'Add Category';
  String get addNewCategoryTitle => isVi ? 'Thêm danh mục mới' : 'Add New Category';
  String get editCategoryTitle => isVi ? 'Chỉnh sửa danh mục' : 'Edit Category';
  String get treeView => isVi ? 'Dạng cây' : 'Tree';
  String get flatView => isVi ? 'Dạng bảng' : 'List';
  String get searchCategories => isVi ? 'Tìm kiếm danh mục...' : 'Search categories...';
  String get searchCategoriesHint => isVi ? 'Tìm tên danh mục, slug...' : 'Search category name, slug...';
  String get categoryName => isVi ? 'Tên danh mục' : 'Category Name';
  String get categoryNameHint => isVi ? 'Ví dụ: Laptop, Chuột Gaming, Bàn phím' : 'e.g. Laptop, Gaming Mouse, Keyboard';
  String get categoryNameRequired => isVi ? 'Vui lòng nhập tên danh mục' : 'Name is required';
  String get urlSlug => isVi ? 'URL Slug' : 'URL Slug';
  String get urlSlugHint => isVi ? 'Ví dụ: laptop-gaming' : 'e.g. laptop-gaming';
  String get urlSlugHelper => isVi
      ? 'Đường dẫn tĩnh SEO, tự động tạo từ tên nếu để trống'
      : 'SEO slug path, auto-generated from name if left empty';
  String get parentCategory => isVi ? 'Danh mục cha' : 'Parent Category';
  String get rootCategoryOption => isVi ? '[Cấp cao nhất - Không có danh mục cha]' : '[Root Level - No Parent]';
  String get iconOrImageUrl => isVi ? 'Biểu tượng / Đường dẫn ảnh (tùy chọn)' : 'Icon / Image URL (optional)';
  String get categoryActive => isVi ? 'Kích hoạt danh mục' : 'Category Active';
  String get categoryActiveDescription => isVi
      ? 'Hiển thị trên danh mục bán hàng và bộ lọc'
      : 'Visible on storefront and navigation filters';
  String get deleteCategoryTitle => isVi ? 'Xóa danh mục' : 'Delete Category';
  String deleteCategoryConfirmMessage(String name) => isVi
      ? 'Bạn có chắc chắn muốn xóa danh mục "$name"? Tất cả liên kết sản phẩm có thể bị ảnh hưởng.'
      : 'Are you sure you want to delete category "$name"?';
  String get categoryCreatedSuccess => isVi ? 'Đã tạo danh mục thành công' : 'Category created successfully';
  String get categoryUpdatedSuccess => isVi ? 'Đã cập nhật danh mục thành công' : 'Category updated successfully';
  String get categoryDeletedSuccess => isVi ? 'Đã xóa danh mục' : 'Category deleted';
  String get categoryStatusUpdated => isVi ? 'Đã cập nhật trạng thái danh mục' : 'Category status updated';
  String get cannotDeleteCategory => isVi ? 'Không thể xóa danh mục' : 'Cannot delete category';
  String get totalCategoriesKpi => isVi ? 'Tổng danh mục' : 'Total Categories';
  String get rootCategoriesKpi => isVi ? 'Danh mục gốc' : 'Root Categories';
  String get subcategoriesKpi => isVi ? 'Danh mục con' : 'Subcategories';
  String get activeCategoriesKpi => isVi ? 'Đang hoạt động' : 'Active';
  String get linkedProductsKpi => isVi ? 'Sản phẩm liên kết' : 'Linked Products';
  String get levelFilterLabel => isVi ? 'Cấp bậc: ' : 'Hierarchy: ';
  String get allHierarchyOption => isVi ? 'Tất cả cấp' : 'All Levels';
  String get rootHierarchyOption => isVi ? 'Cấp gốc' : 'Root Only';
  String get subHierarchyOption => isVi ? 'Cấp con' : 'Subcategories Only';
  String get expandAll => isVi ? 'Mở rộng tất cả' : 'Expand All';
  String get collapseAll => isVi ? 'Thu gọn tất cả' : 'Collapse All';
  String get addSubcategoryTooltip => isVi ? 'Thêm mục con' : 'Add Subcategory';
  String get editCategoryTooltip => isVi ? 'Chỉnh sửa' : 'Edit Category';
  String get deleteCategoryTooltip => isVi ? 'Xóa' : 'Delete Category';
  String get noCategoriesFound => isVi ? 'Không tìm thấy danh mục nào phù hợp' : 'No categories found.';
  String categoryProductsCount(int count) => isVi ? '$count sản phẩm' : '$count products';
  String categorySubcount(int count) => isVi ? '$count danh mục con' : '$count subcategories';
  String categorySummary(int prodCount, int childCount) => isVi
      ? '$prodCount sản phẩm • $childCount danh mục con'
      : '$prodCount products • $childCount subcategories';
  String get activeStatusLabel => isVi ? 'Hoạt động' : 'Active';
  String get inactiveStatusLabel => isVi ? 'Tạm ngừng' : 'Inactive';
  String get activateCategory => isVi ? 'Kích hoạt' : 'Activate';
  String get deactivateCategory => isVi ? 'Tạm ngừng' : 'Deactivate';

  // Orders View
  String get ordersAndFulfillment => isVi ? 'Đơn hàng & Vận hành' : 'Orders & Fulfillment';
  String get newOrder => isVi ? 'Tạo đơn hàng' : 'New Order';
  String get orderCode => isVi ? 'Mã đơn hàng' : 'Order Code';
  String get customer => isVi ? 'Khách hàng' : 'Customer';
  String get paymentStatus => isVi ? 'Thanh toán' : 'Payment';
  String get orderStatus => isVi ? 'Trạng thái đơn' : 'Order Status';
  String get totalAmount => isVi ? 'Tổng tiền' : 'Total Amount';
  String get viewDetails => isVi ? 'Chi tiết' : 'View';
  String get refreshOrders => isVi ? 'Làm mới đơn hàng' : 'Refresh orders';
  String get totalOrdersKpi => isVi ? 'Tổng đơn hàng' : 'Total Orders';
  String get pendingActionKpi => isVi ? 'Chờ xử lý' : 'Pending Action';
  String get inTransitKpi => isVi ? 'Đang vận chuyển' : 'In Transit';
  String get deliveredRevenueKpi => isVi ? 'Doanh thu đã giao' : 'Delivered Revenue';
  String get searchOrdersHint => isVi ? 'Tìm mã đơn, tên người nhận, số điện thoại...' : 'Search order code, recipient name, phone...';
  String get filterButton => isVi ? 'Lọc' : 'Filter';
  String get resetFiltersTooltip => isVi ? 'Đặt lại bộ lọc' : 'Reset Filters';
  String get orderStatusFilterLabel => isVi ? 'Trạng thái đơn: ' : 'Order Status: ';
  String get paymentStatusFilterLabel => isVi ? 'Thanh toán: ' : 'Payment: ';
  String get noOrdersMatching => isVi ? 'Không tìm thấy đơn hàng phù hợp' : 'No orders found matching criteria';
  String get itemsCol => isVi ? 'Sản phẩm' : 'Items';
  String get placedAtCol => isVi ? 'Thời gian đặt' : 'Placed At';
  String get actionCol => isVi ? 'Thao tác' : 'Action';
  String itemsCount(int count) => isVi ? '$count cái' : '$count pcs';

  // Order Details Dialog
  String placedOnDate(String date) => isVi ? 'Đặt lúc $date' : 'Placed on $date';
  String get shippingDetails => isVi ? 'Thông tin giao hàng' : 'Shipping Details';
  String get customerNote => isVi ? 'Ghi chú khách hàng' : 'Customer Note';
  String get lineItems => isVi ? 'Danh sách mặt hàng' : 'Line Items';
  String warrantyMonthsSnapshot(int months) => isVi ? '$months tháng BH' : '$months mo warranty';
  String get subtotalLabel => isVi ? 'Tạm tính:' : 'Subtotal:';
  String get shippingFeeLabel => isVi ? 'Phí vận chuyển:' : 'Shipping Fee:';
  String get discountLabel => isVi ? 'Giảm giá:' : 'Discount:';
  String get finalTotalLabel => isVi ? 'Tổng thanh toán:' : 'Final Total:';
  String orderStatusUpdated(String st) => isVi ? 'Đã cập nhật trạng thái đơn thành $st' : 'Order status updated to $st';
  String paymentStatusUpdated(String pst) => isVi ? 'Đã cập nhật thanh toán thành $pst' : 'Payment status updated to $pst';
  String failedToUpdateStatus(Object err) => isVi ? 'Cập nhật trạng thái thất bại: $err' : 'Failed to update status: $err';
  String failedToUpdatePayment(Object err) => isVi ? 'Cập nhật thanh toán thất bại: $err' : 'Failed to update payment status: $err';

  String get refundExceeded10Days => isVi
      ? 'Đơn hàng đã quá hạn 10 ngày kể từ ngày thanh toán hoặc nhận hàng, không thể hoàn tiền.'
      : 'Order exceeds the 10-day refund window from payment or receipt date.';
  String get cannotReturnToUnpaid => isVi
      ? 'Đơn hàng đã thanh toán không thể chuyển về Chưa thanh toán.'
      : 'Paid orders cannot return to Unpaid.';
  String get sequentialStepNotice => isVi
      ? 'Trạng thái đơn hàng phải chuyển tuần tự từng bước.'
      : 'Order status must advance step-by-step.';

  String orderStatusLabel(String status) {
    if (!isVi) {
      switch (status.toUpperCase()) {
        case 'ACCEPTED':
          return 'ACCEPTED';
        case 'PACKAGING':
          return 'PACKAGING';
        case 'DELIVERY':
          return 'DELIVERY';
        case 'SHIPPED':
          return 'SHIPPED';
        case 'SHOWROOM_BUY':
          return 'SHOWROOM BUY';
        case 'REFUND':
          return 'REFUND';
        default:
          return status;
      }
    }
    switch (status.toUpperCase()) {
      case 'ALL':
        return 'Tất cả';
      case 'ACCEPTED':
      case 'CONFIRMED':
        return 'Đã tiếp nhận';
      case 'PACKAGING':
      case 'PACKING':
        return 'Đang đóng gói';
      case 'DELIVERY':
        return 'Đang giao hàng';
      case 'SHIPPED':
      case 'DELIVERED':
        return 'Đã nhận hàng';
      case 'SHOWROOM_BUY':
        return 'Mua tại Showroom';
      case 'REFUND':
      case 'CANCELLED':
      case 'REFUNDED':
        return 'Hoàn tiền';
      case 'PENDING':
        return 'Chờ duyệt';
      default:
        return status;
    }
  }

  String paymentStatusLabel(String paymentStatus) {
    if (!isVi) {
      switch (paymentStatus.toUpperCase()) {
        case 'PAID':
          return 'PAID';
        case 'UNPAID':
          return 'UNPAID';
        case 'REFUND':
        case 'REFUNDED':
          return 'REFUND';
        default:
          return paymentStatus;
      }
    }
    switch (paymentStatus.toUpperCase()) {
      case 'ALL':
        return 'Tất cả';
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'PAID':
        return 'Đã thanh toán';
      case 'REFUND':
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return paymentStatus;
    }
  }

  // Warehouse View
  String get warehouse => isVi ? 'Kho hàng' : 'Warehouse';
  String get warehouseStock => isVi ? 'Kho hàng' : 'Warehouse';
  String get warehouseValuation => isVi ? 'Định giá kho' : 'Warehouse Valuation';
  String get totalVariants => isVi ? 'Tổng phiên bản' : 'Total Variants';
  String get lowStockAlert => isVi ? 'Cảnh báo sắp hết' : 'Low Stock Alert';
  String get outOfStock => isVi ? 'Hết hàng' : 'Out of Stock';
  String get inStock => isVi ? 'Còn hàng' : 'In Stock';
  String get searchWarehouseHint => isVi
      ? 'Tìm theo tên sản phẩm, phiên bản, SKU...'
      : 'Search product, variant name, SKU...';
  String get allStock => isVi ? 'Tất cả' : 'All';
  String get lowStockOnly => isVi ? 'Sắp hết' : 'Low Stock';
  String get outOfStockOnly => isVi ? 'Hết hàng' : 'Out of Stock';
  String get inStockOnly => isVi ? 'Còn hàng' : 'In Stock';
  String get productAndSpec => isVi ? 'Sản phẩm & Phiên bản' : 'Product & Spec';
  String get unitPrice => isVi ? 'Đơn giá' : 'Unit Price';
  String get onHand => isVi ? 'Thực tế' : 'On Hand';
  String get reserved => isVi ? 'Tạm giữ' : 'Reserved';
  String get available => isVi ? 'Khả dụng' : 'Available';
  String get reorderThreshold => isVi ? 'Mức cảnh báo' : 'Reorder Level';
  String get adjustStock => isVi ? 'Điều chỉnh tồn kho' : 'Adjust Stock';
  String get adjustStockTitle => isVi ? 'Điều chỉnh tồn kho & định mức' : 'Adjust Stock & Threshold';
  String adjustStockFor(String name) => isVi ? 'Điều chỉnh tồn kho: $name' : 'Adjust Stock: $name';
  String get physicalStockOnHand => isVi ? 'Số lượng thực tế (On Hand)' : 'Physical Stock On Hand';
  String get reorderWarningLevel => isVi ? 'Mức cảnh báo sắp hết (Reorder Level)' : 'Reorder Warning Level';
  String get adjustStockSuccess => isVi ? 'Cập nhật tồn kho thành công' : 'Stock updated successfully';
  String get failedToAdjustStock => isVi ? 'Không thể cập nhật tồn kho' : 'Failed to update stock';
  String get noStockFound => isVi ? 'Không tìm thấy dữ liệu tồn kho' : 'No warehouse stock found';
  String get refreshStockTooltip => isVi ? 'Làm mới dữ liệu kho' : 'Refresh warehouse stock';
  String get copySku => isVi ? 'Sao chép SKU' : 'Copy SKU';
  String get skuCopied => isVi ? 'Đã sao chép SKU' : 'SKU copied to clipboard';
  String lowStockBadgeLabel(int available, int reorder) =>
      isVi ? 'Sắp hết ($available/$reorder)' : 'Low Stock ($available/$reorder)';
  String get lineTotalValue => isVi ? 'Giá trị tồn' : 'Total Value';
  String get sku => 'SKU';
  String get stockStatus => isVi ? 'Trạng thái' : 'Status';
  // Goods Receipts & Movements
  String get receiptsTitle => isVi ? 'Phiếu xuất / nhập kho' : 'Stock Movements & Receipts';
  String get inbound => isVi ? 'Nhập kho' : 'Inbound';
  String get outbound => isVi ? 'Xuất kho' : 'Outbound';
  String get allMovementTypes => isVi ? 'Tất cả loại' : 'All Types';
  String get movementType => isVi ? 'Loại phiếu' : 'Movement Type';
  String get movementStatus => isVi ? 'Trạng thái' : 'Status';
  String get receiptCode => isVi ? 'Mã phiếu' : 'Receipt Code';
  String get totalItems => isVi ? 'Số lượng SP' : 'Total Items';
  String get partnerOrOrder => isVi ? 'NCC / Đơn hàng' : 'Supplier / Order';
  String get performerStaff => isVi ? 'Nhân viên thực hiện' : 'Staff';
  String get searchReceiptsHint => isVi
      ? 'Tìm theo mã phiếu, NCC, đơn hàng...'
      : 'Search receipt code, supplier, order...';
  String get newInboundReceipt => isVi ? 'Tạo phiếu nhập mới' : 'New Goods Receipt';
  String get totalReceiptsKpi => isVi ? 'Tổng số phiếu' : 'Total Receipts';
  String get totalInboundValueKpi => isVi ? 'Tổng giá trị nhập' : 'Total Inbound Value';
  String get totalOutboundValueKpi => isVi ? 'Tổng giá trị xuất' : 'Total Outbound Value';
  String get totalItemsMovedKpi => isVi ? 'Tổng số lượng SP' : 'Total Units';
  String get noReceiptsFound => isVi ? 'Không tìm thấy phiếu kho' : 'No receipts found';
  String get completeAndAddStock => isVi ? 'Hoàn tất & Nhập kho' : 'Complete & Add Stock';
  String get receiptDetailsTitle => isVi ? 'Chi tiết phiếu kho' : 'Receipt Details';
  String get goodsReceipts => isVi ? 'Phiếu nhập kho' : 'Goods Receipts';
  String get suppliers => isVi ? 'Nhà cung cấp' : 'Suppliers';
  String get createReceipt => isVi ? 'Tạo phiếu nhập' : 'Create Receipt';
  String get addSupplier => isVi ? 'Thêm nhà cung cấp' : 'Add Supplier';

  // Users View
  String get usersManagement => isVi ? 'Quản lý người dùng' : 'User Management';
  String get addUser => isVi ? 'Thêm người dùng' : 'Add User';
  String get searchUsers => isVi ? 'Tìm kiếm người dùng...' : 'Search users...';
  String get searchUsersHint => isVi ? 'Tìm theo tên, email, số điện thoại...' : 'Search by name, email, phone...';
  String get fullName => isVi ? 'Họ và tên' : 'Full Name';
  String get phone => isVi ? 'Số điện thoại' : 'Phone Number';
  String get role => isVi ? 'Vai trò' : 'Role';
  String get totalUsersKpi => isVi ? 'Tổng người dùng' : 'Total Users';
  String get activeUsersKpi => isVi ? 'Đang hoạt động' : 'Active Users';
  String get suspendedUsersKpi => isVi ? 'Đã tạm khóa' : 'Suspended Users';
  String get staffAndAdminKpi => isVi ? 'Nhân sự & Quản trị' : 'Staff & Admins';
  String get allRoles => isVi ? 'Tất cả vai trò' : 'All Roles';
  String get allStatus => isVi ? 'Tất cả trạng thái' : 'All Status';
  String get activeStatus => isVi ? 'Hoạt động' : 'Active';
  String get suspendedStatus => isVi ? 'Tạm khóa' : 'Suspended';
  String get activeOnly => isVi ? 'Đang hoạt động' : 'Active Only';
  String get suspendedOnly => isVi ? 'Tạm khóa' : 'Suspended Only';
  String get roleFilterLabel => isVi ? 'Vai trò: ' : 'Role: ';
  String get userCol => isVi ? 'Người dùng' : 'User';
  String get roleCol => isVi ? 'Vai trò' : 'Role';
  String get phoneCol => isVi ? 'Số điện thoại' : 'Phone';
  String get joinedAtCol => isVi ? 'Ngày tham gia' : 'Joined Date';
  String get passwordLabel => isVi ? 'Mật khẩu' : 'Password';
  String get emailRequired => isVi ? 'Vui lòng nhập email hợp lệ' : 'Valid email required';
  String get passwordMinLengthRequired => isVi ? 'Mật khẩu tối thiểu 6 ký tự' : 'Min 6 characters required';
  String get nameRequired => isVi ? 'Vui lòng nhập họ và tên' : 'Full name required';
  String get accountActive => isVi ? 'Tài khoản hoạt động' : 'Account Active';
  String get editUser => isVi ? 'Sửa thông tin' : 'Edit User';
  String get deleteUser => isVi ? 'Xóa người dùng' : 'Delete User';
  String get deleteUserConfirmTitle => isVi ? 'Xác nhận xóa người dùng' : 'Delete User';
  String deleteUserConfirmPrompt(String name, String email) => isVi
      ? 'Bạn có chắc chắn muốn xóa vĩnh viễn "$name" ($email)?'
      : 'Are you sure you want to permanently delete "$name" ($email)?';
  String get userCreatedSuccess => isVi ? 'Tạo người dùng thành công' : 'User created successfully';
  String get userUpdatedSuccess => isVi ? 'Cập nhật người dùng thành công' : 'User updated successfully';
  String get userDeletedSuccess => isVi ? 'Xóa người dùng thành công' : 'User deleted successfully';
  String get statusUpdatedSuccess => isVi ? 'Cập nhật trạng thái thành công' : 'Status updated successfully';
  String get refreshUsersTooltip => isVi ? 'Làm mới danh sách người dùng' : 'Refresh users list';
  String get noUsersFound => isVi ? 'Không tìm thấy người dùng phù hợp' : 'No users found matching criteria';
  String get activateUser => isVi ? 'Mở khóa tài khoản' : 'Activate Account';
  String get suspendUser => isVi ? 'Tạm khóa tài khoản' : 'Suspend Account';
  String get editUserTitle => isVi ? 'Cập nhật người dùng' : 'Edit User';

  String userRoleLabel(String roleName) {
    if (!isVi) {
      switch (roleName.toUpperCase()) {
        case 'ROLE_ADMIN':
          return 'Admin';
        case 'ROLE_STAFF':
          return 'Staff';
        case 'ROLE_CUSTOMER':
          return 'Customer';
        default:
          return roleName.replaceFirst('ROLE_', '');
      }
    }
    switch (roleName.toUpperCase()) {
      case 'ROLE_ADMIN':
        return 'Quản trị viên';
      case 'ROLE_STAFF':
        return 'Nhân viên';
      case 'ROLE_CUSTOMER':
        return 'Khách hàng';
      default:
        return roleName.replaceFirst('ROLE_', '');
    }
  }

  // RBAC View
  String get rbacMatrixTitle => isVi ? 'Ma trận Vai trò & Quyền hạn' : 'Roles & Permissions Matrix';
  String get rbacSubtitle => isVi
      ? 'Quản lý vai trò hệ thống, quyền hạn API và kiểm soát truy cập'
      : 'Manage system roles, granular API permissions, and access controls';
  String get addRole => isVi ? 'Thêm vai trò' : 'Add Role';
  String get permissionMatrix => isVi ? 'Bảng phân quyền' : 'Permission Matrix';
  String get totalRoles => isVi ? 'Tổng vai trò' : 'Total Roles';
  String get systemRoles => isVi ? 'Vai trò hệ thống' : 'System Roles';
  String get customRoles => isVi ? 'Vai trò tùy chỉnh' : 'Custom Roles';
  String get totalPermissions => isVi ? 'Tổng quyền hạn' : 'Total Permissions';
  String get systemProtectedRole => isVi ? 'Hệ thống bảo vệ' : 'System Protected';
  String get customRole => isVi ? 'Vai trò tùy chỉnh' : 'Custom role';
  String get systemBuiltinRole => isVi ? 'Vai trò mặc định hệ thống' : 'System built-in role';
  String get editPermissions => isVi ? 'Chỉnh sửa quyền hạn' : 'Edit Permissions';
  String get deleteRole => isVi ? 'Xóa vai trò' : 'Delete Role';
  String deleteRoleConfirm(String roleName) => isVi
      ? 'Bạn có chắc chắn muốn xóa vai trò "$roleName" không?'
      : 'Are you sure you want to delete role "$roleName"?';
  String get createRoleTitle => isVi ? 'Tạo vai trò mới' : 'Create New Role';
  String get roleNameLabel => isVi ? 'Tên vai trò (VD: ROLE_MANAGER)' : 'Role Name (e.g. ROLE_MANAGER)';
  String get roleNameRequired => isVi ? 'Tên vai trò không được để trống' : 'Role name is required';
  String get roleNameMustStartWithRole => isVi ? 'Phải bắt đầu bằng ROLE_' : 'Must start with ROLE_';
  String get description => isVi ? 'Mô tả' : 'Description';
  String get assignPermissions => isVi ? 'Gán quyền hạn ban đầu:' : 'Assign Initial Permissions:';
  String get savePermissions => isVi ? 'Lưu quyền hạn' : 'Save Permissions';
  String get selectAll => isVi ? 'Chọn tất cả' : 'Select All';
  String get deselectAll => isVi ? 'Bỏ chọn' : 'Deselect All';
  String get noPermissionsAssigned => isVi
      ? 'Chưa có quyền hạn nào được gán cho vai trò này.'
      : 'No permissions assigned to this role.';
  String get selectRolePrompt => isVi
      ? 'Chọn một vai trò từ danh sách để xem quyền hạn.'
      : 'Select a role from the list to view permissions.';
  String grantedPermissions(int count) => isVi ? 'Quyền hạn đã cấp ($count)' : 'Granted Permissions ($count)';
  String get roleDeletedSuccess => isVi ? 'Xóa vai trò thành công' : 'Role deleted successfully';
  String get roleCreatedSuccess => isVi ? 'Tạo vai trò thành công' : 'Role created successfully';
  String permissionsUpdatedSuccess(String roleName) => isVi
      ? 'Đã cập nhật quyền hạn cho $roleName'
      : 'Permissions updated for $roleName';
  String get searchRolesHint => isVi ? 'Tìm vai trò...' : 'Search roles...';
  String get searchPermissionsHint => isVi ? 'Tìm quyền hạn...' : 'Search permissions...';
  String get noRolesFound => isVi ? 'Không tìm thấy vai trò nào' : 'No roles found';
  String get noPermissionsFound => isVi ? 'Không tìm thấy quyền hạn nào' : 'No permissions found';

  // Profile Dialog
  String get profileDetails => isVi ? 'Thông tin cá nhân' : 'Profile Details';
  String get security => isVi ? 'Bảo mật' : 'Security';
  String get currentPassword => isVi ? 'Mật khẩu hiện tại' : 'Current Password';
  String get newPassword => isVi ? 'Mật khẩu mới' : 'New Password';
  String get confirmNewPassword => isVi ? 'Xác nhận mật khẩu mới' : 'Confirm New Password';
  String get changePassword => isVi ? 'Đổi mật khẩu' : 'Change Password';
}

class _DashboardLocalizationsDelegate extends LocalizationsDelegate<DashboardLocalizations> {
  const _DashboardLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<DashboardLocalizations> load(Locale locale) {
    return SynchronousFuture<DashboardLocalizations>(DashboardLocalizations(locale));
  }

  @override
  bool shouldReload(_DashboardLocalizationsDelegate old) => false;
}

extension DashboardLocalizationsExtension on BuildContext {
  DashboardLocalizations get l10n => DashboardLocalizations.of(this);
}
