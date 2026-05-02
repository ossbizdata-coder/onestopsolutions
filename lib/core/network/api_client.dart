import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onestopsolutions/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base HTTP client with automatic JWT injection
class ApiClient {
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
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers(token),
    );
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    return http.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    return http.put(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    return http.patch(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path) async {
    final token = await _getToken();
    return http.delete(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers(token),
    );
  }
}

