import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onestopsolutions/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base HTTP client with automatic JWT injection
class ApiClient {
  static const Duration _timeout = Duration(seconds: 30);
  static const bool _debugLogging = true; // Set to false in production

  static void _log(String message) {
    if (_debugLogging) {
      print('[API] $message');
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> get(String path) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$path';
    _log('GET $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      ).timeout(_timeout, onTimeout: () {
        _log('❌ GET TIMEOUT: $url');
        return http.Response('Connection timeout', 408);
      });
      _log('✅ GET $url -> ${response.statusCode}');
      return response;
    } catch (e) {
      _log('❌ GET ERROR: $url -> $e');
      rethrow;
    }
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$path';
    _log('POST $url with body: ${jsonEncode(body)}');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(_timeout, onTimeout: () {
        _log('❌ POST TIMEOUT: $url');
        return http.Response('Connection timeout', 408);
      });
      _log('✅ POST $url -> ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        _log('⚠️ Response body: ${response.body}');
      }
      return response;
    } catch (e) {
      _log('❌ POST ERROR: $url -> $e');
      rethrow;
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$path';
    _log('PUT $url');
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(_timeout, onTimeout: () {
        _log('❌ PUT TIMEOUT: $url');
        return http.Response('Connection timeout', 408);
      });
      _log('✅ PUT $url -> ${response.statusCode}');
      return response;
    } catch (e) {
      _log('❌ PUT ERROR: $url -> $e');
      rethrow;
    }
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$path';
    _log('PATCH $url');
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(_timeout, onTimeout: () {
        _log('❌ PATCH TIMEOUT: $url');
        return http.Response('Connection timeout', 408);
      });
      _log('✅ PATCH $url -> ${response.statusCode}');
      return response;
    } catch (e) {
      _log('❌ PATCH ERROR: $url -> $e');
      rethrow;
    }
  }

  static Future<http.Response> delete(String path) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$path';
    _log('DELETE $url');
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(token),
      ).timeout(_timeout, onTimeout: () {
        _log('❌ DELETE TIMEOUT: $url');
        return http.Response('Connection timeout', 408);
      });
      _log('✅ DELETE $url -> ${response.statusCode}');
      return response;
    } catch (e) {
      _log('❌ DELETE ERROR: $url -> $e');
      rethrow;
    }
  }
}

