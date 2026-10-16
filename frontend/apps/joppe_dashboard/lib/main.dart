import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'src/screens/dashboard_shell.dart';
import 'src/screens/login_screen.dart';

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

  runApp(JoppeDashboardApp(
    authService: authService,
    userService: userService,
    rbacService: rbacService,
    categoryService: categoryService,
    productService: productService,
    mediaService: mediaService,
  ));
}

class JoppeDashboardApp extends StatefulWidget {
  final AuthService authService;
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final CategoryManagementService categoryService;
  final ProductManagementService productService;
  final MediaUploadService? mediaService;
  final AuthSession? initialSession;

  const JoppeDashboardApp({
    super.key,
    required this.authService,
    required this.userService,
    required this.rbacService,
    required this.categoryService,
    required this.productService,
    this.mediaService,
    this.initialSession,
  });

  @override
  State<JoppeDashboardApp> createState() => _JoppeDashboardAppState();
}

class _JoppeDashboardAppState extends State<JoppeDashboardApp> {
  late AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joppe Control Center',
      debugShowCheckedModeBanner: false,
      theme: JoppeTheme.light(),
      darkTheme: JoppeTheme.dark(),
      themeMode: ThemeMode.system,
      home: _session == null
          ? LoginScreen(
              authService: widget.authService,
              onLoginSuccess: (session) {
                setState(() => _session = session);
              },
            )
          : DashboardShell(
              session: _session!,
              authService: widget.authService,
              userService: widget.userService,
              rbacService: widget.rbacService,
              categoryService: widget.categoryService,
              productService: widget.productService,
              mediaService: widget.mediaService,
              onLogout: () {
                setState(() => _session = null);
              },
            ),
    );
  }
}
