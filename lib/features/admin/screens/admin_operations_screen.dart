import 'package:flutter/material.dart';
import 'package:onestopsolutions/features/staff/screens/all_users_screen.dart';
import 'package:onestopsolutions/features/staff/screens/attendance_report_screen.dart';
import 'package:onestopsolutions/features/shop/screens/credits_screen.dart';
import 'package:onestopsolutions/features/shop/screens/shop_detail_screen.dart';
import 'package:onestopsolutions/features/shop/screens/expense_types_screen.dart';
import 'package:onestopsolutions/features/shop/screens/bank_deposits_screen.dart';
import 'package:onestopsolutions/features/admin/screens/audit_logs_screen.dart';

class AdminOperationsScreen extends StatelessWidget {
  const AdminOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _OpsSection('Staff Management', [
        _OpsItem('All Users', Icons.people_alt_rounded, const Color(0xFF1565C0),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen()))),
        _OpsItem('Attendance Report', Icons.calendar_month_rounded, const Color(0xFF6A1B9A),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceReportScreen()))),
      ]),
      _OpsSection('Financial Records', [
        _OpsItem('Credits (All)', Icons.credit_card_rounded, const Color(0xFFE60B31),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsScreen()))),
        _OpsItem('Bank Deposits', Icons.account_balance_rounded, const Color(0xFF2E7D32),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankDepositsScreen()))),
        _OpsItem('Expense Types', Icons.category_rounded, const Color(0xFF6A1B9A),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseTypesScreen()))),
      ]),
      _OpsSection('Shop Daily Entries', [
        _OpsItem('Cafe Entries', Icons.coffee_rounded, const Color(0xFF068A4B),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDetailScreen(shopCode: 'CAFE', shopName: 'Cafe')))),
        _OpsItem('Bookshop Entries', Icons.menu_book_rounded, const Color(0xFF1565C0),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDetailScreen(shopCode: 'BOOKSHOP', shopName: 'Bookshop')))),
        _OpsItem('Food Hut Entries', Icons.restaurant_rounded, const Color(0xFFB65505),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDetailScreen(shopCode: 'FOODHUT', shopName: 'Food Hut')))),
      ]),
      _OpsSection('System', [
        _OpsItem('Audit Logs', Icons.security_rounded, Colors.red.shade700,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen()))),
      ]),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: const Text('Admin Operations', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SuperAdmin access only. All actions are logged.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),

          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
              child: Text(section.title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500, letterSpacing: 0.5)),
            ),
            ...section.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 1.5,
                shadowColor: item.color.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Text(item.label,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14,
                          color: item.color.withValues(alpha: 0.6)),
                    ]),
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _OpsSection {
  final String title;
  final List<_OpsItem> items;
  const _OpsSection(this.title, this.items);
}

class _OpsItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OpsItem(this.label, this.icon, this.color, this.onTap);
}

