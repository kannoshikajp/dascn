import '../api/api_client.dart';
import '../models/customer_ai_model.dart';

class CustomerAiService {
  final ApiClient _client;

  CustomerAiService(this._client);

  Future<CustomerAiChatResponse> sendMessage(
    String message, {
    List<CustomerAiChatMessage> history = const [],
  }) async {
    final payload = {
      'message': message,
      'history': history.map((msg) => msg.toJson()).toList(),
    };

    final response = await _client.post('/api/v1/ai/chat', payload);
    if (response is Map<String, dynamic>) {
      return CustomerAiChatResponse.fromJson(response);
    }
    throw ApiException(500, 'Invalid response format from Customer AI service');
  }
}
