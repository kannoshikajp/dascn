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

  Future<List<UploadedMedia>> listMedia({
    String? folder,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (folder != null && folder.isNotEmpty) queryParams['folder'] = folder;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _client.get(
      '/api/v1/media',
      queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response as List<dynamic>;
    return list
        .map((e) => UploadedMedia.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
