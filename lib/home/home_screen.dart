import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/core/network/api_client.dart';
import 'package:onestopsolutions/core/theme/app_theme.dart';
import 'package:onestopsolutions/features/auth/models/user_model.dart';
import 'package:onestopsolutions/features/auth/services/auth_service.dart';
import 'package:onestopsolutions/features/auth/services/pin_service.dart';
import 'package:onestopsolutions/features/auth/screens/login_screen.dart';
import 'package:onestopsolutions/features/staff/screens/attendance_screen.dart';
import 'package:onestopsolutions/features/staff/screens/salary_screen.dart';
import 'package:onestopsolutions/features/staff/screens/ideas_screen.dart';
import 'package:onestopsolutions/features/staff/screens/attendance_report_screen.dart';
import 'package:onestopsolutions/features/shop/screens/shop_detail_screen.dart';
import 'package:onestopsolutions/features/shop/screens/credits_screen.dart';
import 'package:onestopsolutions/features/shop/screens/bank_deposits_screen.dart';
import 'package:onestopsolutions/features/shop/screens/expense_types_screen.dart';
import 'package:onestopsolutions/features/shop/screens/business_overview_screen.dart';
import 'package:onestopsolutions/features/foodhut/screens/foodhut_main_screen.dart';
import 'package:onestopsolutions/features/admin/screens/audit_logs_screen.dart';
import 'package:onestopsolutions/features/admin/screens/admin_operations_screen.dart';
import 'package:onestopsolutions/features/staff/screens/staff_performance_screen.dart';
import 'package:onestopsolutions/features/shop/services/shop_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN — 3 entry cards based on role
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? currentUser;
  bool loading = true;
  // Shop balances for quick summary (Admin / SuperAdmin)
  Map<String, double> _shopBalances = {'CAFE': 0, 'BOOKSHOP': 0, 'FOODHUT': 0};
  double _unpaidCredits = 0;
  bool _balancesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => loading = true);
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() { currentUser = user; loading = false; });
    // Fetch balances after user loaded (only for admin+)
    if (user != null && (user.isAdmin || user.isSuperAdmin)) {
      _loadBalances();
    }
  }

  Future<void> _loadBalances() async {
    if (!mounted) return;
    setState(() => _balancesLoading = true);
    try {
      final results = await Future.wait([
        ShopService.getLatestClosingBalance(1),
        ShopService.getLatestClosingBalance(2),
        ShopService.getLatestClosingBalance(3),
        ShopService.getUnpaidCreditsTotal(),
      ]);
      if (!mounted) return;
      setState(() {
        _shopBalances = {
          'CAFE': results[0],
          'BOOKSHOP': results[1],
          'FOODHUT': results[2],
        };
        _unpaidCredits = results[3];
        _balancesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _balancesLoading = false);
    }
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
      case 'ADMIN':      return AppTheme.secondaryColor;
      default:           return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, ${user?.name ?? 'User'}! 👋',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('OneStopSolutions',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          if (user?.role != null)
            Container(
              margin: const EdgeInsets.only(right: 6, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(user!.role),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(user.role.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUser),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Quick Balance Summary (Admin/SuperAdmin) ─────
            if (user != null && (user.isAdmin || user.isSuperAdmin)) ...[
              _QuickBalanceCard(
                shopBalances: _shopBalances,
                unpaidCredits: _unpaidCredits,
                loading: _balancesLoading,
                onRefresh: _loadBalances,
              ),
              const SizedBox(height: 16),
            ],

            // ── Customer ─────────────────────────────────────
            if (user?.isCustomer == true) ...[
              _CustomerPlaceholder(name: user!.name),
            ],

            // ── Admin sees My Activities + Shop Management ───
            if (user?.isAdmin == true) ...[
              _EntryCard(
                icon: Icons.person_rounded,
                title: 'My Activities',
                subtitle: 'Attendance · Salary · Feedback',
                color: AppTheme.staffColor,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MyActivitiesScreen(user: user!))),
              ),
              const SizedBox(height: 16),
              _EntryCard(
                icon: Icons.storefront_rounded,
                title: 'Shop Management',
                subtitle: 'Cafe · Bookshop · Food Hut · Credits',
                color: AppTheme.cafeColor,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ShopManagementScreen(user: user!))).then((_) => _loadBalances()),
              ),
            ],

            // ── SuperAdmin also sees Business Summary + Admin Ops ──
            if (user?.isSuperAdmin == true) ...[
              const SizedBox(height: 16),
              _EntryCard(
                icon: Icons.analytics_rounded,
                title: 'Business Summary',
                subtitle: 'Monthly Overview · Deposits · Audit Logs',
                color: Colors.purple.shade700,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BusinessSummaryScreen())),
              ),
              const SizedBox(height: 16),
              _EntryCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin Operations',
                subtitle: 'Edit Users · Credits · Attendance · Expenses · Sales',
                color: Colors.red.shade700,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminOperationsScreen())),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK BALANCE CARD  (shown on home screen for Admin / SuperAdmin)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickBalanceCard extends StatelessWidget {
  final Map<String, double> shopBalances;
  final double unpaidCredits;
  final bool loading;
  final Future<void> Function() onRefresh;

  const _QuickBalanceCard({
    required this.shopBalances,
    required this.unpaidCredits,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          // Main drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          // Softer wide shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          // Top inner highlight (emboss effect)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Row 1: 3 shops
                Row(
                  children: [
                    Expanded(child: _BalanceTile(
                      label: '☕ Cafe',
                      amount: shopBalances['CAFE'] ?? 0,
                      color: AppTheme.cafeColor,
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _BalanceTile(
                      label: '📚 Bookshop',
                      amount: shopBalances['BOOKSHOP'] ?? 0,
                      color: AppTheme.bookshopColor,
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _BalanceTile(
                      label: '🍽️ Food Hut',
                      amount: shopBalances['FOODHUT'] ?? 0,
                      color: AppTheme.foodhutColor,
                    )),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 2: Credits (full width)
                _BalanceTile(
                  label: '💳 Unpaid Credits',
                  amount: unpaidCredits,
                  color: AppTheme.creditsColor,
                  fullWidth: true,
                ),
              ],
            ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool fullWidth;

  const _BalanceTile({
    required this.label,
    required this.amount,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: fullWidth ? 14 : 10, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: fullWidth
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                Text(
                  'Rs ${NumberFormat('#,##0').format(amount)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  'Rs ${NumberFormat('#,##0').format(amount)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}

// Customer placeholder
class _CustomerPlaceholder extends StatelessWidget {
  final String name;
  const _CustomerPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_circle_rounded, size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          Text('Welcome, $name!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Customer features coming soon.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MY ACTIVITIES SUB-SCREEN  (Admin + SuperAdmin)
// ─────────────────────────────────────────────────────────────────────────────
class MyActivitiesScreen extends StatelessWidget {
  final AppUser user;
  const MyActivitiesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('My Attendance', Icons.access_time_filled_rounded, AppTheme.staffColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()))),
      _MenuItem('My Salary', Icons.monetization_on_rounded, Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryScreen()))),
      _MenuItem('Feedback', Icons.feedback_outlined, AppTheme.primaryColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
      // Attendance Report only for ADMIN role (not SuperAdmin)
      if (user.role.toUpperCase() == 'ADMIN')
        _MenuItem('Attendance Report', Icons.bar_chart_rounded, Colors.indigo,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceReportScreen()))),
    ];

    return _ActivityScreen(title: 'My Activities', items: items);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHOP MANAGEMENT SUB-SCREEN  (Admin + SuperAdmin)
// ─────────────────────────────────────────────────────────────────────────────
class ShopManagementScreen extends StatefulWidget {
  final AppUser user;
  const ShopManagementScreen({super.key, required this.user});
  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  Map<String, double> _balances = {'CAFE': 0, 'BOOKSHOP': 0, 'FOODHUT': 0};
  double _unpaidCredits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ShopService.getLatestClosingBalance(1),
        ShopService.getLatestClosingBalance(2),
        ShopService.getLatestClosingBalance(3),
        ShopService.getUnpaidCreditsTotal(),
      ]);
      if (!mounted) return;
      setState(() {
        _balances = {'CAFE': res[0], 'BOOKSHOP': res[1], 'FOODHUT': res[2]};
        _unpaidCredits = res[3];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nav(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Shop Management'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: _loading
              ? [const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))]
              : [
                  _PremiumShopButton(
                    emoji: '☕', text: 'Cafe', balance: _balances['CAFE'],
                    gradient: const [Color(0xFF068A4B), Color(0xFF66BB6A)],
                    icon: Icons.coffee_rounded,
                    onTap: () => _nav(const ShopDetailScreen(shopCode: 'CAFE', shopName: 'Cafe')),
                  ),
                  const SizedBox(height: 14),
                  _PremiumShopButton(
                    emoji: '📚', text: 'Bookshop', balance: _balances['BOOKSHOP'],
                    gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    icon: Icons.menu_book_rounded,
                    onTap: () => _nav(const ShopDetailScreen(shopCode: 'BOOKSHOP', shopName: 'Bookshop')),
                  ),
                  const SizedBox(height: 14),
                  _PremiumShopButton(
                    emoji: '🍽️', text: 'Food Hut', balance: _balances['FOODHUT'],
                    gradient: const [Color(0xFFB65505), Color(0xFFFF9800)],
                    icon: Icons.restaurant_rounded,
                    onTap: () => _nav(const ShopDetailScreen(shopCode: 'FOODHUT', shopName: 'Food Hut')),
                  ),
                  const SizedBox(height: 14),
                  _PremiumShopButton(
                    emoji: '🍳', text: 'Food Hut Kitchen', balance: null,
                    gradient: const [Color(0xFF795548), Color(0xFFA1887F)],
                    icon: Icons.soup_kitchen_rounded,
                    onTap: () => _nav(const FoodHutMainScreen()),
                  ),
                  const SizedBox(height: 14),
                  _PremiumShopButton(
                    emoji: '💳', text: 'Credits', balance: _unpaidCredits,
                    balanceLabel: 'unpaid',
                    gradient: const [Color(0xFFE60B31), Color(0xFFE57373)],
                    icon: Icons.credit_card_rounded,
                    onTap: () => _nav(const CreditsScreen()),
                  ),
                  const SizedBox(height: 14),
                  _PremiumShopButton(
                    emoji: '📋', text: 'Expense Types', balance: null,
                    gradient: [Colors.purple.shade700, Colors.purple.shade400],
                    icon: Icons.category_rounded,
                    onTap: () => _nav(const ExpenseTypesScreen()),
                  ),
                ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM SHOP BUTTON  (OSD-style gradient card with balance)
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumShopButton extends StatefulWidget {
  final String emoji;
  final String text;
  final double? balance;
  final String? balanceLabel;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumShopButton({
    required this.emoji,
    required this.text,
    required this.balance,
    required this.gradient,
    required this.icon,
    required this.onTap,
    this.balanceLabel,
  });

  @override
  State<_PremiumShopButton> createState() => _PremiumShopButtonState();
}

class _PremiumShopButtonState extends State<_PremiumShopButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.diagonal3Values(
            _pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.gradient[0].withValues(alpha: 0.38),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -28,
                right: 50,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -35,
                right: -15,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      child: Center(
                        child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.text,
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3)),
                          if (widget.balance != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  'Rs ${NumberFormat('#,##0').format(widget.balance!)}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9)),
                                ),
                                if (widget.balanceLabel != null) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(widget.balanceLabel!,
                                        style: const TextStyle(fontSize: 9, color: Colors.white70)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.85), size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUSINESS SUMMARY SUB-SCREEN  (SuperAdmin only) — monthly view
// ─────────────────────────────────────────────────────────────────────────────
class BusinessSummaryScreen extends StatefulWidget {
  const BusinessSummaryScreen({super.key});
  @override
  State<BusinessSummaryScreen> createState() => _BusinessSummaryScreenState();
}

class _BusinessSummaryScreenState extends State<BusinessSummaryScreen> {
  bool _loading = true;
  Map<String, dynamic>? _cafe;
  Map<String, dynamic>? _bookshop;
  Map<String, dynamic>? _foodhut;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _startDate => DateFormat('yyyy-MM-dd').format(
      DateTime(_selectedMonth.year, _selectedMonth.month, 1));
  String get _endDate => DateFormat('yyyy-MM-dd').format(
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/api/transactions/department-summary?department=CAFE&startDate=$_startDate&endDate=$_endDate'),
        ApiClient.get('/api/transactions/department-summary?department=BOOKSHOP&startDate=$_startDate&endDate=$_endDate'),
        ApiClient.get('/api/transactions/department-summary?department=FOODHUT&startDate=$_startDate&endDate=$_endDate'),
      ]);
      if (!mounted) return;
      setState(() {
        if (results[0].statusCode == 200) _cafe     = jsonDecode(results[0].body);
        if (results[1].statusCode == 200) _bookshop = jsonDecode(results[1].body);
        if (results[2].statusCode == 200) _foodhut  = jsonDecode(results[2].body);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  double _v(Map<String, dynamic>? m, String key) => (m?[key] ?? 0).toDouble();

  @override
  Widget build(BuildContext context) {
    final menuItems = <_MenuItem>[
      _MenuItem('Staff Performance', Icons.leaderboard_rounded, Colors.blue.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffPerformanceScreen()))),
      _MenuItem('Business Overview', Icons.analytics_rounded, Colors.purple.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessOverviewScreen()))),
      _MenuItem('Bank Deposits', Icons.account_balance_rounded, Colors.green.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankDepositsScreen()))),
      _MenuItem('Audit Logs', Icons.security_rounded, Colors.red.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen()))),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Business Summary'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── MONTH SWITCHER ────────────────────────────────
            Container(
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
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth, color: Colors.purple.shade700),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.purple.shade700),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: _isCurrentMonth ? Colors.grey.shade300 : Colors.purple.shade700),
                    onPressed: _isCurrentMonth ? null : _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── MONTHLY BALANCE DASHBOARD ─────────────────────
            _SummaryDashboard(
              loading: _loading,
              cafe: _cafe,
              bookshop: _bookshop,
              foodhut: _foodhut,
              valFn: _v,
              monthLabel: DateFormat('MMM yyyy').format(_selectedMonth),
            ),
            const SizedBox(height: 24),

            // ── SECTION LABEL ─────────────────────────────────
            Text('Management Tools',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600, letterSpacing: 0.5)),
            const SizedBox(height: 12),

            // ── MENU GRID ─────────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, i) => _MenuCard(item: menuItems[i]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TODAY'S BALANCE DASHBOARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryDashboard extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? cafe;
  final Map<String, dynamic>? bookshop;
  final Map<String, dynamic>? foodhut;
  final double Function(Map<String, dynamic>?, String) valFn;
  final String monthLabel;

  const _SummaryDashboard({
    required this.loading,
    required this.cafe,
    required this.bookshop,
    required this.foodhut,
    required this.valFn,
    this.monthLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final cafeBalance     = valFn(cafe,     'closingBalance');
    final bookshopBalance = valFn(bookshop, 'closingBalance');
    final foodhutBalance  = valFn(foodhut,  'closingBalance');
    final totalBalance    = cafeBalance + bookshopBalance + foodhutBalance;

    final cafeSales     = valFn(cafe,     'calculatedSales');
    final bookshopSales = valFn(bookshop, 'calculatedSales');
    final foodhutSales  = valFn(foodhut,  'calculatedSales');
    final totalSales    = cafeSales + bookshopSales + foodhutSales;

    final cafeExp     = valFn(cafe,     'totalExpenses');
    final bookshopExp = valFn(bookshop, 'totalExpenses');
    final foodhutExp  = valFn(foodhut,  'totalExpenses');
    final totalExp    = cafeExp + bookshopExp + foodhutExp;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade800, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.purple.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: loading
          ? const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthLabel.isNotEmpty ? '$monthLabel Summary' : "Today's Balance",
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      monthLabel.isNotEmpty ? '' : DateFormat('EEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs ${_fmt(totalBalance)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  _pill('Sales Rs ${_fmt(totalSales)}', Colors.greenAccent.shade400),
                  const SizedBox(width: 8),
                  _pill('Exp Rs ${_fmt(totalExp)}', Colors.orange.shade300),
                ]),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),

                // Per-shop row
                Row(
                  children: [
                    Expanded(child: _ShopBalanceTile(
                      emoji: '☕', name: 'Cafe',
                      balance: cafeBalance, sales: cafeSales, expenses: cafeExp,
                      color: const Color(0xFF4CAF50),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _ShopBalanceTile(
                      emoji: '📚', name: 'Bookshop',
                      balance: bookshopBalance, sales: bookshopSales, expenses: bookshopExp,
                      color: const Color(0xFF64B5F6),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _ShopBalanceTile(
                      emoji: '🍽️', name: 'Food Hut',
                      balance: foodhutBalance, sales: foodhutSales, expenses: foodhutExp,
                      color: const Color(0xFFFFB74D),
                    )),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  static String _fmt(double v) => NumberFormat('#,##0').format(v);
}

class _ShopBalanceTile extends StatelessWidget {
  final String emoji;
  final String name;
  final double balance;
  final double sales;
  final double expenses;
  final Color color;

  const _ShopBalanceTile({
    required this.emoji,
    required this.name,
    required this.balance,
    required this.sales,
    required this.expenses,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $name', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Rs ${NumberFormat('#,##0').format(balance)}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Sales: Rs ${NumberFormat('#,##0').format(sales)}',
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text('Exp: Rs ${NumberFormat('#,##0').format(expenses)}',
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY SCREEN  — full-width list layout for My Activities
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityScreen extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _ActivityScreen({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: item.color.withValues(alpha: 0.15),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: item.color),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SUB-SCREEN SHELL
// ─────────────────────────────────────────────────────────────────────────────
class _SubScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_MenuItem> items;

  const _SubScreen({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => _MenuCard(item: items[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED DATA CLASSES & WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.label, this.icon, this.color, this.onTap);
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      shadowColor: item.color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
