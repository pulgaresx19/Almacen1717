import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;

class DriverModule extends StatefulWidget {
  const DriverModule({super.key});

  @override
  State<DriverModule> createState() => _DriverModuleState();
}

class _DriverModuleState extends State<DriverModule> {
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
                    Text(appLanguage.value == 'es' ? 'Choferes y Entregas' : 'Driver / Deliveries', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(appLanguage.value == 'es' ? 'Administración de choferes, camiones y despachos.' : 'Management of drivers, trucks, and deliveries.', style: TextStyle(color: textS, fontSize: 13)),
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
                  hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search Delivery...',
                  hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Add Delivery Button
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(appLanguage.value == 'es' ? 'Añadir Entrega' : 'Add Delivery', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client.from('Delivers').select().order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF10b981)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  var delivers = snapshot.data ?? [];
                  
                  if (_searchController.text.isNotEmpty) {
                    final term = _searchController.text.toLowerCase();
                    delivers = delivers.where((u) {
                      final str = '${u['truck-company']} ${u['driver']} ${u['door']}'.toLowerCase();
                      return str.contains(term);
                    }).toList();
                  }

                  if (delivers.isEmpty) return const Center(child: Text('No Deliveries found.', style: TextStyle(color: Color(0xFF94a3b8))));

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                        dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                        headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),
                        columns: const [
                          DataColumn(label: Text('Order')),
                          DataColumn(label: Text('Door')),
                          DataColumn(label: Text('Company')),
                          DataColumn(label: Text('Driver Name')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('AWB Pickups')),
                        ],
                        rows: List.generate(delivers.length, (index) {
                          final u = delivers[index];
                          
                          // Count AWB Pickups
                          int awbCount = 0;
                          if (u['list-pickup'] != null && u['list-pickup'] is List) {
                            awbCount = (u['list-pickup'] as List).length;
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text(u['sort_order']?.toString() ?? '${index + 1}')),
                              DataCell(Text(u['door']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.amberAccent : const Color(0xFFD97706), fontWeight: FontWeight.bold))),
                              DataCell(Text(u['truck-company']?.toString() ?? '-')),
                              DataCell(Text(u['driver']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w500))),
                              DataCell(Text(u['type']?.toString() ?? '-')),
                              DataCell(_buildStatusBadge(u['status']?.toString() ?? 'Waiting')),
                              DataCell(Text('$awbCount AWBs', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5)))),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
            ),
          ),
        ),
      ],
    );
     }
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    if (status.toLowerCase().contains('waiting')) {
       bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (status.toLowerCase().contains('process')) {
       bg = const Color(0xFF1e40af).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (status.toLowerCase().contains('completed') || status.toLowerCase().contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
