import 'dart:convert';
import 'package:onestopsolutions/core/constants/api_constants.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class FoodHutService {
  static Future<Map<String, dynamic>?> getTodaySummary(String date) async {
    final res = await ApiClient.get('${ApiConstants.salesSummary}?date=$date');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<List<dynamic>> getSalesForDay(String date) async {
    final res = await ApiClient.get(ApiConstants.salesForDay(date));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getAllItems() async {
    final res = await ApiClient.get(ApiConstants.items);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> recordSale(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.sales, data);
    return res.statusCode == 200 || res.statusCode == 201;
  }
}

