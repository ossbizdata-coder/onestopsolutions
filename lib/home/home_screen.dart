import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/theme/app_theme.dart';
import 'package:onestopsolutions/features/auth/models/user_model.dart';
import 'package:onestopsolutions/features/auth/services/auth_service.dart';
import 'package:onestopsolutions/features/auth/services/pin_service.dart';
import 'package:onestopsolutions/features/auth/screens/login_screen.dart';
import 'package:onestopsolutions/features/staff/screens/attendance_screen.dart';
import 'package:onestopsolutions/features/staff/screens/salary_screen.dart';
import 'package:onestopsolutions/features/staff/screens/all_users_screen.dart';
import 'package:onestopsolutions/features/staff/screens/ideas_screen.dart';
import 'package:onestopsolutions/features/staff/screens/improvements_screen.dart';
import 'package:onestopsolutions/features/staff/screens/attendance_report_screen.dart';
import 'package:onestopsolutions/features/shop/screens/shop_detail_screen.dart';
import 'package:onestopsolutions/features/shop/screens/credits_screen.dart';
import 'package:onestopsolutions/features/shop/screens/bank_deposits_screen.dart';
import 'package:onestopsolutions/features/shop/screens/expense_types_screen.dart';
import 'package:onestopsolutions/features/shop/screens/business_overview_screen.dart';
import 'package:onestopsolutions/features/foodhut/screens/foodhut_main_screen.dart';
import 'package:onestopsolutions/features/admin/screens/audit_logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? currentUser;
  bool loading = true;
  Map<String, double> shopBalances = {'CAFE': 0, 'BOOKSHOP': 0, 'FOODHUT': 0};
  double unpaidCredits = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => loading = true);
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      currentUser = user;
      loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    await PinService.clearPin();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPERADMIN': return Colors.purple.shade700;
      case 'ADMIN': return Colors.blue.shade700;
      case 'STAFF': return Colors.green.shade700;
      default: return Colors.orange.shade700;
    }
  }

  List<_ModuleSection> _buildSections() {
    if (currentUser == null) return [];
    final sections = <_ModuleSection>[];

    // ── STAFF MODULE ──────────────────────────────────────
    final staffItems = <_MenuItem>[
      _MenuItem('Attendance', Icons.access_time_filled_rounded, AppTheme.staffColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()))),
      _MenuItem('My Salary', Icons.monetization_on_rounded, Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryScreen()))),
      _MenuItem('Idea of Week', Icons.lightbulb_outline_rounded, Colors.amber.shade800,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdeasScreen()))),
      _MenuItem('Improvements', Icons.build_outlined, Colors.blue.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImprovementsScreen()))),
    ];
    if (currentUser!.isAdmin) {
      staffItems.add(_MenuItem('Attendance Report', Icons.bar_chart, Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceReportScreen()))));
    }
    if (currentUser!.isSuperAdmin) {
      staffItems.add(_MenuItem('All Users', Icons.group_rounded, Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen()))));
    }
    sections.add(_ModuleSection(
      title: '👥 Staff & HR',
      color: AppTheme.staffColor,
      items: staffItems,
    ));

    // ── SHOP OPERATIONS MODULE ─────────────────────────────
    sections.add(_ModuleSection(
      title: '🏪 Shop Operations',
      color: AppTheme.cafeColor,
      items: [
        _MenuItem('☕ Cafe', Icons.coffee, AppTheme.cafeColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDetailScreen(shopCode: 'CAFE', shopName: 'Cafe')))),
        _MenuItem('📚 Bookshop', Icons.menu_book_rounded, AppTheme.bookshopColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDetailScreen(shopCode: 'BOOKSHOP', shopName: 'Bookshop')))),
        _MenuItem('🍽️ Food Hut', Icons.restaurant_menu, AppTheme.foodhutColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDetailScreen(shopCode: 'FOODHUT', shopName: 'Food Hut')))),
        if (currentUser!.canEdit) ...[
          _MenuItem('Credits', Icons.credit_card, AppTheme.creditsColor,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsScreen()))),
          _MenuItem('Expense Types', Icons.category, Colors.purple.shade600,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseTypesScreen()))),
        ],
        if (currentUser!.isSuperAdmin) ...[
          _MenuItem('Bank Deposits', Icons.account_balance, Colors.green.shade700,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankDepositsScreen()))),
          _MenuItem('Business Overview', Icons.analytics, Colors.indigo.shade700,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessOverviewScreen()))),
        ],
      ],
    ));

    // ── FOOD HUT MODULE ────────────────────────────────────
    sections.add(_ModuleSection(
      title: '🍽️ Food Hut Kitchen',
      color: AppTheme.foodhutColor,
      items: [
        _MenuItem('Daily Entry', Icons.restaurant_menu, AppTheme.foodhutColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodHutMainScreen()))),
      ],
    ));

    // ── ADMIN MODULE ───────────────────────────────────────
    if (currentUser!.isSuperAdmin) {
      sections.add(_ModuleSection(
        title: '⚙️ Admin & Reports',
        color: Colors.purple.shade700,
        items: [
          _MenuItem('Audit Logs', Icons.security, Colors.purple.shade700,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen()))),
        ],
      ));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sections = _buildSections();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, ${currentUser?.name ?? 'User'}! 👋',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('OneStopSolutions', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        actions: [
          if (currentUser?.role != null)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(currentUser!.role),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(currentUser!.role.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUser, tooltip: 'Refresh'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: sections.map((section) => _SectionWidget(section: section)).toList(),
        ),
      ),
    );
  }
}

class _ModuleSection {
  final String title;
  final Color color;
  final List<_MenuItem> items;
  const _ModuleSection({required this.title, required this.color, required this.items});
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.label, this.icon, this.color, this.onTap);
}

class _SectionWidget extends StatelessWidget {
  final _ModuleSection section;
  const _SectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: section.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: section.color,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: section.items.length,
          itemBuilder: (context, i) {
            final item = section.items[i];
            return _MenuCard(item: item);
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

