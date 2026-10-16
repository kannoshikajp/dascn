import '../api/api_client.dart';
import '../models/uploaded_media.dart';

class MediaUploadService {
  final ApiClient _client;

  MediaUploadService(this._client);

  Future<UploadedMedia> uploadImage({
    required List<int> bytes,
    required String filename,
    String folder = 'general',
  }) async {
    final response = await _client.postMultipart(
      '/api/v1/media/upload',
      bytes: bytes,
      filename: filename,
      fieldName: 'file',
      fields: {'folder': folder},
    );
    return UploadedMedia.fromJson(response as Map<String, dynamic>);
  }
}
