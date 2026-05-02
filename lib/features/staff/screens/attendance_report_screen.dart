import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});
  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<dynamic> records = [];
  bool loading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    try {
      final res = await ApiClient.get('/api/attendance/all?date=$dateStr');
      if (res.statusCode == 200 && mounted) {
        setState(() { records = jsonDecode(res.body); loading = false; });
      } else if (mounted) {
        setState(() { records = []; loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { records = []; loading = false; });
    }
  }

  void _changeDate(int offset) {
    setState(() => selectedDate = selectedDate.add(Duration(days: offset)));
    _load();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WORKING': case 'CHECKED_IN': case 'COMPLETED': return Colors.green;
      case 'NOT_WORKING': return Colors.red;
      case 'HALF_DAY': return Colors.orange;
      case 'LEAVE': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'WORKING': case 'CHECKED_IN': case 'COMPLETED': return Icons.check_circle;
      case 'NOT_WORKING': return Icons.cancel;
      case 'HALF_DAY': return Icons.timelapse;
      case 'LEAVE': return Icons.beach_access;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d, yyyy').format(selectedDate);
    final workingCount = records.where((r) {
      final s = r['status']?.toString().toUpperCase() ?? '';
      return s == 'WORKING' || s == 'CHECKED_IN' || s == 'COMPLETED';
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: Colors.indigo,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          // Date nav
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
                Column(children: [
                  Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('$workingCount / ${records.length} working',
                      style: TextStyle(fontSize: 12, color: Colors.indigo.shade700)),
                ]),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      color: selectedDate.day == DateTime.now().day ? Colors.grey : null),
                  onPressed: selectedDate.day == DateTime.now().day ? null : () => _changeDate(1),
                ),
              ],
            ),
          ),
          // Summary chips
          if (records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _chip('Working', workingCount, Colors.green),
                  const SizedBox(width: 8),
                  _chip('Off', records.length - workingCount, Colors.red),
                ],
              ),
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                    ? const Center(child: Text('No attendance records for this date', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: records.length,
                        itemBuilder: (context, i) {
                          final r = records[i];
                          final status = r['status']?.toString() ?? '';
                          final ot = (r['overtimeHours'] ?? 0).toDouble();
                          final ded = (r['deductionHours'] ?? 0).toDouble();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(status).withOpacity(0.15),
                                child: Icon(_statusIcon(status), color: _statusColor(status), size: 20),
                              ),
                              title: Text(r['userName']?.toString() ?? r['name']?.toString() ?? 'Staff',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(status.isEmpty ? 'Not Recorded' : status,
                                  style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w500)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (ot > 0)
                                    Text('+${ot.toStringAsFixed(1)}h OT',
                                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                  if (ded > 0)
                                    Text('-${ded.toStringAsFixed(1)}h',
                                        style: const TextStyle(color: Colors.red, fontSize: 12)),
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

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('$label: $count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}


