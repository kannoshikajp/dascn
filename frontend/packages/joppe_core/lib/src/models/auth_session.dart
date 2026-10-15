class AuthSession {
  final String tokenType;
  final String accessToken;
  final int expiresInSeconds;
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final List<String> permissions;

  const AuthSession({
    required this.tokenType,
    required this.accessToken,
    required this.expiresInSeconds,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    this.permissions = const [],
  });

  bool hasPermission(String perm) => permissions.contains(perm);
  bool hasAnyPermission(Iterable<String> perms) => perms.any(permissions.contains);

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: json['accessToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 86400,
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'ROLE_CUSTOMER',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
