import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class ExpenseTypesScreen extends StatefulWidget {
  const ExpenseTypesScreen({super.key});
  @override
  State<ExpenseTypesScreen> createState() => _ExpenseTypesScreenState();
}

class _ExpenseTypesScreenState extends State<ExpenseTypesScreen> {
  List<dynamic> types = [];
  bool loading = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('/api/expense-types');
      if (res.statusCode == 200 && mounted) {
        setState(() { types = jsonDecode(res.body); loading = false; });
      } else if (mounted) {
        setState(() { types = []; loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { types = []; loading = false; });
    }
  }

  Future<void> _add() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    final res = await ApiClient.post('/api/expense-types', {'name': name});
    if (res.statusCode == 200 || res.statusCode == 201) {
      _ctrl.clear();
      _load();
    }
  }

  Future<void> _delete(int id) async {
    final res = await ApiClient.delete('/api/expense-types/$id');
    if (res.statusCode == 200 || res.statusCode == 204) _load();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Expense Type'),
        content: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Electricity, Salary, Supplies'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _add(); },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.purple.shade600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: const Text('Expense Types'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : types.isEmpty
              ? const Center(child: Text('No expense types. Tap + to add.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: types.length,
                  itemBuilder: (context, i) {
                    final t = types[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(Icons.category, color: color, size: 18),
                        ),
                        title: Text(t['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _delete(t['id'] as int),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


