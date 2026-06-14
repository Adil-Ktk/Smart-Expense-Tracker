import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'expense_page.dart';

void main() async {
  // Make sure Flutter is ready before we do anything
  WidgetsFlutterBinding.ensureInitialized();

  // Connect our app to Supabase
  await Supabase.initialize(
    url: 'https://bpvxgmpsfiknzyheczzz.supabase.co',        // project URL
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwdnhnbXBzZmlrbnp5aGVjenp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNDE2NjAsImV4cCI6MjA5NjkxNzY2MH0.mxb6mtGxlCj-uvGrXNymHbbs6Rt_q0FcflPIE5hc7Jk',        // anon key
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Check if user is already logged in
      home: Supabase.instance.client.auth.currentUser == null
          ? AuthPage()       // Not logged in → show login screen
          : ExpensePage(),   // Already logged in → go to app
    );
  }
}