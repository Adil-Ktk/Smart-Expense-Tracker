import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'expense_page.dart';

// This page handles both Login and Signup in one screen
class AuthPage extends StatefulWidget {
  const AuthPage({super.key}); // key helps Flutter identify this widget
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  // ─── Controllers ────────────────────────────────────────────
  // TextEditingController connects to a TextField and lets us
  // read whatever the user typed, or clear the field programmatically
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ─── State Variables ─────────────────────────────────────────
  bool _isLogin = true;       // true = Login mode, false = Signup mode
  bool _isLoading = false;    // true = show spinner, false = show button
  String _errorMessage = '';  // empty means no error to display

  // ─── Supabase Client ─────────────────────────────────────────
  // Supabase.instance.client is the single entry point to:
  // - auth (login, signup, logout)
  // - database (insert, select, delete)
  final supabase = Supabase.instance.client;

  // ─── AUTHENTICATE ────────────────────────────────────────────
  // This function handles both Login and Signup logic
  // It runs when user taps the Login or Sign Up button
  Future<void> _authenticate() async {

    // Read and clean user input from text fields
    // .trim() removes any accidental spaces at start or end
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation — stop if fields are empty
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email and password.';
      });
      return; // exit function early, don't call Supabase
    }

    // Show loading spinner and clear any previous error message
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {

      if (_isLogin) {
        // ── LOGIN ──────────────────────────────────────────────
        // signInWithPassword() sends credentials to Supabase Auth
        // Supabase checks if the user exists and password is correct
        // If wrong → throws an exception which we catch below
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // ── SIGNUP ─────────────────────────────────────────────
        // signUp() creates a brand new user account in Supabase Auth
        // Supabase stores the email and hashed password securely
        // No need to create a users table — Supabase handles this
        await supabase.auth.signUp(
          email: email,
          password: password,
        );
      }

      // ── After successful auth ──────────────────────────────
      // 'mounted' tells us if this widget is still in the widget tree
      // If user navigates away during the async call above,
      // 'mounted' will be false and we should NOT use 'context'
      // because the screen no longer exists in memory
      if (!mounted) return;

      // pushReplacement navigates to ExpensePage AND removes
      // AuthPage from the navigation stack so user cannot
      // go back to login screen by pressing back button
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ExpensePage()),
      );

    } catch (e) {
      // Supabase throws exceptions for wrong password, invalid email etc.
      // We catch them here and display the message to the user

      // mounted check before setState — screen must still be open
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString(); // show error below the button
      });

    } finally {
      // finally block ALWAYS runs — whether try succeeded or catch ran
      // Perfect place to hide the loading spinner in all cases
      // We use if(mounted) instead of return inside finally
      // because 'return' inside finally is considered bad practice —
      // it can silently swallow exceptions and confuse control flow
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Center(
        // SingleChildScrollView prevents overflow when keyboard appears
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ── App Icon ──────────────────────────────────────
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.green,
              ),
              SizedBox(height: 16),

              // ── Title ─────────────────────────────────────────
              // Changes text based on current mode (login or signup)
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),

              // ── Email Field ───────────────────────────────────
              // controller links this field to _emailController
              // so we can read its value later in _authenticate()
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),

              // ── Password Field ────────────────────────────────
              // obscureText: true hides characters as user types
              // This is standard behavior for password fields
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),

              // ── Error Message ─────────────────────────────────
              // This widget only appears when _errorMessage is not empty
              // 'if' inside a Column acts like a conditional widget
              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 16),

              // ── Login / Signup Button ─────────────────────────
              SizedBox(
                width: double.infinity, // stretch button to full width
                child: ElevatedButton(
                  // When _isLoading is true, onPressed is set to null
                  // A null onPressed automatically disables the button
                  // This prevents user from tapping multiple times
                  onPressed: _isLoading ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Show spinner when loading, show text when idle
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? 'Login' : 'Sign Up',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              SizedBox(height: 16),

              // ── Toggle Between Login and Signup ───────────────
              // TextButton is a flat button with no background
              // Tapping it flips _isLogin between true and false
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin; // flip mode
                    _errorMessage = '';   // clear errors on mode switch
                  });
                },
                child: Text(
                  // Ternary operator: condition ? ifTrue : ifFalse
                  _isLogin
                      ? "Don't have an account? Sign Up"
                      : 'Already have an account? Login',
                  style: TextStyle(color: Colors.green),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}