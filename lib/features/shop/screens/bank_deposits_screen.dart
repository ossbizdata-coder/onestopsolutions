import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class BankDepositsScreen extends StatefulWidget {
  const BankDepositsScreen({super.key});
  @override
  State<BankDepositsScreen> createState() => _BankDepositsScreenState();
}

class _BankDepositsScreenState extends State<BankDepositsScreen> {
  List<dynamic> deposits = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('/api/admin/daily-cash');
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          deposits = data is List ? data : (data['content'] ?? data['data'] ?? []);
          loading = false;
        });
      } else if (mounted) {
        setState(() { deposits = []; loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { deposits = []; loading = false; });
    }
  }

  String _formatDate(dynamic v) {
    try {
      if (v is int) return DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(v));
      if (v is String) {
        final ms = int.tryParse(v);
        if (ms != null) return DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));
        return DateFormat('dd MMM yyyy').format(DateTime.parse(v));
      }
    } catch (_) {}
    return v?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.green.shade700;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('Bank Deposits'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : deposits.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.account_balance, size: 64, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text('No bank deposits recorded', style: TextStyle(color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deposits.length,
                  itemBuilder: (context, i) {
                    final d = deposits[i];
                    final dept = d['department']?.toString() ?? d['shopCode']?.toString() ?? '';
                    final amount = (d['bankDeposit'] ?? d['amount'] ?? 0).toDouble();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(Icons.account_balance, color: color, size: 20),
                        ),
                        title: Text(_formatDate(d['date'] ?? d['createdAt']),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(dept.isNotEmpty ? dept : 'All Shops'),
                        trailing: Text('Rs ${amount.toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                      ),
                    );
                  },
                ),
    );
  }
}


