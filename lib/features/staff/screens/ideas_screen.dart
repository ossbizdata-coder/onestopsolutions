import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/network/api_client.dart';
import 'package:intl/intl.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<dynamic> items = [];
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
      final res = await ApiClient.get('/api/messages/idea');
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
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => submitting = true);
    try {
      final res = await ApiClient.post('/api/messages/idea', {'idea': text, 'title': text, 'content': text});
      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          _ctrl.clear();
          FocusScope.of(context).unfocus();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted!'), backgroundColor: Colors.green),
          );
          _load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed (${res.statusCode}). Try again.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        title: const Text('Feedback'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          // Submit box
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Share your feedback or idea...',
                      prefixIcon: const Icon(Icons.feedback_outlined),
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
                    minimumSize: const Size(52, 52),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(
                        child: Text('No feedback yet. Be the first!',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Color(0xFFE8F5E9),
                                      child: Icon(Icons.feedback_outlined, size: 16, color: Color(0xFF00A86B)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item['submittedBy']?.toString() ?? item['userName']?.toString() ?? 'Staff',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                    Text(_formatDate(item['createdAt'] ?? item['date']),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['idea']?.toString() ?? item['title']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
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

