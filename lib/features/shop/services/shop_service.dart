import 'dart:convert';
import 'package:onestopsolutions/core/constants/api_constants.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class ShopService {
  static Future<Map<String, dynamic>?> getDepartmentSummary(String shopCode, {String? date}) async {
    var url = '${ApiConstants.transactionsDeptSummary}?department=$shopCode';
    if (date != null) url += '&date=$date';
    final res = await ApiClient.get(url);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<double> getLatestClosingBalance(String shopCode) async {
    final res = await ApiClient.get('${ApiConstants.transactionsCashTotal}?department=$shopCode');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['cashTotal'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  static Future<List<dynamic>> getTransactionsByDate(String shopCode, String date) async {
    final res = await ApiClient.get('${ApiConstants.transactionsByDate}?department=$shopCode&date=$date');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> addTransaction(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.transactions, data);
    return res.statusCode == 200;
  }
}

