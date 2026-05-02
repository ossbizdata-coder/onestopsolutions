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
            icon: const Icon(Icons.check_circle_outline),
            label: Text(isNotWorking ? '✏️ Change to Working' : 'YES — Working Today'),
            onPressed: () async {
              await AttendanceService.checkIn();
              _load();
            },
          ),
          const SizedBox(height: 8),
        ],
        if (!isNotWorking) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: Text(isWorking ? '✏️ Change to Day Off' : 'NO — Day Off'),
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
                padding: const EdgeInsets.all(16),
                children: [
                  // Today's card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today — ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _statusLabel(today),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(today),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Show action buttons — always allow changing status
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isWorking ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isWorking ? Icons.check_circle : Icons.cancel,
            color: isWorking ? Colors.green : Colors.red,
          ),
        ),
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(status),
        trailing: record['overtimeHours'] != null && record['overtimeHours'] > 0
            ? Chip(
                label: Text('+${record['overtimeHours']}h OT'),
                backgroundColor: Colors.orange.shade100,
              )
            : null,
      ),
    );
  }
}

