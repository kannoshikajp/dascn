import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import '../views/overview_view.dart';
import '../views/orders_view.dart';
import '../views/warehouse_view.dart';
import '../views/receipts_view.dart';
import '../views/inventory_view.dart';
import '../views/users_view.dart';
import '../views/rbac_view.dart';
import '../views/categories_view.dart';
import '../views/products_view.dart';
import '../views/pos/pos_cashier_view.dart';
import '../views/settings_view.dart';
import '../views/ai_assistant_view.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/sidebar/dashboard_sidebar.dart';

class DashboardShell extends StatefulWidget {
  final AuthSession session;
  final AuthService authService;
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final CategoryManagementService categoryService;
  final ProductManagementService productService;
  final OrderService orderService;
  final InventoryService inventoryService;
  final AnalyticsService? analyticsService;
  final VnPayService? vnPayService;
  final MediaUploadService? mediaService;
  final AdminAiService? aiService;
  final VoidCallback onLogout;
  final Locale? currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;
  final ThemeMode? currentThemeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const DashboardShell({
    super.key,
    required this.session,
    required this.authService,
    required this.userService,
    required this.rbacService,
    required this.categoryService,
    required this.productService,
    required this.orderService,
    required this.inventoryService,
    this.analyticsService,
    this.vnPayService,
    this.mediaService,
    this.aiService,
    required this.onLogout,
    this.currentLocale,
    this.onLocaleChanged,
    this.currentThemeMode,
    this.onThemeModeChanged,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profile = UserProfile(
      id: widget.session.userId,
      email: widget.session.email,
      fullName: widget.session.fullName,
      role: widget.session.role,
      permissions: widget.session.permissions,
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await widget.authService.getCurrentProfile();
      if (mounted) {
        setState(() => _profile = p);
      }
    } catch (_) {
      // Keep session fallback if offline or failed
    }
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const defaultApiUrl = 'http://localhost:8080';
    if (url.startsWith('/')) {
      return '$defaultApiUrl$url';
    }
    return '$defaultApiUrl/$url';
  }

  String _getInitials(String name, String email) {
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  Future<void> _handleLogout() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.signOut)),
        ],
      ),
    );
    if (confirm == true) {
      widget.authService.logout();
      widget.onLogout();
    }
  }

  Future<void> _openProfileDialog() async {
    final current = _profile ??
        UserProfile(
          id: widget.session.userId,
          email: widget.session.email,
          fullName: widget.session.fullName,
          role: widget.session.role,
          permissions: widget.session.permissions,
        );

    await showDialog(
      context: context,
      builder: (ctx) => ProfileDialog(
        profile: current,
        authService: widget.authService,
        mediaService: widget.mediaService,
        onProfileUpdated: (updated) {
          setState(() => _profile = updated);
        },
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildProfileMenuItems(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return [
      // User Header Info Card
      PopupMenuItem<String>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.md, vertical: JoppeSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                backgroundImage: (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
                    ? NetworkImage(_resolveImageUrl(_profile!.avatarUrl!))
                    : null,
                onBackgroundImageError: (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
                    ? (_, _) {}
                    : null,
                child: (_profile?.avatarUrl == null || _profile!.avatarUrl!.isEmpty)
                    ? Text(
                        _getInitials(_profile?.fullName ?? widget.session.fullName, widget.session.email),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: JoppeSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _profile?.fullName != null && _profile!.fullName.isNotEmpty
                          ? _profile!.fullName!
                          : (widget.session.fullName.isNotEmpty ? widget.session.fullName : 'System User'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.session.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.session.role,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
      // Profile
      PopupMenuItem<String>(
        value: 'profile',
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: JoppeSpacing.sm),
            Text(l10n.accountProfile, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'settings',
        child: Row(
          children: [
            Icon(Icons.settings_outlined, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: JoppeSpacing.sm),
            Text(l10n.navSettings, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
      // Sign Out
      PopupMenuItem<String>(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: colorScheme.error),
            const SizedBox(width: JoppeSpacing.sm),
            Text(
              l10n.signOut,
              style: TextStyle(fontSize: 13, color: colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ];
  }

  void _onProfileMenuSelected(String value) {
    if (value == 'profile') {
      _openProfileDialog();
    } else if (value == 'settings') {
      setState(() => _selectedIndex = 10);
    } else if (value == 'logout') {
      _handleLogout();
    }
  }

  Widget _buildCompactProfileButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final displayName = _profile?.fullName != null && _profile!.fullName.isNotEmpty
        ? _profile!.fullName!
        : (widget.session.fullName.isNotEmpty ? widget.session.fullName : 'System User');

    return PopupMenuButton<String>(
      tooltip: l10n.accountProfile,
      offset: const Offset(0, 48),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      color: colorScheme.surface,
      padding: EdgeInsets.zero,
      itemBuilder: (context) => _buildProfileMenuItems(context),
      onSelected: _onProfileMenuSelected,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        backgroundImage: (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
            ? NetworkImage(_resolveImageUrl(_profile!.avatarUrl!))
            : null,
        onBackgroundImageError: (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
            ? (_, _) {}
            : null,
        child: (_profile?.avatarUrl == null || _profile!.avatarUrl!.isEmpty)
            ? Text(
                _getInitials(displayName, widget.session.email),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              )
            : null,
      ),
    );
  }

  Widget _buildSidebarProfile(BuildContext context, bool isCollapsed) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final displayName = _profile?.fullName != null && _profile!.fullName.isNotEmpty
        ? _profile!.fullName!
        : (widget.session.fullName.isNotEmpty ? widget.session.fullName : 'System User');

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      backgroundImage: (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
          ? NetworkImage(_resolveImageUrl(_profile!.avatarUrl!))
          : null,
      onBackgroundImageError: (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
          ? (_, _) {}
          : null,
      child: (_profile?.avatarUrl == null || _profile!.avatarUrl!.isEmpty)
          ? Text(
              _getInitials(displayName, widget.session.email),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: PopupMenuButton<String>(
        tooltip: isCollapsed ? displayName : l10n.accountProfile,
        offset: isCollapsed ? const Offset(60, -140) : const Offset(0, -180),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
        ),
        color: colorScheme.surface,
        padding: EdgeInsets.zero,
        itemBuilder: (context) => _buildProfileMenuItems(context),
        onSelected: _onProfileMenuSelected,
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 4 : 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(60),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
          ),
          child: isCollapsed
              ? Center(child: avatar)
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: JoppeSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.session.email,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.unfold_more, size: 18, color: colorScheme.onSurfaceVariant),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final effectiveLocale = widget.currentLocale ?? Localizations.maybeLocaleOf(context) ?? const Locale('vi');

    final destinations = DashboardSidebar.buildDestinations(context);

    Widget currentBody;
    switch (_selectedIndex) {
      case 0:
        currentBody = OverviewView(
          userService: widget.userService,
          rbacService: widget.rbacService,
          categoryService: widget.categoryService,
          productService: widget.productService,
          orderService: widget.orderService,
          analyticsService: widget.analyticsService,
          onNavigateToOrders: () => setState(() => _selectedIndex = 1),
          onNavigateToProducts: () => setState(() => _selectedIndex = 3),
          onNavigateToCategories: () => setState(() => _selectedIndex = 4),
          onNavigateToInventory: () => setState(() => _selectedIndex = 5),
          onNavigateToReceipts: () => setState(() => _selectedIndex = 6),
          onNavigateToUsers: () => setState(() => _selectedIndex = 8),
          onNavigateToRbac: () => setState(() => _selectedIndex = 9),
        );
        break;
      case 1:
        currentBody = OrdersView(
          orderService: widget.orderService,
          productService: widget.productService,
          userService: widget.userService,
        );
        break;
      case 2:
        currentBody = PosCashierView(
          orderService: widget.orderService,
          productService: widget.productService,
          userService: widget.userService,
          vnPayService: widget.vnPayService,
        );
        break;
      case 3:
        currentBody = ProductsView(
          productService: widget.productService,
          categoryService: widget.categoryService,
          mediaUploadService: widget.mediaService,
        );
        break;
      case 4:
        currentBody = CategoriesView(
          categoryService: widget.categoryService,
          mediaUploadService: widget.mediaService,
        );
        break;
      case 5:
        currentBody = WarehouseView(
          key: const ValueKey('warehouse_view'),
          inventoryService: widget.inventoryService,
        );
        break;
      case 6:
        currentBody = ReceiptsView(
          key: const ValueKey('receipts_view'),
          inventoryService: widget.inventoryService,
          productService: widget.productService,
        );
        break;
      case 7:
        currentBody = InventoryView(
          key: const ValueKey('suppliers_directory_view'),
          inventoryService: widget.inventoryService,
          productService: widget.productService,
          fixedTab: 2,
        );
        break;
      case 8:
        currentBody = UsersView(
          userService: widget.userService,
          rbacService: widget.rbacService,
        );
        break;
      case 9:
        currentBody = RbacView(
          rbacService: widget.rbacService,
        );
        break;
      case 10:
        currentBody = SettingsView(
          currentLocale: effectiveLocale,
          onLocaleChanged: widget.onLocaleChanged ?? (_) {},
          currentThemeMode: widget.currentThemeMode ?? ThemeMode.system,
          onThemeModeChanged: widget.onThemeModeChanged ?? (_) {},
        );
        break;
      case 11:
        currentBody = AiAssistantView(
          aiService: widget.aiService ?? AdminAiService(widget.authService.client),
          onNavigateToDestination: (idx) => setState(() => _selectedIndex = idx),
        );
        break;
      default:
        currentBody = const SizedBox.shrink();
    }

    return JoppeResponsiveScaffold(
      title: l10n.appTitle,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
      destinations: destinations,
      actions: [
        if (MediaQuery.sizeOf(context).width < 600)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: _buildCompactProfileButton(context),
          ),
        const SizedBox(width: JoppeSpacing.md),
      ],
      sidebarFooterBuilder: (context, isCollapsed) => _buildSidebarProfile(context, isCollapsed),
      collapseTooltip: l10n.collapseSidebar,
      expandTooltip: l10n.expandSidebar,
      body: currentBody,
    );
  }
}
