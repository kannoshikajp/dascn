import 'package:joppe_core/joppe_core.dart';

/// Central API Client provider for Joppe App, utilizing joppe_core.ApiClient.
class AppApiClient {
  static ApiClient? _instance;

  static ApiClient get instance {
    _instance ??= ApiClient(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://joppe.penguinlab.org',
      ),
    );
    return _instance!;
  }

  static void setInstance(ApiClient client) {
    _instance = client;
  }

  static void reset() {
    _instance = null;
  }
}
