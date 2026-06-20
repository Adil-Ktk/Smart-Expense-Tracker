import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'category_icons.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});
  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {

  // ─── Supabase ────────────────────────────────────────────────
  final supabase = Supabase.instance.client;

  // ─── State ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = false;
  String _userName = ''; // NEW — stores fetched profile name

  // ─── Form ────────────────────────────────────────────────────
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  String _selectedType = 'Expense';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _fetchCategories();
    _fetchUserName(); // NEW
  }

  // ─── FETCH Transactions ──────────────────────────────────────
  // RLS policies automatically ensure only the logged-in user's
  // rows are returned — no manual user_id filter needed here
  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('transactions')
          .select()
          .order('date', ascending: false);

      if (!mounted) return;
      setState(() {
        _transactions = List<Map<String, dynamic>>.from(response);
      });
      _calculateTotals();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error fetching data: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── FETCH Categories ────────────────────────────────────────
  Future<void> _fetchCategories() async {
    try {
      final response = await supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      if (!mounted) return;

      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        if (_categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = _categories.first['name'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error loading categories: $e', isError: true);
    }
  }

  // ─── FETCH User Profile Name (NEW) ───────────────────────────
  // Fetches the name saved during onboarding to personalize the
  // header greeting. Fails silently — name is nice-to-have, not critical
  Future<void> _fetchUserName() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase
          .from('profiles')
          .select('name')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _userName = profile?['name'] ?? '';
      });
    } catch (e) {
      // Silently fail — don't bother user with an error for this
    }
  }

  // ─── ADD New Category ────────────────────────────────────────
  Future<void> _addCategory(String name) async {
    if (name.trim().isEmpty) return;

    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('categories').insert({
        'user_id': userId,
        'name': name.trim(),
      });

      if (!mounted) return;

      await _fetchCategories();
      setState(() => _selectedCategory = name.trim());
      _newCategoryController.clear();

    } catch (e) {
      if (!mounted) return;
      _showSnack('Error adding category: $e', isError: true);
    }
  }

  // ─── CALCULATE Totals ────────────────────────────────────────
  void _calculateTotals() {
    double income = 0;
    double expense = 0;
    for (var t in _transactions) {
      if (t['type'] == 'Income') {
        income += (t['amount'] as num).toDouble();
      } else {
        expense += (t['amount'] as num).toDouble();
      }
    }
    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  // ─── ADD Transaction ─────────────────────────────────────────
  Future<void> _addTransaction() async {
    if (_amountController.text.trim().isEmpty) {
      _showSnack('Please enter an amount', isError: true);
      return;
    }
    if (_selectedCategory == null) {
      _showSnack('Please select a category', isError: true);
      return;
    }
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('transactions').insert({
        'user_id': userId,
        'type': _selectedType,
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text.trim()),
        'description': _descriptionController.text.trim(),
        'date': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _amountController.clear();
      _descriptionController.clear();
      Navigator.pop(context);
      _fetchTransactions();
      _showSnack('Transaction added!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', isError: true);
    }
  }

  // ─── DELETE Transaction ──────────────────────────────────────
  Future<void> _deleteTransaction(String id) async {
    try {
      await supabase.from('transactions').delete().eq('id', id);
      if (!mounted) return;
      _fetchTransactions();
      _showSnack('Transaction deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', isError: true);
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────
  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  // ─── SNACKBAR Helper ─────────────────────────────────────────
  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ─── SHOW Add Category Dialog ─────────────────────────────────
  void _showAddCategoryDialog() {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'New Category',
            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _newCategoryController,
            autofocus: true,
            style: TextStyle(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Vegetables, Gym, Rent',
              hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.3)),
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newCategoryController.clear();
                Navigator.pop(dialogContext);
              },
              child: Text('Cancel', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5))),
            ),
            FilledButton(
              onPressed: () {
                _addCategory(_newCategoryController.text);
                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // ─── SHOW Add Transaction Sheet ──────────────────────────────
  void _showAddTransactionSheet() {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'New Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Type Toggle ───────────────────────────
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Income',
                        label: Text('Income'),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      ButtonSegment(
                        value: 'Expense',
                        label: Text('Expense'),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (value) {
                      setState(() => _selectedType = value.first);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Category Row: Dropdown + Add Button ──────
                  Row(
                    children: [
                      Expanded(
                        child: _categories.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'No categories yet — tap + to add one',
                                  style: TextStyle(color: colors.onSurface.withValues(alpha: 0.4), fontSize: 13),
                                ),
                              )
                            : DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(
                                    _selectedCategory != null
                                        ? CategoryIconHelper.getIcon(_selectedCategory!)
                                        : Icons.category_rounded,
                                    color: _selectedCategory != null
                                        ? CategoryIconHelper.getColor(_selectedCategory!)
                                        : colors.primary,
                                  ),
                                  filled: true,
                                  fillColor: colors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                                  ),
                                ),
                                items: _categories.map((cat) {
                                  final name = cat['name'] as String;
                                  return DropdownMenuItem(
                                    value: name,
                                    child: Row(
                                      children: [
                                        Icon(
                                          CategoryIconHelper.getIcon(name),
                                          color: CategoryIconHelper.getColor(name),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedCategory = value);
                                  setSheetState(() {});
                                },
                              ),
                      ),
                      const SizedBox(width: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _showAddCategoryDialog();
                          },
                          icon: Icon(Icons.add_rounded, color: colors.primary),
                          tooltip: 'Add new category',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Amount Field ──────────────────────────
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'PKR  ',
                      prefixStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Description Field ─────────────────────
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit Button ─────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _addTransaction,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Add Transaction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── MAIN UI ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    double balance = _totalIncome - _totalExpense;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        // Shows "Hi, Name 👋" if name is loaded, otherwise falls
        // back to the generic app title
        title: Text(
          _userName.isNotEmpty ? 'Hi, $_userName 👋' : 'Expense Tracker',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _logout,
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: colors.primary.withValues(alpha: 0.2),
                child: Icon(Icons.person_rounded, size: 18, color: colors.primary),
              ),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchTransactions();
                await _fetchCategories();
                await _fetchUserName();
              },
              color: colors.primary,
              child: CustomScrollView(
                slivers: [

                  // ── Summary Card ─────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.primary.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              'Total Balance',
                              style: TextStyle(
                                color: colors.onPrimary.withValues(alpha: 0.7),
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'PKR ${balance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: colors.onPrimary,
                                  fontSize: isSmallScreen ? 28 : 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Divider(color: colors.onPrimary.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Income',
                                                style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.7), fontSize: 12)),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'PKR ${_totalIncome.toStringAsFixed(0)}',
                                                style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 40, color: colors.onPrimary.withValues(alpha: 0.2)),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Expense',
                                                  style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.7), fontSize: 12)),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'PKR ${_totalExpense.toStringAsFixed(0)}',
                                                  style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Transactions Header ───────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transactions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                          ),
                          Text(
                            '${_transactions.length} total',
                            style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Empty State ───────────────────────────
                  if (_transactions.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 64, color: colors.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('No transactions yet',
                                style: TextStyle(fontSize: 16, color: colors.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text('Tap + to add your first one',
                                style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.3))),
                          ],
                        ),
                      ),
                    ),

                  // ── Transaction List ──────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final t = _transactions[index];
                          final isIncome = t['type'] == 'Income';
                          final category = t['category'] ?? 'Other';

                          final icon = CategoryIconHelper.getIcon(category);
                          final color = CategoryIconHelper.getColor(category);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              title: Text(category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              subtitle: Text(
                                t['description'] ?? '',
                                style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.4)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${isIncome ? '+' : '-'} ${(t['amount'] as num).toStringAsFixed(0)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isIncome ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: colors.onSurface.withValues(alpha: 0.3), size: 20),
                                    onPressed: () => _deleteTransaction(t['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _transactions.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}