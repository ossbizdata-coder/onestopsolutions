import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/features/auth/services/auth_service.dart';
import 'package:onestopsolutions/features/auth/models/user_model.dart';
import 'package:onestopsolutions/features/shop/services/shop_service.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});
  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  static const _color = Color(0xFFE65D05);

  List<Map<String, dynamic>> allCredits = [];
  List<Map<String, dynamic>> filtered = [];
  bool loading = true;

  String shopFilter   = 'ALL';
  String statusFilter = 'ALL';
  String userFilter   = 'ALL';

  double totalAmount  = 0;
  double paidAmount   = 0;
  double unpaidAmount = 0;

  AppUser? currentUser;

  static const _shops = ['ALL', 'CAFE', 'BOOKSHOP', 'FOODHUT'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final user = await AuthService.getCurrentUser();
    final credits = await ShopService.getAllCredits();
    if (!mounted) return;
    setState(() {
      currentUser = user;
      allCredits = credits;
      loading = false;
      // Reset userFilter if the previously selected user no longer exists
      final names = credits.map(_userName).toSet();
      if (userFilter != 'ALL' && !names.contains(userFilter)) {
        userFilter = 'ALL';
      }
    });
    _applyFilters();
  }

  void _applyFilters() {
    if (!mounted) return;
    var list = allCredits.where((c) {
      final dept = (c['department'] ?? '').toString().toUpperCase();
      final isPaid = c['isPaid'] == true || c['is_paid'] == true || c['paid'] == true;
      final uName = _userName(c).toUpperCase();

      if (shopFilter != 'ALL' && dept != shopFilter) return false;
      if (statusFilter == 'PAID' && !isPaid) return false;
      if (statusFilter == 'UNPAID' && isPaid) return false;
      if (userFilter != 'ALL' && uName != userFilter.toUpperCase()) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      final da = _parseDate(a['transactionDate'] ?? a['transaction_date'] ?? a['createdAt'] ?? a['created_at']);
      final db = _parseDate(b['transactionDate'] ?? b['transaction_date'] ?? b['createdAt'] ?? b['created_at']);
      return db.compareTo(da);
    });

    double tot = 0, paid = 0, unpaid = 0;
    for (var c in list) {
      final amt = ((c['amount'] ?? 0) as num).toDouble();
      tot += amt;
      final isPaid = c['isPaid'] == true || c['is_paid'] == true || c['paid'] == true;
      if (isPaid) paid += amt; else unpaid += amt;
    }

    setState(() {
      filtered     = list;
      totalAmount  = tot;
      paidAmount   = paid;
      unpaidAmount = unpaid;
    });
  }

  String _userName(Map<String, dynamic> c) =>
      (c['userName'] ?? c['user_name'] ?? c['customerName'] ?? c['name'] ?? 'Unknown').toString();

  DateTime _parseDate(dynamic v) {
    try {
      if (v is int)    return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        final ms = int.tryParse(v);
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
        return DateTime.parse(v);
      }
    } catch (_) {}
    return DateTime(1970);
  }

  String _formatDate(dynamic v) {
    final d = _parseDate(v);
    if (d.year == 1970) return '—';
    return DateFormat('dd MMM yyyy').format(d);
  }

  List<String> get _uniqueUsers {
    final names = allCredits.map(_userName).toSet().toList()..sort();
    return ['ALL', ...names];
  }

  bool get _isAdmin =>
      currentUser?.role.toUpperCase() == 'ADMIN' ||
      currentUser?.role.toUpperCase() == 'SUPERADMIN';

  Future<void> _markPaid(Map<String, dynamic> c) async {
    final id = c['id'] as int?; if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Mark Rs ${NumberFormat('#,##0').format(c['amount'] ?? 0)} credit for ${_userName(c)} as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ShopService.markCreditPaid(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Marked as paid' : 'Failed')));
        if (ok) _load();
      }
    }
  }

  Future<void> _deleteCredit(Map<String, dynamic> c) async {
    final id = c['id'] as int?; if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Credit'),
        content: Text('Delete Rs ${NumberFormat('#,##0').format(c['amount'] ?? 0)} credit for ${_userName(c)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ShopService.deleteCredit(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Credit deleted' : 'Failed')));
        if (ok) _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _color,
        title: const Text('Credits', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(children: [
        // Summary banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          color: _color.withValues(alpha: 0.05),
          child: Row(children: [
            _amountChip('Total',  totalAmount,  Colors.blueGrey),
            const SizedBox(width: 4),
            _amountChip('Unpaid', unpaidAmount, Colors.red),
            const SizedBox(width: 4),
            _amountChip('Paid',   paidAmount,   Colors.green),
          ]),
        ),

        // Shop filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
          child: Row(children: [
            const Text('Shop: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ..._shops.map((s) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                label: Text(s, style: const TextStyle(fontSize: 10)),
                selected: shopFilter == s,
                onSelected: (_) { setState(() => shopFilter = s); _applyFilters(); },
                selectedColor: _color.withValues(alpha: 0.15),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                visualDensity: VisualDensity.compact,
              ),
            )),
          ]),
        ),

        // Status + Person filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
          child: Row(children: [
            // Status chips
            const Text('Status: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ...['ALL', 'UNPAID', 'PAID'].map((s) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                label: Text(s, style: const TextStyle(fontSize: 10)),
                selected: statusFilter == s,
                onSelected: (_) { setState(() => statusFilter = s); _applyFilters(); },
                selectedColor: s == 'PAID'
                    ? Colors.green.shade100
                    : s == 'UNPAID'
                        ? Colors.red.shade100
                        : _color.withValues(alpha: 0.15),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                visualDensity: VisualDensity.compact,
              ),
            )),
            const Spacer(),
            // Person dropdown
            const Text('Person: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: _color.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: userFilter,
                  isDense: true,
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                  items: _uniqueUsers.map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u == 'ALL' ? 'All' : u, style: const TextStyle(fontSize: 11)),
                  )).toList(),
                  onChanged: (v) { if (v != null) { setState(() => userFilter = v); _applyFilters(); } },
                ),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('No credits found', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final isPaid = c['isPaid'] == true || c['is_paid'] == true || c['paid'] == true;
                          final amount = ((c['amount'] ?? 0) as num).toDouble();
                          final dept   = (c['department'] ?? '').toString().toUpperCase();
                          final reason = (c['reason'] ?? c['description'] ?? c['note'] ?? '').toString();
                          final dateVal = c['transactionDate'] ?? c['transaction_date'] ?? c['createdAt'] ?? c['created_at'];
                          final name = _userName(c);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isPaid ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                                  child: Icon(
                                    isPaid ? Icons.check_circle : Icons.credit_card,
                                    color: isPaid ? Colors.green : Colors.red, size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    if (reason.isNotEmpty)
                                      Text(reason, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      if (dept.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: _color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(dept, style: TextStyle(fontSize: 9, color: _color, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(_formatDate(dateVal), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ]),
                                  ]),
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Rs ${NumberFormat('#,##0').format(amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14,
                                        color: isPaid ? Colors.green : Colors.red,
                                      )),
                                  const SizedBox(height: 4),
                                  if (!isPaid && _isAdmin)
                                    GestureDetector(
                                      onTap: () => _markPaid(c),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('Mark Paid',
                                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                                      ),
                                    )
                                  else if (isPaid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('PAID',
                                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  if (_isAdmin)
                                    GestureDetector(
                                      onTap: () => _deleteCredit(c),
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                      ),
                                    ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _amountChip(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          Text('Rs ${NumberFormat('#,##0').format(amount)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}
