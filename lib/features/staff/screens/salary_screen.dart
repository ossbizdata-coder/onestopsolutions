import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});
  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  bool loading = true;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  double dailySalary = 0, hourlyRate = 0, deductionRatePerHour = 0;
  int totalDaysWorked = 0;
  double baseSalary = 0, totalCredits = 0, finalSalary = 0;
  double totalOTHours = 0, totalOTAmount = 0;
  double totalDeductionHours = 0, totalDeductionAmount = 0;
  List<dynamic> daily = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get(
          '/api/salary/me/monthly?year=$selectedYear&month=$selectedMonth');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        double unpaidCredits = 0;
        try {
          final cr = await ApiClient.get('/api/credits/me/summary');
          if (cr.statusCode == 200) {
            unpaidCredits =
                (jsonDecode(cr.body)['unpaidCredits'] ?? 0).toDouble();
          }
        } catch (_) {}

        final rawDaily = List.from(data['dailyBreakdown'] ?? []);
        rawDaily.sort((a, b) {
          int aTs = _ts(a['date']), bTs = _ts(b['date']);
          return bTs.compareTo(aTs);
        });

        double otH = 0, dedH = 0;
        int worked = 0;
        for (var d in rawDaily) {
          final s = d['status']?.toString() ?? '';
          if (s == 'WORKING' || s == 'CHECKED_IN' || s == 'COMPLETED') {
            worked++;
            otH += (d['overtimeHours'] ?? 0).toDouble();
            dedH += (d['deductionHours'] ?? 0).toDouble();
          }
        }
        final ds = (data['dailySalary'] ?? 0).toDouble();
        final hr = (data['hourlyRate'] ?? 0).toDouble();
        final dr = (data['deductionRatePerHour'] ?? hr).toDouble();
        final double base = worked.toDouble() * ds;
        final otAmt = otH * hr;
        final dedAmt = dedH * dr;

        if (!mounted) return;
        setState(() {
          dailySalary = ds;
          hourlyRate = hr;
          deductionRatePerHour = dr;
          totalDaysWorked = worked;
          totalOTHours = otH;
          totalOTAmount = otAmt;
          totalDeductionHours = dedH;
          totalDeductionAmount = dedAmt;
          totalCredits = unpaidCredits;
          baseSalary = base;
          finalSalary = base + otAmt - dedAmt - unpaidCredits;
          daily = rawDaily;
          loading = false;
        });
      } else {
        if (mounted) setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  int _ts(dynamic v) {
    if (v is int) return v;
    if (v is String) {
      final ms = int.tryParse(v);
      if (ms != null) return ms;
      try { return DateTime.parse(v).millisecondsSinceEpoch; } catch (_) {}
    }
    return 0;
  }

  String _fmtDate(dynamic v) {
    DateTime? d;
    if (v is int) {
      d = DateTime.fromMillisecondsSinceEpoch(v, isUtc: true)
          .add(const Duration(hours: 5, minutes: 30));
    } else if (v is String) {
      final ms = int.tryParse(v);
      if (ms != null) {
        d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
            .add(const Duration(hours: 5, minutes: 30));
      } else if (v.length == 10 && v.contains('-')) {
        final p = v.split('-');
        d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } else {
        d = DateTime.tryParse(v);
      }
    }
    if (d == null) return v?.toString() ?? '';
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth += offset;
      if (selectedMonth == 0) { selectedMonth = 12; selectedYear--; }
      else if (selectedMonth == 13) { selectedMonth = 1; selectedYear++; }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat.yMMMM().format(DateTime(selectedYear, selectedMonth));
    const primary = Color(0xFF1565C0); // Nice deep blue

    return Scaffold(
      appBar: AppBar(title: const Text('My Salary')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          onPressed: () => _changeMonth(-1)),
                      Text(monthLabel,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900)),
                      IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: () => _changeMonth(1)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [primary, primary.withOpacity(0.8)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Monthly Salary',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text('$totalDaysWorked days',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Rs ${NumberFormat('#,##0').format(finalSalary)}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold)),
                              const Divider(color: Colors.white30, height: 20),
                              _row('Base Salary', baseSalary, Colors.white70),
                              if (totalOTAmount > 0)
                                _row('Overtime', totalOTAmount,
                                    Colors.greenAccent.shade400,
                                    prefix: '+'),
                              if (totalDeductionAmount > 0)
                                _row('Deductions', totalDeductionAmount,
                                    Colors.orange.shade300,
                                    prefix: '-'),
                              if (totalCredits > 0)
                                _row('Credits', totalCredits,
                                    Colors.orange.shade300,
                                    prefix: '-'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Rs ${dailySalary.toStringAsFixed(0)}/day',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                    Text('OT: Rs ${hourlyRate.toStringAsFixed(0)}/hr',
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('Daily Breakdown',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),
                        if (daily.isEmpty)
                          const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No records this month',
                                      style: TextStyle(color: Colors.grey))))
                        else
                          ...daily
                              .where((d) => d['status'] != 'NOT_STARTED')
                              .map((d) {
                            final status = d['status']?.toString() ?? '';
                            final worked = status == 'WORKING' ||
                                status == 'CHECKED_IN' ||
                                status == 'COMPLETED';
                            final ot = (d['overtimeHours'] ?? 0).toDouble();
                            final ded =
                                (d['deductionHours'] ?? 0).toDouble();
                            final dayPay = worked
                                ? dailySalary +
                                    ot * hourlyRate -
                                    ded * deductionRatePerHour
                                : 0.0;
                            final color =
                                worked ? Colors.green : Colors.red;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8, left: 2, right: 2),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: color.withOpacity(0.15)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_fmtDate(d['date']),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(
                                          worked ? 'Worked' : 'Not Working',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: color,
                                              fontWeight: FontWeight.w600)),
                                      if (ot > 0)
                                        Text('+${ot.toStringAsFixed(1)}h OT',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.green)),
                                      if (ded > 0)
                                        Text(
                                            '-${ded.toStringAsFixed(1)}h deduction',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.red)),
                                    ],
                                  ),
                                  Text(
                                      'Rs ${NumberFormat('#,##0').format(dayPay)}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: primary)),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, double amount, Color color, {String prefix = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
              '${prefix.isNotEmpty ? '$prefix ' : ''}Rs ${NumberFormat('#,##0').format(amount)}',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
