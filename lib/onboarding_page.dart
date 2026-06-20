import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'expense_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {

  final supabase = Supabase.instance.client;

  // ─── Controllers ─────────────────────────────────────────────
  final TextEditingController _nameController = TextEditingController(); // NEW
  final TextEditingController _incomeController = TextEditingController();

  // ─── State ───────────────────────────────────────────────────
  String? _selectedGender;
  String? _selectedMaritalStatus;
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalOptions = ['Single', 'Married', 'Divorced', 'Widowed'];

  // ─── SUBMIT Onboarding Data ──────────────────────────────────
  Future<void> _submitOnboarding() async {

    final name = _nameController.text.trim(); // NEW
    final incomeText = _incomeController.text.trim();

    // ── Validation ──────────────────────────────────────────
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }
    if (incomeText.isEmpty) {
      setState(() => _errorMessage = 'Please enter your monthly income.');
      return;
    }
    if (_selectedGender == null) {
      setState(() => _errorMessage = 'Please select your gender.');
      return;
    }
    if (_selectedMaritalStatus == null) {
      setState(() => _errorMessage = 'Please select your marital status.');
      return;
    }

    final income = double.tryParse(incomeText);
    if (income == null || income <= 0) {
      setState(() => _errorMessage = 'Please enter a valid income amount.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = supabase.auth.currentUser!.id;

      // ── STEP 1: Insert income as first transaction ────────
      await supabase.from('transactions').insert({
        'user_id': userId,
        'type': 'Income',
        'category': 'Salary',
        'amount': income,
        'description': 'Monthly Income',
        'date': DateTime.now().toIso8601String(),
      });

      // ── STEP 2: Insert profile info (now includes name) ────
      await supabase.from('profiles').insert({
        'user_id': userId,
        'name': name, // NEW
        'gender': _selectedGender,
        'marital_status': _selectedMaritalStatus,
      });

      // ── STEP 3: Seed default categories ────────────────────
      final defaultCategories = ['Food', 'Transport', 'Shopping', 'Salary', 'Other'];
      final categoryRows = defaultCategories.map((cat) {
        return {'user_id': userId, 'name': cat};
      }).toList();

      await supabase.from('categories').insert(categoryRows);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ExpensePage()),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              Icon(Icons.waving_hand_rounded, size: 48, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'Let\'s set up\nyour account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Just a few quick questions to personalize your experience',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),

              // ── Name (NEW) ────────────────────────────────
              Text(
                'What is your name?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'e.g. Muhammad Adil',
                  hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.3)),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: colors.primary),
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

              // ── Monthly Income ───────────────────────────
              Text(
                'What is your monthly income?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This becomes your starting balance',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0',
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
              const SizedBox(height: 24),

              // ── Gender ────────────────────────────────────
              Text(
                'Gender',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _genderOptions.map((gender) {
                  final isSelected = _selectedGender == gender;
                  return ChoiceChip(
                    label: Text(gender),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedGender = gender);
                    },
                    selectedColor: colors.primary,
                    backgroundColor: colors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Marital Status ───────────────────────────
              Text(
                'Marital Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _maritalOptions.map((status) {
                  final isSelected = _selectedMaritalStatus == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedMaritalStatus = status);
                    },
                    selectedColor: colors.primary,
                    backgroundColor: colors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: colors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitOnboarding,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}