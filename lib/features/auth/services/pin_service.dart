import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const _pinKey = 'app_pin';
  static const _sessionKey = 'pin_session';
  static const _sessionDurationHours = 12;

  static Future<bool> hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await _refreshSession();
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);
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
    return (now - lastActivity) < _sessionDurationHours * 60 * 60 * 1000;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await clearSession();
  }
}
