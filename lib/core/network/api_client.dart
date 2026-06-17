import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/env.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(secureStorageProvider));
});

class ApiClient {
  final SecureStorage _secureStorage;
  final http.Client _client = http.Client();
  ApiClient(this._secureStorage);

  Future<Map<String, String>> _headers() async {
    final token = await _secureStorage.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse> get(String path) async {
    try {
      final headers = await _headers();
      final response = await _client.get(Uri.parse('${Env.backendUrl}$path'), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('GET $path failed', e);
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await _client.post(Uri.parse('${Env.backendUrl}$path'), headers: headers, body: jsonEncode(body));
      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('POST $path failed', e);
      return ApiResponse(success: false, error: e.toString());
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = jsonDecode(response.body);
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse(success: true, data: body, statusCode: statusCode);
    } else {
      final errorMessage = body['error'] ?? 'Unknown error';
      return ApiResponse(success: false, error: errorMessage, statusCode: statusCode);
    }
  }
}

class ApiResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final int? statusCode;
  ApiResponse({required this.success, this.data, this.error, this.statusCode});
}
