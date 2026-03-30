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
      final res = await Supabase.instance.client.from('Delivers').select().order('time-deliver', ascending: true);
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
                                  showCheckboxColumn: false,
                                  headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                                  dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                                  dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                                  headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),
                                  columns: [
                                    const DataColumn(label: Text('#')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Compañía' : 'Truck Co.')),
                                    const DataColumn(label: Text('Driver')),
                                    const DataColumn(label: Text('Door')),
                                    const DataColumn(label: Text('Type')),
                                    const DataColumn(label: Text('ID Pickup')),
                                    const DataColumn(label: Text('Time')),
                                    const DataColumn(label: Text('Priority')),
                                    const DataColumn(label: Text('Remarks')),
                                    const DataColumn(label: Text('AWBs')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
                                  ],
                                  rows: List.generate(items.length, (index) {
                                    final u = items[index];
                                    

                                    String timeStr = '-';
                                    if (u['time-deliver'] != null) {
                                      final tdt = DateTime.tryParse(u['time-deliver'].toString())?.toLocal();
                                      if (tdt != null) timeStr = '${tdt.hour.toString().padLeft(2, '0')}:${tdt.minute.toString().padLeft(2, '0')}';
                                    }

                                    String awbsStr = '0';
                                    if (u['list-pickup'] != null) {
                                      if (u['list-pickup'] is List) {
                                        awbsStr = (u['list-pickup'] as List).length.toString();
                                      } else {
                                        awbsStr = '1';
                                      }
                                    }
                                    
                                    bool isPriority = u['isPriority'] == true;

                                    return DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected == true) {
                                          _showDeliverDetails(context, u, dark);
                                        }
                                      },
                                      cells: [
                                        DataCell(Text('${index + 1}')),
                                        DataCell(Text(u['truck-company']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                                        DataCell(Text(u['driver']?.toString() ?? '-')),
                                        DataCell(Text(u['door']?.toString() ?? '-')),
                                        DataCell(Text(u['type']?.toString() ?? '-')),
                                        DataCell(Text(u['id-pickup']?.toString() ?? '-')),
                                        DataCell(Text(timeStr)),
                                        DataCell(isPriority ? const Icon(Icons.star_rounded, color: Colors.orange, size: 20) : const Icon(Icons.star_border_rounded, color: Colors.grey, size: 20)),
                                        DataCell(Tooltip(message: u['remarks']?.toString() ?? '', child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(u['remarks']?.toString() ?? '-', overflow: TextOverflow.ellipsis)))),
                                        DataCell(Text(awbsStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366f1)))),
                                        DataCell(_buildStatusBadge(u['status']?.toString() ?? 'Waiting')),
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

  void _showDeliverDetails(BuildContext context, Map<String, dynamic> u, bool dark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final borderC = dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
        final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? const Color(0xFF1e293b) : const Color(0xFFF9FAFB);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

        List<dynamic> awbs = [];
        if (u['list-pickup'] != null && u['list-pickup'] is List) {
          awbs = u['list-pickup'] as List;
        } else if (u['list-pickup'] != null && u['list-pickup'].toString().isNotEmpty) {
          awbs = [u['list-pickup'].toString()];
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: bg,
            elevation: 16,
            child: SizedBox(
              width: 480,
              height: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, color: textP, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deliver Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(u['truck-company']?.toString() ?? 'Unknown Company', style: TextStyle(color: textS, fontSize: 13)),
                            ],
                          ),
                        ),
                        _buildStatusBadge(u['status']?.toString() ?? 'Waiting'),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: textS),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver Information', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _buildInfoCard('Driver Name', u['driver']?.toString() ?? '-', Icons.person_outline, borderC, bgCard, textP, textS),
                          const SizedBox(height: 12),
                          _buildInfoCard('ID Pickup', u['id-pickup']?.toString() ?? '-', Icons.badge_outlined, borderC, bgCard, textP, textS),
                          
                          const SizedBox(height: 32),
                          
                          Text('Delivery Details', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _buildInfoCard('Type', u['type']?.toString() ?? '-', Icons.local_shipping_outlined, borderC, bgCard, textP, textS),
                          const SizedBox(height: 12),
                          _buildInfoCard('Door', u['door']?.toString() ?? '-', Icons.door_front_door_outlined, borderC, bgCard, textP, textS),
                          const SizedBox(height: 12),
                          _buildInfoCard('Priority', u['isPriority'] == true ? 'High Priority' : 'Normal', Icons.star_outline, borderC, bgCard, textP, textS, iconColor: u['isPriority'] == true ? Colors.orange : null),
                          
                          if (u['remarks'] != null && u['remarks'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoCard('Remarks', u['remarks'].toString(), Icons.notes, borderC, bgCard, textP, textS),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          Row(
                            children: [
                              Text('List of AWBs', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                                child: Text('${awbs.length}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (awbs.isEmpty)
                            Text('No AWBs assigned.', style: TextStyle(color: textS))
                          else
                            ...awbs.map((awb) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: textS, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(awb.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 14))),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String val, IconData icon, Color borderC, Color bgCard, Color textP, Color textS, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? textS, size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: textS, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(val, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting') || s.contains('espera')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('pending') || s.contains('pendiente')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (s.contains('completed') || s.contains('completado') || s.contains('ready') || s.contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('received') || s.contains('recibido') || s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('checked')){
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
    }

    return Container(
      width: 100,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
