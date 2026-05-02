import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/features/shop/services/shop_service.dart';

class ShopDetailScreen extends StatefulWidget {
  final String shopCode;
  final String shopName;
  const ShopDetailScreen({super.key, required this.shopCode, required this.shopName});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  Map<String, dynamic>? summary;
  bool loading = true;
  DateTime selectedDate = DateTime.now();

  Color get shopColor {
    switch (widget.shopCode) {
      case 'CAFE': return const Color(0xFF068A4B);
      case 'BOOKSHOP': return const Color(0xFF1565C0);
      default: return const Color(0xFFB65505);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final data = await ShopService.getDepartmentSummary(widget.shopCode, date: dateStr);
    if (!mounted) return;
    setState(() {
      summary = data;
      loading = false;
    });
  }

  Widget _infoTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Rs ${double.tryParse(value.toString())?.toStringAsFixed(0) ?? value}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: shopColor,
        title: Text(widget.shopName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: shopColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
                            _load();
                          },
                        ),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: selectedDate.day == DateTime.now().day ? Colors.grey : null),
                          onPressed: selectedDate.day == DateTime.now().day ? null : () {
                            setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (summary != null) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _infoTile('Opening Balance', summary!['openingBalance'].toString(), Colors.blue),
                        _infoTile('Closing Balance', summary!['closingBalance'].toString(), Colors.green),
                        _infoTile('Total Sales', summary!['calculatedSales'].toString(), shopColor),
                        _infoTile('Total Expenses', summary!['totalExpenses'].toString(), Colors.red),
                        _infoTile('Credits', summary!['totalCredits'].toString(), Colors.orange),
                        _infoTile('Profit', summary!['profit'].toString(), Colors.green.shade800),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if ((summary!['expenseItems'] as List?)?.isNotEmpty == true) ...[
                      const Text('Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...(summary!['expenseItems'] as List).map((e) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          leading: const Icon(Icons.remove_circle, color: Colors.red),
                          title: Text(e['expenseTypeName'] ?? 'Expense'),
                          subtitle: e['comment'] != null ? Text(e['comment']) : null,
                          trailing: Text('Rs ${e['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )),
                    ],
                  ] else
                    const Center(child: Text('No data for this date')),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: shopColor,
        onPressed: () {
          // TODO: Open add transaction dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add transaction dialog — coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

