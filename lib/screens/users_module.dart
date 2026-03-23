import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;

class UsersModule extends StatefulWidget {
  const UsersModule({super.key});

  @override
  State<UsersModule> createState() => _UsersModuleState();
}

class _UsersModuleState extends State<UsersModule> {
  final _searchController = TextEditingController();

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
                    Text(appLanguage.value == 'es' ? 'Usuarios Activos' : 'Active Users', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(appLanguage.value == 'es' ? 'Administración de roles y accesos del personal.' : 'Management of staff roles and accesses.', style: TextStyle(color: textS, fontSize: 13)),
                  ],
            ),
            const Spacer(),
            
            // Search Box
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
            const SizedBox(width: 8),

            // Refresh Button
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
              child: Stack(
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
                            columns: const [
                              DataColumn(label: Text('Member Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Position')),
                              DataColumn(label: Text('Building')),
                              DataColumn(label: Text('Shift')),
                              DataColumn(label: Text('Phone')),
                            ],
                            rows: users.map((u) {
                              final name = u['full-name'] ?? 'Unknown';
                              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                              
                              return DataRow(
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
                                  DataCell(Text(u['building'] ?? '-')),
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
                                      Text(
                                        u['phone-number'] ?? '-',
                                        style: TextStyle(fontFamily: 'monospace', color: textS),
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
}
