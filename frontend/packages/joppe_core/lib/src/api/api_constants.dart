class ApiConstants {
  ApiConstants._();

  static const String defaultBaseUrl = 'http://localhost:8080';
  static const String apiVersion = '/api/v1';

  // Auth endpoints
  static const String authRegister = '$apiVersion/auth/register';
  static const String authLogin = '$apiVersion/auth/login';
  static const String authMe = '$apiVersion/auth/me';
  static const String authChangePassword = '$apiVersion/auth/change-password';
}
