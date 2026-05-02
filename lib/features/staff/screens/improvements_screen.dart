import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/network/api_client.dart';
import 'package:intl/intl.dart';

class ImprovementsScreen extends StatefulWidget {
  const ImprovementsScreen({super.key});
  @override
  State<ImprovementsScreen> createState() => _ImprovementsScreenState();
}

class _ImprovementsScreenState extends State<ImprovementsScreen> {
  List<dynamic> items = [];
  bool loading = true;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('/api/improvements');
      if (res.statusCode == 200 && mounted) {
        setState(() { items = jsonDecode(res.body); loading = false; });
      } else if (mounted) {
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => submitting = true);
    try {
      final res = await ApiClient.post('/api/improvements', {'title': title, 'description': desc});
      if (res.statusCode == 200 || res.statusCode == 201) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _load();
      }
    } catch (_) {}
    if (mounted) setState(() => submitting = false);
  }

  void _showSubmitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suggest an Improvement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              onPressed: submitting ? null : () { Navigator.pop(context); _submit(); },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Improvements'),
        backgroundColor: Colors.blue.shade700,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        onPressed: _showSubmitSheet,
        icon: const Icon(Icons.add),
        label: const Text('Suggest'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.build_circle_outlined, size: 64, color: Colors.blue.shade200),
                  const SizedBox(height: 16),
                  const Text('No improvements yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Tap + to suggest an improvement', style: TextStyle(color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final status = item['status']?.toString() ?? 'PENDING';
                    final statusColor = status == 'DONE' ? Colors.green
                        : status == 'IN_PROGRESS' ? Colors.blue
                        : Colors.orange;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(item['title']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(item['description'].toString(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(item['submittedBy']?.toString() ?? item['userName']?.toString() ?? 'Staff',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const Spacer(),
                            Text(_formatDate(item['createdAt'] ?? item['date']),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}


