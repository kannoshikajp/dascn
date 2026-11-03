import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'src/localization/dashboard_localizations.dart';
import 'src/screens/boot_loader_screen.dart';
import 'src/screens/dashboard_shell.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/server_offline_screen.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final authService = AuthService(apiClient);
  final userService = UserManagementService(apiClient);
  final rbacService = RbacManagementService(apiClient);
  final categoryService = CategoryManagementService(apiClient);
  final productService = ProductManagementService(apiClient);
  final mediaService = MediaUploadService(apiClient);
  final orderService = OrderService(apiClient);
  final inventoryService = InventoryService(apiClient);
  final analyticsService = AnalyticsService(apiClient);
  final vnPayService = VnPayService(apiClient);
  final aiService = AdminAiService(apiClient);

  runApp(JoppeDashboardApp(
    apiClient: apiClient,
    authService: authService,
    userService: userService,
    rbacService: rbacService,
    categoryService: categoryService,
    productService: productService,
    mediaService: mediaService,
    orderService: orderService,
    inventoryService: inventoryService,
    analyticsService: analyticsService,
    vnPayService: vnPayService,
    aiService: aiService,
  ));
}

class JoppeDashboardApp extends StatefulWidget {
  final ApiClient? apiClient;
  final AuthService authService;
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final CategoryManagementService categoryService;
  final ProductManagementService productService;
  final MediaUploadService? mediaService;
  final OrderService orderService;
  final InventoryService inventoryService;
  final AnalyticsService? analyticsService;
  final VnPayService? vnPayService;
  final AdminAiService? aiService;
  final AuthSession? initialSession;
  final bool checkLivenessOnInit;
  final Locale? initialLocale;
  final ThemeMode? initialThemeMode;

  const JoppeDashboardApp({
    super.key,
    this.apiClient,
    required this.authService,
    required this.userService,
    required this.rbacService,
    required this.categoryService,
    required this.productService,
    this.mediaService,
    required this.orderService,
    required this.inventoryService,
    this.analyticsService,
    this.vnPayService,
    this.aiService,
    this.initialSession,
    this.checkLivenessOnInit = true,
    this.initialLocale,
    this.initialThemeMode,
  });

  @override
  State<JoppeDashboardApp> createState() => _JoppeDashboardAppState();
}

class _JoppeDashboardAppState extends State<JoppeDashboardApp> {
  late AuthSession? _session;
  late Locale _locale;
  late ThemeMode _themeMode;
  bool _isCheckingLive = false;
  bool _isServerLive = false;
  String? _liveErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.apiClient != null) {
      ApiClient.defaultInstance = widget.apiClient!;
    }
    _session = widget.initialSession;
    _locale = widget.initialLocale ?? const Locale('vi');
    _themeMode = widget.initialThemeMode ?? ThemeMode.system;
    if (widget.checkLivenessOnInit && widget.apiClient != null) {
      _isCheckingLive = true;
      _isServerLive = false;
      _checkLiveness();
    } else {
      _isCheckingLive = false;
      _isServerLive = true;
    }
  }

  void _changeLocale(Locale newLocale) {
    if (_locale != newLocale) {
      setState(() => _locale = newLocale);
    }
  }

  void _changeThemeMode(ThemeMode newMode) {
    if (_themeMode != newMode) {
      setState(() => _themeMode = newMode);
    }
  }

  Future<void> _checkLiveness() async {
    setState(() {
      _isCheckingLive = true;
    });

    try {
      final res = await widget.apiClient!.checkLiveness();
      final status = res['status']?.toString().toUpperCase();
      final isUp = status == 'UP';

      if (mounted) {
        setState(() {
          _isCheckingLive = false;
          _isServerLive = isUp;
          _liveErrorMessage = isUp
              ? null
              : (res['message']?.toString() ?? 'Server status: $status');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLive = false;
          _isServerLive = false;
          _liveErrorMessage = 'Cannot reach backend at /live: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _locale.languageCode == 'vi' ? 'Quản trị Joppe' : 'Joppe Control Center',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        DashboardLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: JoppeTheme.light(),
      darkTheme: JoppeTheme.dark(),
      themeMode: _themeMode,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final baseUrl = widget.apiClient?.baseUrl ?? ApiClient.resolveUrl('');

    if (_isCheckingLive && !_isServerLive) {
      return BootLoaderScreen(baseUrl: baseUrl);
    }

    if (!_isServerLive) {
      return ServerOfflineScreen(
        baseUrl: baseUrl,
        errorMessage: _liveErrorMessage,
        isRetrying: _isCheckingLive,
        onRetry: _checkLiveness,
      );
    }

    if (_session == null) {
      return LoginScreen(
        authService: widget.authService,
        onLoginSuccess: (session) {
          setState(() => _session = session);
        },
      );
    }

    return DashboardShell(
      session: _session!,
      authService: widget.authService,
      userService: widget.userService,
      rbacService: widget.rbacService,
      categoryService: widget.categoryService,
      productService: widget.productService,
      orderService: widget.orderService,
      inventoryService: widget.inventoryService,
      analyticsService: widget.analyticsService,
      vnPayService: widget.vnPayService,
      mediaService: widget.mediaService,
      aiService: widget.aiService,
      currentLocale: _locale,
      onLocaleChanged: _changeLocale,
      currentThemeMode: _themeMode,
      onThemeModeChanged: _changeThemeMode,
      onLogout: () {
        setState(() => _session = null);
      },
    );
  }
}
