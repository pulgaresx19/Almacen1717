import 'package:flutter/material.dart';

import '../../main.dart'; // To get appLanguage, isDarkMode, currentUserData
import 'dashboard_modals.dart';

class DashboardSidebar extends StatelessWidget {
  final bool dark;
  final Color bgSidebar;
  final Color borderWhite;
  final Color textP;
  final Color textS;
  final Function(String) can;
  final String userEmail;
  final bool isTablet;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final VoidCallback onLogout;
  final VoidCallback onCloseDrawer;

  const DashboardSidebar({
    super.key,
    required this.dark,
    required this.bgSidebar,
    required this.borderWhite,
    required this.textP,
    required this.textS,
    required this.can,
    required this.userEmail,
    required this.isTablet,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.onCloseDrawer,
  });

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;
    final Color activeColor = dark
        ? const Color(0xFF818cf8)
        : const Color(0xFF4f46e5);
    final Color activeBg = dark
        ? const Color(0xFF6366f1).withAlpha(25)
        : const Color(0xFF6366f1).withAlpha(20);
    final Color activeBorder = dark
        ? const Color(0xFF6366f1).withAlpha(76)
        : const Color(0xFF6366f1).withAlpha(30);
    final Color hoverBg = dark
        ? Colors.white.withAlpha(10)
        : Colors.black.withAlpha(5);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(12),
          hoverColor: hoverBg,
          splashColor: activeColor.withAlpha(20),
          highlightColor: activeColor.withAlpha(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeBorder : Colors.transparent,
                width: 1,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.campaign_rounded, color: Color(0xFF64748b), size: 20),
                  onPressed: () => showBroadcastModal(context, dark, textP, textS, borderWhite),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: appLanguage.value == 'es' ? 'Enviar Notificación' : 'Broadcast Message',
                ),
                IconButton(
                  icon: Icon(isTablet ? Icons.close_rounded : Icons.menu_open_rounded, color: const Color(0xFF64748b), size: 20),
                  onPressed: onCloseDrawer,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: 'Collapse sidebar',
                ),
              ],
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
                    'Flights',
                    12,
                  ),

                if (can('awbs'))
                  _buildNavItem(
                    Icons.description_outlined,
                    'Storage',
                    16,
                  ),

                if (can('delivers'))
                  _buildNavItem(
                    Icons.local_shipping_outlined,
                    'Delivers',
                    17,
                  ),
                if (can('damages'))
                  _buildNavItem(
                    Icons.broken_image_outlined,
                    'Damages',
                    21,
                  ),
                if (can('users'))
                  _buildNavItem(
                    Icons.people_alt_rounded,
                    'Users',
                    5,
                  ),
                if ((can('system') || can('coordinator') || can('location') || can('driver') || can('system_bf')) &&
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
                    Icons.settings_system_daydream_outlined,
                    'System',
                    14,
                  ),
                if (can('coordinator'))
                  _buildNavItem(
                    Icons.support_agent_outlined,
                    'Coordinator',
                    15,
                  ),

                if (can('location'))
                  _buildNavItem(
                    Icons.location_on_outlined,
                    'Location',
                    18,
                  ),
                if (can('driver'))
                  _buildNavItem(
                    Icons.local_shipping_outlined,
                    'Driver',
                    19,
                  ),
                if (can('system_bf'))
                  _buildNavItem(
                    Icons.computer_rounded,
                    'System (BF)',
                    10,
                  ),
                if (can('driver_bf'))
                  _buildNavItem(
                    Icons.local_shipping_outlined,
                    'Driver (BF)',
                    20,
                  ),
                if (can('area_nobreak'))
                  _buildNavItem(
                    Icons.grid_view_rounded,
                    appLanguage.value == 'es' ? 'Área (No Break)' : 'Area (No Break)',
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
                final String? currentAvatarConfig = userData?['avatar_url'];
                return Row(
                  children: [
                    InkWell(
                      onTap: () => showProfileModal(context, dark, textP, textS, borderWhite),
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF4f46e5),
                        backgroundImage: currentAvatarConfig != null && currentAvatarConfig.isNotEmpty ? NetworkImage(currentAvatarConfig) : null,
                        child: currentAvatarConfig == null || currentAvatarConfig.isEmpty ? Text(
                          (userData?['full_name'] as String?)?.isNotEmpty == true
                              ? userData!['full_name'][0].toUpperCase()
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
                        onTap: () => showProfileModal(context, dark, textP, textS, borderWhite),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData?['full_name'] ?? userEmail.split('@')[0],
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
                      onPressed: onLogout,
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
}
