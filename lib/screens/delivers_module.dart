import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;
import 'add_deliver_screen.dart';

class DeliversModule extends StatefulWidget {
  const DeliversModule({super.key});

  @override
  State<DeliversModule> createState() => _DeliversModuleState();
}

class _DeliversModuleState extends State<DeliversModule> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddDeliverScreenState> _addDeliverKey = GlobalKey<AddDeliverScreenState>();

  Future<List<Map<String, dynamic>>> _fetchData() async {
    try {
      // Intenta consultar la tabla 'Delivers', si falla o no existe devolverá un array vacío para no quebrar la UI
      final res = await Supabase.instance.client.from('Delivers').select().order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

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
                            onPressed: () async {
                              if (_addDeliverKey.currentState != null) {
                                final canPop = await _addDeliverKey.currentState!.handleBackRequest();
                                if (canPop) {
                                  setState(() => _showAddForm = false);
                                }
                              } else {
                                setState(() => _showAddForm = false);
                              }
                            },
                            icon: Icon(Icons.arrow_back_rounded, color: textP, size: 28),
                            padding: const EdgeInsets.only(right: 8),
                            constraints: const BoxConstraints(),
                          ),
                          Text(appLanguage.value == 'es' ? 'Añadir Nueva Entrega' : 'Add New Deliver', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text('Delivers', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(
                        appLanguage.value == 'es' ? 'Registra una nueva entrega en el sistema.' : 'Register a new delivery in the system.',
                        style: TextStyle(color: textS, fontSize: 13)
                      )
                    else
                      Text(
                        appLanguage.value == 'es' 
                          ? 'Administración de entregas.' 
                          : 'Management of deliveries.', 
                        style: TextStyle(color: textS, fontSize: 13)
                      ),
                  ],
                ),
                const Spacer(),
                
                // Search Box
                if (!_showAddForm) ...[
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
                ],
                
                if (!_showAddForm)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showAddForm = true),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Añadir Deliver', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
            
            if (_showAddForm)
              Expanded(
                child: AddDeliverScreen(
                  key: _addDeliverKey,
                  onPop: (didAdd) {
                    setState(() => _showAddForm = false);
                  },
                ),
              )
            else
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
                      future: _fetchData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                        }
                        
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                        }
  
                        var items = snapshot.data ?? [];
                      
                      if (_searchController.text.isNotEmpty) {
                        final term = _searchController.text.toLowerCase();
                        items = items.where((u) => u.toString().toLowerCase().contains(term)).toList();
                      }

                      if (items.isEmpty) return Center(child: Text(appLanguage.value == 'es' ? 'No se encontraron registros.' : 'No records found.', style: const TextStyle(color: Color(0xFF94a3b8))));

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
                                  columns: [
                                    const DataColumn(label: Text('#')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Referencia' : 'Reference')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Detalles' : 'Details')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
                                  ],
                                  rows: List.generate(items.length, (index) {
                                    final u = items[index];
                                    
                                    return DataRow(
                                      cells: [
                                        DataCell(Text('${index + 1}')),
                                        DataCell(Text(u['reference']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                                        DataCell(Text(u['details']?.toString() ?? '-')),
                                        DataCell(_buildStatusBadge(u['status']?.toString() ?? 'Pending')),
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
    
    if (status.toLowerCase().contains('pending') || status.toLowerCase().contains('pendiente')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (status.toLowerCase().contains('completed') || status.toLowerCase().contains('completado')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
