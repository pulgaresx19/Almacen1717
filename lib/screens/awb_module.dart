import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;
import 'add_awb_screen.dart';

class AwbModule extends StatefulWidget {
  const AwbModule({super.key});

  @override
  State<AwbModule> createState() => _AwbModuleState();
}

class _AwbModuleState extends State<AwbModule> {
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
                    Text(appLanguage.value == 'es' ? 'Guías Aéreas' : 'Air Waybills (AWB)', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(appLanguage.value == 'es' ? 'Administración y desglose de guías aéreas.' : 'Management and breakdown of Air Waybills.', style: TextStyle(color: textS, fontSize: 13)),
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
                  hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                  hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Add AWB Button
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAwbScreen()),
                );
                if (result == true) setState(() {}); 
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366f1),
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
                future: Supabase.instance.client.from('AWB').select().order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  var awbs = snapshot.data ?? [];
                  
                  if (_searchController.text.isNotEmpty) {
                    final term = _searchController.text.toLowerCase();
                    awbs = awbs.where((u) => u['AWB number']?.toString().toLowerCase().contains(term) ?? false).toList();
                  }

                  if (awbs.isEmpty) return const Center(child: Text('No AWBs found.', style: TextStyle(color: Color(0xFF94a3b8))));

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
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('AWB Number')),
                          DataColumn(label: Text('Total Pcs/Wgt')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: List.generate(awbs.length, (index) {
                          final u = awbs[index];
                          
                          // Parse some json data safely
                          var pieces = '-';
                          var weight = '-';
                          var status = 'Received';
                          
                          try {
                            if (u['data-AWB'] != null) {
                              var dataAwb = u['data-AWB'] as Map<String, dynamic>;
                               if (dataAwb.containsKey('pieces')) pieces = dataAwb['pieces'].toString();
                               if (dataAwb.containsKey('weight')) weight = dataAwb['weight'].toString();
                               if (dataAwb.containsKey('status')) status = dataAwb['status'].toString();
                            }
                          } catch (_) {}

                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(u['AWB number']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                              DataCell(Text('$pieces pcs / $weight kg')),
                              DataCell(_buildStatusBadge(status)),
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
    
    if (status.toLowerCase().contains('pending')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (status.toLowerCase().contains('ready')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
