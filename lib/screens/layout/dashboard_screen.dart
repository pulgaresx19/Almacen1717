import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart'; // To get appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData, scaffoldMessengerKey
import '../auth/login_screen.dart';

import '../users_module.dart';
import '../flight_module.dart';
import '../dashboard_view_module.dart';
import '../uld_module.dart';
import '../awb_module.dart';
import '../delivers_module.dart';
import '../driver_module.dart';
import '../other_modules.dart';
import '../system_bf_module.dart';
import '../area_nobreak_module.dart';
import '../flights_v2/flights_v2_screen.dart';
import '../ulds_v2/ulds_v2_screen.dart';
import '../system_v2/system_v2_screen.dart';
import '../coordinator_v2/coordinator_v2_screen.dart';
import '../awbs_v2/awbs_v2_screen.dart';
import '../delivers_v2/delivers_v2_screen.dart';
import '../location_v2/location_v2_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Future<void> _logout() async {
    currentUserData.value = null;
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

  void _showProfileModal(BuildContext context, bool dark, Color textP, Color textS, Color borderWhite) {
    bool isUploading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Profile',
      barrierColor: Colors.black.withAlpha(20),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (BuildContext modalContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 90),
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Usuario';
                  final avatarUrl = currentUserData.value?['avatar-url'] as String?;
                  
                  return Container(
                    width: 260, // Matches sidebar exactly
                    padding: const EdgeInsets.only(top: 12, bottom: 32, left: 24, right: 24),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1e293b) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderWhite.withAlpha(50)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         // Bottom sheet handle
                         Container(
                           width: 40,
                           height: 4,
                           margin: const EdgeInsets.only(bottom: 12),
                           decoration: BoxDecoration(
                             color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                             borderRadius: BorderRadius.circular(2),
                           ),
                         ),
                         // Title & Close Button
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             const SizedBox(width: 20), // Spacer for balance
                             Text(appLanguage.value == 'es' ? 'Mi Perfil' : 'My Profile', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                             InkWell(
                               onTap: () => Navigator.pop(context),
                               child: Container(
                                 padding: const EdgeInsets.all(4),
                                 decoration: BoxDecoration(
                                   color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                   shape: BoxShape.circle,
                                 ),
                                 child: Icon(Icons.close_rounded, color: textS, size: 14),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 24),
                   Stack(
                     alignment: Alignment.center,
                     children: [
                       CircleAvatar(
                         radius: 40,
                         backgroundColor: const Color(0xFF4f46e5),
                         backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                         child: avatarUrl == null || avatarUrl.isEmpty ? Text(
                           (currentUserData.value?['full-name'] as String?)?.isNotEmpty == true
                               ? currentUserData.value!['full-name'][0].toUpperCase()
                               : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U'),
                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                         ) : null,
                       ),
                       if (isUploading)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(128),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                       Positioned(
                         bottom: 0,
                         right: 0,
                         child: InkWell(
                           onTap: () async {
                              if (isUploading) return;
                              
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );

                              if (image == null) return;
                              setModalState(() { isUploading = true; });

                              try {
                                final bytes = await image.readAsBytes();
                                final userId = Supabase.instance.client.auth.currentUser?.id;
                                if (userId == null) throw Exception("User not authenticated");

                                final fileExt = image.name.split('.').last.isEmpty ? 'jpg' : image.name.split('.').last;
                                final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                                await Supabase.instance.client.storage.from('avatars').uploadBinary(
                                  fileName,
                                  bytes,
                                  fileOptions: FileOptions(contentType: image.mimeType ?? 'image/jpeg'),
                                );

                                final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

                                await Supabase.instance.client.from('users').update({
                                  'avatar-url': publicUrl,
                                }).eq('id', userId);

                                if (currentUserData.value != null) {
                                  final Map<String, dynamic> updatedData = Map.from(currentUserData.value!);
                                  updatedData['avatar-url'] = publicUrl;
                                  currentUserData.value = updatedData;
                                }
                                
                                setModalState(() { isUploading = false; });
                                if (modalContext.mounted) Navigator.pop(modalContext);
                              } catch (e) {
                                debugPrint('Avatar Error: $e');
                                setModalState(() { isUploading = false; });
                                scaffoldMessengerKey.currentState?.showSnackBar(
                                  SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
                                );
                              }
                           },
                           child: Container(
                             padding: const EdgeInsets.all(6),
                             decoration: BoxDecoration(
                               color: const Color(0xFF6366f1),
                               shape: BoxShape.circle,
                               border: Border.all(color: dark ? const Color(0xFF1e293b) : Colors.white, width: 2),
                             ),
                             child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                           ),
                         ),
                       )
                     ],
                   ),
                   const SizedBox(height: 16),
                   Text(
                     currentUserData.value?['full-name'] ?? userEmail.split('@')[0],
                     style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 16),
                   ),
                   Text(
                     currentUserData.value?['position'] ?? 'Admin',
                     style: TextStyle(color: textS, fontSize: 14),
                   ),
                ],
              ),
            );
          }
        ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent(bool dark, Color bgSidebar, Color borderWhite, Color textP, Color textS, Function(String) can, String userEmail, bool isTablet) {
    return Container(
                        width: 260,
                        decoration: BoxDecoration(
                          color: bgSidebar,
                          border: Border(
                            right: BorderSide(color: borderWhite, width: 1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.only(right: 16, top: 16, bottom: 4),
                              child: IconButton(
                                icon: Icon(isTablet ? Icons.close_rounded : Icons.menu_open_rounded, color: const Color(0xFF64748b), size: 20),
                                onPressed: () {
                                  if (isTablet) { _scaffoldKey.currentState?.closeDrawer(); } else { isSidebarExpandedNotifier.value = false; }
                                },
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: 'Collapse sidebar',
                              ),
                            ),
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
                              Expanded(
                                child: Text(
                                  'Warehouse 1717',
                                  style: TextStyle(
                                    color: textP,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                              if (can('dashboard'))
                                _buildNavItem(
                                  Icons.dashboard_rounded,
                                  'Dashboard',
                                  0,
                                ),
                              if (can('flights'))
                                _buildNavItem(
                                  Icons.flight_land_rounded,
                                  'Flight',
                                  1,
                                ),
                              if (can('flights'))
                                _buildNavItem(
                                  Icons.flight_outlined,
                                  'Flights',
                                  12,
                                ),
                              if (can('ulds'))
                                _buildNavItem(
                                  Icons.inventory_2_rounded,
                                  'ULD',
                                  2,
                                ),
                              if (can('ulds'))
                                _buildNavItem(
                                  Icons.inventory_2_outlined,
                                  'ULDs',
                                  13,
                                ),
                              if (can('awbs'))
                                _buildNavItem(
                                  Icons.description_rounded,
                                  'AWB',
                                  3,
                                ),
                              if (can('awbs'))
                                _buildNavItem(
                                  Icons.description_outlined,
                                  'AWBs V2',
                                  16,
                                ),

                              if (can('delivers'))
                                _buildNavItem(
                                  Icons.local_shipping_outlined,
                                  'Delivers',
                                  4,
                                ),
                              if (can('delivers'))
                                _buildNavItem(
                                  Icons.local_shipping_outlined,
                                  'Delivers V2',
                                  17,
                                ),
                              if (can('users'))
                                _buildNavItem(
                                  Icons.people_alt_rounded,
                                  'Users',
                                  5,
                                ),
                              if ((can('system') || can('coordinator') || can('location') || can('driver') || can('system_bf') || can('area_nobreak')) &&
                                  (currentUserData.value?['position'] == 'Supervisor' || currentUserData.value?['position'] == 'Manager' || currentUserData.value?['position'] == 'Administrator'))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16.0,
                                    bottom: 8,
                                    top: 16.0,
                                  ),
                                  child: Text(
                                    appLanguage.value == 'es' ? 'OPERACIONES' : 'OPERATIONS',
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
                              if (can('system'))
                                _buildNavItem(
                                  Icons.settings_system_daydream_rounded,
                                  'System',
                                  6,
                                ),
                              if (can('system'))
                                _buildNavItem(
                                  Icons.settings_system_daydream_outlined,
                                  'System V2',
                                  14,
                                ),
                              if (can('coordinator'))
                                _buildNavItem(
                                  Icons.support_agent_rounded,
                                  'Coordinator',
                                  7,
                                ),
                              if (can('coordinator'))
                                _buildNavItem(
                                  Icons.support_agent_outlined,
                                  'Coordinator V2',
                                  15,
                                ),

                              if (can('location'))
                                _buildNavItem(
                                  Icons.location_on_rounded,
                                  'Location',
                                  8,
                                ),
                              if (can('location'))
                                _buildNavItem(
                                  Icons.location_on_outlined,
                                  'Location V2',
                                  18,
                                ),
                              if (can('driver'))
                                _buildNavItem(
                                  Icons.local_shipping_rounded,
                                  'Driver',
                                  9,
                                ),
                              if (can('system_bf'))
                                _buildNavItem(
                                  Icons.computer_rounded,
                                  'System (BF)',
                                  10,
                                ),
                              if (can('area_nobreak'))
                                _buildNavItem(
                                  Icons.dashboard_customize_rounded,
                                  'Area (No break)',
                                  11,
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
                          child: ValueListenableBuilder<Map<String, dynamic>?>(
                            valueListenable: currentUserData,
                            builder: (context, userData, _) {
                              final String? currentAvatarConfig = userData?['avatar-url'];
                              return Row(
                                children: [
                                  InkWell(
                                    onTap: () => _showProfileModal(context, dark, textP, textS, borderWhite),
                                    borderRadius: BorderRadius.circular(20),
                                    child: CircleAvatar(
                                      backgroundColor: const Color(0xFF4f46e5),
                                      backgroundImage: currentAvatarConfig != null && currentAvatarConfig.isNotEmpty ? NetworkImage(currentAvatarConfig) : null,
                                      child: currentAvatarConfig == null || currentAvatarConfig.isEmpty ? Text(
                                        (userData?['full-name'] as String?)?.isNotEmpty == true
                                            ? userData!['full-name'][0].toUpperCase()
                                            : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _showProfileModal(context, dark, textP, textS, borderWhite),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userData?['full-name'] ?? userEmail.split('@')[0],
                                            style: TextStyle(
                                              color: textP,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            userData?['position'] ?? 'Admin',
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
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'Usuario';

    final apMap = currentUserData.value?['access-page'] as Map?;
    // Safely parse permissions. If null, we'll allow (backward compatibility for old admin users).
    bool can(String key) => apMap == null || apMap[key] == true;

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
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        final isTablet = MediaQuery.of(context).size.width <= 1024;
        final isPhone = MediaQuery.of(context).size.width < 600;

        if (isPhone) {
          return Scaffold(
            backgroundColor: bgMain,
            appBar: AppBar(
              backgroundColor: bgSidebar,
              iconTheme: IconThemeData(color: textP),
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text('Location Scanner', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: currentUserData,
                  builder: (context, userData, _) {
                    final String? currentAvatarConfig = userData?['avatar-url'];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _showProfileModal(context, dark, textP, textS, borderWhite),
                          borderRadius: BorderRadius.circular(20),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF4f46e5),
                            backgroundImage: currentAvatarConfig != null && currentAvatarConfig.isNotEmpty ? NetworkImage(currentAvatarConfig) : null,
                            child: currentAvatarConfig == null || currentAvatarConfig.isEmpty ? Text(
                              (userData?['full-name'] as String?)?.isNotEmpty == true
                                  ? userData!['full-name'][0].toUpperCase()
                                  : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                            ) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userData?['full-name'] ?? userEmail.split('@')[0],
                          style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, color: Color(0xFFef4444), size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  }
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(color: borderWhite, height: 1.0),
              ),
            ),
            body: const LocationV2Screen(isActive: true),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgMain,
          appBar: isTablet ? AppBar(
            backgroundColor: bgSidebar,
            iconTheme: IconThemeData(color: textP),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text('Warehouse 1717', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: borderWhite, height: 1.0),
            )
          ) : null,
          drawer: isTablet ? Drawer(
             width: 260,
             backgroundColor: bgSidebar,
             child: _buildSidebarContent(dark, bgSidebar, borderWhite, textP, textS, can, userEmail, true),
          ) : null,
          body: ValueListenableBuilder<String>(
            valueListenable: appLanguage,
            builder: (context, lang, child) {
              return Row(
                children: [
                  if (!isTablet) ...[
                    ValueListenableBuilder<bool>(
                      valueListenable: isSidebarExpandedNotifier,
                      builder: (context, isSidebarExpanded, _) {
                        if (!isSidebarExpanded) return const SizedBox.shrink();
                        return _buildSidebarContent(dark, bgSidebar, borderWhite, textP, textS, can, userEmail, false);
                      }
                    ),
                  ],

                  // Main Content Area
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isSidebarExpandedNotifier,
                      builder: (context, expanded, _) {
                        return Stack(
                          children: [
                            Container(
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
                            if (!expanded && !isTablet)
                              Positioned(
                                top: 40,
                                left: 24,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      isSidebarExpandedNotifier.value = true;
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: dark ? const Color(0xFF1e293b) : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: borderWhite),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
                                        ],
                                      ),
                                      child: Icon(Icons.menu_rounded, color: textP, size: 22),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
        FlightsV2Screen(isActive: _selectedIndex == 12),
        UldsV2Screen(isActive: _selectedIndex == 13),
        const SystemV2Screen(),
        const CoordinatorV2Screen(),
        AwbsV2Screen(isActive: _selectedIndex == 16),
        DeliversV2Screen(isActive: _selectedIndex == 17),
        LocationV2Screen(isActive: _selectedIndex == 18),
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
