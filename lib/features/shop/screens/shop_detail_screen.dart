import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onestopsolutions/features/auth/services/auth_service.dart';
import 'package:onestopsolutions/features/auth/models/user_model.dart';
import 'package:onestopsolutions/features/shop/services/shop_service.dart';

class ShopDetailScreen extends StatefulWidget {
  final String shopCode;
  final String shopName;
  const ShopDetailScreen({super.key, required this.shopCode, required this.shopName});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? dailyCashData;
  bool loading = true;
  AppUser? currentUser;
  late int shopId;

  Color get shopColor {
    switch (widget.shopCode.toUpperCase()) {
      case 'CAFE':     return const Color(0xFF068A4B);
      case 'BOOKSHOP': return const Color(0xFF1565C0);
      default:         return const Color(0xFFB65505);
    }
  }

  @override
  void initState() {
    super.initState();
    shopId = ShopService.getShopId(widget.shopCode);
    _loadUser();
  }

  Future<void> _loadUser() async {
    currentUser = await AuthService.getCurrentUser();
    _loadDailyCash();
  }

  Future<void> _loadDailyCash() async {
    setState(() => loading = true);
    final data = await ShopService.getDailyCash(shopId, selectedDate);

    if (data != null) {
      // If no opening balance, try to fetch yesterday's closing as suggestion
      final hasOpening = (data['openingCash'] ?? data['opening_cash'] ?? 0) != 0;
      if (!hasOpening) {
        final prev = await ShopService.getDailyCash(shopId, selectedDate.subtract(const Duration(days: 1)));
        if (prev != null) {
          final closing = prev['closingCash'] ?? prev['closing_cash'] ??
              prev['closingBalance'] ?? prev['closing_balance'];
          if (closing != null && closing != 0) {
            data['suggestedOpening'] = (closing as num).toDouble();
          }
        }
      }
    }

    if (!mounted) return;
    setState(() { dailyCashData = data; loading = false; });
  }

  bool get canEdit {
    if (currentUser == null) return false;
    return currentUser!.isAdmin; // ADMIN or SUPERADMIN only
  }

  bool get canDelete {
    if (currentUser == null) return false;
    return currentUser!.isAdmin; // ADMIN or SUPERADMIN only
  }

  double _getOpeningBalance() {
    if (dailyCashData == null) return 0.0;
    final v = dailyCashData!['openingCash'] ?? dailyCashData!['opening_cash'] ??
        dailyCashData!['openingBalance'] ?? dailyCashData!['opening_balance'];
    return v != null ? (v as num).toDouble() : 0.0;
  }

  double _getClosingBalance() {
    if (dailyCashData == null) return 0.0;
    final v = dailyCashData!['closingCash'] ?? dailyCashData!['closing_cash'] ??
        dailyCashData!['closingBalance'] ?? dailyCashData!['closing_balance'] ??
        dailyCashData!['endingCash'];
    return v != null ? (v as num).toDouble() : 0.0;
  }

  double _getSuggestedOpening() {
    final cur = _getOpeningBalance();
    if (cur > 0) return cur;
    final s = dailyCashData?['suggestedOpening'];
    return s != null ? (s as num).toDouble() : 0.0;
  }

  bool _isOpeningConfirmed() {
    final v = dailyCashData?['openingConfirmed'] ?? dailyCashData?['opening_confirmed'];
    return v == true || v == 1;
  }

  void _msg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _warn(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
          ),
          const SizedBox(width: 12),
          const Text('Warning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Text(msg),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Add Start (Opening Balance) ─────────────────────────────────────────────
  Future<void> _openCash() async {
    final isLocked = dailyCashData?['locked'] == true || dailyCashData?['locked'] == 1;
    if (isLocked) { _msg('Day is locked. Cannot modify.'); return; }
    if (_isOpeningConfirmed()) { _warn('Opening balance already confirmed. Cannot modify once set.'); return; }

    final opening = _getOpeningBalance();
    final suggested = _getSuggestedOpening();
    final prefill = opening > 0 ? opening : suggested;
    final ctrl = TextEditingController(text: prefill > 0 ? prefill.toStringAsFixed(2) : '');
    final prevDate = selectedDate.subtract(const Duration(days: 1));
    final isUpdating = dailyCashData?['dailyCashId'] != null && opening > 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isUpdating ? 'Update Opening Balance' : 'Add Start'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (isUpdating)
              _infoBox(Colors.orange, Icons.edit, 'Update Opening Balance',
                  'Current: Rs ${opening.toStringAsFixed(2)}'),
            if (!isUpdating && suggested > 0)
              _infoBox(Colors.blue, Icons.info_outline, "Previous Day's Closing",
                  '${DateFormat('MMM d').format(prevDate)} closing: Rs ${suggested.toStringAsFixed(2)}\nPre-filled as your opening balance'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Starting Balance', prefixText: 'Rs '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text);
              if (amount == null || amount < 0) { _msg('Invalid amount'); return; }
              final ok = await ShopService.openDailyCash(shopId, selectedDate, amount, userConfirmed: true);
              if (mounted) Navigator.pop(context, ok);
            },
            child: Text(isUpdating ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
    if (result == true) { _msg('Opening balance saved'); await _loadDailyCash(); }
    else if (result == false) _msg('Failed to save opening balance');
  }

  // ── Add End (Closing Balance) ───────────────────────────────────────────────
  Future<void> _closeCash() async {
    final dailyCashId = dailyCashData?['dailyCashId'];
    if (dailyCashId == null) return;
    if (!_isOpeningConfirmed()) { _warn('Please enter Starting Balance first.'); return; }

    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add End'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ending Balance', prefixText: 'Rs '),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text);
              if (amount == null || amount < 0) { _msg('Invalid amount'); return; }
              final ok = await ShopService.closeDailyCash(dailyCashId, amount);
              if (mounted) Navigator.pop(context, ok);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == true) { _msg('Ending balance added'); _loadDailyCash(); }
  }

  // ── Add Expense ─────────────────────────────────────────────────────────────
  Future<void> _addExpense() async {
    final dailyCashId = dailyCashData?['dailyCashId'];
    if (dailyCashId == null) { _msg('Open daily cash first'); return; }
    if (!_isOpeningConfirmed()) { _warn('Please enter Starting Balance first.'); return; }

    final types = await ShopService.getExpenseTypesForShop(widget.shopCode);
    if (types.isEmpty) { _msg('No expense types for this shop.'); return; }

    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Map<String, dynamic>? selectedType;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => _actionDialog(
          color: Colors.red, icon: Icons.remove_circle, title: 'Add Expense',
          onSubmit: () async {
            if (selectedType == null) { _msg('Select expense type'); return; }
            final amount = double.tryParse(amtCtrl.text);
            if (amount == null || amount <= 0) { _msg('Enter valid amount'); return; }
            final ok = await ShopService.addExpense(
              dailyCashId: dailyCashId, amount: amount,
              expenseTypeId: selectedType!['id'], description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            );
            if (ctx.mounted) Navigator.pop(ctx, ok);
          },
          submitLabel: 'Add Expense',
          child: Column(children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: selectedType,
              decoration: InputDecoration(
                labelText: 'Expense Type *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.category),
              ),
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t['name'] ?? ''))).toList(),
              onChanged: (v) => ss(() => selectedType = v),
            ),
            const SizedBox(height: 16),
            _amountField(amtCtrl),
            const SizedBox(height: 16),
            _descField(descCtrl),
          ]),
        ),
      ),
    );
    if (result == true) { _msg('Expense added'); await _loadDailyCash(); }
    else if (result == false) _msg('Failed to add expense');
  }

  // ── Add Sale ────────────────────────────────────────────────────────────────
  Future<void> _addSale() async {
    final dailyCashId = dailyCashData?['dailyCashId'];
    if (dailyCashId == null) { _msg('Open daily cash first'); return; }
    if (!_isOpeningConfirmed()) { _warn('Please enter Starting Balance first.'); return; }

    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _actionDialog(
        color: Colors.green, icon: Icons.add_circle, title: 'Add Sale',
        onSubmit: () async {
          final amount = double.tryParse(amtCtrl.text);
          if (amount == null || amount <= 0) { _msg('Enter valid amount'); return; }
          final ok = await ShopService.addSale(
            dailyCashId: dailyCashId, amount: amount,
            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          );
          if (context.mounted) Navigator.pop(context, ok);
        },
        submitLabel: 'Add Sale',
        child: Column(children: [
          _amountField(amtCtrl),
          const SizedBox(height: 16),
          _descField(descCtrl, hint: 'e.g., Cash sale, Card sale'),
        ]),
      ),
    );
    if (result == true) { _msg('Sale added'); await _loadDailyCash(); }
    else if (result == false) _msg('Failed to add sale');
  }

  // ── Add Credit ──────────────────────────────────────────────────────────────
  Future<void> _addCredit() async {
    if (!_isOpeningConfirmed()) { _warn('Please enter Starting Balance first.'); return; }
    final users = await ShopService.getAllUsers();
    if (users.isEmpty) { _msg('No users available.'); return; }

    final amtCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    Map<String, dynamic>? selectedUser;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => _actionDialog(
          color: Colors.orange, icon: Icons.credit_card, title: 'Add Credit',
          onSubmit: () async {
            if (selectedUser == null) { _msg('Select a user'); return; }
            final amount = double.tryParse(amtCtrl.text);
            if (amount == null || amount <= 0) { _msg('Enter valid amount'); return; }
            if (reasonCtrl.text.trim().isEmpty) { _msg('Enter a reason'); return; }
            final ok = await ShopService.addCredit(
              userId: selectedUser!['id'], amount: amount,
              reason: reasonCtrl.text.trim(), department: widget.shopCode,
              shopId: shopId, transactionDate: selectedDate,
            );
            if (ctx.mounted) Navigator.pop(ctx, ok);
          },
          submitLabel: 'Add Credit',
          child: Column(children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: selectedUser,
              decoration: InputDecoration(
                labelText: 'User *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person),
              ),
              items: users.map((u) => DropdownMenuItem(value: u, child: Text(u['name'] ?? ''))).toList(),
              onChanged: (v) => ss(() => selectedUser = v),
            ),
            const SizedBox(height: 16),
            _amountField(amtCtrl),
            const SizedBox(height: 16),
            _descField(reasonCtrl, label: 'Reason *', hint: 'e.g., Advance, Loan'),
          ]),
        ),
      ),
    );
    if (result == true) { _msg('Credit added'); await _loadDailyCash(); }
    else if (result == false) _msg('Failed to add credit');
  }

  // ── Edit/Delete Expense ─────────────────────────────────────────────────────
  Future<void> _editExpense(Map<String, dynamic> exp) async {
    final id = exp['id']; if (id == null) return;
    final types = await ShopService.getExpenseTypesForShop(widget.shopCode);
    final amtCtrl = TextEditingController(text: (exp['amount'] ?? 0.0).toStringAsFixed(2));
    final descCtrl = TextEditingController(text: exp['description'] ?? '');
    final curTypeId = exp['expenseTypeId'] ?? exp['expense_type_id'];
    Map<String, dynamic>? sel = types.firstWhere((t) => t['id'] == curTypeId, orElse: () => types.isNotEmpty ? types.first : {});
    if (sel.isEmpty) sel = null;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Edit Expense'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: sel,
              decoration: const InputDecoration(labelText: 'Expense Type *'),
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t['name'] ?? ''))).toList(),
              onChanged: (v) => ss(() => sel = v),
            ),
            const SizedBox(height: 12),
            _amountField(amtCtrl),
            const SizedBox(height: 12),
            _descField(descCtrl),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text);
                if (amount == null || amount <= 0) { _msg('Enter valid amount'); return; }
                final ok = await ShopService.updateTransaction(id, {
                  'amount': amount,
                  if (sel != null) 'expenseTypeId': sel!['id'],
                  if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                });
                if (context.mounted) Navigator.pop(context, ok);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (result == true) { _msg('Expense updated'); await _loadDailyCash(); }
  }

  Future<void> _deleteExpense(Map<String, dynamic> exp) async {
    final id = exp['id']; if (id == null) return;
    final confirmed = await _confirmDelete('expense', exp['amount']);
    if (confirmed == true) {
      final ok = await ShopService.deleteTransaction(id);
      ok ? _msg('Expense deleted') : _msg('Failed to delete expense');
      if (ok) await _loadDailyCash();
    }
  }

  Future<void> _editSale(Map<String, dynamic> sale) async {
    final id = sale['id']; if (id == null) return;
    final amtCtrl = TextEditingController(text: (sale['amount'] ?? 0.0).toStringAsFixed(2));
    final descCtrl = TextEditingController(text: sale['description'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Edit Sale'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _amountField(amtCtrl),
          const SizedBox(height: 12),
          _descField(descCtrl),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amtCtrl.text);
              if (amount == null || amount <= 0) { _msg('Enter valid amount'); return; }
              final ok = await ShopService.updateTransaction(id, {
                'amount': amount,
                if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context, ok);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result == true) { _msg('Sale updated'); await _loadDailyCash(); }
  }

  Future<void> _deleteSale(Map<String, dynamic> s) async {
    final id = s['id']; if (id == null) return;
    final confirmed = await _confirmDelete('sale', s['amount']);
    if (confirmed == true) {
      final ok = await ShopService.deleteTransaction(id);
      ok ? _msg('Sale deleted') : _msg('Failed to delete sale');
      if (ok) await _loadDailyCash();
    }
  }

  Future<void> _editCredit(Map<String, dynamic> credit) async {
    final id = credit['id']; if (id == null) return;
    final amtCtrl = TextEditingController(text: (credit['amount'] ?? 0.0).toStringAsFixed(2));
    final reasonCtrl = TextEditingController(text: credit['reason'] ?? '');
    bool isPaid = credit['isPaid'] ?? credit['is_paid'] ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Edit Credit'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            _amountField(amtCtrl),
            const SizedBox(height: 12),
            _descField(reasonCtrl, label: 'Reason *'),
            const SizedBox(height: 4),
            CheckboxListTile(
              title: const Text('Paid'),
              value: isPaid,
              onChanged: (v) => ss(() => isPaid = v ?? false),
              contentPadding: EdgeInsets.zero,
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text);
                if (amount == null || amount <= 0) { _msg('Enter valid amount'); return; }
                if (reasonCtrl.text.trim().isEmpty) { _msg('Enter a reason'); return; }
                final ok = await ShopService.updateCredit(id,
                    amount: amount, reason: reasonCtrl.text.trim(), isPaid: isPaid);
                if (context.mounted) Navigator.pop(context, ok);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (result == true) { _msg('Credit updated'); await _loadDailyCash(); }
  }

  Future<void> _deleteCredit(Map<String, dynamic> c) async {
    final id = c['id']; if (id == null) return;
    final confirmed = await _confirmDelete('credit', c['amount']);
    if (confirmed == true) {
      final ok = await ShopService.deleteCredit(id);
      ok ? _msg('Credit deleted') : _msg('Failed to delete credit');
      if (ok) await _loadDailyCash();
    }
  }

  Future<bool?> _confirmDelete(String type, dynamic amount) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete this $type of Rs ${(amount ?? 0.0).toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Shared dialog helper ────────────────────────────────────────────────────
  Widget _actionDialog({
    required Color color, required IconData icon, required String title,
    required VoidCallback onSubmit, required String submitLabel, required Widget child,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          SingleChildScrollView(child: child),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 2,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                child: Text(submitLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _amountField(TextEditingController ctrl) => TextField(
    controller: ctrl, autofocus: true,
    decoration: InputDecoration(
      labelText: 'Amount *', prefixText: 'Rs ',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
  );

  Widget _descField(TextEditingController ctrl,
      {String label = 'Description (optional)', String? hint}) => TextField(
    controller: ctrl, maxLines: 2,
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      prefixIcon: const Icon(Icons.notes),
    ),
  );

  Widget _infoBox(Color color, IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(fontSize: 11)),
      ]),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: shopColor,
        title: Text('${widget.shopName} Management'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDailyCash)],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDailyCash,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // ── Date Navigation ──────────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
                              _loadDailyCash();
                            },
                          ),
                          Expanded(
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.calendar_today, size: 13),
                              const SizedBox(width: 6),
                              Text(DateFormat('MMM d, y').format(selectedDate),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
                              _loadDailyCash();
                            },
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Add Start / Add End ──────────────────────────────────
                    Row(children: [
                      Expanded(
                        child: Builder(builder: (_) {
                          final hasNoCash = dailyCashData == null || dailyCashData!['dailyCashId'] == null;
                          final isLocked = dailyCashData?['locked'] == true || dailyCashData?['locked'] == 1;
                          final enabled = (hasNoCash || !isLocked) && canEdit;
                          final suggested = _getSuggestedOpening();
                          return ElevatedButton.icon(
                            onPressed: enabled ? _openCash : null,
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text(suggested > 0 ? 'Rs ${suggested.toStringAsFixed(2)}' : 'Add Start',
                                style: const TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              disabledBackgroundColor: Colors.grey.shade400,
                              disabledForegroundColor: Colors.white,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Builder(builder: (_) {
                          final isLocked = dailyCashData?['locked'] == true || dailyCashData?['locked'] == 1;
                          final enabled = dailyCashData != null && canEdit && !isLocked;
                          final closing = _getClosingBalance();
                          return ElevatedButton.icon(
                            onPressed: enabled ? _closeCash : null,
                            icon: const Icon(Icons.stop, size: 18),
                            label: Text(closing > 0 ? 'Rs ${closing.toStringAsFixed(2)}' : 'Add End',
                                style: const TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              disabledBackgroundColor: Colors.purple.shade200,
                              disabledForegroundColor: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // ── Summary ──────────────────────────────────────────────
                    if (dailyCashData != null) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 12),

                      // ── Action Buttons ───────────────────────────────────
                      // ── Action Buttons (ADMIN / SUPERADMIN only) ─────────
                      if (canEdit)
                        Row(children: [
                          _actionBtn('Expense', Icons.remove_circle, Colors.red,
                              canEdit ? _addExpense : null),
                          const SizedBox(width: 8),
                          _actionBtn('Credit', Icons.credit_card, Colors.orange,
                              canEdit ? _addCredit : null),
                          const SizedBox(width: 8),
                          _actionBtn('Sale', Icons.add_circle, Colors.green,
                              canEdit ? _addSale : null),
                        ]),
                      const SizedBox(height: 14),

                      // ── Transactions ─────────────────────────────────────
                      const Text('Transactions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildTransactionsList('Expenses', dailyCashData!['expenses'] ?? []),
                      const SizedBox(height: 10),
                      _buildTransactionsList('Credits', dailyCashData!['credits'] ?? []),
                      const SizedBox(height: 10),
                      _buildTransactionsList('Sales', dailyCashData!['sales'] ?? []),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No data for this date',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ),
                  ]),
                ),
              ),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final opening = _getOpeningBalance();
    final closing = _getClosingBalance();
    final expenses = (dailyCashData!['expenses'] as List? ?? [])
        .fold<double>(0.0, (s, e) => s + ((e['amount'] ?? 0.0) as num).toDouble());
    final credits = (dailyCashData!['credits'] as List? ?? [])
        .fold<double>(0.0, (s, c) => s + ((c['amount'] ?? 0.0) as num).toDouble());

    double sales = ((dailyCashData!['totalSales'] as num?) ?? 0.0).toDouble();
    bool hasShortfall = false;
    double shortfall = 0.0;

    if (sales < 0) {
      hasShortfall = true; shortfall = sales.abs(); sales = 0.0;
    } else if (sales == 0.0 && (closing != 0.0 || expenses != 0.0 || credits != 0.0)) {
      final calc = (closing - opening) + expenses + credits;
      if (calc < 0) { hasShortfall = true; shortfall = calc.abs(); sales = 0.0; }
      else { sales = calc; }
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Divider(height: 12),
          _summaryRow('Opening Balance', 'Rs ${opening.toStringAsFixed(2)}', Colors.blue),
          _summaryRow('Ending Balance',  'Rs ${closing.toStringAsFixed(2)}',  Colors.purple),
          _summaryRow('Total Sales',     'Rs ${sales.toStringAsFixed(2)}',    Colors.green),
          if (hasShortfall)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Cash Shortfall: Rs ${shortfall.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
          _summaryRow('Total Expenses', 'Rs ${expenses.toStringAsFixed(2)}', Colors.red),
          _summaryRow('Total Credits',  'Rs ${credits.toStringAsFixed(2)}',  Colors.orange),
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildTransactionsList(String title, List<dynamic> list) {
    final isExpense = title == 'Expenses';
    final isCredit  = title == 'Credits';
    final color = isExpense ? Colors.red : isCredit ? Colors.orange : Colors.green;
    final icon  = isExpense ? Icons.remove_circle : isCredit ? Icons.credit_card : Icons.add_circle;

    final sorted = List<dynamic>.from(list);
    if (isExpense) sorted.sort((a, b) =>
        ((a['amount'] ?? 0.0) as num).compareTo((b['amount'] ?? 0.0) as num));

    final isAdminEdit = canDelete; // ADMIN or SUPERADMIN only

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Divider(height: 10),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text('No $title yet', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            )
          else
            ...sorted.map((txn) {
              String mainText;
              String? subText;

              if (isExpense) {
                mainText = txn['expenseTypeName'] ?? txn['expense_type_name'] ??
                    txn['expenseType'] ?? 'Expense';
                subText = txn['description'];
              } else if (isCredit) {
                mainText = txn['userName'] ?? txn['user_name'] ?? 'Credit';
                final reason  = txn['reason'] ?? txn['description'] ?? '';
                final paid    = txn['isPaid'] ?? txn['is_paid'] ?? false;
                subText = reason.isNotEmpty
                    ? '$reason (${paid ? '✓ Paid' : '✗ Unpaid'})'
                    : (paid ? '✓ Paid' : '✗ Unpaid');
              } else {
                final desc = txn['description'];
                mainText = (desc != null && desc.toString().toLowerCase().contains('opening'))
                    ? 'Opening Balance'
                    : (desc ?? 'Sale');
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(mainText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (subText != null && subText.isNotEmpty)
                      Text(subText, style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                  Text('Rs ${(txn['amount'] ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                  if (isAdminEdit) ...[
                    const SizedBox(width: 2),
                    SizedBox(width: 28, height: 28,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 14), color: Colors.blue,
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        onPressed: () {
                          if (isExpense) _editExpense(txn);
                          else if (isCredit) _editCredit(txn);
                          else _editSale(txn);
                        },
                      ),
                    ),
                    SizedBox(width: 28, height: 28,
                      child: IconButton(
                        icon: const Icon(Icons.delete, size: 14), color: Colors.red,
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        onPressed: () {
                          if (isExpense) _deleteExpense(txn);
                          else if (isCredit) _deleteCredit(txn);
                          else _deleteSale(txn);
                        },
                      ),
                    ),
                  ],
                ]),
              );
            }),
        ]),
      ),
    );
  }
}

