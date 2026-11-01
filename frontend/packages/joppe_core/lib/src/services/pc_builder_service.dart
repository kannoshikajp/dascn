import '../api/api_client.dart';
import '../api/api_constants.dart';

class PcBuilderService {
  final ApiClient _client;

  PcBuilderService(this._client);

  Future<dynamic> simulateBuild(Map<String, dynamic> components) async {
    return _client.post(ApiConstants.pcBuilderSimulate, components);
  }

  Future<dynamic> saveBuild(Map<String, dynamic> buildData) async {
    return _client.post(ApiConstants.pcBuilderSave, buildData);
  }

  Future<dynamic> getMyBuilds() async {
    return _client.get(ApiConstants.pcBuilderMy);
  }

  Future<dynamic> addBuildToCart(String buildId) async {
    return _client.post('${ApiConstants.pcBuilder}/$buildId/add-to-cart');
  }
}
