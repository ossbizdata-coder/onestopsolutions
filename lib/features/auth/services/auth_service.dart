import 'dart:convert';
import 'package:onestopsolutions/core/constants/api_constants.dart';
import 'package:onestopsolutions/core/network/api_client.dart';
import 'package:onestopsolutions/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// Login with email and password
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final res = await ApiClient.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveSession(data);
      return data;
    }
    return null;
  }

  /// Register a new user
  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    final res = await ApiClient.post(ApiConstants.register, {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    return res.statusCode == 201;
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token'] ?? '');
    await prefs.setString('email', data['email'] ?? '');
    await prefs.setString('name', data['name'] ?? '');
    await prefs.setString('role', data['role'] ?? 'STAFF');
    await prefs.setInt('userId', data['userId'] ?? 0);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('role');
    await prefs.remove('userId');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  static Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final role = prefs.getString('role');
    if (id == null || name == null) return null;
    return AppUser(
      id: id,
      name: name,
      email: email ?? '',
      role: role ?? 'STAFF',
    );
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}

