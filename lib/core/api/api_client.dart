import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:incident_reporter/core/services/auth_service.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final AuthService _authService = AuthService.instance;

  Future<dynamic> getJson(String absoluteUrlOrPath) async {
    final headers = await _headers();
    final response = await _send(
      () => _http.get(Uri.parse(absoluteUrlOrPath), headers: headers),
    );
    return _decode(response);
  }

  Future<dynamic> postJson(
      String absoluteUrlOrPath, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await _send(
      () => _http.post(
        Uri.parse(absoluteUrlOrPath),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> patchJson(
      String absoluteUrlOrPath, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await _send(
      () => _http.patch(
        Uri.parse(absoluteUrlOrPath),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> putJson(
      String absoluteUrlOrPath, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await _send(
      () => _http.put(
        Uri.parse(absoluteUrlOrPath),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getValidToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() action) async {
    final response = await action();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    String message = 'Request failed with status ${response.statusCode}';
    try {
      final decoded = _decode(response);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    final body = utf8.decode(response.bodyBytes);
    if (body.isEmpty) {
      return null;
    }
    return jsonDecode(body);
  }
}
