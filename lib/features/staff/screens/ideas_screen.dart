import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/network/api_client.dart';
import 'package:intl/intl.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});
  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  List<dynamic> ideas = [];
  bool loading = true;
  final _ctrl = TextEditingController();
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('/api/ideas');
      if (res.statusCode == 200 && mounted) {
        setState(() { ideas = jsonDecode(res.body); loading = false; });
      } else if (mounted) {
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => submitting = true);
    try {
      final res = await ApiClient.post('/api/ideas', {'idea': text, 'title': text});
      if (res.statusCode == 200 || res.statusCode == 201) {
        _ctrl.clear();
        _load();
      }
    } catch (_) {}
    if (mounted) setState(() => submitting = false);
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
        title: const Text('Ideas of the Week'),
        backgroundColor: Colors.amber.shade800,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          // Submit box
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Share your idea...',
                      prefixIcon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    minimumSize: const Size(60, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ideas.isEmpty
                    ? const Center(child: Text('No ideas yet. Share the first one!', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ideas.length,
                        itemBuilder: (context, i) {
                          final item = ideas[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                                    child: Icon(Icons.lightbulb, color: Colors.amber.shade800, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(item['submittedBy']?.toString() ?? item['userName']?.toString() ?? 'Staff',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ),
                                  Text(_formatDate(item['createdAt'] ?? item['date']),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ]),
                                const SizedBox(height: 8),
                                Text(item['idea']?.toString() ?? item['title']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 14)),
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


