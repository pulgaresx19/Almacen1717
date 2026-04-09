import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;

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
  final Map<String, Map<String, dynamic>> _driverItemPayloadData = {};
  final Set<String> _hiddenDriverItems = {};
  final Map<String, Map<String, dynamic>> _localRejections = {};
  List<Map<String, dynamic>> _driverAwbs = [];
  bool _isLoadingAwbs = false;
  bool _isDelivering = false;
  bool _autoFoundPieces = true;
  final _manualFoundCtrl = TextEditingController(text: '0');
  late Stream<List<Map<String, dynamic>>> _deliversStream;

  @override
  void initState() {
    super.initState();
    _deliversStream = Supabase.instance.client.from('Delivers').stream(primaryKey: ['id']).order('time-deliver', ascending: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualFoundCtrl.dispose();
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
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _deliversStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildDriverDetailView(_selectedDriver!, dark, textP, textS, bgCard, borderCard, iconColor);
                }
                final uList = snapshot.data ?? [];
                final updatedDriver = uList.firstWhere(
                  (element) => element['id'] == _selectedDriver!['id'],
                  orElse: () => _selectedDriver!
                );
                return _buildDriverDetailView(updatedDriver, dark, textP, textS, bgCard, borderCard, iconColor);
              }
            )
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
                    const statusOrder = ['Waiting', 'In process', 'Ready', 'Canceled'];
                    final statusA = a['status']?.toString() ?? 'Waiting';
                    final statusB = b['status']?.toString() ?? 'Waiting';
                    
                    int indexA = statusOrder.indexOf(statusA);
                    int indexB = statusOrder.indexOf(statusB);
                    if (indexA == -1) indexA = 999;
                    if (indexB == -1) indexB = 999;
                    
                    int statusComp = indexA.compareTo(indexB);
                    if (statusComp != 0) return statusComp;

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
                                const DataColumn(label: Text('No Show')),
                                const DataColumn(label: Text('Agent')),
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
                                
                                int noShowCount = 0;
                                if (u['no-show'] != null) {
                                  if (u['no-show'] is List) {
                                    noShowCount = (u['no-show'] as List).length;
                                  } else if (u['no-show'] is Map && (u['no-show'] as Map).isNotEmpty) {
                                    noShowCount = 1;
                                  }
                                }

                                return DataRow(
                                  onSelectChanged: (selected) {
                                    if (selected == true) {
                                      _showDriverConfirmationOverlay(u);
                                    }
                                  },
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
                                    DataCell(
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) {
                                              List<Map<String, dynamic>> awbItems = [];
                                              if (u['list-pickup'] is List) {
                                                awbItems = (u['list-pickup'] as List).map((e) {
                                                   if (e is Map) return Map<String, dynamic>.from(e);
                                                   final str = e.toString();
                                                   final parts = str.split(' - ');
                                                   return {
                                                      'AWB-number': parts.isNotEmpty ? parts[0].trim() : '-',
                                                      'pieces': parts.length > 1 ? parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '') : '-',
                                                      'weight': '',
                                                      'remarks': parts.length > 2 ? parts[2].trim() : '',
                                                   };
                                                }).toList();
                                              } else if (u['list-pickup'] != null) {
                                                final str = u['list-pickup'].toString();
                                                final parts = str.split(' - ');
                                                awbItems = [{
                                                   'AWB-number': parts.isNotEmpty ? parts[0].trim() : '-',
                                                   'pieces': parts.length > 1 ? parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '') : '-',
                                                   'weight': '',
                                                   'remarks': parts.length > 2 ? parts[2].trim() : '',
                                                }];
                                              }
                                              return AlertDialog(
                                                backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                                title: Row(
                                                  children: [
                                                    const Icon(Icons.inventory_2_rounded, color: Color(0xFF6366f1)),
                                                    const SizedBox(width: 8),
                                                    Text('AWBs Details', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold)),
                                                  ]
                                                ),
                                                content: SizedBox(
                                                  width: 400,
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: awbItems.length,
                                                    itemBuilder: (ctx, i) {
                                                      final item = awbItems[i];
                                                      final awbN = item['AWB-number']?.toString() ?? '-';
                                                      final pcs = item['pieces']?.toString() ?? '-';
                                                      final weight = item['weight']?.toString() ?? '';
                                                      final rmks = item['remarks']?.toString() ?? '';
                                                      return Container(
                                                        margin: const EdgeInsets.only(bottom: 8),
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Expanded(child: Text(awbN, style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold))),
                                                                SizedBox(
                                                                  width: 70,
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                    children: [
                                                                      Flexible(child: Text('$pcs pcs', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                                    ],
                                                                  ),
                                                                ),
                                                                if (weight.isNotEmpty && weight != '0.00' && weight != '0')
                                                                  SizedBox(
                                                                    width: 80,
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        Flexible(child: Text('${weight}kg', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                if (weight.isEmpty || weight == '0.00' || weight == '0')
                                                                  const SizedBox(width: 80),
                                                              ]
                                                            ),
                                                            if (rmks.isNotEmpty) ...[
                                                              const SizedBox(height: 4),
                                                              Text('Remarks: $rmks', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 12)),
                                                            ]
                                                          ]
                                                        )
                                                      );
                                                    }
                                                  )
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx),
                                                    child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold))
                                                  )
                                                ]
                                              );
                                            }
                                          );
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366f1).withAlpha(25),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(awbsStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366f1), fontSize: 13)),
                                        )
                                      )
                                    ),
                                    DataCell(
                                      noShowCount > 0 
                                          ? InkWell(
                                              onTap: () {
                                                _showNoShowDetails(context, u['no-show'], dark, dark ? Colors.white : const Color(0xFF111827));
                                              },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(color: Colors.redAccent.withAlpha(30), shape: BoxShape.circle),
                                                child: Text('$noShowCount', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                              ),
                                            )
                                          : const Text('-', style: TextStyle(color: Colors.grey))
                                    ),
                                    DataCell(
                                      Builder(builder: (ctx) {
                                        if (u['ref-userDrive'] == null) return const Text('-', style: TextStyle(color: Colors.grey));
                                        if (u['ref-userDrive'] is Map) {
                                          final userMap = u['ref-userDrive'] as Map;
                                          final userName = userMap['user']?.toString() ?? '-';
                                          String dtStr = '';
                                          if (userMap['time'] != null) {
                                            final dt = DateTime.tryParse(userMap['time'].toString())?.toLocal();
                                            if (dt != null) dtStr = DateFormat('MMM dd, hh:mm a').format(dt);
                                          }
                                          final avatarStr = userMap['avatar']?.toString();
                                          return Tooltip(
                                            message: 'Agent: $userName',
                                            child: InkWell(
                                              onTap: () => _showAgentProfile(context, userName, avatarStr, dtStr, dark),
                                              borderRadius: BorderRadius.circular(20),
                                              child: CircleAvatar(
                                                radius: 16,
                                                backgroundColor: const Color(0xFF6366f1).withAlpha(50),
                                                backgroundImage: avatarStr != null && avatarStr.isNotEmpty ? NetworkImage(avatarStr) : null,
                                                child: avatarStr == null || avatarStr.isEmpty ? Text(
                                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366f1), fontSize: 13),
                                                ) : null,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('-', style: TextStyle(color: Colors.grey));
                                      })
                                    ),
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

  void _showAgentProfile(BuildContext context, String userName, String? avatarStr, String timeStr, bool dark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(50),
      builder: (BuildContext modalContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10))
                ],
                border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF4f46e5),
                    backgroundImage: avatarStr != null && avatarStr.isNotEmpty ? NetworkImage(avatarStr) : null,
                    child: avatarStr == null || avatarStr.isEmpty ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                    ) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF6366f1).withAlpha(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(modalContext),
                      child: Text('Close', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155).withAlpha(150); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('in process') || s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('ready')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('canceled')) {
      bg = const Color(0xFF7f1d1d).withAlpha(51); fg = const Color(0xFFfca5a5);
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


  void _showNoShowDetails(BuildContext context, dynamic noShowData, bool dark, Color textP) {
    List<Map<String, dynamic>> items = [];
    if (noShowData is List) {
      items = noShowData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (noShowData is Map) {
      items = [Map<String, dynamic>.from(noShowData)];
    }

    showDialog(context: context, builder: (ctx) {
      return Dialog(
        backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No Show Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...items.map((i) {
                String tStr = i['time']?.toString() ?? '-';
                if (tStr != '-') {
                  final parsed = DateTime.tryParse(tStr)?.toLocal();
                  if (parsed != null) {
                    tStr = DateFormat('MMM dd, hh:mm a').format(parsed);
                  }
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark ? Colors.white.withAlpha(20) : Colors.grey.shade300)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(i['user']?.toString() ?? 'Unknown User', style: TextStyle(color: textP, fontWeight: FontWeight.w600))),
                        ]
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tStr, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                        ]
                      )
                    ]
                  )
                );
              }),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        )
      );
    });
  }

  void _showDriverConfirmationOverlay(Map<String, dynamic> u) {
    bool dark = isDarkMode.value;

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

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1e293b) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(dark ? 100 : 25),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                )
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)))
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366f1).withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF6366f1), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          appLanguage.value == 'es' ? 'Verificar Conductor' : 'Verify Driver', 
                          style: TextStyle(color: dark ? Colors.white : const Color(0xFF0f172a), fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                      ),
                      if (u['isPriority'] == true)
                        const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Icon(Icons.star_rounded, color: Colors.orange, size: 28),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF0f172a).withAlpha(128) : const Color(0xFFf8fafc),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _confirmDetailRow(Icons.business_rounded, appLanguage.value == 'es' ? 'Compañía' : 'Company', u['truck-company']?.toString().isNotEmpty == true ? u['truck-company'].toString() : '-', dark),
                                      Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), height: 24),
                                      _confirmDetailRow(Icons.person_rounded, appLanguage.value == 'es' ? 'Conductor' : 'Driver', u['driver']?.toString().isNotEmpty == true ? u['driver'].toString() : '-', dark),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: dark ? Colors.amberAccent.withAlpha(20) : Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: dark ? Colors.amberAccent.withAlpha(50) : Colors.amber.shade300)
                                  ),
                                  child: Column(
                                    children: [
                                      Text(appLanguage.value == 'es' ? 'PUERTA' : 'DOOR', style: TextStyle(color: dark ? Colors.amberAccent : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text(u['door']?.toString().isNotEmpty == true ? u['door'].toString() : '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 24, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), height: 24),
                            Row(
                              children: [
                                Expanded(child: _confirmDetailRow(Icons.local_shipping_rounded, appLanguage.value == 'es' ? 'Tipo' : 'Type', u['type']?.toString().isNotEmpty == true ? u['type'].toString() : '-', dark)),
                                Container(width: 1, height: 40, color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                                Expanded(child: _confirmDetailRow(Icons.qr_code_rounded, 'ID Pickup', u['id-pickup']?.toString().isNotEmpty == true ? u['id-pickup'].toString() : '-', dark)),
                              ],
                            ),
                            Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), height: 24),
                            Row(
                              children: [
                                Expanded(child: _confirmDetailRow(Icons.access_time_rounded, appLanguage.value == 'es' ? 'Hora' : 'Time', timeStr, dark)),
                                Container(width: 1, height: 40, color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                                Expanded(child: _confirmDetailRow(Icons.inventory_2_outlined, 'AWBs', awbsStr, dark)),
                              ],
                            ),
                            if (u['remarks']?.toString().isNotEmpty == true) ...[
                              Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), height: 24),
                              _confirmDetailRow(Icons.notes_rounded, appLanguage.value == 'es' ? 'Comentarios' : 'Remarks', u['remarks'].toString(), dark),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    border: Border(top: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.block_rounded, size: 18),
                        onPressed: () async {
                          final currentTime = DateTime.now().toIso8601String();
                          final currentUserFullName = currentUserData.value?['full-name'] ?? 'Unknown';
                          
                          try {
                            final currentNoShow = u['no-show'];
                            List updatedNoShowList = [];
                            if (currentNoShow is List) {
                              updatedNoShowList = List.from(currentNoShow);
                            } else if (currentNoShow is Map && currentNoShow.isNotEmpty) {
                              updatedNoShowList.add(currentNoShow);
                            }
                            updatedNoShowList.add({
                              'time': currentTime,
                              'user': currentUserFullName,
                            });
                            
                            Map<String, dynamic> updatePayload = {
                              'no-show': updatedNoShowList
                            };
                            
                            if (updatedNoShowList.length >= 2) {
                              updatePayload['status'] = 'Canceled';
                            }
                            
                            await Supabase.instance.client.from('Delivers').update(updatePayload).eq('id', u['id']);
                          } catch (e) {
                            debugPrint('NO SHOW Update Error: $e');
                          }
                          
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFef4444),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        label: const Text('NO SHOW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final currentTime = DateTime.now().toUtc().toIso8601String();
                          final currentUserFullName = currentUserData.value?['full-name'] ?? 'Unknown';
                          final currentUserAvatar = currentUserData.value?['avatar-url'];

                          try {
                            await Supabase.instance.client.from('Delivers').update({
                              'ref-userDrive': {
                                'time': currentTime,
                                'user': currentUserFullName,
                                'avatar': currentUserAvatar,
                              }
                            }).eq('id', u['id']);
                            u['ref-userDrive'] = {
                                'time': currentTime,
                                'user': currentUserFullName,
                                'avatar': currentUserAvatar,
                            };
                          } catch (e) {
                            debugPrint('Confirm Update Error: $e');
                          }
                          
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _loadDriverDetails(u);
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        label: Text(appLanguage.value == 'es' ? 'Confirmar' : 'Confirm', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        );
      }
    );
  }

  Widget _confirmDetailRow(IconData icon, String label, String value, bool dark) {
    return Row(
      children: [
        Icon(icon, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: dark ? const Color(0xFFf8fafc) : const Color(0xFF0f172a), fontSize: 14, fontWeight: FontWeight.bold)),
            ]
          ),
        )
      ]
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
           if (e is Map) return e['AWB-number']?.toString() ?? '';
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

  Widget _buildDriverDetailView(Map<String, dynamic> u, bool dark, Color textP, Color textS, Color bgCard, Color borderCard, Color iconColor) {
    bool allDelivered = _driverAwbs.isNotEmpty && _driverAwbs.every((awb) {
      if (awb['data-deliver'] == null) return false;
      if (awb['data-deliver'] is List) {
        return (awb['data-deliver'] as List).any((d) => d is Map && d['pickup_id'] == u['id-pickup']);
      }
      if (awb['data-deliver'] is Map) {
        return awb['data-deliver']['pickup_id'] == u['id-pickup'];
      }
      return false;
    });
    
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
                           ..._driverAwbs.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final awb = entry.value;
                              final awbNum = awb['AWB-number']?.toString() ?? '-';
                              final listPickup = u['list-pickup'] as List? ?? [];
                              String piecesStr = '';
                              String remarkStr = '';
                              String weightStr = '';
                              for (var item in listPickup) {
                                if (item is Map && item['AWB-number'] == awbNum) {
                                   piecesStr = item['pieces']?.toString() ?? '';
                                   weightStr = item['weight']?.toString() ?? '';
                                   remarkStr = item['remarks']?.toString() ?? '';
                                   if (!piecesStr.toLowerCase().contains('pcs') && piecesStr.isNotEmpty) piecesStr += ' Pcs';
                                   if (weightStr.isNotEmpty && weightStr != '0.00' && weightStr != '0') weightStr += ' kg';
                                   break;
                                } else if (item is String && item.startsWith(awbNum)) {
                                   final parts = item.split(' - ');
                                   if (parts.length > 1) piecesStr = parts[1].trim();
                                   if (parts.length > 2) remarkStr = parts[2].trim();
                                   break;
                                }
                              }

                              bool isThisDelivered = false;
                              if (awb['data-deliver'] != null) {
                                if (awb['data-deliver'] is List) {
                                  isThisDelivered = (awb['data-deliver'] as List).any((d) => d is Map && d['pickup_id'] == u['id-pickup']);
                                } else if (awb['data-deliver'] is Map) {
                                  isThisDelivered = awb['data-deliver']['pickup_id'] == u['id-pickup'];
                                }
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
                                    Container(
                                      width: 24, height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                      child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: Text(awbNum, style: const TextStyle(color: Color(0xFF6366f1), fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Flexible(child: Text(piecesStr, style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: weightStr.isNotEmpty ? Row(
                                        children: [
                                          Flexible(child: Text(weightStr, style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ) : const SizedBox(),
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: remarkStr.isNotEmpty ? Row(
                                          children: [
                                            Icon(Icons.notes_rounded, color: textS, size: 14),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text(remarkStr, style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ) : const SizedBox(),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.check_circle_outline_rounded, 
                                      color: isThisDelivered ? const Color(0xFF10b981) : textS, 
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
                 const SizedBox(height: 16),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     onPressed: allDelivered ? () async {
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
                                      BoxShadow(color: const Color(0xFF10b981).withAlpha(40), blurRadius: 40, offset: const Offset(0, 10)),
                                    ],
                                    border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(20), shape: BoxShape.circle),
                                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        appLanguage.value == 'es' ? '¡Entrega Completada!' : 'Delivery Completed!',
                                        style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        appLanguage.value == 'es' ? 'La entrega ha sido registrada exitosamente.' : 'The delivery has been successfully recorded.',
                                        style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 14, fontWeight: FontWeight.w500),
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
                              child: FadeTransition(opacity: anim1, child: child),
                            );
                          },
                        ).then((_) => dialogOpen = false);

                        try {
                          await Supabase.instance.client.from('Delivers').update({
                             'status': 'Delivered'
                          }).eq('id', u['id']);
                          
                          await Future.delayed(const Duration(milliseconds: 2000));
                          
                          if (mounted) {
                            if (dialogOpen) Navigator.of(context).pop();
                            
                            setState(() {
                              _selectedDriver = null;
                              _selectedAwbDetails = null;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            if (dialogOpen) Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating status: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                     } : null,
                     icon: Icon(Icons.check_circle_outline, 
                       color: allDelivered ? Colors.white : (dark ? Colors.white54 : Colors.black38), 
                       size: 20
                     ),
                     label: Text('DELIVERY COMPLETED', 
                       style: TextStyle(
                         fontWeight: FontWeight.bold, 
                         fontSize: 14,
                         color: allDelivered ? Colors.white : (dark ? Colors.white54 : Colors.black38)
                       )
                     ),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       backgroundColor: allDelivered ? const Color(0xFF10b981) : (dark ? Colors.white12 : Colors.black12),
                       elevation: allDelivered ? 2 : 0,
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

  List<Widget> _buildSavedDeliveryUI(Map? matchingDelivery, String awbNum, bool dark, Color textP, Color textS, Color borderCard) {
    if (matchingDelivery == null || matchingDelivery['references'] == null) return [];
    List refs = matchingDelivery['references'] is List ? matchingDelivery['references'] : [];
    if (refs.isEmpty) return [Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No delivered items selected.', style: TextStyle(color: textS))))];
    
    // Group by ULD + Flight
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var r in refs) {
       if (r is Map) {
          String uld = r['refULD']?.toString() ?? 'UNKNOWN ULD';
          String curFlight = r['refNumber']?.toString() ?? '';
          String carrier = r['refCarrier']?.toString() ?? '';
          String groupKey = '${uld}___${curFlight}___$carrier';
          if (!grouped.containsKey(groupKey)) grouped[groupKey] = [];
          grouped[groupKey]!.add(Map<String, dynamic>.from(r));
       }
    }
    
    return grouped.entries.map((entry) {
       String groupKey = entry.key;
       var parts = groupKey.split('___');
       String uldNumber = parts[0];
       String flightNum = parts.length > 2 ? parts[1] : '';
       String carrierNum = parts.length > 2 ? parts[2] : '';
       String flightStr = '$carrierNum $flightNum'.trim();
       
       List<Map<String, dynamic>> items = entry.value;

       String rawDate = items.isNotEmpty ? (items.first['refDate']?.toString() ?? '') : '';
       String dateStr = rawDate;
       if (dateStr.length >= 10 && dateStr.contains('-')) {
         var dateParts = dateStr.split('-');
         if (dateParts.length >= 3) {
           dateStr = '${dateParts[1]}-${dateParts[2]}';
         }
       }
       
       bool isBreak = !items.any((i) => i['item'] == 'NO BREAK AREA');
       
       String uldKey = 'DELIVERED_${awbNum}_$uldNumber';
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
                                   uldNumber,
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
                                     maxLines: 1,
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
                             const Center(
                               child: Text(
                                 'DELIVERED',
                                 style: TextStyle(color: Color(0xFF10b981), fontSize: 13, fontWeight: FontWeight.bold),
                               ),
                             ),
                             dark,
                             width: 110,
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
                   ),
                 ],
               ),
             ),
             if (!isHidden)
               ClipRRect(
                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                 child: LayoutBuilder(
                   builder: (context, constraints) {
                     List<DataRow> tableRows = items.map((item) {
                        String displayName = item['item']?.toString() ?? '';
                        if (displayName == 'NO BREAK AREA' || displayName == 'NO_BREAK') {
                           displayName = item['refULD']?.toString() ?? displayName;
                        }
                        String pieces = item['pieces']?.toString() ?? '-';
                        if (pieces == '0' || pieces == 'null') pieces = '-';
                        String locText = item['location']?.toString() ?? 'FLOOR';
                        Color locColor = locText == 'FLOOR' ? textS : textP;
                        
                        return DataRow(cells: [
                           const DataCell(Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 20)),
                           DataCell(Text(displayName, style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 14))),
                           DataCell(Text(pieces, style: TextStyle(color: textP, fontSize: 14))),
                           DataCell(Text(locText, style: TextStyle(color: locColor, fontSize: 14, fontStyle: locText == 'FLOOR' ? FontStyle.italic : FontStyle.normal))),
                        ]);
                     }).toList();

                     return SingleChildScrollView(
                       scrollDirection: Axis.horizontal,
                       child: ConstrainedBox(
                         constraints: BoxConstraints(minWidth: constraints.maxWidth),
                         child: DataTable(
                           headingRowHeight: 40,
                           headingRowColor: WidgetStateProperty.all(Colors.transparent),
                           columns: [
                             DataColumn(
                               label: Icon(Icons.done_all, color: textS.withAlpha(150), size: 22)
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
    }).toList();
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

    Map<String, dynamic>? matchingDelivery;
    Set<String> alreadyPickedUpKeys = {};
    if (awb['data-deliver'] != null) {
      if (awb['data-deliver'] is List) {
        for (var d in (awb['data-deliver'] as List)) {
          if (d is Map && d['pickup_id'] == _selectedDriver?['id-pickup']) {
            matchingDelivery = d as Map<String, dynamic>;
          }
          if (d is Map && d['references'] is List) {
            for (var ref in d['references']) {
               if (ref is Map) {
                  alreadyPickedUpKeys.add('${ref['refULD']}_${ref['refNumber']}_${ref['item']}');
               }
            }
          }
        }
      } else if (awb['data-deliver'] is Map) {
        final singleMap = awb['data-deliver'] as Map<String, dynamic>;
        if (singleMap['pickup_id'] == _selectedDriver?['id-pickup']) {
          matchingDelivery = singleMap;
        }
        if (singleMap['references'] is List) {
           for (var ref in singleMap['references']) {
              if (ref is Map) {
                 alreadyPickedUpKeys.add('${ref['refULD']}_${ref['refNumber']}_${ref['item']}');
              }
           }
        }
      }
    }
    
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
      final listPickup = _selectedDriver!['list-pickup'] as List? ?? [];
      for (var item in listPickup) {
        if (item is Map && item['AWB-number'] == awbNum) {
          deliverPiecesStr = item['pieces']?.toString() ?? '';
          if (!deliverPiecesStr.toLowerCase().contains('pcs') && deliverPiecesStr.isNotEmpty) deliverPiecesStr += ' Pcs';
          break;
        } else if (item is String && item.startsWith(awbNum)) {
          final parts = item.split(' - ');
          if (parts.length > 1) deliverPiecesStr = parts[1].trim();
          break;
        }
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
    
    int calculatedFoundPieces = foundPieces;
    if (!_autoFoundPieces) {
       foundPieces = int.tryParse(_manualFoundCtrl.text) ?? 0;
    }
    
    String digitsOnly = deliverPiecesStr.replaceAll(RegExp(r'[^0-9]'), '');
    int expectedDeliver = int.tryParse(digitsOnly) ?? 0;

    int rejectedQty = 0;
    String rejectReason = '';
    String rejectUser = '';
    String rejectTime = 'Unknown';
    String rejectLocation = 'Unknown';
    
    List<Map<String, dynamic>> rejectList = [];
    
    if (_localRejections.containsKey(awbNum)) {
      rejectList.add(_localRejections[awbNum]!);
    } else {
      if (matchingDelivery != null && matchingDelivery['rejection'] != null) {
        rejectList.add(matchingDelivery['rejection'] as Map<String, dynamic>);
      }
    }

    for (var rejectData in rejectList) {
      rejectedQty += int.tryParse(rejectData['pieces']?.toString() ?? rejectData['qty']?.toString() ?? '0') ?? 0;
      rejectReason = rejectData['reason']?.toString() ?? 'No reason provided';
      rejectUser = rejectData['user']?.toString() ?? 'Unknown';
      rejectLocation = rejectData['location']?.toString() ?? 'Unknown';
      if (rejectData['time'] != null) {
        try {
          final dt = DateTime.parse(rejectData['time'].toString()).toLocal();
          rejectTime = DateFormat('hh:mm a').format(dt);
        } catch (_) {}
      }
    }

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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text('Found', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                if (matchingDelivery == null) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _autoFoundPieces,
                                      activeColor: const Color(0xFF6366f1),
                                      onChanged: (val) {
                                         setState(() {
                                            _autoFoundPieces = val ?? true;
                                            if (!_autoFoundPieces) {
                                               _manualFoundCtrl.text = calculatedFoundPieces.toString();
                                            }
                                         });
                                      },
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (matchingDelivery != null)
                               Text(matchingDelivery['found']?.toString() ?? '0', style: TextStyle(color: foundColor, fontSize: 24, fontWeight: FontWeight.bold))
                            else if (_autoFoundPieces)
                               Text(foundPieces.toString(), style: TextStyle(color: foundColor, fontSize: 24, fontWeight: FontWeight.bold))
                            else
                               SizedBox(
                                 width: 90,
                                 height: 36,
                                 child: TextField(
                                   controller: _manualFoundCtrl,
                                   keyboardType: TextInputType.number,
                                   style: TextStyle(color: foundColor, fontSize: 20, fontWeight: FontWeight.bold),
                                   textAlign: TextAlign.center,
                                   decoration: InputDecoration(
                                     isDense: true,
                                     contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                     enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCard), borderRadius: BorderRadius.circular(8)),
                                     focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366f1)), borderRadius: BorderRadius.circular(8)),
                                   ),
                                   onChanged: (val) {
                                      setState(() {});
                                   }
                                 )
                               ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Container(width: 1, height: 40, color: borderCard),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reject', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(rejectedQty.toString(), style: TextStyle(color: rejectedQty > 0 ? Colors.redAccent : textP, fontSize: 24, fontWeight: FontWeight.bold)),
                                if (rejectedQty > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1f2937) : Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Reject Details', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                                                  if (_localRejections.containsKey(awbNum))
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                      tooltip: 'Delete Local Rejection',
                                                      onPressed: () {
                                                        setState(() {
                                                          _localRejections.remove(awbNum);
                                                        });
                                                        Navigator.pop(ctx);
                                                      },
                                                    ),
                                                ],
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('Pieces', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                                            const SizedBox(height: 4),
                                                            Text(rejectedQty.toString(), style: TextStyle(color: textP, fontSize: 14)),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text('Location', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                                            const SizedBox(height: 4),
                                                            Text(rejectLocation, style: TextStyle(color: textP, fontSize: 14)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text('Reason', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text(rejectReason, style: TextStyle(color: textP, fontSize: 14)),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('User', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                                            const SizedBox(height: 4),
                                                            Text(rejectUser, style: TextStyle(color: textP, fontSize: 14)),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text('Time', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                                            const SizedBox(height: 4),
                                                            Text(rejectTime, style: TextStyle(color: textP, fontSize: 14)),
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                                                )
                                              ]
                                            ),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                  Builder(
                    builder: (context) {
                      bool isSavedDelivery = matchingDelivery != null && matchingDelivery['references'] is List;
                      if (isSavedDelivery) {
                         return Column(children: _buildSavedDeliveryUI(matchingDelivery, awbNum, dark, textP, textS, borderCard));
                      }
                      
                      if (awbItems.isEmpty) {
                        return Text('No flight data available.', style: TextStyle(color: textS, fontStyle: FontStyle.italic));
                      }
                      
                      return Column(
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
                           
                           _driverItemPayloadData[checkKey] = {
                              'refULD': awbItem['refULD']?.toString() ?? '',
                              'refNumber': awbItem['refNumber']?.toString() ?? '',
                              'refCarrier': awbItem['refCarrier']?.toString() ?? '',
                              'refDate': (awbItem['refDate'] ?? locMatch['refDate'])?.toString() ?? '',
                              'item': displayName,
                              'pieces': pieces,
                              'location': locText,
                           };

                           String unifiedKey = '${awbItem['refULD']}_${awbItem['refNumber']}_$displayName';
                           bool isAlreadyPickedUp = alreadyPickedUpKeys.contains(unifiedKey);

                           return DataRow(cells: [
                             DataCell(
                               isAlreadyPickedUp
                                 ? const SizedBox(
                                     width: 40,
                                     height: 40,
                                     child: Center(
                                       child: Icon(Icons.check_circle, color: Color(0xFF10b981), size: 24),
                                     ),
                                   )
                                 : Checkbox(
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
                           
                           _driverItemPayloadData[checkKey] = {
                              'refULD': uldNumber,
                              'refNumber': awbItem['refNumber']?.toString() ?? '',
                              'refCarrier': awbItem['refCarrier']?.toString() ?? '',
                              'refDate': awbItem['refDate']?.toString() ?? '',
                              'item': uldNumber,
                              'pieces': totalPieces,
                              'location': 'NO BREAK AREA',
                           };
                           
                           allItemKeys.clear();
                           allItemKeys.add('NO_BREAK'); // to satisfy the Checkbox allChecked logic below
                           
                           tableRows.clear();
                           
                           String unifiedKey1 = '${awbItem['refULD']}_${awbItem['refNumber']}_NO BREAK AREA';
                           String unifiedKey2 = '${awbItem['refULD']}_${awbItem['refNumber']}_$uldNumber';
                           bool isAlreadyPickedUp = alreadyPickedUpKeys.contains(unifiedKey1) || alreadyPickedUpKeys.contains(unifiedKey2);

                           tableRows.add(DataRow(cells: [
                             DataCell(
                               isAlreadyPickedUp
                                 ? const SizedBox(
                                     width: 40,
                                     height: 40,
                                     child: Center(
                                       child: Icon(Icons.check_circle, color: Color(0xFF10b981), size: 24),
                                     ),
                                   )
                                 : Checkbox(
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
                                                 mainAxisAlignment: MainAxisAlignment.center,
                                                 children: [
                                                   Text('ULD:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                                                   const SizedBox(width: 4),
                                                   Flexible(
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
                                                   mainAxisAlignment: MainAxisAlignment.center,
                                                   children: [
                                                     Text('Flight:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                                                     const SizedBox(width: 4),
                                                     Flexible(
                                                       child: RichText(
                                                         overflow: TextOverflow.ellipsis,
                                                         maxLines: 1,
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
                                       Container(
                                         width: 26,
                                         height: 26,
                                         margin: const EdgeInsets.only(right: 8),
                                         decoration: BoxDecoration(
                                           color: const Color(0xFF10b981).withAlpha(30),
                                           shape: BoxShape.circle,
                                         ),
                                         alignment: Alignment.center,
                                         child: Text(
                                           '${awbItem['pieces'] ?? 0}',
                                           style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold),
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
                                           List<String> selectableKeys = allItemKeys.where((itemKey) {
                                             String displayName = itemKey.replaceAll('_', ' ');
                                             if (itemKey.startsWith('AGI Skid_')) {
                                               int idx = int.tryParse(itemKey.split('_').last) ?? 0;
                                               displayName = 'AGI Skid ${idx + 1}';
                                             }
                                             if (itemKey == 'NO_BREAK') {
                                               String unifiedKey1 = '${awbItem['refULD']}_${awbItem['refNumber']}_NO BREAK AREA';
                                               String unifiedKey2 = '${awbItem['refULD']}_${awbItem['refNumber']}_${awbItem['refULD']}';
                                               return !alreadyPickedUpKeys.contains(unifiedKey1) && !alreadyPickedUpKeys.contains(unifiedKey2);
                                             }
                                             String unifiedKey = '${awbItem['refULD']}_${awbItem['refNumber']}_$displayName';
                                             return !alreadyPickedUpKeys.contains(unifiedKey);
                                           }).toList();

                                           bool allChecked = selectableKeys.isNotEmpty && selectableKeys.every((itemKey) {
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
                                                       value: selectableKeys.isEmpty ? false : allChecked,
                                                       onChanged: selectableKeys.isEmpty ? null : (val) {
                                                         setState(() {
                                                           for (var itemKey in selectableKeys) {
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
                      );
                    }
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
                  bool isDelivered = false;
                  Map<String, dynamic>? matchingDelivery;
                  if (awb['data-deliver'] != null) {
                    if (awb['data-deliver'] is List) {
                      for (var d in (awb['data-deliver'] as List)) {
                        if (d is Map && d['pickup_id'] == _selectedDriver?['id-pickup']) {
                          isDelivered = true;
                          matchingDelivery = d as Map<String, dynamic>;
                          break;
                        }
                      }
                    } else if (awb['data-deliver'] is Map) {
                      final singleMap = awb['data-deliver'] as Map<String, dynamic>;
                      if (singleMap['pickup_id'] == _selectedDriver?['id-pickup']) {
                        isDelivered = true;
                        matchingDelivery = singleMap;
                      }
                    }
                  }

                  if (isDelivered) {
                     return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const Icon(Icons.check_circle_outline, color: Color(0xFF10b981), size: 24),
                           const SizedBox(width: 8),
                           const Text('Delivered', style: TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 16)),
                           if (matchingDelivery != null && matchingDelivery['user'] != null) ...[
                              const SizedBox(width: 8),
                              Text('by ${matchingDelivery['user']}', style: TextStyle(color: textS)),
                           ]
                        ],
                     );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _isDelivering ? null : () async {
                          final piecesCtrl = TextEditingController();
                          final locCtrl = TextEditingController();
                          bool rejectAll = false;
                          bool hasSubmitError = false;
                          bool isEditMode = true;
                          String initReason = '';

                          if (_localRejections.containsKey(awbNum)) {
                            final rInfo = _localRejections[awbNum]!;
                            initReason = rInfo['reason']?.toString() ?? '';
                            piecesCtrl.text = rInfo['qty']?.toString() ?? '';
                            locCtrl.text = rInfo['location']?.toString() == 'OVERSIZE' ? 'OVERSIZE' : (rInfo['location']?.toString() ?? '');
                            rejectAll = piecesCtrl.text == expectedDeliver.toString();
                            isEditMode = false;
                          }
                          
                          final reasonCtrl = TextEditingController(text: initReason);
                          
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => StatefulBuilder(
                              builder: (ctx, setDialogState) {
                                return AlertDialog(
                                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Reject AWB', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                                      if (!isEditMode)
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366f1), size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Edit',
                                          onPressed: () {
                                            setDialogState(() {
                                              isEditMode = true;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
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
                                              readOnly: !isEditMode,
                                              keyboardType: TextInputType.number,
                                              style: TextStyle(color: textP),
                                              decoration: InputDecoration(
                                                hintText: 'Ej. 5',
                                                hintStyle: TextStyle(color: textS.withValues(alpha: 0.5)),
                                                errorText: (hasSubmitError && piecesCtrl.text.trim().isEmpty) ? 'Required' : null,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCard), borderRadius: BorderRadius.circular(8)),
                                                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366f1)), borderRadius: BorderRadius.circular(8)),
                                                errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                                                focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onChanged: (val) {
                                                if (hasSubmitError) setDialogState(() {});
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: rejectAll,
                                                activeColor: const Color(0xFF6366f1),
                                                onChanged: isEditMode ? (val) {
                                                  setDialogState(() {
                                                    rejectAll = val ?? false;
                                                    if (rejectAll) {
                                                      piecesCtrl.text = expectedDeliver.toString();
                                                    } else {
                                                      piecesCtrl.clear();
                                                    }
                                                  });
                                                } : null,
                                              ),
                                              Text('All ($expectedDeliver)', style: TextStyle(color: textP)),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text('Please provide a reason for rejecting this AWB.', style: TextStyle(color: textS)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: reasonCtrl,
                                        readOnly: !isEditMode,
                                        style: TextStyle(color: textP),
                                        decoration: InputDecoration(
                                          hintText: 'Reason...',
                                          hintStyle: TextStyle(color: textS.withValues(alpha: 0.5)),
                                          errorText: (hasSubmitError && reasonCtrl.text.trim().isEmpty) ? 'Required' : null,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCard), borderRadius: BorderRadius.circular(8)),
                                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366f1)), borderRadius: BorderRadius.circular(8)),
                                          errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                                          focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (val) {
                                          if (hasSubmitError) setDialogState(() {});
                                        },
                                        ),
                                        const SizedBox(height: 16),
                                        Text('New Location', style: TextStyle(color: textS)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: locCtrl,
                                          readOnly: !isEditMode,
                                          style: TextStyle(color: textP),
                                          decoration: InputDecoration(
                                            hintText: 'Enter new location (Optional)...',
                                            hintStyle: TextStyle(color: textS.withValues(alpha: 0.5)),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCard), borderRadius: BorderRadius.circular(8)),
                                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6366f1)), borderRadius: BorderRadius.circular(8)),
                                            errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                                            focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                                            suffixIcon: Padding(
                                              padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
                                              child: TextButton(
                                                onPressed: isEditMode ? () {
                                                  setDialogState(() {
                                                    if (locCtrl.text == 'OVERSIZE') {
                                                      locCtrl.clear();
                                                    } else {
                                                      locCtrl.text = 'OVERSIZE';
                                                    }
                                                    if (hasSubmitError) hasSubmitError = false;
                                                  });
                                                } : null,
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  backgroundColor: locCtrl.text == 'OVERSIZE' ? const Color(0xFF6366f1).withAlpha(50) : Colors.transparent,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                ),
                                                child: const Text('OVERSIZE', style: TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            if (hasSubmitError) setDialogState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(isEditMode ? 'Cancel' : 'Close', style: TextStyle(color: textS)),
                                    ),
                                    if (isEditMode)
                                      ElevatedButton(
                                        onPressed: () {
                                          if (reasonCtrl.text.trim().isEmpty || piecesCtrl.text.trim().isEmpty) {
                                            setDialogState(() { hasSubmitError = true; });
                                          } else {
                                            Navigator.pop(ctx, true);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                        child: const Text('Confirm Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                );
                              }
                            ),
                          );

                          if (confirm == true && reasonCtrl.text.trim().isNotEmpty && piecesCtrl.text.trim().isNotEmpty) {
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
                               if (mounted && context.mounted) {
                                 setState(() {
                                    _localRejections[awbNum] = {
                                       'time': timeStr,
                                       'user': userFullName,
                                       'reason': reasonCtrl.text.trim(),
                                       'qty': int.tryParse(piecesCtrl.text.trim()) ?? 0,
                                       'location': locCtrl.text.trim(),
                                    };
                                 });
                               }
                             } catch (e) {
                               if (mounted && context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving rejection locally.'), backgroundColor: Colors.redAccent));
                               }
                             } finally {
                               if (mounted) {
                                 setState(() => _isDelivering = false);
                               }
                             }
                          }
                          piecesCtrl.dispose();
                          locCtrl.dispose();
                        },
                        icon: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 20),
                        label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: ((foundPieces + rejectedQty) == expectedDeliver && expectedDeliver > 0 && !_isDelivering) ? () async {
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
                          
                          List<Map<String, dynamic>> selectedReferences = [];
                          _driverItemCheckState.forEach((key, isChecked) {
                            if (isChecked && key.startsWith('${awbNum}_')) {
                              if (_driverItemPayloadData.containsKey(key)) {
                                      selectedReferences.add(_driverItemPayloadData[key]!);
                              }
                            }
                          });
                          
                          try {
                             List<dynamic> currentDeliveries = [];
                             if (awb['data-deliver'] != null) {
                                if (awb['data-deliver'] is List) {
                                   currentDeliveries = List.from(awb['data-deliver']);
                                } else if (awb['data-deliver'] is Map) {
                                   currentDeliveries = [awb['data-deliver']];
                                }
                             }

                             Map<String, dynamic> newDeliveryObj = {
                                'time': timeStr,
                                'user': userFullName,
                                'delivery': expectedDeliver,
                                'found': foundPieces,
                                'total': int.tryParse(totalPieces) ?? 0,
                                'references': selectedReferences,
                                'company': _selectedDriver?['truck-company'],
                                'driver': _selectedDriver?['driver'],
                                'pickup_id': _selectedDriver?['id-pickup'],
                                'type': _selectedDriver?['type'],
                                'status': _selectedDriver?['status'],
                                'remark': _selectedDriver?['remarks'],
                                'door': _selectedDriver?['door'],
                                if (_localRejections.containsKey(awbNum))
                                   'rejection': _localRejections[awbNum],
                             };

                             currentDeliveries.add(newDeliveryObj);
                             
                             await Supabase.instance.client.from('AWB').update({
                                'data-deliver': currentDeliveries
                             }).eq('AWB-number', awbNum);
                             
                             if (mounted && context.mounted) {
                               setState(() {
                                  awb['data-deliver'] = currentDeliveries;
                                  awb.remove('data-reject');
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


