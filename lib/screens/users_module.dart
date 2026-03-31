import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;
import 'add_user_screen.dart';

class UsersModule extends StatefulWidget {
  const UsersModule({super.key});

  @override
  State<UsersModule> createState() => _UsersModuleState();
}

class _UsersModuleState extends State<UsersModule> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff);
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final Color iconColor = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Header Row (Title, Search, Buttons)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showAddForm)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _showAddForm = false),
                            icon: Icon(Icons.arrow_back_rounded, color: textP, size: 28),
                            padding: const EdgeInsets.only(right: 8),
                            constraints: const BoxConstraints(),
                          ),
                          Text(appLanguage.value == 'es' ? 'Añadir Nuevo Usuario' : 'Add New User', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text(appLanguage.value == 'es' ? 'Usuarios Activos' : 'Active Users', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(appLanguage.value == 'es' ? 'Registra un nuevo usuario en el sistema.' : 'Register a new user in the system.', style: TextStyle(color: textS, fontSize: 13))
                    else
                      Text(appLanguage.value == 'es' ? 'Administración de roles y accesos del personal.' : 'Management of staff roles and accesses.', style: TextStyle(color: textS, fontSize: 13)),
                  ],
            ),
            const Spacer(),
            
            // Search Box
            if (!_showAddForm)
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCard),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textP, fontSize: 13),
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: appLanguage.value == 'es' ? 'Buscar usuario...' : 'Search user...',
                    hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            
            // Add User Button
            if (!_showAddForm)
              ElevatedButton.icon(
                onPressed: () => setState(() => _showAddForm = true),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(appLanguage.value == 'es' ? 'Añadir Usuario' : 'Add User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            const SizedBox(width: 8),

            // Refresh Button
            if (!_showAddForm)
              IconButton(
                onPressed: () => setState(() {}),
                icon: Icon(Icons.refresh_rounded, color: iconColor, size: 18),
                tooltip: appLanguage.value == 'es' ? 'Refrescar' : 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: dark ? Colors.white.withAlpha(25) : const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.all(12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCard),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _showAddForm 
                  ? AddUserScreen(
                      isInline: true,
                      onPop: (_) => setState(() => _showAddForm = false),
                    )
                  : Stack(
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: Supabase.instance.client.from('Users').select(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                        );
                      }

                      var users = snapshot.data ?? [];
                      
                      if (_searchController.text.isNotEmpty) {
                        final term = _searchController.text.toLowerCase();
                        users = users.where((u) {
                          final str = '${u['full-name']} ${u['email']} ${u['position']} ${u['shift']}'.toLowerCase();
                          return str.contains(term);
                        }).toList();
                      }
                      
                      if (users.isEmpty) {
                        return const Center(
                          child: Text(
                            'No users found in database.',
                            style: TextStyle(color: Color(0xFF94a3b8), fontStyle: FontStyle.italic),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                            dataRowColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6);
                              }
                              return Colors.transparent;
                            }),
                            dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                            headingTextStyle: TextStyle(
                              color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), 
                              fontWeight: FontWeight.w600, 
                              fontSize: 12,
                            ),
                            dividerThickness: 1,
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Member Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Building')),
                              DataColumn(label: Text('Phone')),
                              DataColumn(label: Text('Shift')),
                              DataColumn(label: Text('Position')),
                            ],
                            rows: users.map((u) {
                              final name = u['full-name'] ?? 'Unknown';
                              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                              
                              return DataRow(
                                onSelectChanged: (_) => _showUserDrawer(context, u, dark),
                                cells: [
                                  DataCell(
                                    Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: const Color(0xFF6366f1).withAlpha(40),
                                            child: Text(initial, style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(name, style: TextStyle(color: textP, fontWeight: FontWeight.w500)),
                                        ],
                                    ),
                                  ),
                                  DataCell(Text(u['email'] ?? '-')),
                                  DataCell(Text(u['building'] ?? '-')),
                                  DataCell(
                                      Text(
                                        u['phone-number'] ?? '-',
                                        style: TextStyle(fontFamily: 'monospace', color: textS),
                                      ),
                                  ),
                                  DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: borderCard),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(u['shift'] ?? '-', style: TextStyle(fontSize: 12, color: textP)),
                                      ),
                                  ),
                                  DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(u['position'] ?? '-', style: TextStyle(fontSize: 12, color: textP)),
                                      ),
                                  ),
                                ],
                              );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
     }
    );
  }

  void _showUserDrawer(BuildContext context, Map<String, dynamic> user, bool dark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 480,
              height: double.infinity,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0f172a) : Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: UserDrawerDetails(user: user, dark: dark),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
          child: child,
        );
      },
    );
  }
}

class UserDrawerDetails extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool dark;

  const UserDrawerDetails({super.key, required this.user, required this.dark});

  Widget _buildInfoCard(String label, String value, Color colorL, Color colorV, Color borderC, Color bgCard, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colorL, size: 14),
                const SizedBox(width: 6),
              ],
              Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: colorV, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
    final borderC = dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    
    final name = user['full-name'] ?? 'Unknown';
    final initial = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 24, right: 16),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1e293b) : const Color(0xFFf8fafc),
            border: Border(bottom: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appLanguage.value == 'es' ? 'Detalles de Usuario' : 'User Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.close, color: textS), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF6366f1).withAlpha(40),
                      child: Text(initial, style: const TextStyle(color: Color(0xFF6366f1), fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${user['email'] ?? '-'}', style: TextStyle(color: textS, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                LayoutBuilder(builder: (context, constraints) {
                  final wFull = constraints.maxWidth;
                  final wHalf = (wFull - 8) / 2;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(width: wHalf, child: _buildInfoCard(appLanguage.value == 'es' ? 'Edificio' : 'Building', '${user['building'] ?? '-'}', textS, textP, borderC, bgCard, icon: Icons.business_rounded)),
                      SizedBox(width: wHalf, child: _buildInfoCard(appLanguage.value == 'es' ? 'Posición' : 'Position', '${user['position'] ?? '-'}', textS, textP, borderC, bgCard, icon: Icons.badge_rounded)),
                      SizedBox(width: wHalf, child: _buildInfoCard(appLanguage.value == 'es' ? 'Teléfono' : 'Phone', '${user['phone-number'] ?? '-'}', textS, textP, borderC, bgCard, icon: Icons.phone_rounded)),
                      SizedBox(width: wHalf, child: _buildInfoCard(appLanguage.value == 'es' ? 'Turno' : 'Shift', '${user['shift'] ?? '-'}', textS, textP, borderC, bgCard, icon: Icons.access_time_rounded)),
                    ]
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
