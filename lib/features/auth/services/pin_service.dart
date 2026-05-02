import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'app_pin';
  static const _sessionKey = 'pin_session';
  static const _sessionDurationHours = 12;

  static Future<bool> hasPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _refreshSession();
  }

  static Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    if (storedPin == pin) {
      await _refreshSession();
      return true;
    }
    return false;
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt(_sessionKey);
    if (lastActivity == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastActivity;
    return diff < _sessionDurationHours * 60 * 60 * 1000;
  }

  static Future<void> _refreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await clearSession();
  }
}

