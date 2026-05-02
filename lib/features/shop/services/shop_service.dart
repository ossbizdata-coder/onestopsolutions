import 'dart:convert';
import 'package:onestopsolutions/core/network/api_client.dart';

class ShopService {
  static int getShopId(String code) {
    switch (code.toUpperCase()) {
      case 'CAFE':
        return 1;
      case 'BOOKSHOP':
        return 2;
      case 'FOODHUT':
        return 3;
      default:
        return 1;
    }
  }

  static Future<Map<String, dynamic>?> getDailyCash(int shopId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final res = await ApiClient.get('/api/daily-cash/$shopId/$dateStr');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<bool> openDailyCash(int shopId, DateTime date, double openingCash,
      {bool userConfirmed = false}) async {
    final data = await getDailyCash(shopId, date);
    if (data == null || data['dailyCashId'] == null) return false;
    final id = data['dailyCashId'];
    final res = await ApiClient.patch('/api/daily-cash/$id/opening', {
      'openingCash': openingCash,
      'userConfirmed': userConfirmed,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> closeDailyCash(int dailyCashId, double closingCash) async {
    final res = await ApiClient.post('/api/daily-cash/$dailyCashId/close', {
      'closingCash': closingCash,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> addExpense({
    required int dailyCashId, required double amount,
    required int expenseTypeId, String? description,
  }) async {
    final res = await ApiClient.post('/api/daily-cash/$dailyCashId/expenses', {
      'amount': amount, 'expenseTypeId': expenseTypeId,
      if (description != null) 'description': description,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> addSale({
    required int dailyCashId, required double amount, String? description,
  }) async {
    final res = await ApiClient.post('/api/daily-cash/$dailyCashId/sales', {
      'amount': amount,
      if (description != null) 'description': description,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> updateTransaction(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('/api/admin/transactions/$id', data);
    return res.statusCode == 200;
  }

  static Future<bool> deleteTransaction(int id) async {
    final res = await ApiClient.delete('/api/admin/transactions/$id');
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<bool> addCredit({
    required int userId, required double amount, required String reason,
    required String department, int? shopId, DateTime? transactionDate,
  }) async {
    final res = await ApiClient.post('/api/credits', {
      'userId': userId, 'amount': amount, 'reason': reason, 'department': department,
      if (shopId != null) 'shopId': shopId,
      if (transactionDate != null)
        'transactionDate': transactionDate.toIso8601String().split('T')[0],
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> updateCredit(int creditId,
      {required double amount, required String reason, bool isPaid = false}) async {
    final res = await ApiClient.put('/api/credits/$creditId/edit',
        {'amount': amount, 'reason': reason, 'isPaid': isPaid});
    return res.statusCode == 200;
  }

  static Future<bool> deleteCredit(int creditId) async {
    final res = await ApiClient.delete('/api/credits/$creditId');
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<List<Map<String, dynamic>>> getExpenseTypesForShop(String shopCode) async {
    final res = await ApiClient.get('/api/expense-types');
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    List raw = decoded is List ? decoded : (decoded['data'] ?? []);
    final all = raw.cast<Map<String, dynamic>>();
    return all.where((t) {
      final s = (t['shopCode'] ?? t['shop'] ?? '').toString().toUpperCase();
      return s.isEmpty || s == 'ALL' || s == shopCode.toUpperCase();
    }).toList()
      ..sort((a, b) => (a['name'] ?? '').toString()
          .toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final res = await ApiClient.get('/api/auth/all-users');
    if (res.statusCode != 200) return [];
    final List raw = jsonDecode(res.body);
    return raw.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getAllCredits() async {
    final res = await ApiClient.get('/api/credits');
    if (res.statusCode != 200) return [];
    final List raw = jsonDecode(res.body);
    return raw.cast<Map<String, dynamic>>();
  }

  static Future<bool> markCreditPaid(int creditId) async {
    final res = await ApiClient.put('/api/credits/$creditId/pay', {});
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getDepartmentSummary(String shopCode,
      {String? date}) async {
    var url = '/api/transactions/department-summary?department=$shopCode';
    if (date != null) url += '&date=$date';
    final res = await ApiClient.get(url);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  /// Returns the latest closing balance for a shop (like OSD's getLatestClosingBalance)
  static Future<double> getLatestClosingBalance(int shopId) async {
    try {
      final res = await ApiClient.get('/api/daily-cash/$shopId/latest-closing-balance');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['closingBalance'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  /// Returns sum of all unpaid credit amounts across all shops
  static Future<double> getUnpaidCreditsTotal() async {
    try {
      final res = await ApiClient.get('/api/credits/unpaid');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        double total = 0.0;
        for (var item in data) {
          total += (item['amount'] as num?)?.toDouble() ?? 0.0;
        }
        return total;
      }
    } catch (_) {}
    return 0.0;
  }
}
