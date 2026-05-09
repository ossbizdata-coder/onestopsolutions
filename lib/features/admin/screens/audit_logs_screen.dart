import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';
import 'package:onestopsolutions/core/constants/api_constants.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<dynamic> _logs = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _actionFilter;
  static const _actions = ['CREATE', 'UPDATE', 'DELETE', 'LOGIN'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.get(ApiConstants.auditLogs);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (!mounted) return;
        setState(() { _logs = data; _applyFilter(); _loading = false; });
      } else {
        if (!mounted) return;
        setState(() { _error = 'Server returned ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    var list = List<dynamic>.from(_logs);
    if (_actionFilter != null) {
      list = list.where((l) => l['action'] == _actionFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((l) =>
        (l['description'] ?? '').toString().toLowerCase().contains(q) ||
        (l['userName'] ?? '').toString().toLowerCase().contains(q) ||
        (l['entityType'] ?? '').toString().toLowerCase().contains(q) ||
        (l['action'] ?? '').toString().toLowerCase().contains(q),
      ).toList();
    }
    _filtered = list;
  }

  Color _actionColor(String? action) {
    switch (action) {
      case 'CREATE': return Colors.green;
      case 'UPDATE': return Colors.blue;
      case 'DELETE': return Colors.red;
      case 'LOGIN':  return Colors.purple;
      default:       return Colors.grey;
    }
  }

  IconData _actionIcon(String? action) {
    switch (action) {
      case 'CREATE': return Icons.add_circle_outline;
      case 'UPDATE': return Icons.edit_outlined;
      case 'DELETE': return Icons.delete_outline;
      case 'LOGIN':  return Icons.login;
      default:       return Icons.info_outline;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('MMM d, hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: const Text('Audit Logs'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by user, action, description…',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
            ),
          ),
          // Action filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              _chip('All', null),
              ..._actions.map((a) => _chip(a, a)),
            ]),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(children: [
                Text('${_filtered.length} entries',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ]))
                    : _filtered.isEmpty
                        ? Center(child: Text('No audit logs found',
                            style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final log = _filtered[i];
                              final action = log['action']?.toString() ?? '';
                              final color = _actionColor(action);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(_actionIcon(action), color: color, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                                              child: Text(action,
                                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                            ),
                                            const SizedBox(width: 6),
                                            Text((log['entityType'] ?? '').toString().replaceAll('_', ' '),
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                          ]),
                                          const SizedBox(height: 4),
                                          if ((log['description'] ?? '').toString().isNotEmpty)
                                            Text(log['description'].toString(),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Row(children: [
                                            Icon(Icons.person_outline, size: 12, color: Colors.grey.shade400),
                                            const SizedBox(width: 3),
                                            Text(log['userName']?.toString() ?? 'Unknown',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            const Spacer(),
                                            Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                                            const SizedBox(width: 3),
                                            Text(_formatTime(log['createdAt']?.toString()),
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                          ]),
                                        ],
                                      )),
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

  Widget _chip(String label, String? value) {
    final selected = _actionFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        selected: selected,
        onSelected: (_) => setState(() { _actionFilter = value; _applyFilter(); }),
        selectedColor: Colors.red.shade700,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        side: BorderSide(color: selected ? Colors.red.shade700 : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
