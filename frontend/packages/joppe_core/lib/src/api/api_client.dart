import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  const ApiException(this.statusCode, this.message, [this.data]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  ApiClient({
    this.baseUrl = 'http://localhost:8080',
    http.Client? client,
  }) : _client = client ?? http.Client();

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Resolves relative media paths (e.g. '/uploads/products/xyz.webp') to absolute URLs with baseUrl.
  String resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$baseUrl$cleanPath';
  }

  Map<String, String> _headers() {
    final map = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  Future<Map<String, dynamic>> checkLiveness() async {
    try {
      final uri = Uri.parse('$baseUrl/live');
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
      return {
        'status': response.statusCode == 200 ? 'UP' : 'DOWN',
        'message': response.statusCode == 200
            ? 'Backend is live and healthy.'
            : 'Cannot access /live: server returned HTTP ${response.statusCode}',
      };
    } catch (e) {
      return {
        'status': 'DOWN',
        'message': 'Cannot access /live at $baseUrl: connection failed. Please ensure the backend server is running.',
        'error': e.toString(),
      };
    }
  }

  Future<dynamic> get(String endpoint, [Map<String, String>? queryParams]) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await _client.get(uri, headers: _headers());
    return _handleResponse(response);
  }

  Future<String> getRaw(String endpoint, [Map<String, String>? queryParams]) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = _headers();
    headers['Accept'] = 'text/csv, text/plain, */*';

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return utf8.decode(response.bodyBytes);
    }
    throw ApiException(response.statusCode, 'HTTP ${response.statusCode}: ${response.body}');
  }

  Future<dynamic> post(String endpoint, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.put(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.patch(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.delete(uri, headers: _headers());
    return _handleResponse(response);
  }

  static http_parser.MediaType _resolveContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return http_parser.MediaType('image', 'jpeg');
    } else if (lower.endsWith('.png')) {
      return http_parser.MediaType('image', 'png');
    } else if (lower.endsWith('.webp')) {
      return http_parser.MediaType('image', 'webp');
    } else if (lower.endsWith('.gif')) {
      return http_parser.MediaType('image', 'gif');
    } else if (lower.endsWith('.svg')) {
      return http_parser.MediaType('image', 'svg+xml');
    }
    return http_parser.MediaType('application', 'octet-stream');
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.headers['Accept'] = 'application/json';
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: _resolveContentType(filename),
      ),
    );
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic json;
    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        json = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    String errorMsg = 'HTTP ${response.statusCode}';
    if (json is Map<String, dynamic> && json['message'] != null) {
      errorMsg = json['message'].toString();
    }
    throw ApiException(response.statusCode, errorMsg, json is Map<String, dynamic> ? json : null);
  }
}
