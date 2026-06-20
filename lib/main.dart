import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'expense_page.dart';
import 'onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bpvxgmpsfiknzyheczzz.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwdnhnbXBzZmlrbnp5aGVjenp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNDE2NjAsImV4cCI6MjA5NjkxNzY2MH0.mxb6mtGxlCj-uvGrXNymHbbs6Rt_q0FcflPIE5hc7Jk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C63FF),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1.5),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1E1E2E),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF12121F),
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF12121F),
      ),

      home: const SplashDecider(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SplashDecider
// This widget decides WHERE to send the user:
// - AuthPage (not logged in)
// - OnboardingPage (logged in but never completed onboarding)
// - ExpensePage (logged in and onboarding already done)
// ─────────────────────────────────────────────────────────────
class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});
  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();

    // We delay this call until AFTER the first frame finishes building.
    // Without this, Navigator gets called WHILE Flutter is still building
    // the widget tree, which throws "setState() called during build" /
    // "navigator._debugLocked" errors — especially likely on Web where
    // Supabase can respond almost instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideDestination();
    });
  }

  Future<void> _decideDestination() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // Case 1: Not logged in at all
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
      return;
    }

    // Case 2: Logged in — check if profile exists
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        // No profile row = onboarding never completed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      } else {
        // Profile exists = onboarding already done
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExpensePage()),
        );
      }
    } catch (e) {
      // If anything goes wrong, safest fallback is AuthPage
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading screen while we decide where to send the user
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}















// eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwdnhnbXBzZmlrbnp5aGVjenp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNDE2NjAsImV4cCI6MjA5NjkxNzY2MH0.mxb6mtGxlCj-uvGrXNymHbbs6Rt_q0FcflPIE5hc7Jk