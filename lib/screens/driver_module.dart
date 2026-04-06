import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;

class DriverModule extends StatefulWidget {
  const DriverModule({super.key});

  @override
  State<DriverModule> createState() => _DriverModuleState();
}

class _DriverModuleState extends State<DriverModule> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _selectedDriver;
  List<Map<String, dynamic>> _driverAwbs = [];
  bool _isLoadingAwbs = false;
  late Stream<List<Map<String, dynamic>>> _deliversStream;

  @override
  void initState() {
    super.initState();
    _deliversStream = Supabase.instance.client.from('Delivers').stream(primaryKey: ['id']);
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
                ValueListenableBuilder<bool>(
                  valueListenable: isSidebarExpandedNotifier,
                  builder: (context, expanded, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: expanded ? 0 : 44,
                    );
                  },
                ),
                if (_selectedDriver != null) ...[
                  IconButton(
                    onPressed: () => setState(() => _selectedDriver = null),
                    icon: Icon(Icons.arrow_back_rounded, color: textP, size: 28),
                  ),
                  const SizedBox(width: 16),
                ],
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
          ],
        ),
        const SizedBox(height: 30),
        
        if (_selectedDriver != null)
          Expanded(child: _buildDriverDetailView(dark, textP, textS, bgCard, borderCard, iconColor))
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
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _deliversStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF10b981)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  var delivers = List<Map<String, dynamic>>.from(snapshot.data ?? []);
                  
                  delivers.sort((a, b) {
                    final taStr = a['time-deliver']?.toString() ?? '';
                    final tbStr = b['time-deliver']?.toString() ?? '';
                    if (taStr.isEmpty && tbStr.isNotEmpty) return 1;
                    if (taStr.isNotEmpty && tbStr.isEmpty) return -1;
                    if (taStr.isEmpty && tbStr.isEmpty) return 0;
                    
                    final da = DateTime.tryParse(taStr) ?? DateTime(1970);
                    final db = DateTime.tryParse(tbStr) ?? DateTime(1970);
                    return da.compareTo(db);
                  });

                  if (_searchController.text.isNotEmpty) {
                    final term = _searchController.text.toLowerCase();
                    delivers = delivers.where((u) {
                      final str = u.toString().toLowerCase();
                      return str.contains(term);
                    }).toList();
                  }

                  if (delivers.isEmpty) return Center(child: Text(appLanguage.value == 'es' ? 'No se encontraron registros.' : 'No records found.', style: const TextStyle(color: Color(0xFF94a3b8))));

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
                              rows: List.generate(delivers.length, (index) {
                                final u = delivers[index];
                          
                                String timeStr = '-';
                                if (u['time-deliver'] != null) {
                                  final tdt = DateTime.tryParse(u['time-deliver'].toString())?.toLocal();
                                  if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
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
                                  onSelectChanged: (_) => _showDriverDetailsDialog(context, u, dark, awbsStr, timeStr),
                                  cells: [
                                    DataCell(Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)))),
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

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting') || s.contains('espera')) {
      bg = const Color(0xFF334155).withAlpha(150); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('completed') || s.contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
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

  void _showDriverDetailsDialog(BuildContext context, Map<String, dynamic> u, bool dark, String awbsStr, String timeStr) {
    showDialog(
      context: context,
      builder: (context) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final bgCard = dark ? const Color(0xFF0f172a) : Colors.white;
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final accentC = const Color(0xFF6366f1);
        final bgAccent = dark ? accentC.withAlpha(30) : accentC.withAlpha(20);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderC),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(dark ? 150 : 30), blurRadius: 24, offset: const Offset(0, 12)),
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.only(left: 24, right: 16, top: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgAccent, 
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accentC.withAlpha(50))
                        ),
                        child: Icon(Icons.local_shipping_rounded, color: accentC, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    u['truck-company']?.toString().isNotEmpty == true ? u['truck-company'].toString() : 'Unknown Company', 
                                    style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (u['isPriority'] == true) ...[
                                  const SizedBox(width: 8),
                                  const Tooltip(
                                    message: 'Priority',
                                    child: Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${u['id-pickup']?.toString() ?? 'N/A'}', 
                              style: TextStyle(color: textS, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusBadge(u['status']?.toString() ?? 'Waiting'),
                      const SizedBox(width: 16),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                        onPressed: () => Navigator.pop(context), 
                        icon: Icon(Icons.close_rounded, color: textP, size: 20),
                      ),
                    ],
                  ),
                ),
                
                Divider(color: borderC, height: 1),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Door Highlight & Driver
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                              child: Row(
                                children: [
                                  CircleAvatar(backgroundColor: dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB), child: Icon(Icons.person_rounded, color: textS)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u['driver']?.toString().isNotEmpty == true ? u['driver'].toString() : 'Unknown Driver', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        Text(u['truck-company']?.toString() ?? '-', style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ]
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: dark ? Colors.amberAccent.withAlpha(20) : Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amberAccent.withAlpha(50))),
                            child: Column(
                              children: [
                                Text('DOOR', style: TextStyle(color: dark ? Colors.amberAccent : Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(u['door']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // Specs Grid
                      Row(
                        children: [
                          Expanded(child: _buildModalDataBlock('Time', timeStr, Icons.access_time_rounded, textS, textP, dark, borderC)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModalDataBlock('Type', u['type']?.toString() ?? '-', Icons.category_rounded, textS, textP, dark, borderC)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModalDataBlock('AWBs', awbsStr, Icons.inventory_2_rounded, textS, textP, dark, borderC)),
                        ],
                      ),

                      if ((u['remarks']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: dark ? Colors.redAccent.withAlpha(20) : Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.redAccent.withAlpha(50) : Colors.red.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: dark ? Colors.redAccent : Colors.red.shade600),
                                  const SizedBox(width: 8),
                                  Text('Remarks', style: TextStyle(color: dark ? Colors.redAccent : Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(u['remarks'].toString(), style: TextStyle(color: textP, fontSize: 13, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)), border: Border(top: BorderSide(color: borderC))),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // En un futuro aqui se mandara a guardar el No Show
                        },
                        icon: const Icon(Icons.person_off_rounded, size: 18),
                        label: const Text('No Show', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadDriverDetails(u);
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                        label: Text(
                          appLanguage.value == 'es' ? 'Confirmar Entrega' : 'Confirm Delivery',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentC,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalDataBlock(String label, String value, IconData icon, Color colorL, Color colorV, bool dark, Color borderC) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: colorL),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: colorL, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: colorV, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<void> _loadDriverDetails(Map<String, dynamic> u) async {
    setState(() {
      _selectedDriver = u;
      _driverAwbs = [];
      _isLoadingAwbs = true;
    });

    List<String> awbsToFetch = [];
    if (u['list-pickup'] != null && u['list-pickup'] is List) {
       awbsToFetch = (u['list-pickup'] as List).map((e) => e.toString()).toList();
    }

    if (awbsToFetch.isNotEmpty) {
      try {
        final res = await Supabase.instance.client.from('AWB').select().inFilter('AWB-number', awbsToFetch);
        if (mounted) {
          setState(() {
             _driverAwbs = List<Map<String, dynamic>>.from(res);
             _isLoadingAwbs = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingAwbs = false);
        }
      }
    } else {
       if (mounted) {
         setState(() => _isLoadingAwbs = false);
       }
    }
  }

  Widget _buildDriverDetailView(bool dark, Color textP, Color textS, Color bgCard, Color borderCard, Color iconColor) {
    final u = _selectedDriver!;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: General Information
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCard)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB), child: Icon(Icons.person_rounded, size: 32, color: textS)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['driver']?.toString().isNotEmpty == true ? u['driver'].toString() : 'Unknown Driver', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(u['truck-company']?.toString() ?? '-', style: TextStyle(color: textS, fontSize: 16)),
                        ],
                      ),
                    ),
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: BoxDecoration(color: dark ? Colors.amberAccent.withAlpha(20) : Colors.amber.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.amberAccent.withAlpha(50) : Colors.amber.shade300)),
                       child: Column(
                         children: [
                           Text('DOOR', style: TextStyle(color: dark ? Colors.amberAccent : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                           Text(u['door']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 28, fontWeight: FontWeight.bold)),
                         ],
                       ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow('ID Pickup', u['id-pickup']?.toString() ?? '-', textS, textP),
                const SizedBox(height: 12),
                _buildInfoRow('Type', u['type']?.toString() ?? '-', textS, textP),
                const SizedBox(height: 12),
                _buildInfoRow('Status', u['status']?.toString() ?? '-', textS, textP),
                if ((u['remarks']?.toString() ?? '').isNotEmpty) ...[
                   const SizedBox(height: 24),
                   Text('Remarks', style: TextStyle(color: textS, fontSize: 14, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                     child: Text(u['remarks'].toString(), style: TextStyle(color: textP, fontSize: 14)),
                   ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        
        // Right Column: AWB List
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCard)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_rounded, color: textP, size: 24),
                    const SizedBox(width: 12),
                    Text(appLanguage.value == 'es' ? 'Lista de AWBs' : 'AWBs List', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isLoadingAwbs)
                   const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))))
                else if (_driverAwbs.isEmpty)
                   Expanded(child: Center(child: Text(appLanguage.value == 'es' ? 'No hay AWBs registrados para este chófer.' : 'No AWBs attached to this driver.', style: TextStyle(color: textS))))
                else
                   Expanded(
                     child: ListView.separated(
                        itemCount: _driverAwbs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                           final awb = _driverAwbs[index];
                           final awbNum = awb['AWB-number']?.toString() ?? '-';
                           final total = awb['total']?.toString() ?? '0';
                           return Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: borderCard),
                             ),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(awbNum, style: TextStyle(color: const Color(0xFF6366f1), fontSize: 16, fontWeight: FontWeight.bold)),
                                     const SizedBox(height: 4),
                                     Text('Total: $total', style: TextStyle(color: textS, fontSize: 13)),
                                   ],
                                 ),
                                 Icon(Icons.chevron_right_rounded, color: textS),
                               ],
                             ),
                           );
                        },
                     ),
                   ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String val, Color textS, Color textP) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 14)),
        Text(val, style: TextStyle(color: textP, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}


