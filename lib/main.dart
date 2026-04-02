import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/users_module.dart';
import 'screens/flight_module.dart';
import 'screens/dashboard_view_module.dart';
import 'screens/uld_module.dart';
import 'screens/awb_module.dart';
import 'screens/delivers_module.dart';
import 'screens/driver_module.dart';
import 'screens/other_modules.dart';
import 'screens/system_bf_module.dart';
import 'screens/area_nobreak_module.dart';
import 'screens/control_flight_module.dart';


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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {

        // Clear text fields to trick Google Chrome into not prompting for password save
        _emailController.clear();
        _passwordController.clear();

        // Navigation to Dashboard!
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, _, _) => const DashboardScreen(),
              transitionsBuilder: (_, animation, _, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          content: Text('Error: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (_animation.value * 50),
                    left: -100 + (_animation.value * 30),
                    child: childShape(400, const Color(0xFF4f46e5)),
                  ),
                  Positioned(
                    bottom: -50 - (_animation.value * 40),
                    right: -50 + (_animation.value * 50),
                    child: childShape(300, const Color(0xFFec4899)),
                  ),
                  Positioned(
                    top:
                        MediaQuery.of(context).size.height / 2 -
                        125 +
                        (_animation.value * 30),
                    left:
                        MediaQuery.of(context).size.width / 2 -
                        125 -
                        (_animation.value * 30),
                    child: childShape(250, const Color(0xFF06b6d4)),
                  ),
                ],
              );
            },
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Warehouse 1717',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to your account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94a3b8),
                              ),
                            ),
                            const SizedBox(height: 30),

                            const Text(
                              'Email Address',
                              style: TextStyle(
                                color: Color(0xFFcbd5e1),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              'example@email.com',
                              false,
                              _emailController,
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Password',
                              style: TextStyle(
                                color: Color(0xFFcbd5e1),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              '••••••••',
                              true,
                              _passwordController,
                            ),
                            const SizedBox(height: 30),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366f1),
                                    Color(0xFFa855f7),
                                    Color(0xFFec4899),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFa855f7,
                                    ).withAlpha(102),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _loginUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget childShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildTextField(
    String hintText,
    bool isPassword,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isPasswordObscured : false,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: const ['off'],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withAlpha(76)),
        filled: true,
        fillColor: Colors.white.withAlpha(13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordObscured
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white.withAlpha(128),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8b5cf6), width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// DASHBOARD SCREEN WITH PREMIUM NAVIGATION RAIL
// ---------------------------------------------------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Dashboard content placeholder based on selection

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'Usuario';

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        final bgMain = dark ? const Color(0xFF0f172a) : const Color(0xFFF4F7F9);
        final bgSidebar = dark
            ? const Color(0xFF1e293b)
            : const Color(0xFFffffff);
        final borderWhite = dark
            ? Colors.white.withAlpha(15)
            : const Color(0xFFE5E7EB);
        final textP = dark ? Colors.white : const Color(0xFF111827);

        return Scaffold(
          backgroundColor: bgMain,
          body: ValueListenableBuilder<String>(
            valueListenable: appLanguage,
            builder: (context, lang, child) {
              return Row(
                children: [
                  // Sidebar
                  Container(
                    width: 260,
                    decoration: BoxDecoration(
                      color: bgSidebar,
                      border: Border(
                        right: BorderSide(color: borderWhite, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Logo Area
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366f1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.warehouse_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Warehouse 1717',
                                style: TextStyle(
                                  color: textP,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Navigation Items
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildNavItem(
                                Icons.dashboard_rounded,
                                'Dashboard',
                                0,
                              ),
                              _buildNavItem(
                                Icons.flight_land_rounded,
                                'Flight',
                                1,
                              ),
                              _buildNavItem(
                                Icons.inventory_2_rounded,
                                'ULD',
                                2,
                              ),
                              _buildNavItem(
                                Icons.description_rounded,
                                'AWB',
                                3,
                              ),
                              _buildNavItem(
                                Icons.local_shipping_outlined,
                                'Delivers',
                                4,
                              ),
                              _buildNavItem(
                                Icons.people_alt_rounded,
                                'Users',
                                5,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  bottom: 8,
                                ),
                                child: Text(
                                  'OPERACIONES',
                                  style: TextStyle(
                                    color: dark
                                        ? const Color(0xFF64748b)
                                        : const Color(0xFF6B7280),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              _buildNavItem(
                                Icons.settings_system_daydream_rounded,
                                'System',
                                6,
                              ),
                              _buildNavItem(
                                Icons.support_agent_rounded,
                                'Coordinator',
                                7,
                              ),
                              _buildNavItem(
                                Icons.location_on_rounded,
                                'Location',
                                8,
                              ),
                              _buildNavItem(
                                Icons.local_shipping_rounded,
                                'Driver',
                                9,
                              ),
                              _buildNavItem(
                                Icons.computer_rounded,
                                'System (BF)',
                                10,
                              ),
                              _buildNavItem(
                                Icons.dashboard_customize_rounded,
                                'Area (No break)',
                                11,
                              ),
                              _buildNavItem(
                                Icons.airplane_ticket_rounded,
                                'Control (Flight)',
                                12,
                              ),
                            ],
                          ),
                        ),

                        // Theme & Language
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  dark
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  color: const Color(0xFF64748b),
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => isDarkMode.value = !dark,
                                tooltip: dark ? 'Modo Claro' : 'Modo Oscuro',
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.language_rounded,
                                color: Color(0xFF64748b),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Idioma',
                                style: TextStyle(
                                  color: dark
                                      ? const Color(0xFF94a3b8)
                                      : const Color(0xFF4B5563),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: appLanguage.value,
                                  dropdownColor: dark
                                      ? const Color(0xFF1e293b)
                                      : Colors.white,
                                  style: TextStyle(
                                    color: textP,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Color(0xFF64748b),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'en',
                                      child: Text('EN'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'es',
                                      child: Text('ES'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) appLanguage.value = v;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // User Profile & Logout
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: borderWhite)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF4f46e5),
                                child: Text(
                                  userEmail.isNotEmpty
                                      ? userEmail[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userEmail.split('@')[0],
                                      style: TextStyle(
                                        color: textP,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Admin',
                                      style: TextStyle(
                                        color: dark
                                            ? const Color(0xFF94a3b8)
                                            : const Color(0xFF6B7280),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFef4444),
                                  size: 20,
                                ),
                                tooltip: 'Cerrar Sesión',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content Area
                  Expanded(
                    child: Container(
                      color:
                          bgMain, // Dynamically changes to light or dark background
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page Body - dynamically rendered per module
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              child: _buildBodyContent(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBodyContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const DashboardViewModule(),
        FlightModule(isActive: _selectedIndex == 1),
        UldModule(isActive: _selectedIndex == 2),
        AwbModule(isActive: _selectedIndex == 3),
        DeliversModule(isActive: _selectedIndex == 4),
        UsersModule(isActive: _selectedIndex == 5),
        const SystemModule(),
        const CoordinatorModule(singlePanelMode: true),
        const LocationModule(),
        const DriverModule(),
        const SystemBfModule(),
        const AreaNobreakModule(),
        const ControlFlightModule(),
      ],
    );
  }


  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    final bool dark = isDarkMode.value;
    final Color textP = dark ? Colors.white : const Color(0xFF111827);
    final Color textS = dark
        ? const Color(0xFF94a3b8)
        : const Color(0xFF4B5563);
    final Color activeColor = dark
        ? const Color(0xFF818cf8)
        : const Color(0xFF4f46e5);
    final Color activeBg = dark
        ? const Color(0xFF6366f1).withAlpha(25)
        : const Color(0xFF6366f1).withAlpha(20);
    final Color activeBorder = dark
        ? const Color(0xFF6366f1).withAlpha(76)
        : const Color(0xFF6366f1).withAlpha(30);

    return InkWell(
      onTap: () => _onDestinationSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? activeBg : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? activeColor : textS, size: 22),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : textP,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
