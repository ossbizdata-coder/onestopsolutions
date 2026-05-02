import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/features/foodhut/services/foodhut_service.dart';

class FoodHutMainScreen extends StatefulWidget {
  const FoodHutMainScreen({super.key});

  @override
  State<FoodHutMainScreen> createState() => _FoodHutMainScreenState();
}

class _FoodHutMainScreenState extends State<FoodHutMainScreen> {
  static const _green = Color(0xFF21C36F);
  static const _orange = Color(0xFFFF9F3A);
  static const _blue = Color(0xFF2196F3);

  DateTime selectedDate = DateTime.now();
  bool loading = true;
  Map<String, dynamic>? summary;
  List<dynamic> sales = [];

  int preparedAmount = 0;
  int remainingAmount = 0;
  int soldAmount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(selectedDate);
  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final s = await FoodHutService.getTodaySummary(_dateStr);
    final sl = await FoodHutService.getSalesForDay(_dateStr);
    if (!mounted) return;

    int prepared = 0, remaining = 0;
    for (var sale in sl) {
      final qty = (sale['quantity'] ?? 0) as int;
      final price = (sale['price'] ?? 0) as int;
      final type = sale['actionType']?.toString() ?? '';
      if (type == 'PREPARED') prepared += qty * price;
      if (type == 'REMAINING') remaining += qty * price;
    }

    setState(() {
      summary = s;
      sales = sl;
      preparedAmount = prepared;
      remainingAmount = remaining;
      soldAmount = prepared - remaining;
      loading = false;
    });
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.day == now.day && d.month == now.month) return 'Today';
    if (d.day == yesterday.day && d.month == yesterday.month) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: _green,
        title: const Text('Food Hut Kitchen', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: _green,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _green.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: _green),
                          onPressed: () {
                            setState(() { selectedDate = selectedDate.subtract(const Duration(days: 1)); loading = true; });
                            _load();
                          },
                        ),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: _green),
                            const SizedBox(width: 8),
                            Text(_formatDate(selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: _isToday ? Colors.grey : _green),
                          onPressed: _isToday ? null : () {
                            setState(() { selectedDate = selectedDate.add(const Duration(days: 1)); loading = true; });
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(child: _summaryCard('Prepared', preparedAmount, Icons.restaurant_menu, _green)),
                      const SizedBox(width: 8),
                      Expanded(child: _summaryCard('Sold', soldAmount, Icons.trending_up, _blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _summaryCard('Remaining', remainingAmount, Icons.inventory_2_outlined, _orange)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  _actionButton('Add Prepared Item', Icons.add_circle_outline, _green,
                      enabled: _isToday, onTap: () => _showSnack('Add Prepared — opening soon')),
                  const SizedBox(height: 12),
                  _actionButton('Add Remaining Item', Icons.inventory_2_outlined, _orange,
                      enabled: _isToday, onTap: () => _showSnack('Add Remaining — opening soon')),
                  const SizedBox(height: 12),
                  _actionButton('View Menu Items', Icons.restaurant_menu, const Color(0xFF7007B6),
                      onTap: () => _showSnack('Menu items — opening soon')),
                  const SizedBox(height: 20),

                  // Sales List
                  if (sales.isNotEmpty) ...[
                    const Text('Today\'s Entries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...sales.map((s) => _SaleTile(sale: s)),
                  ],
                ],
              ),
            ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _summaryCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _actionButton(String title, IconData icon, Color color, {bool enabled = true, VoidCallback? onTap}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white))),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final dynamic sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final type = sale['actionType']?.toString() ?? '';
    final color = type == 'PREPARED'
        ? const Color(0xFF21C36F)
        : type == 'REMAINING'
            ? const Color(0xFFFF9F3A)
            : Colors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.fastfood, color: color, size: 20)),
        title: Text('${sale['itemName']} (${sale['variation']})',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(type, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${sale['quantity']}x', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Rs ${sale['price']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

