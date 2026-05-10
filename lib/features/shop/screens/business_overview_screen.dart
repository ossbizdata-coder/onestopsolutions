import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class BusinessOverviewScreen extends StatefulWidget {
  const BusinessOverviewScreen({super.key});
  @override
  State<BusinessOverviewScreen> createState() => _BusinessOverviewScreenState();
}

class _BusinessOverviewScreenState extends State<BusinessOverviewScreen> {
  bool loading = true;
  Map<String, dynamic>? cafe;
  Map<String, dynamic>? bookshop;
  Map<String, dynamic>? foodhut;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final today = DateFormat('yyyy-MM-md').format(DateTime.now());
    try {
      final results = await Future.wait([
        ApiClient.get('/api/transactions/department-summary?department=CAFE&date=$today'),
        ApiClient.get('/api/transactions/department-summary?department=BOOKSHOP&date=$today'),
        ApiClient.get('/api/transactions/department-summary?department=FOODHUT&date=$today'),
      ]);
      if (!mounted) return;
      setState(() {
        if (results[0].statusCode == 200) cafe = jsonDecode(results[0].body);
        if (results[1].statusCode == 200) bookshop = jsonDecode(results[1].body);
        if (results[2].statusCode == 200) foodhut = jsonDecode(results[2].body);
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  double _val(Map<String, dynamic>? m, String key) => (m?[key] ?? 0).toDouble();

  @override
  Widget build(BuildContext context) {
    final totalSales = _val(cafe, 'calculatedSales') + _val(bookshop, 'calculatedSales') + _val(foodhut, 'calculatedSales');
    final totalExpenses = _val(cafe, 'totalExpenses') + _val(bookshop, 'totalExpenses') + _val(foodhut, 'totalExpenses');
    final totalProfit = totalSales - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        title: const Text('Business Overview'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                children: [
                  // Today's headline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.indigo.shade500]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Today — ${DateFormat('EEE, MMM d').format(DateTime.now())}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _headlineStat('Total Sales', totalSales, Colors.white),
                        _headlineStat('Expenses', totalExpenses, Colors.orange.shade300),
                        _headlineStat('Profit', totalProfit, totalProfit >= 0 ? Colors.greenAccent : Colors.redAccent),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Per-shop cards
                  _shopCard('☕ Cafe', cafe, const Color(0xFF068A4B)),
                  const SizedBox(height: 8),
                  _shopCard('📚 Bookshop', bookshop, const Color(0xFF1565C0)),
                  const SizedBox(height: 8),
                  _shopCard('🍽️ Food Hut', foodhut, const Color(0xFFB65505)),
                ],
              ),
            ),
    );
  }

  Widget _headlineStat(String label, double value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      const SizedBox(height: 4),
      Text('Rs ${NumberFormat('#,##0').format(value)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    ]);
  }

  Widget _shopCard(String name, Map<String, dynamic>? data, Color color) {
    final sales = _val(data, 'calculatedSales');
    final expenses = _val(data, 'totalExpenses');
    final profit = sales - expenses;
    final credits = _val(data, 'totalCredits');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statItem('Sales', sales, color)),
          Expanded(child: _statItem('Expenses', expenses, Colors.red)),
          Expanded(child: _statItem('Profit', profit, profit >= 0 ? Colors.green : Colors.red)),
          if (credits > 0) Expanded(child: _statItem('Credits', credits, Colors.orange)),
        ]),
      ]),
    );
  }

  Widget _statItem(String label, double value, Color color) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      const SizedBox(height: 4),
      Text('Rs ${NumberFormat('#,##0').format(value)}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}
