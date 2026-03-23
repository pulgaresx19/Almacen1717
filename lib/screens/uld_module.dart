import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;
import 'add_uld_screen.dart';

class UldModule extends StatefulWidget {
  const UldModule({super.key});

  @override
  State<UldModule> createState() => _UldModuleState();
}

class _UldModuleState extends State<UldModule> {
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
                      Text(appLanguage.value == 'es' ? 'Añadir Nuevo ULD' : 'Add New ULD', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700))
                    else
                      Text(appLanguage.value == 'es' ? 'Contenedores' : 'Unit Load Devices (ULD)', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(appLanguage.value == 'es' ? 'Registra y asigna ULDs individualmente.' : 'Create and assign ULDs individually.', style: TextStyle(color: textS, fontSize: 13))
                    else
                      Text(appLanguage.value == 'es' ? 'Administración de contenedores y pallets de carga.' : 'Administration of Unit Load Devices.', style: TextStyle(color: textS, fontSize: 13)),
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
                    hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                    hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            
            // Add ULD Button
            if (!_showAddForm)
              ElevatedButton.icon(
                onPressed: () => setState(() => _showAddForm = true),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(appLanguage.value == 'es' ? 'Añadir ULD' : 'Add ULD', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                  ? AddUldScreen(
                      isInline: true,
                      onPop: (_) => setState(() => _showAddForm = false),
                    )
                  : FutureBuilder<List<Map<String, dynamic>>>(
                      future: Supabase.instance.client.from('ULD').select().order('created_at', ascending: false),
                      builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  var ulds = snapshot.data ?? [];
                  
                  if (_searchController.text.isNotEmpty) {
                    final term = _searchController.text.toLowerCase();
                    ulds = ulds.where((u) => u['ULD number']?.toString().toLowerCase().contains(term) ?? false).toList();
                  }

                  if (ulds.isEmpty) return const Center(child: Text('No ULDs found.', style: TextStyle(color: Color(0xFF94a3b8))));

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
                          DataColumn(label: Text('ULD Number')),
                          DataColumn(label: Text('Pcs')),
                          DataColumn(label: Text('Weight')),
                          DataColumn(label: Text('Priority')),
                          DataColumn(label: Text('Break')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Remarks')),
                        ],
                        rows: List.generate(ulds.length, (index) {
                          final u = ulds[index];
                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(u['ULD number']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                              DataCell(Text(u['pieces']?.toString() ?? '0')),
                              DataCell(Text('${u['weight']?.toString() ?? '0'} kg')),
                              DataCell(Text(u['isPriority'] == true ? 'Yes' : 'No', style: TextStyle(color: u['isPriority'] == true ? Colors.redAccent : const Color(0xFFcbd5e1)))),
                              DataCell(Text(u['isBreak'] == true ? 'Yes' : 'No')),
                              DataCell(_buildStatusBadge(u['status']?.toString() ?? 'Received')),
                              DataCell(Text(u['remarks']?.toString() ?? '-')),
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
    
    if (status.toLowerCase() == 'pending') {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (status.toLowerCase() == 'ready') {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
