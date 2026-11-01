import '../api/api_client.dart';
import '../models/analytics_overview_model.dart';

class AnalyticsService {
  final ApiClient apiClient;

  const AnalyticsService(this.apiClient);

  Future<AnalyticsOverviewModel> getOverview() async {
    final res = await apiClient.get('/api/v1/admin/analytics/overview');
    return AnalyticsOverviewModel.fromJson(res as Map<String, dynamic>);
  }
}
