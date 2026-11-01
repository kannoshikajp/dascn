class ApiConstants {
  ApiConstants._();

  static const String defaultBaseUrl = 'http://localhost:8080';
  static const String apiVersion = '/api/v1';

  // Auth endpoints
  static const String authRegister = '$apiVersion/auth/register';
  static const String authLogin = '$apiVersion/auth/login';
  static const String authGoogle = '$apiVersion/auth/google';
  static const String authMe = '$apiVersion/auth/me';
  static const String authProfile = '$apiVersion/auth/profile';
  static const String authChangePassword = '$apiVersion/auth/change-password';

  // Public Catalog endpoints
  static const String products = '$apiVersion/products';
  static const String categories = '$apiVersion/categories';
  static const String categoriesTree = '$apiVersion/categories/tree';

  // Address endpoints
  static const String addresses = '$apiVersion/addresses';

  // Cart endpoints
  static const String cart = '$apiVersion/cart';
  static const String cartItems = '$apiVersion/cart/items';
  static const String cartMerge = '$apiVersion/cart/merge';

  // Orders endpoints
  static const String ordersCheckout = '$apiVersion/orders/checkout';
  static const String ordersMy = '$apiVersion/orders/my';
  static const String orders = '$apiVersion/orders';

  // Admin Order endpoints
  static const String adminOrders = '$apiVersion/admin/orders';

  // Admin Inventory & Supplier endpoints
  static const String adminInventorySuppliers = '$apiVersion/admin/inventory/suppliers';
  static const String adminInventoryReceipts = '$apiVersion/admin/inventory/receipts';
  static const String adminInventoryStock = '$apiVersion/admin/inventory/stock';

  // PC Builder endpoints
  static const String pcBuilder = '$apiVersion/pc-builder';
  static const String pcBuilderSimulate = '$apiVersion/pc-builder/simulate';
  static const String pcBuilderSave = '$apiVersion/pc-builder/save';
  static const String pcBuilderMy = '$apiVersion/pc-builder/my';

  // Reviews endpoints
  static const String reviews = '$apiVersion/reviews';
}
