import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/features/staff/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic>? today;
  List<dynamic> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final t = await AttendanceService.getToday();
    final h = await AttendanceService.getHistory();
    if (!mounted) return;
    setState(() {
      today = t;
      history = h;
      loading = false;
    });
  }

  Widget _buildActionButtons() {
    final status = today?['status']?.toString().toUpperCase() ?? '';
    final isWorking = status == 'WORKING';
    final isNotWorking = status == 'NOT_WORKING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isWorking) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(isNotWorking ? 'Change to Working' : 'YES — Working Today'),
            onPressed: () async {
              await AttendanceService.checkIn();
              _load();
            },
          ),
          const SizedBox(height: 8),
        ],
        if (!isNotWorking) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined, size: 20),
            label: Text(isWorking ? 'Change to Day Off' : 'NO — Day Off'),
            onPressed: () async {
              await AttendanceService.markNotWorking();
              _load();
            },
          ),
        ],
      ],
    );
  }

  String _statusLabel(dynamic attendance) {
    if (attendance == null) return 'Not Recorded';
    final status = attendance['status']?.toString() ?? '';
    switch (status.toUpperCase()) {
      case 'WORKING': return '✅ Working';
      case 'NOT_WORKING': return '❌ Not Working';
      case 'HALF_DAY': return '🌗 Half Day';
      case 'LEAVE': return '🌴 Leave';
      default: return 'Not Started';
    }
  }

  Color _statusColor(dynamic attendance) {
    final status = (attendance != null ? attendance['status']?.toString().toUpperCase() : null) ?? '';
    switch (status) {
      case 'WORKING': return Colors.green;
      case 'NOT_WORKING': return Colors.red;
      case 'HALF_DAY': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                children: [
                  // Today's card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today — ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _statusLabel(today),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(today),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  ...history.map((record) => _HistoryTile(record: record)),
                ],
              ),
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final dynamic record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = record['workDate']?.toString() ?? '';
    final status = record['status']?.toString() ?? '';
    final isWorking = status.toUpperCase() == 'WORKING';

    return Card(
      margin: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isWorking ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isWorking ? Icons.check_circle : Icons.cancel,
            color: isWorking ? Colors.green : Colors.red,
            size: 18,
          ),
        ),
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(status, style: const TextStyle(fontSize: 12)),
        trailing: record['overtimeHours'] != null && record['overtimeHours'] > 0
            ? Chip(
                label: Text('+${record['overtimeHours']}h OT', style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.orange.shade50,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )
            : null,
      ),
    );
  }
}
