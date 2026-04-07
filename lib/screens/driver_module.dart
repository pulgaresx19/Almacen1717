import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Map<String, dynamic>? _selectedAwbDetails;
  final Map<String, bool> _driverItemCheckState = {};
  final Set<String> _hiddenDriverItems = {};
  List<Map<String, dynamic>> _driverAwbs = [];
  bool _isLoadingAwbs = false;
  bool _isDelivering = false;
  late Stream<List<Map<String, dynamic>>> _deliversStream;

  @override
  void initState() {
    super.initState();
    _deliversStream = Supabase.instance.client.from('Delivers').stream(primaryKey: ['id']).order('time-deliver', ascending: true);
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
                  
                  if (snapshot.hasError && !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text('Connection lost or failed to load data.\nRetrying...', textAlign: TextAlign.center, style: TextStyle(color: dark ? Colors.white70 : Colors.black54)),
                        ]
                      )
                    );
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
      _selectedAwbDetails = null;
    });

    List<String> awbsToFetch = [];
    if (u['list-pickup'] != null && u['list-pickup'] is List) {
       awbsToFetch = (u['list-pickup'] as List).map((e) {
           String displayStr = e.toString();
           if (displayStr.contains(' - ')) {
               return displayStr.split(' - ').first.trim();
           }
           return displayStr;
       }).toList();
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
        // Left Column: General Information + AWBs List
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
                          Text(u['truck-company']?.toString().isNotEmpty == true ? u['truck-company'].toString() : 'Unknown Company', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(u['driver']?.toString() ?? 'Unknown Driver', style: TextStyle(color: textS, fontSize: 16)),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID Pickup', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(u['id-pickup']?.toString() ?? '-', style: TextStyle(color: textP, fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(u['type']?.toString() ?? '-', style: TextStyle(color: textP, fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(u['status']?.toString() ?? '-', style: TextStyle(color: textP, fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Remarks', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text((u['remarks']?.toString() ?? '').isEmpty ? '-' : u['remarks'].toString(), style: TextStyle(color: textP, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Icon(Icons.inventory_2_rounded, color: textP, size: 20),
                            const SizedBox(width: 8),
                            Text(appLanguage.value == 'es' ? 'Lista de AWBs' : 'AWBs List', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingAwbs)
                           const Padding(
                             padding: EdgeInsets.all(32),
                             child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))),
                           )
                        else if (_driverAwbs.isEmpty)
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 32),
                             child: Center(child: Text(appLanguage.value == 'es' ? 'No hay AWBs registrados para este chófer.' : 'No AWBs attached to this driver.', style: TextStyle(color: textS))),
                           )
                        else
                           ..._driverAwbs.map((awb) {
                              final awbNum = awb['AWB-number']?.toString() ?? '-';
                              final listPickup = (u['list-pickup'] as List?)?.map((e) => e.toString()).toList() ?? [];
                              String piecesStr = '';
                              final match = listPickup.firstWhere((element) => element.startsWith(awbNum), orElse: () => '');
                              if (match.contains(' - ')) {
                                 piecesStr = match.split(' - ').last.trim();
                              }

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAwbDetails = awb;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _selectedAwbDetails == awb ? (dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFFe0e7ff)) : (dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _selectedAwbDetails == awb ? const Color(0xFF6366f1) : borderCard),
                                  ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(awbNum, style: TextStyle(color: const Color(0xFF6366f1), fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    if (piecesStr.isNotEmpty)
                                      Expanded(
                                        flex: 2,
                                        child: Text(piecesStr, style: TextStyle(color: textS, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                      ),
                                    Icon(
                                      Icons.check_circle_outline_rounded, 
                                      color: awb['data-deliver'] != null ? const Color(0xFF10b981) : textS, 
                                      size: 20
                                    ),
                                  ],
                                ),
                              ),
                              );
                           }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
             // Right Column
        Expanded(
          flex: 6,
          child: _selectedAwbDetails == null ? Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
               color: dark ? Colors.white.withAlpha(2) : Colors.black.withAlpha(2), 
               borderRadius: BorderRadius.circular(16), 
               border: Border.all(color: borderCard, style: BorderStyle.solid)
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.widgets_outlined, size: 48, color: dark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 16),
                  Text('Espacio Reservado', style: TextStyle(color: textS, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Seleccione un AWB de la lista para ver su detalle operativo.', textAlign: TextAlign.center, style: TextStyle(color: textS.withAlpha(150), fontSize: 14)),
                ],
              ),
            ),
          ) : _buildAwbDetailPanel(_selectedAwbDetails!, dark, textP, textS, bgCard, borderCard),
        ),
      ],
    );
  }

  Widget _buildCustomChip(Widget child, bool dark, {double width = 140}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _buildAwbDetailPanel(Map<String, dynamic> awb, bool dark, Color textP, Color textS, Color bgCard, Color borderCard) {
    final awbNum = awb['AWB-number']?.toString() ?? '-';
    
    List awbItems = [];
    if (awb['data-AWB'] is List) {
      awbItems = awb['data-AWB'];
    } else if (awb['data-AWB'] is Map) {
      awbItems = [awb['data-AWB']];
    }

    List locList = [];
    if (awb['data-location'] is List) {
      locList = awb['data-location'];
    } else if (awb['data-location'] is Map && (awb['data-location'] as Map).isNotEmpty) {
      locList = [awb['data-location']];
    }
    
    List coordList = [];
    if (awb['data-coordinator'] is List) {
      coordList = awb['data-coordinator'];
    } else if (awb['data-coordinator'] is Map && (awb['data-coordinator'] as Map).isNotEmpty) {
      coordList = [awb['data-coordinator']];
    }

    final totalPieces = awb['total']?.toString() ?? '-';
    String deliverPiecesStr = '';
    if (_selectedDriver != null && _selectedDriver!['list-pickup'] != null) {
      final listPickup = (_selectedDriver!['list-pickup'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final match = listPickup.firstWhere((element) => element.startsWith(awbNum), orElse: () => '');
      if (match.contains(' - ')) {
         deliverPiecesStr = match.split(' - ').last.trim();
      }
    }

    int foundPieces = 0;
    for (var awbItem in awbItems) {
       Map breakdown = {};
       for (var c in coordList) {
          if (c is Map && c['refULD'] == awbItem['refULD']) {
             if (c['breakdown'] is Map) breakdown = c['breakdown'] as Map;
             break;
          }
       }

       String uldKeyPrefix = '${awb['AWB-number']}_${awbItem['refULD']}_${awbItem['refNumber']}_';
       _driverItemCheckState.forEach((key, isChecked) {
          if (isChecked && key.startsWith(uldKeyPrefix)) {
             String itemKey = key.substring(uldKeyPrefix.length);
             int pieces = 0;
             if (itemKey == 'NO_BREAK') {
                pieces = int.tryParse(awbItem['pieces']?.toString() ?? '0') ?? 0;
             } else if (itemKey.startsWith('AGI Skid_')) {
                int idx = int.tryParse(itemKey.split('_').last) ?? 0;
                if (breakdown['AGI Skid'] is List && (breakdown['AGI Skid'] as List).length > idx) {
                   pieces = int.tryParse(breakdown['AGI Skid'][idx].toString()) ?? 0;
                }
             } else {
                dynamic bdVal = breakdown[itemKey];
                if (bdVal == null && itemKey == 'Crate') bdVal = breakdown['Crate(s)'];
                if (bdVal == null && itemKey == 'Box') bdVal = breakdown['Box(es)'];
                
                if (bdVal is List) {
                   pieces = bdVal.fold(0, (a, b) => a + (int.tryParse(b.toString()) ?? 0));
                } else if (bdVal != null) {
                   pieces = int.tryParse(bdVal.toString()) ?? 0;
                }
             }
             foundPieces += pieces;
          }
       });
    }
    
    String digitsOnly = deliverPiecesStr.replaceAll(RegExp(r'[^0-9]'), '');
    int expectedDeliver = int.tryParse(digitsOnly) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderCard)),
            ),
            child: Builder(
              builder: (context) {
                Color foundColor = (foundPieces == expectedDeliver && expectedDeliver > 0) ? const Color(0xFF10b981) : const Color(0xFFf59e0b); // Amber

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detalle AWB', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(awbNum, style: TextStyle(color: const Color(0xFF6366f1), fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Container(width: 1, height: 40, color: borderCard),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deliver', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(deliverPiecesStr.isEmpty ? '0' : deliverPiecesStr, style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Container(width: 1, height: 40, color: borderCard),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Found Pieces', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(foundPieces.toString(), style: TextStyle(color: foundColor, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Container(width: 1, height: 40, color: borderCard),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(totalPieces, style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedAwbDetails = null),
                      icon: Icon(Icons.close_rounded, color: textS),
                    ),
                  ],
                );
              }
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Location section
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: textP, size: 24),
                      const SizedBox(width: 8),
                      Text('Location Info', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (awbItems.isEmpty)
                    Text('No flight data available.', style: TextStyle(color: textS, fontStyle: FontStyle.italic))
                  else
                    Column(
                      children: awbItems.map<Widget>((awbItem) {
                        Map itemLocs = {};
                        Map locMatch = {};
                        for (var l in locList) {
                           if (l is Map && l['refULD'] == awbItem['refULD']) {
                              locMatch = l;
                              if (l['itemLocations'] is Map) {
                                 itemLocs = l['itemLocations'] as Map;
                              }
                              break;
                           }
                        }
                        
                        // Find matching coordData to get correct pieces
                        Map breakdown = {};
                        for (var c in coordList) {
                           if (c is Map && c['refULD'] == awbItem['refULD']) {
                              if (c['breakdown'] is Map) breakdown = c['breakdown'] as Map;
                              break;
                           }
                        }
                        
                        bool isBreak = awbItem['isBreak'] == true;
                        
                        bool hasCoord = coordList.any((c) => c is Map && c['refULD'] == awbItem['refULD']);
                        bool hasLoc = locMatch.isNotEmpty;

                        String statusText = 'PENDING';
                        Color statusColor = const Color(0xFFf59e0b);

                        if (!isBreak) {
                          statusText = 'No Break Area';
                          statusColor = const Color(0xFF8b5cf6); // Distinct color for no break area status
                        } else if (hasCoord && hasLoc) {
                          statusText = 'READY';
                          statusColor = const Color(0xFF10b981);
                        } else if (hasCoord && !hasLoc) {
                          statusText = 'CHECKED';
                          statusColor = const Color(0xFF3b82f6);
                        }

                        String dateStr = (awbItem['refDate'] ?? locMatch['refDate'] ?? '').toString();
                        if (dateStr.length >= 10 && dateStr.contains('-')) {
                          var parts = dateStr.split('-');
                          if (parts.length >= 3) {
                            dateStr = '${parts[1]}-${parts[2]}';
                          }
                        }
                        String flightStr = '${awbItem['refCarrier'] ?? ''} ${awbItem['refNumber'] ?? ''}'.trim();

                        List<String> allItemKeys = [];
                        if (breakdown.isNotEmpty) {
                          for (var entry in breakdown.entries) {
                            var k = entry.key;
                            var v = entry.value;
                            if (k == 'AGI Skid' && v is List) {
                               for (int i=0; i<v.length; i++) {
                                  if ((int.tryParse(v[i].toString()) ?? 0) > 0) {
                                     allItemKeys.add('AGI Skid_$i');
                                  }
                               }
                            } else {
                               String keyName = k.toString().replaceAll('(s)', '').replaceAll('(es)', '');
                               int pcs = v is List ? v.fold(0, (a, b) => a + (int.tryParse(b.toString()) ?? 0)) : (int.tryParse(v.toString()) ?? 0);
                               if (pcs > 0) {
                                   allItemKeys.add(keyName);
                               }
                            }
                          }
                        }
                        for (var k in itemLocs.keys) {
                          if (!allItemKeys.contains(k.toString())) {
                             allItemKeys.add(k.toString());
                          }
                        }

                        final tableRows = allItemKeys.map<DataRow>((itemKey) {
                           String displayName = itemKey.replaceAll('_', ' ');
                           int pieces = 0;
                           
                           if (itemKey.startsWith('AGI Skid_')) {
                              int idx = int.tryParse(itemKey.split('_').last) ?? 0;
                              displayName = 'AGI Skid ${idx + 1}';
                              if (breakdown['AGI Skid'] is List && (breakdown['AGI Skid'] as List).length > idx) {
                                 pieces = int.tryParse(breakdown['AGI Skid'][idx].toString()) ?? 0;
                              }
                           } else {
                              dynamic bdVal = breakdown[itemKey];
                              if (bdVal == null && itemKey == 'Crate') bdVal = breakdown['Crate(s)'];
                              if (bdVal == null && itemKey == 'Box') bdVal = breakdown['Box(es)'];
                              
                              if (bdVal is List) {
                                 pieces = bdVal.fold(0, (a, b) => a + (int.tryParse(b.toString()) ?? 0));
                              } else if (bdVal != null) {
                                 pieces = int.tryParse(bdVal.toString()) ?? 0;
                              }
                           }
                           
                           String? locVal = itemLocs[itemKey]?.toString();
                           String locText = (locVal != null && locVal.isNotEmpty) ? locVal.toUpperCase() : 'FLOOR';
                           Color locColor = locText == 'FLOOR' ? textS : textP;

                           String checkKey = '${awb['AWB-number']}_${awbItem['refULD']}_${awbItem['refNumber']}_$itemKey';
                           bool isChecked = _driverItemCheckState[checkKey] ?? false;

                           return DataRow(cells: [
                             DataCell(
                               Checkbox(
                                 value: isChecked,
                                 onChanged: (val) {
                                   setState(() {
                                     _driverItemCheckState[checkKey] = val == true;
                                   });
                                 },
                                 activeColor: const Color(0xFF6366f1),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                               ),
                             ),
                             DataCell(Text(displayName, style: TextStyle(color: const Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 14))),
                             DataCell(Text(pieces > 0 ? pieces.toString() : '-', style: TextStyle(color: textP, fontSize: 14))),
                             DataCell(Text(locText, style: TextStyle(color: locColor, fontSize: 14, fontStyle: locText == 'FLOOR' ? FontStyle.italic : FontStyle.normal))),
                           ]);
                        }).toList();

                        if (!isBreak) {
                           String checkKey = '${awb['AWB-number']}_${awbItem['refULD']}_${awbItem['refNumber']}_NO_BREAK';
                           bool isChecked = _driverItemCheckState[checkKey] ?? false;
                           String uldNumber = awbItem['refULD']?.toString() ?? 'UNKNOWN ULD';
                           int totalPieces = int.tryParse(awbItem['pieces']?.toString() ?? '0') ?? 0;
                           
                           allItemKeys.clear();
                           allItemKeys.add('NO_BREAK'); // to satisfy the Checkbox allChecked logic below
                           
                           tableRows.clear();
                           tableRows.add(DataRow(cells: [
                             DataCell(
                               Checkbox(
                                 value: isChecked,
                                 onChanged: (val) {
                                   setState(() {
                                     _driverItemCheckState[checkKey] = val == true;
                                   });
                                 },
                                 activeColor: const Color(0xFF6366f1),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                               ),
                             ),
                             DataCell(Text(uldNumber, style: TextStyle(color: const Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 14))),
                             DataCell(Text(totalPieces > 0 ? totalPieces.toString() : '-', style: TextStyle(color: textP, fontSize: 14))),
                             DataCell(Text('NO BREAK AREA', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold))),
                           ]));
                        }

                           String uldKey = '${awb['AWB-number']}_${awbItem['refULD']}_${awbItem['refNumber']}';
                           bool isHidden = _hiddenDriverItems.contains(uldKey);

                           return Container(
                             width: double.infinity,
                             margin: const EdgeInsets.only(bottom: 16),
                             decoration: BoxDecoration(
                               color: dark ? Colors.white.withAlpha(5) : Colors.white,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: borderCard),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: [
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                   decoration: BoxDecoration(
                                     color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                     borderRadius: isHidden ? BorderRadius.circular(12) : const BorderRadius.vertical(top: Radius.circular(12)),
                                     border: isHidden ? null : Border(bottom: BorderSide(color: borderCard)),
                                   ),
                                   child: Row(
                                     children: [
                                       Expanded(
                                         child: Wrap(
                                           spacing: 16,
                                           runSpacing: 8,
                                           children: [
                                             _buildCustomChip(
                                               Row(
                                                 children: [
                                                   Text('ULD:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                                                   const SizedBox(width: 4),
                                                   Expanded(
                                                     child: Text(
                                                       awbItem['refULD']?.toString().isNotEmpty == true ? awbItem['refULD'].toString() : '-',
                                                       style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                                       overflow: TextOverflow.ellipsis,
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               dark,
                                               width: 160,
                                             ),
                                             if (flightStr.isNotEmpty)
                                               _buildCustomChip(
                                                 Row(
                                                   children: [
                                                     Text('Flight:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                                                     const SizedBox(width: 4),
                                                     Expanded(
                                                       child: RichText(
                                                         overflow: TextOverflow.ellipsis,
                                                         text: TextSpan(
                                                           children: [
                                                             TextSpan(text: flightStr, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                                             if (dateStr.isNotEmpty)
                                                               TextSpan(text: ' / $dateStr', style: TextStyle(color: textS.withAlpha(150), fontSize: 12, fontWeight: FontWeight.normal)),
                                                           ],
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 dark,
                                                 width: 170,
                                               ),
                                             _buildCustomChip(
                                               Center(
                                                 child: Text(
                                                   isBreak ? 'BREAK' : 'NO BREAK',
                                                   style: TextStyle(color: isBreak ? const Color(0xFF22c55e) : const Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.bold),
                                                 ),
                                               ),
                                               dark,
                                               width: 100,
                                             ),
                                             _buildCustomChip(
                                               Center(
                                                 child: Text(
                                                   statusText,
                                                   style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                                                 ),
                                               ),
                                               dark,
                                               width: 110,
                                             ),
                                             if (statusText == 'PENDING')
                                               Padding(
                                                 padding: const EdgeInsets.only(left: 12.0),
                                                 child: IconButton(
                                                   icon: const Icon(Icons.assignment_add, color: Color(0xFF6366f1), size: 24),
                                                   onPressed: () => _showDriverCoordinatorDialog(awb, awbItem),
                                                   tooltip: 'Add Coordinator Data',
                                                   padding: const EdgeInsets.all(4),
                                                   constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                 ),
                                               ),
                                           ],
                                         ),
                                       ),
                                       IconButton(
                                         icon: Icon(isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textS, size: 20),
                                         onPressed: () {
                                           setState(() {
                                             if (isHidden) {
                                               _hiddenDriverItems.remove(uldKey);
                                             } else {
                                               _hiddenDriverItems.add(uldKey);
                                             }
                                           });
                                         },
                                         padding: EdgeInsets.zero,
                                         constraints: const BoxConstraints(),
                                       ),
                                     ],
                                   ),
                                 ),
                                 if (!isHidden && statusText == 'PENDING')
                                   Padding(
                                     padding: const EdgeInsets.all(16),
                                     child: Text('ULD is pending to be checked.', style: TextStyle(color: textS, fontStyle: FontStyle.italic)),
                                   )
                                 else if (!isHidden && statusText != 'PENDING')
                                   if (tableRows.isEmpty)
                                     Padding(
                                       padding: const EdgeInsets.all(16),
                                       child: Text('No itemized location breakdown available.', style: TextStyle(color: textS, fontStyle: FontStyle.italic)),
                                     )
                                   else
                                     ClipRRect(
                                       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                       child: LayoutBuilder(
                                         builder: (context, constraints) {
                                           bool allChecked = allItemKeys.isNotEmpty && allItemKeys.every((itemKey) {
                                             String checkKey = '${awb['AWB-number']}_${awbItem['refULD']}_${awbItem['refNumber']}_$itemKey';
                                             return _driverItemCheckState[checkKey] == true;
                                           });

                                           return SingleChildScrollView(
                                             scrollDirection: Axis.horizontal,
                                             child: ConstrainedBox(
                                               constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                               child: DataTable(
                                                 headingRowHeight: 40,
                                                 headingRowColor: WidgetStateProperty.all(Colors.transparent),
                                                 columns: [
                                                   DataColumn(
                                                     label: Checkbox(
                                                       value: allItemKeys.isEmpty ? false : allChecked,
                                                       onChanged: allItemKeys.isEmpty ? null : (val) {
                                                         setState(() {
                                                           for (var itemKey in allItemKeys) {
                                                             String checkKey = '${awb['AWB-number']}_${awbItem['refULD']}_${awbItem['refNumber']}_$itemKey';
                                                             _driverItemCheckState[checkKey] = val == true;
                                                           }
                                                         });
                                                       },
                                                       activeColor: const Color(0xFF6366f1),
                                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                     ),
                                                   ),
                                                   DataColumn(label: Text('Item', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold))),
                                                   DataColumn(label: Text('Pieces', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold))),
                                                   DataColumn(label: Text('Location', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold))),
                                                 ],
                                                 rows: tableRows,
                                               ),
                                             ),
                                           );
                                         }
                                       ),
                                     ),
                               ],
                             ),
                           );
                      }).toList(),
                    ),

                ],
              ),
            ),
          ),
          
          // Fixed footer with Deliver AWB button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderCard)),
            ),
            child: Builder(
               builder: (context) {
                  bool isDelivered = awb['data-deliver'] != null;
                  bool isRejected = awb['data-reject'] != null;

                  if (isDelivered) {
                     return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const Icon(Icons.check_circle_outline, color: Color(0xFF10b981), size: 24),
                           const SizedBox(width: 8),
                           const Text('Delivered', style: TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 16)),
                           if (awb['data-deliver']['user'] != null) ...[
                              const SizedBox(width: 8),
                              Text('by ${awb['data-deliver']['user']}', style: TextStyle(color: textS)),
                           ]
                        ],
                     );
                  } else if (isRejected) {
                     return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const Icon(Icons.block_rounded, color: Colors.amber, size: 24),
                           const SizedBox(width: 8),
                           const Text('Rejected', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                           if (awb['data-reject']['user'] != null) ...[
                              const SizedBox(width: 8),
                              Text('by ${awb['data-reject']['user']}', style: TextStyle(color: textS)),
                           ]
                        ],
                     );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _isDelivering ? null : () async {
                          String reason = '';
                          final piecesCtrl = TextEditingController();
                          bool rejectAll = false;
                          
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => StatefulBuilder(
                              builder: (ctx, setDialogState) {
                                return AlertDialog(
                                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Reject AWB', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Quantity (Pieces)', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: piecesCtrl,
                                              keyboardType: TextInputType.number,
                                              style: TextStyle(color: textP),
                                              decoration: InputDecoration(
                                                hintText: 'Ej. 5',
                                                hintStyle: TextStyle(color: textS.withValues(alpha: 0.5)),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCard), borderRadius: BorderRadius.circular(8)),
                                                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366f1)), borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: rejectAll,
                                                activeColor: const Color(0xFF6366f1),
                                                onChanged: (val) {
                                                  setDialogState(() {
                                                    rejectAll = val ?? false;
                                                    if (rejectAll) {
                                                      piecesCtrl.text = totalPieces;
                                                    } else {
                                                      piecesCtrl.clear();
                                                    }
                                                  });
                                                },
                                              ),
                                              Text('All ($totalPieces)', style: TextStyle(color: textP)),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text('Please provide a reason for rejecting this AWB.', style: TextStyle(color: textS)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        style: TextStyle(color: textP),
                                        decoration: InputDecoration(
                                          hintText: 'Reason...',
                                          hintStyle: TextStyle(color: textS.withValues(alpha: 0.5)),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCard), borderRadius: BorderRadius.circular(8)),
                                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366f1)), borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (val) => reason = val,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('Cancel', style: TextStyle(color: textS)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      child: const Text('Confirm Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              }
                            ),
                          );

                          if (confirm == true && reason.trim().isNotEmpty && piecesCtrl.text.trim().isNotEmpty) {
                             setState(() => _isDelivering = true);
                             String userFullName = 'Driver';
                             final uUser = Supabase.instance.client.auth.currentUser;
                             if (uUser != null) {
                                userFullName = uUser.email?.split('@')[0] ?? 'Driver';
                                try {
                                   final userRow = await Supabase.instance.client.from('Users').select('full-name').eq('id', uUser.id).maybeSingle();
                                   if (userRow != null && userRow['full-name'] != null) {
                                      userFullName = userRow['full-name'];
                                   }
                                } catch (_) {}
                             }
                             final timeStr = DateTime.now().toUtc().toIso8601String();
                             
                             try {
                               await Supabase.instance.client.from('AWB').update({
                                  'data-reject': {
                                     'time': timeStr,
                                     'user': userFullName,
                                     'reason': reason.trim(),
                                     'pieces': int.tryParse(piecesCtrl.text.trim()) ?? 0,
                                  }
                               }).eq('AWB-number', awbNum);
                               
                               if (mounted && context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AWB Rejected.'), backgroundColor: Colors.amber));
                                 setState(() {
                                    awb['data-reject'] = {
                                       'time': timeStr,
                                       'user': userFullName,
                                       'reason': reason.trim(),
                                       'pieces': int.tryParse(piecesCtrl.text.trim()) ?? 0,
                                    };
                                 });
                               }
                             } catch (e) {
                               if (mounted && context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error registering rejection.'), backgroundColor: Colors.redAccent));
                               }
                             } finally {
                               if (mounted) {
                                 setState(() => _isDelivering = false);
                               }
                             }
                          } else if (confirm == true) {
                             if (mounted && context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reason and quantity are required to reject.'), backgroundColor: Colors.redAccent));
                             }
                          }
                          piecesCtrl.dispose();
                        },
                        icon: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 20),
                        label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: (foundPieces > 0 && foundPieces == expectedDeliver && !_isDelivering) ? () async {
                          setState(() => _isDelivering = true);
                          String userFullName = 'Driver';
                          final uUser = Supabase.instance.client.auth.currentUser;
                          if (uUser != null) {
                             userFullName = uUser.email?.split('@')[0] ?? 'Driver';
                             try {
                                final userRow = await Supabase.instance.client.from('Users').select('full-name').eq('id', uUser.id).maybeSingle();
                                if (userRow != null && userRow['full-name'] != null) {
                                   userFullName = userRow['full-name'];
                                }
                             } catch (_) {}
                          }
                          final timeStr = DateTime.now().toUtc().toIso8601String();
                          
                          try {
                            await Supabase.instance.client.from('AWB').update({
                               'data-deliver': {
                                  'time': timeStr,
                                  'user': userFullName,
                                  'delivery': expectedDeliver,
                                  'found': foundPieces,
                                  'total': int.tryParse(totalPieces) ?? 0,
                               }
                            }).eq('AWB-number', awbNum);
                            
                            if (mounted && context.mounted) {
                              setState(() {
                                 awb['data-deliver'] = {
                                    'time': timeStr,
                                    'user': userFullName,
                                    'delivery': expectedDeliver,
                                    'found': foundPieces,
                                    'total': int.tryParse(totalPieces) ?? 0,
                                 };
                              });

                              bool dialogOpen = true;
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: false,
                                barrierColor: Colors.black54,
                                transitionDuration: const Duration(milliseconds: 350),
                                pageBuilder: (context, anim1, anim2) {
                                  return Center(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        width: 320,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                        decoration: BoxDecoration(
                                          color: dark ? const Color(0xFF1e293b) : Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF10b981).withValues(alpha: 0.15),
                                              blurRadius: 40,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                          border: Border.all(color: const Color(0xFF10b981).withValues(alpha: 0.2), width: 1.5),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10b981).withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              appLanguage.value == 'es' ? 'Entrega Confirmada' : 'Driver Delivery',
                                              style: TextStyle(
                                                color: dark ? Colors.white : const Color(0xFF111827),
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              appLanguage.value == 'es' ? 'El AWB se entregó correctamente.' : 'The AWB was successfully delivered.',
                                              style: TextStyle(
                                                color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                transitionBuilder: (context, anim1, anim2, child) {
                                  return Transform.scale(
                                    scale: Curves.easeOutBack.transform(anim1.value),
                                    child: FadeTransition(
                                      opacity: anim1,
                                      child: child,
                                    ),
                                  );
                                },
                              ).then((_) => dialogOpen = false);

                              Future.delayed(const Duration(milliseconds: 2000), () {
                                if (mounted && context.mounted) {
                                  if (dialogOpen) {
                                    Navigator.of(context).pop();
                                  }
                                  setState(() => _selectedAwbDetails = null);
                                }
                              });
                            }
                          } catch (e) {
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error registering delivery.'), backgroundColor: Colors.redAccent));
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isDelivering = false);
                            }
                          }
                        } : null,
                        icon: _isDelivering ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.outbox_rounded, color: Colors.white, size: 20),
                        label: Text(_isDelivering ? 'Delivering...' : 'Deliver AWB', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          disabledBackgroundColor: const Color(0xFF6366f1).withValues(alpha: 0.5),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

  Future<void> _showDriverCoordinatorDialog(Map<String, dynamic> awb, Map<String, dynamic> awbItem) async {
    final dark = isDarkMode.value;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

    final ctrls = {
      'AGI Skid': TextEditingController(),
      'Pre Skid': TextEditingController(),
      'Crate': TextEditingController(),
      'Box': TextEditingController(),
      'Other': TextEditingController(),
    };

    int expectedPieces = int.tryParse(awbItem['pieces']?.toString() ?? '0') ?? 0;
    int enteredPieces = 0;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateCount() {
              int sum = 0;
              ctrls.forEach((key, ctrl) {
                if (key == 'AGI Skid') {
                  final parts = ctrl.text.split(RegExp(r'[,\s-]+'));
                  for (var p in parts) {
                    sum += int.tryParse(p) ?? 0;
                  }
                } else {
                  sum += int.tryParse(ctrl.text) ?? 0;
                }
              });
              if (sum != enteredPieces) setDialogState(() => enteredPieces = sum);
            }

            int agiLastLen = 0;

            Widget buildField(String label) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: ctrls[label],
                  keyboardType: label == 'AGI Skid' ? TextInputType.text : TextInputType.number,
                  inputFormatters: [
                    if (label == 'AGI Skid')
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s+]'))
                    else
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(color: textP),
                  onChanged: (val) {
                    if (label == 'AGI Skid') {
                      if (val.endsWith(' ') && val.length > agiLastLen) {
                        final newText = '${val.substring(0, val.length - 1)} + ';
                        ctrls[label]!.value = TextEditingValue(
                          text: newText,
                          selection: TextSelection.collapsed(offset: newText.length),
                        );
                      }
                      agiLastLen = ctrls[label]!.text.length;
                    }
                    updateCount();
                  },
                  decoration: InputDecoration(
                    labelText: label == 'AGI Skid' ? 'AGI Skid (space separated)' : label,
                    labelStyle: TextStyle(color: textS, fontSize: label == 'AGI Skid' ? 13 : 15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
              title: Column(
                children: [
                  Text('Insert Coordinator Data', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('EXPECTED', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$expectedPieces', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(width: 1, height: 35, color: dark ? Colors.white24 : Colors.grey.shade300),
                      Column(
                        children: [
                          Text('COUNTED', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$enteredPieces', style: TextStyle(color: enteredPieces == expectedPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildField('AGI Skid'),
                      buildField('Pre Skid'),
                      buildField('Crate'),
                      buildField('Box'),
                      buildField('Other'),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: textS)),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() => isLoading = true);
                    
                    String userFullName = 'Driver';
                    final uUser = Supabase.instance.client.auth.currentUser;
                    if (uUser != null) {
                      userFullName = uUser.email?.split('@')[0] ?? 'Driver';
                      try {
                        final userRow = await Supabase.instance.client.from('Users').select('full-name').eq('id', uUser.id).maybeSingle();
                        if (userRow != null && userRow['full-name'] != null) {
                          userFullName = userRow['full-name'];
                        }
                      } catch (_) {}
                    }

                    final timeStr = DateTime.now().toUtc().toIso8601String();

                    Map<String, dynamic> breakdownToSave = {};
                    ctrls.forEach((key, ctrl) {
                      if (key == 'AGI Skid') {
                        final parts = ctrl.text.split(RegExp(r'[,\s-]+'));
                        List<int> skids = [];
                        for (var p in parts) {
                          final v = int.tryParse(p);
                          if (v != null && v > 0) skids.add(v);
                        }
                        breakdownToSave[key] = skids;
                      } else {
                        breakdownToSave[key] = int.tryParse(ctrl.text) ?? 0;
                      }
                    });

                    if (enteredPieces != expectedPieces) {
                      if (!ctx.mounted) return;
                      bool? confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (context) => AlertDialog(
                          backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                          title: Text('Discrepancy Detected', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                          content: Text(
                            'Expected $expectedPieces pieces, but counted $enteredPieces. Do you want to proceed and save this discrepancy?',
                            style: TextStyle(color: textP),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: textS))),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true), 
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444)),
                              child: const Text('Proceed', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm != true) {
                        setDialogState(() => isLoading = false);
                        return;
                      }
                    }

                    Map<String, dynamic> coordData = {
                      'breakdown': breakdownToSave,
                      'refULD': awbItem['refULD']?.toString().toUpperCase(),
                      'refCarrier': awbItem['refCarrier'],
                      'refNumber': awbItem['refNumber'],
                      'refDate': awbItem['refDate'],
                      'user': userFullName,
                      'time': timeStr,
                      'selectedLocations': [],
                    };

                    if (enteredPieces != expectedPieces) {
                      coordData['discrepancy'] = {
                        'confirmed': true,
                        'expected': expectedPieces,
                        'received': enteredPieces,
                      };
                    }

                    try {
                      final existing = await Supabase.instance.client.from('AWB').select('data-coordinator').eq('AWB-number', awb['AWB-number']).maybeSingle();
                      List<dynamic> existingDcList = [];
                      if (existing != null && existing['data-coordinator'] != null) {
                        if (existing['data-coordinator'] is List) {
                          existingDcList = List.from(existing['data-coordinator']);
                        } else if (existing['data-coordinator'] is Map) {
                          existingDcList = [existing['data-coordinator']];
                        }
                      }

                      existingDcList.add(coordData);

                      await Supabase.instance.client.from('AWB').update({
                        'data-coordinator': existingDcList,
                      }).eq('AWB-number', awb['AWB-number']);
                      
                    } catch (e) {
                      debugPrint('Error saving driver coordinator: $e');
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    
                    if (!mounted) return;
                    if (_selectedDriver != null) {
                      final previouslySelectedAwbNumber = awb['AWB-number'];
                      await _loadDriverDetails(_selectedDriver!);
                      
                      if (mounted) {
                        try {
                           final matchingAwb = _driverAwbs.firstWhere((a) => a['AWB-number'] == previouslySelectedAwbNumber);
                           setState(() => _selectedAwbDetails = matchingAwb);
                        } catch (_) {}
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white),
                  child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}


