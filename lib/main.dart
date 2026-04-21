import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://rbefksdbdosxoxicfqww.supabase.co',
    anonKey: 'sb_publishable_ZH5JD9AlFYTVYcOx-DckPg_9WqzrRkf',
  );

  runApp(const AlmacenApp());
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Global settings
final ValueNotifier<String> appLanguage = ValueNotifier<String>('en');
final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);
final ValueNotifier<bool> isSidebarExpandedNotifier = ValueNotifier<bool>(true);
final ValueNotifier<Map<String, dynamic>?> currentUserData = ValueNotifier<Map<String, dynamic>?>(null);

class AlmacenApp extends StatelessWidget {
  const AlmacenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Warehouse 1717',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366f1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0f172a),
      ),
      home: const LoginScreen(),
    );
  }
}