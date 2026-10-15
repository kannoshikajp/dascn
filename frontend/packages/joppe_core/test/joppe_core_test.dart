import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_core/joppe_core.dart';

void main() {
  test('UserProfile JSON serialization and permission check', () {
    final profile = UserProfile.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'email': 'admin@joppe.vn',
      'fullName': 'Admin User',
      'role': 'ROLE_ADMIN',
      'permissions': ['AUTH_ME', 'USER_READ'],
      'isActive': true,
    });

    expect(profile.email, 'admin@joppe.vn');
    expect(profile.hasPermission('AUTH_ME'), isTrue);
    expect(profile.hasPermission('PRODUCT_DELETE'), isFalse);
    expect(profile.toJson()['role'], 'ROLE_ADMIN');
  });
}
