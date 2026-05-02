import 'dart:convert';
import 'package:onestopsolutions/core/constants/api_constants.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class AttendanceService {
  static Future<Map<String, dynamic>?> getToday() async {
    final res = await ApiClient.get(ApiConstants.attendanceToday);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<bool> checkIn() async {
    final res = await ApiClient.post(ApiConstants.attendanceWorking, {});
    return res.statusCode == 200;
  }

  static Future<bool> markNotWorking() async {
    final res = await ApiClient.post(ApiConstants.attendanceNotWorking, {});
    return res.statusCode == 200;
  }

  static Future<List<dynamic>> getHistory() async {
    final res = await ApiClient.get(ApiConstants.attendanceHistory);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getAllAttendance() async {
    final res = await ApiClient.get(ApiConstants.attendanceAll);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }
}

