import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/update_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const ProviderScope(child: CruzaroApp()));
}

class CruzaroApp extends StatefulWidget {
  const CruzaroApp({super.key});

  @override
  State<CruzaroApp> createState() => _CruzaroAppState();
}

class _CruzaroAppState extends State<CruzaroApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen for auth state changes (especially password recovery)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      
      // Handle password recovery event
      if (event == AuthChangeEvent.passwordRecovery) {
        // Navigate to Update Password screen when user clicks reset link
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUZARO ENT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      home: const LoginScreen(),
    );
  }
}