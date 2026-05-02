import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class StaffPerformanceScreen extends StatefulWidget {
  const StaffPerformanceScreen({super.key});
  @override
  State<StaffPerformanceScreen> createState() => _StaffPerformanceScreenState();
}

class _StaffPerformanceScreenState extends State<StaffPerformanceScreen> {
  static const _purple = Color(0xFF6A1B9A);

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  List<_StaffStat> _stats = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  int get _workingDaysInMonth {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    // Count Mon–Sat as working days (exclude Sunday)
    int count = 0;
    for (int d = 1; d <= lastDay; d++) {
      final wd = DateTime(year, month, d).weekday;
      if (wd != DateTime.sunday) count++;
    }
    return count;
  }

  int get _workingDaysSoFar {
    if (!_isCurrentMonth) return _workingDaysInMonth;
    final today = DateTime.now().day;
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    int count = 0;
    for (int d = 1; d <= today; d++) {
      final wd = DateTime(year, month, d).weekday;
      if (wd != DateTime.sunday) count++;
    }
    return count;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final year  = _selectedMonth.year;
      final month = _selectedMonth.month;

      // Fetch all users + their attendance report for the month
      final usersRes  = await ApiClient.get('/api/auth/all-users');
      final attRes    = await ApiClient.get('/api/attendance/report?month=$month&year=$year');

      if (!mounted) return;

      List<dynamic> users = [];
      Map<int, int> workingDaysMap = {}; // userId -> count of WORKING days

      if (usersRes.statusCode == 200) {
        users = jsonDecode(usersRes.body);
      }

      if (attRes.statusCode == 200) {
        final attData = jsonDecode(attRes.body);
        // Expected: list of {userId, status, date} OR map of userId -> list
        if (attData is List) {
          for (final a in attData) {
            final uid   = a['userId'] ?? a['user_id'];
            final status = (a['status'] ?? '').toString().toUpperCase();
            if (uid != null && status == 'WORKING') {
              workingDaysMap[uid] = (workingDaysMap[uid] ?? 0) + 1;
            }
          }
        } else if (attData is Map) {
          attData.forEach((key, val) {
            final uid = int.tryParse(key.toString());
            if (uid != null && val is List) {
              int cnt = val.where((a) => (a['status'] ?? '').toString().toUpperCase() == 'WORKING').length;
              workingDaysMap[uid] = cnt;
            }
          });
        }
      }

      final targetDays = _workingDaysInMonth;
      final soFar      = _workingDaysSoFar;

      final stats = <_StaffStat>[];
      for (final u in users) {
        final role = (u['role'] ?? '').toString().toUpperCase();
        if (role == 'CUSTOMER') continue; // skip customers
        final uid  = u['id'] as int? ?? 0;
        final name = (u['name'] ?? u['username'] ?? 'Unknown').toString();
        final worked = workingDaysMap[uid] ?? 0;
        stats.add(_StaffStat(
          name: name,
          role: role,
          workedDays: worked,
          targetDays: targetDays,
          soFarDays:  soFar,
        ));
      }
      // Sort: lowest performance first
      stats.sort((a, b) => a.percentage.compareTo(b.percentage));

      setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _prevMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    _load();
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: _purple,
        title: const Text('Staff Performance', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(children: [
        // Month switcher
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth, color: _purple),
              Column(children: [
                Text(DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _purple)),
                Text('Target: $_workingDaysInMonth working days (so far: $_workingDaysSoFar)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    color: _isCurrentMonth ? Colors.grey.shade300 : _purple),
                onPressed: _isCurrentMonth ? null : _nextMonth,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                  : _stats.isEmpty
                      ? const Center(child: Text('No staff data', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            itemCount: _stats.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => _StaffCard(stat: _stats[i]),
                          ),
                        ),
        ),
      ]),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────
class _StaffStat {
  final String name;
  final String role;
  final int workedDays;
  final int targetDays;
  final int soFarDays;

  const _StaffStat({
    required this.name,
    required this.role,
    required this.workedDays,
    required this.targetDays,
    required this.soFarDays,
  });

  /// % against days elapsed so far (fair comparison mid-month)
  double get percentage => soFarDays == 0 ? 0 : (workedDays / soFarDays).clamp(0.0, 1.0);
  double get monthPercentage => targetDays == 0 ? 0 : (workedDays / targetDays).clamp(0.0, 1.0);

  Color get statusColor {
    if (percentage >= 0.9) return const Color(0xFF2E7D32); // green
    if (percentage >= 0.7) return const Color(0xFFF57F17); // amber
    return const Color(0xFFC62828); // red
  }

  String get statusLabel {
    if (percentage >= 0.9) return 'On Track';
    if (percentage >= 0.7) return 'Moderate';
    return 'Low';
  }

  IconData get statusIcon {
    if (percentage >= 0.9) return Icons.check_circle_rounded;
    if (percentage >= 0.7) return Icons.warning_amber_rounded;
    return Icons.cancel_rounded;
  }
}

// ─── Staff Performance Card ───────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final _StaffStat stat;
  const _StaffCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stat.statusColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(
            backgroundColor: stat.statusColor.withValues(alpha: 0.12),
            radius: 20,
            child: Text(
              stat.name.isNotEmpty ? stat.name[0].toUpperCase() : '?',
              style: TextStyle(color: stat.statusColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(stat.role, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: stat.statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(stat.statusIcon, size: 12, color: Colors.white),
              const SizedBox(width: 3),
              Text(stat.statusLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),

        // Progress bar
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stat.percentage,
                backgroundColor: stat.statusColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(stat.statusColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(stat.percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: stat.statusColor),
          ),
        ]),
        const SizedBox(height: 6),

        // Stats row
        Row(children: [
          _statChip('Worked', '${stat.workedDays}d', Colors.blueGrey),
          const SizedBox(width: 8),
          _statChip('Expected', '${stat.soFarDays}d', Colors.orange.shade700),
          const SizedBox(width: 8),
          _statChip('Monthly Target', '${stat.targetDays}d', Colors.purple.shade700),
        ]),
      ]),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8))),
      ]),
    );
  }
}

