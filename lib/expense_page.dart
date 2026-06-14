import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key}); // key helps Flutter identify this widget
  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {

  // ─── Supabase Client ────────────────────────────────────────
  // Supabase.instance.client gives us access to database and auth
  final supabase = Supabase.instance.client;

  // ─── State Variables ────────────────────────────────────────
  List<Map<String, dynamic>> _transactions = []; // all transactions from DB
  double _totalIncome = 0;    // sum of all income
  double _totalExpense = 0;   // sum of all expenses
  bool _isLoading = false;    // controls loading spinner

  // ─── Form Controllers ────────────────────────────────────────
  // TextEditingController lets us read/clear text field values
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // ─── Dropdown Default Values ─────────────────────────────────
  String _selectedType = 'Expense';   // default transaction type
  String _selectedCategory = 'Food'; // default category

  // All available categories shown in dropdown
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Salary',
    'Other',
  ];

  // ─── Lifecycle Method ────────────────────────────────────────
  // initState() runs ONCE when this screen first opens
  // Perfect place to load initial data from database
  @override
  void initState() {
    super.initState();
    _fetchTransactions(); // load transactions when screen opens
  }

  // ─── FETCH Transactions (Read) ───────────────────────────────
  // Gets all transactions from Supabase and updates the UI
  Future<void> _fetchTransactions() async {

    // Show loading spinner while fetching
    setState(() => _isLoading = true);

    try {
      // Query the transactions table
      // .select() → get all columns
      // .order() → sort by date, newest first
      final response = await supabase
          .from('transactions')
          .select()
          .order('date', ascending: false);

      // 'mounted' check — makes sure screen is still open
      // after the async await completes before updating UI
      // Without this, if user navigates away during fetch,
      // the app would crash trying to update a closed screen
      if (!mounted) return;

      setState(() {
        // Convert response to a typed List of Maps
        _transactions = List<Map<String, dynamic>>.from(response);
      });

      // Recalculate totals with fresh data
      _calculateTotals();

    } catch (e) {
      // mounted check before using context after await
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      // Always hide spinner whether success or error
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── CALCULATE Totals ────────────────────────────────────────
  // Loops through all transactions and calculates income/expense sums
  void _calculateTotals() {
    double income = 0;
    double expense = 0;

    for (var transaction in _transactions) {
      // Check type field of each transaction
      if (transaction['type'] == 'Income') {
        // 'as num' safely converts dynamic type to number
        // .toDouble() ensures we always work with decimal numbers
        income += (transaction['amount'] as num).toDouble();
      } else {
        expense += (transaction['amount'] as num).toDouble();
      }
    }

    // Update UI with new calculated values
    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  // ─── ADD Transaction (Create) ────────────────────────────────
  // Inserts a new transaction into Supabase database
  Future<void> _addTransaction() async {

    // Validate — do not proceed if amount is empty
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an amount')),
      );
      return; // stop function here
    }

    try {
      // Get logged-in user's unique ID from Supabase Auth
      // Every authenticated user has a unique UUID
      final userId = supabase.auth.currentUser!.id;

      // Insert new row into transactions table
      // Each key matches a column name in our Supabase table
      await supabase.from('transactions').insert({
        'user_id': userId,
        'type': _selectedType,
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text.trim()),
        'description': _descriptionController.text.trim(),
        'date': DateTime.now().toIso8601String(), // current timestamp
      });

      // mounted check before using context after await
      if (!mounted) return;

      // Clear form fields after successful insert
      _amountController.clear();
      _descriptionController.clear();

      // Close the bottom sheet form
      Navigator.pop(context);

      // Refresh transaction list to show new entry
      _fetchTransactions();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction added successfully!')),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding transaction: $e')),
      );
    }
  }

  // ─── DELETE Transaction ──────────────────────────────────────
  // Removes a transaction from database using its unique ID
  Future<void> _deleteTransaction(String id) async {
    try {
      // .delete() removes the row
      // .eq('id', id) means: only delete where id matches
      // This ensures we delete only the intended row
      await supabase
          .from('transactions')
          .delete()
          .eq('id', id);

      // mounted check before using context after await
      if (!mounted) return;

      // Refresh list after deletion
      _fetchTransactions();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction deleted')),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────
  // Signs out current user from Supabase and returns to AuthPage
  Future<void> _logout() async {
    // signOut() clears the user session from Supabase
    await supabase.auth.signOut();

    // mounted check before using context after await
    if (!mounted) return;

    // pushReplacement removes ExpensePage from navigation stack
    // so user cannot go back to it after logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  // ─── SHOW Add Transaction Form ───────────────────────────────
  // Opens a slide-up bottom sheet containing the add form
  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows sheet to resize with keyboard
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          // viewInsets.bottom = keyboard height
          // This pushes the form above the keyboard automatically
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // wrap content, don't fill screen
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Add Transaction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // ── Type Dropdown ─────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Map each string to a DropdownMenuItem widget
                items: ['Income', 'Expense'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              SizedBox(height: 12),

              // ── Category Dropdown ─────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              SizedBox(height: 12),

              // ── Amount Field ──────────────────────────────────
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (PKR)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // ── Description Field ─────────────────────────────
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // ── Submit Button ─────────────────────────────────
              SizedBox(
                width: double.infinity, // full width button
                child: ElevatedButton(
                  onPressed: _addTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add Transaction',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ─── MAIN UI ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    // Calculate balance on every rebuild
    double balance = _totalIncome - _totalExpense;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ── AppBar ───────────────────────────────────────────────
      appBar: AppBar(
        title: Text('Smart Expense Tracker'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Logout icon button at top right
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────
      // Show spinner while loading, otherwise show content
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [

                // ── Summary Card ───────────────────────────────
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [

                      Text(
                        'Remaining Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 8),

                      // Large balance amount
                      Text(
                        'PKR ${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Income and Expense side by side
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [

                          // ── Income Summary ────────────────────
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_downward,
                                      color: Colors.greenAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text('Income',
                                      style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              Text(
                                'PKR ${_totalIncome.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // ── Expense Summary ───────────────────
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_upward,
                                      color: Colors.redAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text('Expense',
                                      style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              Text(
                                'PKR ${_totalExpense.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ],
                  ),
                ),

                // ── Section Header ─────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // ── Transaction List ───────────────────────────
                // Expanded fills remaining screen space with list
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactions.length,
                          // itemBuilder builds each card one by one
                          // index = position in list (0, 1, 2...)
                          itemBuilder: (context, index) {
                            final t = _transactions[index];
                            final isIncome = t['type'] == 'Income';

                            return Card(
                              margin: EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                // Colored circle icon on the left
                                leading: CircleAvatar(
                                  backgroundColor: isIncome
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isIncome
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),

                                // Category name as main title
                                title: Text(
                                  t['category'] ?? 'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),

                                // Description below title
                                subtitle: Text(t['description'] ?? ''),

                                // Amount + delete button on the right
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'} PKR ${(t['amount'] as num).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isIncome
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.grey),
                                      // Pass transaction id to delete function
                                      onPressed: () =>
                                          _deleteTransaction(t['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      // ── Floating Action Button ─────────────────────────────
      // Green + button at bottom right to open add form
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}