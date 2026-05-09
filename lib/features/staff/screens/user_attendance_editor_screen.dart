import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

/// SuperAdmin-only screen: view & edit any employee's monthly attendance.
class UserAttendanceEditorScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserAttendanceEditorScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserAttendanceEditorScreen> createState() =>
      _UserAttendanceEditorScreenState();
}

class _UserAttendanceEditorScreenState
    extends State<UserAttendanceEditorScreen> {
  bool loading = true;
  List<dynamic> attendanceList = [];
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get(
          '/api/attendance/all?userId=${widget.userId}&year=$selectedYear&month=$selectedMonth');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          attendanceList = jsonDecode(res.body);
          loading = false;
        });
      } else if (mounted) {
        setState(() { attendanceList = []; loading = false; });
        _msg('Failed to load attendance (${res.statusCode})');
      }
    } catch (e) {
      if (mounted) setState(() { attendanceList = []; loading = false; });
      _msg('Error: $e');
    }
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editRecord(Map<String, dynamic> record) async {
    final overtimeCtrl = TextEditingController(
        text: (record['overtimeHours'] ?? 0).toString());
    final deductionCtrl = TextEditingController(
        text: (record['deductionHours'] ?? 0).toString());
    final otReasonCtrl = TextEditingController(
        text: record['overtimeReason'] ?? '');
    final dedReasonCtrl = TextEditingController(
        text: record['deductionReason'] ?? '');
    String selectedStatus = record['status'] ?? 'NOT_WORKING';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit – ${_formatDate(record["workDate"])}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status ──────────────────────────────────────
                const Text('Work Status',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(children: [
                    for (final s in ['WORKING', 'NOT_WORKING', 'HALF_DAY', 'LEAVE'])
                      RadioListTile<String>(
                        dense: true,
                        title: Text(s, style: const TextStyle(fontSize: 13)),
                        value: s,
                        groupValue: selectedStatus,
                        onChanged: (v) => ss(() => selectedStatus = v!),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Overtime ────────────────────────────────────
                _SectionBox(
                  color: Colors.green.shade50,
                  border: Colors.green.shade200,
                  icon: Icons.add_circle_outline,
                  iconColor: Colors.green.shade700,
                  label: 'Overtime Hours',
                  child: Column(children: [
                    _numField(overtimeCtrl, 'Hours (e.g. 2.5)'),
                    const SizedBox(height: 8),
                    _textField(otReasonCtrl, 'Reason'),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Deduction ───────────────────────────────────
                _SectionBox(
                  color: Colors.red.shade50,
                  border: Colors.red.shade200,
                  icon: Icons.remove_circle_outline,
                  iconColor: Colors.red.shade700,
                  label: 'Deduction Hours',
                  child: Column(children: [
                    _numField(deductionCtrl, 'Hours (e.g. 1.0)'),
                    const SizedBox(height: 8),
                    _textField(dedReasonCtrl, 'Reason'),
                  ]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _save(
        record['id'],
        selectedStatus,
        double.tryParse(overtimeCtrl.text) ?? 0,
        double.tryParse(deductionCtrl.text) ?? 0,
        otReasonCtrl.text.trim(),
        dedReasonCtrl.text.trim(),
      );
    }
  }

  Future<void> _save(
    int id,
    String status,
    double ot,
    double ded,
    String otReason,
    String dedReason,
  ) async {
    final res = await ApiClient.put(
      '/api/attendance/$id/admin-edit',
      {
        'status': status,
        'overtimeHours': ot,
        'deductionHours': ded,
        'overtimeReason': otReason,
        'deductionReason': dedReason,
      },
    );
    if (res.statusCode == 200) {
      _msg('Attendance updated ✓');
      _load();
    } else {
      _msg('Failed to update: ${res.body}');
    }
  }

  String _formatDate(dynamic raw) {
    try {
      DateTime d;
      if (raw is int)    d = DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
      else if (raw is String) {
        final ms = int.tryParse(raw);
        d = ms != null
            ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
            : DateTime.parse(raw).toUtc();
      } else {
        return raw?.toString() ?? 'N/A';
      }
      return DateFormat('dd MMM yyyy').format(d.toLocal());
    } catch (_) {
      return raw?.toString() ?? 'N/A';
    }
  }

  Color _statusColor(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'WORKING':     return Colors.green;
      case 'COMPLETED':   return Colors.blue;
      case 'CHECKED_IN':  return Colors.orange;
      case 'HALF_DAY':    return Colors.amber.shade700;
      case 'LEAVE':       return Colors.indigo;
      case 'NOT_WORKING': return Colors.grey;
      default:            return Colors.red;
    }
  }

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  Widget _numField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );

  Widget _textField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userName}'s Attendance"),
        actions: [
          // Month picker
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Select Month',
            onSelected: (m) { setState(() => selectedMonth = m); _load(); },
            itemBuilder: (_) => List.generate(12, (i) => PopupMenuItem(
              value: i + 1,
              child: Text(_months[i],
                  style: TextStyle(
                    fontWeight: selectedMonth == i + 1
                        ? FontWeight.bold : FontWeight.normal)),
            )),
          ),
          // Year picker
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Year',
            onSelected: (y) { setState(() => selectedYear = y); _load(); },
            itemBuilder: (_) => List.generate(5, (i) {
              final y = DateTime.now().year - i;
              return PopupMenuItem(
                value: y,
                child: Text(y.toString(),
                    style: TextStyle(
                      fontWeight: selectedYear == y
                          ? FontWeight.bold : FontWeight.normal)),
              );
            }),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : attendanceList.isEmpty
              ? Center(
                  child: Text(
                    'No records for ${_months[selectedMonth - 1]} $selectedYear',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Colors.blue.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_months[selectedMonth - 1]} $selectedYear',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text('${attendanceList.length} records',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: attendanceList.length,
                        itemBuilder: (_, i) {
                          final r = attendanceList[i];
                          final status = r['status'] ?? 'N/A';
                          final ot  = (r['overtimeHours']  ?? 0).toDouble();
                          final ded = (r['deductionHours'] ?? 0).toDouble();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => _editRecord(r),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(r['workDate']),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        Chip(
                                          label: Text(status,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _statusColor(status))),
                                          backgroundColor:
                                              _statusColor(status).withValues(alpha: 0.1),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    if (ot > 0 || ded > 0) ...[
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        if (ot > 0) ...[
                                          Icon(Icons.add_circle_outline,
                                              size: 14,
                                              color: Colors.green.shade700),
                                          const SizedBox(width: 4),
                                          Text('OT: ${ot}h',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green.shade700)),
                                          const SizedBox(width: 12),
                                        ],
                                        if (ded > 0) ...[
                                          Icon(Icons.remove_circle_outline,
                                              size: 14,
                                              color: Colors.red.shade700),
                                          const SizedBox(width: 4),
                                          Text('Deduction: ${ded}h',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red.shade700)),
                                        ],
                                      ]),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('Tap to edit',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue.shade600)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.edit,
                                            size: 13,
                                            color: Colors.blue.shade600),
                                      ],
                                    ),
                                  ],
                                ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SectionBox extends StatelessWidget {
  final Color color;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _SectionBox({
    required this.color,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }
}

