import '../api/api_client.dart';
import '../models/admin_ai_model.dart';

class AdminAiService {
  final ApiClient _client;

  AdminAiService(this._client);

  Future<AdminAiChatResponse> sendMessage(
    String message, {
    List<AdminAiChatMessage> history = const [],
  }) async {
    final payload = {
      'message': message,
      'history': history.map((msg) => msg.toJson()).toList(),
    };

    final response = await _client.post('/api/v1/admin/ai/chat', payload);
    if (response is Map<String, dynamic>) {
      return AdminAiChatResponse.fromJson(response);
    }
    throw ApiException(500, 'Invalid response format from AI service');
  }
}
