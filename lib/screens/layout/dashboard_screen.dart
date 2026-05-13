import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart'; // To get appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData, scaffoldMessengerKey
import '../auth/login_screen.dart';

import 'dashboard_sidebar.dart';
import 'dashboard_modals.dart';

import '../users_module.dart';
import '../dashboard_view_module.dart';
import '../system_bf_v2/system_bf_v2_screen.dart';

import '../flights_v2/flights_v2_screen.dart';
import '../system_v2/system_v2_screen.dart';
import '../coordinator_v2/coordinator_v2_screen.dart';
import '../awbs_v2/awbs_v2_screen.dart';
import '../delivers_v2/delivers_v2_screen.dart';
import '../damages_v2/damages_v2_screen.dart';
import '../location_v2/location_v2_screen.dart';
import '../driver_v2/driver_v2_screen.dart';
import '../driver_bf_v2/driver_bf_v2_screen.dart';
import '../no_break_area_v2/no_break_area_v2_screen.dart';
import '../../services/realtime_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    realtimeService.init();
    realtimeService.broadcastMessages.addListener(_checkBroadcastMessages);
  }

  @override
  void dispose() {
    realtimeService.broadcastMessages.removeListener(_checkBroadcastMessages);
    super.dispose();
  }

  bool _isShowingBroadcast = false;

  void _checkBroadcastMessages() {
    if (!mounted) return;
    if (_isShowingBroadcast) return;
    final messages = realtimeService.broadcastMessages.value;
    if (messages.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final String myId = user.id;
    final String myRole = currentUserData.value?['position'] ?? 'Agent';

    final now = DateTime.now();

    for (var msg in messages) {
       final createdAtStr = msg['created_at']?.toString();
       if (createdAtStr == null) continue;
       
       final createdAt = DateTime.tryParse(createdAtStr)?.toLocal();
       if (createdAt == null) continue;
       
       // Filter 1: Max 10 minutes old
       final diff = now.difference(createdAt);
       if (diff.inMinutes > 10) continue; 
       
       // Filter 2: Target role
       final role = msg['target_role']?.toString() ?? 'All';
       if (role != 'All' && role != myRole) continue;
       
       // Filter 3: Already read?
       final rawReadBy = msg['read_by'];
       List<dynamic> readByList = [];
       if (rawReadBy is List) {
         readByList = rawReadBy;
       } 
       
       if (readByList.contains(myId)) continue; 
       
       // Found a valid message! Show it.
       _isShowingBroadcast = true;
       showIncomingBroadcastDialog(context, msg, myId, () {
          _isShowingBroadcast = false;
          _checkBroadcastMessages(); // Check again in case there are multiple pending messages
       });
       break; // Only show one at a time
    }
  }



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



  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'Usuario';

    final apMap = currentUserData.value?['access_page'] as Map?;
    // Safely parse permissions. If null, we'll allow (backward compatibility for old admin users).
    bool can(String key) => apMap == null || apMap[key] == true;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        final bgMain = dark ? const Color(0xFF0f172a) : const Color(0xFFF4F7F9);
        final bgSidebar = dark
            ? const Color(0xFF0f172a)
            : Colors.white;
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
                    final String? currentAvatarConfig = userData?['avatar_url'];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => showProfileModal(context, dark, textP, textS, borderWhite),
                          borderRadius: BorderRadius.circular(20),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF4f46e5),
                            backgroundImage: currentAvatarConfig != null && currentAvatarConfig.isNotEmpty ? NetworkImage(currentAvatarConfig) : null,
                            child: currentAvatarConfig == null || currentAvatarConfig.isEmpty ? Text(
                              (userData?['full_name'] as String?)?.isNotEmpty == true
                                  ? userData!['full_name'][0].toUpperCase()
                                  : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                            ) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userData?['full_name'] ?? userEmail.split('@')[0],
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
             child: DashboardSidebar(
               dark: dark,
               bgSidebar: bgSidebar,
               borderWhite: borderWhite,
               textP: textP,
               textS: textS,
               can: can,
               userEmail: userEmail,
               isTablet: true,
               selectedIndex: _selectedIndex,
               onDestinationSelected: _onDestinationSelected,
               onLogout: _logout,
               onCloseDrawer: () => _scaffoldKey.currentState?.closeDrawer(),
             ),
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
                        return DashboardSidebar(
                          dark: dark,
                          bgSidebar: bgSidebar,
                          borderWhite: borderWhite,
                          textP: textP,
                          textS: textS,
                          can: can,
                          userEmail: userEmail,
                          isTablet: false,
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: _onDestinationSelected,
                          onLogout: _logout,
                          onCloseDrawer: () => isSidebarExpandedNotifier.value = false,
                        );
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
        const SizedBox.shrink(), // Formerly V1 FlightModule
        const SizedBox.shrink(), // Formerly V1 UldModule
        const SizedBox.shrink(), // Formerly V1 AwbModule
        const SizedBox.shrink(), // Formerly V1 DeliversModule
        UsersModule(isActive: _selectedIndex == 5),
        const SizedBox.shrink(), // Formerly V1 SystemModule
        const SizedBox.shrink(), // Formerly V1 CoordinatorModule
        const SizedBox.shrink(), // Formerly V1 LocationModule
        const SizedBox.shrink(), // Formerly V1 DriverModule
        const SystemBfV2Screen(),
        NoBreakAreaV2Screen(isActive: _selectedIndex == 11),
        FlightsV2Screen(isActive: _selectedIndex == 12),
        const SizedBox.shrink(), // Formerly UldsV2Screen
        const SystemV2Screen(),
        const CoordinatorV2Screen(),
        AwbsV2Screen(isActive: _selectedIndex == 16),
        DeliversV2Screen(isActive: _selectedIndex == 17),
        LocationV2Screen(isActive: _selectedIndex == 18),
        DriverV2Screen(isActive: _selectedIndex == 19),
        DriverBfV2Screen(isActive: _selectedIndex == 20),
        DamagesV2Screen(isActive: _selectedIndex == 21),
      ],
    );
  }
}
