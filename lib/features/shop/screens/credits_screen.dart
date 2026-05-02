import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});
  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  List<dynamic> credits = [];
  bool loading = true;
  String filter = 'ALL';
  double totalUnpaid = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('/api/credits');
      if (res.statusCode == 200 && mounted) {
        final all = List.from(jsonDecode(res.body));
        final unpaid = all.where((c) => c['paid'] == false || c['paid'] == null).toList();
        final total = unpaid.fold<double>(0, (sum, c) => sum + (c['amount'] ?? 0).toDouble());
        setState(() { credits = all; totalUnpaid = total; loading = false; });
      } else if (mounted) {
        setState(() { credits = []; loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { credits = []; loading = false; });
    }
  }

  Future<void> _markPaid(int id) async {
    final res = await ApiClient.put('/api/credits/$id/pay', {});
    if (res.statusCode == 200) _load();
  }

  List<dynamic> get _filtered {
    if (filter == 'UNPAID') return credits.where((c) => c['paid'] == false || c['paid'] == null).toList();
    if (filter == 'PAID') return credits.where((c) => c['paid'] == true).toList();
    return credits;
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
    const color = Color(0xFFE60B31);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('Credits'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          if (totalUnpaid > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 10),
                Text('Total Unpaid: Rs ${totalUnpaid.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['ALL', 'UNPAID', 'PAID'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
                  selectedColor: color.withOpacity(0.15),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No credits found', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final paid = c['paid'] == true;
                          final amount = (c['amount'] ?? 0).toDouble();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                CircleAvatar(
                                  backgroundColor: paid ? Colors.green.shade50 : Colors.red.shade50,
                                  child: Icon(paid ? Icons.check_circle : Icons.credit_card,
                                      color: paid ? Colors.green : Colors.red, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['customerName']?.toString() ?? c['name']?.toString() ?? 'Customer',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(_formatDate(c['date'] ?? c['createdAt']),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  if (c['note'] != null)
                                    Text(c['note'].toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Rs ${amount.toStringAsFixed(0)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                                          color: paid ? Colors.green : Colors.red)),
                                  if (!paid)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        backgroundColor: Colors.green.shade50,
                                      ),
                                      onPressed: () => _markPaid(c['id'] as int),
                                      child: const Text('Mark Paid', style: TextStyle(fontSize: 11, color: Colors.green)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('PAID', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
