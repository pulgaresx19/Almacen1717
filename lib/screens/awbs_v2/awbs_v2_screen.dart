import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;
import '../add_awb_v2/add_awb_v2_screen.dart';
import '../add_uld_v2/add_uld_v2_screen.dart';
// removed intl
// unused import removed
import 'awbs_v2_pdf_exporter.dart';
import 'awbs_v2_drawer.dart';
import 'awbs_v2_uld_drawer.dart';
import '../../services/realtime_service.dart';
import '../flights_v2/flights_v2_status_logic.dart';

class AwbsV2Screen extends StatefulWidget {
  final bool isActive;
  const AwbsV2Screen({super.key, this.isActive = true});

  @override
  State<AwbsV2Screen> createState() => _AwbsV2ScreenState();
}

class _AwbsV2ScreenState extends State<AwbsV2Screen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final _searchController = TextEditingController();
  final GlobalKey<AddAwbV2ScreenState> _addAwbKey = GlobalKey<AddAwbV2ScreenState>();
  final GlobalKey<AddUldV2ScreenState> _addUldKey = GlobalKey<AddUldV2ScreenState>();
  final Set<String> _selectedAwbIds = {};
  bool _showAddForm = false;
  bool _showAddUldForm = false;
  bool _showUldTab = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(AwbsV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      if (_showAddForm && _addAwbKey.currentState != null) {
        if (!_addAwbKey.currentState!.hasDataSync) {
          setState(() {
            _showAddForm = false;
          });
        }
      }
    }
  }

  String _computeAwbStatus(Map<String, dynamic> u) {
    int deliveredPieces = 0;
    if (u['data-deliver'] != null) {
      if (u['data-deliver'] is List) {
        for (var item in u['data-deliver']) {
          if (item is Map && item.containsKey('found')) {
            deliveredPieces += int.tryParse(item['found']?.toString() ?? '0') ?? 0;
          }
        }
      } else if (u['data-deliver'] is Map) {
        deliveredPieces = int.tryParse(u['data-deliver']['found']?.toString() ?? '0') ?? 0;
      }
    }
    
    final int totalValInt = int.tryParse(u['total']?.toString() ?? '0') ?? 0;
    if (deliveredPieces == totalValInt && totalValInt > 0) {
       return 'Ready';
    } else if (deliveredPieces > 0) {
       return 'In Process';
    }
    return 'Waiting';
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
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
        final Color bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showAddForm)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (_addAwbKey.currentState != null) {
                                final canPop = await _addAwbKey.currentState!.handleBackRequest();
                                if (canPop) {
                                  setState(() => _showAddForm = false);
                                }
                              } else {
                                setState(() => _showAddForm = false);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            tooltip: appLanguage.value == 'es' ? 'Volver' : 'Back',
                          ),
                          const SizedBox(width: 8),
                          Text(appLanguage.value == 'es' ? 'Añadir Nuevo Aerobill' : 'Add New Air Waybill', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else if (_showAddUldForm)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (_addUldKey.currentState != null) {
                                final canPop = await _addUldKey.currentState!.handleBackRequest();
                                if (canPop) {
                                  setState(() => _showAddUldForm = false);
                                }
                              } else {
                                setState(() => _showAddUldForm = false);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            tooltip: appLanguage.value == 'es' ? 'Volver' : 'Back',
                          ),
                          const SizedBox(width: 8),
                          Text(appLanguage.value == 'es' ? 'Añadir Nuevo ULD' : 'Add New ULD', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    if (_showAddForm) ...[
                      const SizedBox(height: 4),
                      Text(appLanguage.value == 'es' ? 'Crea y registra detalles de los aerobills.' : 'Create and register Air Waybill details.', style: TextStyle(color: textS, fontSize: 13)),
                    ] else if (_showAddUldForm) ...[
                      const SizedBox(height: 4),
                      Text(appLanguage.value == 'es' ? 'Registra un ULD en la nueva base de datos.' : 'Register a ULD in the new database.', style: TextStyle(color: textS, fontSize: 13)),
                    ] else ...[
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_showUldTab) {
                                setState(() {
                                  _showUldTab = false;
                                  _searchController.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_showUldTab ? const Color(0xFF6366f1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(appLanguage.value == 'es' ? 'Números AWB' : 'AWB Numbers', style: TextStyle(color: !_showUldTab ? Colors.white : textS, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (!_showUldTab) {
                                setState(() {
                                  _showUldTab = true;
                                  _searchController.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showUldTab ? const Color(0xFF6366f1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(appLanguage.value == 'es' ? 'ULDs No Break' : 'No Break ULDs', style: TextStyle(color: _showUldTab ? Colors.white : textS, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                
                if (!_showAddForm && !_showAddUldForm) ...[
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
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          var text = newValue.text;
                          
                          if (text.contains(RegExp(r'[a-zA-Z]'))) {
                             final updatedText = text.toUpperCase();
                             return TextEditingValue(
                               text: updatedText,
                               selection: newValue.selection,
                             );
                          }
                          
                          text = text.replaceAll(RegExp(r'[^0-9]'), '');
                          if (text.length > 11) text = text.substring(0, 11);

                          var formatted = '';
                          for (int i = 0; i < text.length; i++) {
                            if (i == 3) formatted += '-';
                            if (i == 7) formatted += ' ';
                            formatted += text[i];
                          }

                          return TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        })
                      ],
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
                  
                  // Add Buttons
                  if (currentUserData.value?['position'] != 'Supervisor') ...[
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showAddForm = true),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF6366f1).withAlpha(100),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showAddUldForm = true),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(appLanguage.value == 'es' ? 'Añadir ULD' : 'Add ULD', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF6366f1).withAlpha(100),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 30),
            
            if (_showAddForm)
              Expanded(
                child: AddAwbV2Screen(
                  key: _addAwbKey,
                  onPop: (didAdd) {
                    setState(() {
                      _showAddForm = false;
                    });
                  },
                ),
              )
            else if (_showAddUldForm)
              Expanded(
                child: AddUldV2Screen(
                  key: _addUldKey,
                  isInline: true,
                  onPop: (didAdd) {
                    setState(() {
                      _showAddUldForm = false;
                    });
                  },
                ),
              )
            else
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCard),
                        ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: _showUldTab ? realtimeService.ulds : realtimeService.awbs,
                builder: (context, dataList, child) {
                  
                  if (dataList.isEmpty) {
                    if (_showUldTab) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_rounded, size: 64, color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
                            const SizedBox(height: 16),
                            Text(appLanguage.value == 'es' ? 'No hay ULDs' : 'No Break ULDs', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(appLanguage.value == 'es' ? 'Aún no hay ULDs registrados.' : 'There are no registered ULDs yet.', style: TextStyle(color: textS)),
                          ],
                        )
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flight_land_rounded, size: 64, color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
                            const SizedBox(height: 16),
                            Text(appLanguage.value == 'es' ? 'No hay AWBs' : 'No AWBs', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(appLanguage.value == 'es' ? 'Aún no hay AWBs registrados.' : 'There are no registered AWBs yet.', style: TextStyle(color: textS)),
                          ],
                        )
                      );
                    }
                  }

                  if (_showUldTab) {
                    var ulds = dataList.where((u) => u['is_break'] != true).toList();
                    
                    if (_searchController.text.isNotEmpty) {
                      final terms = _searchController.text.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
                      ulds = ulds.where((u) {
                        final uldSearch = (u['uld_number']?.toString() ?? u['ULD-number']?.toString() ?? '').toLowerCase();
                        final statusSearch = FlightsV2StatusLogic.getUldStatus(u).toLowerCase();
                        final combinedString = '$uldSearch $statusSearch';
                        return terms.every((term) => combinedString.contains(term));
                      }).toList();
                    }

                    if (ulds.isEmpty) {
                      return Center(child: Text(appLanguage.value == 'es' ? 'No se encontraron ULDs.' : 'No ULDs found matching the search.', style: const TextStyle(color: Colors.grey)));
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          thickness: 8,
                          radius: const Radius.circular(8),
                          interactive: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 28,
                                  showCheckboxColumn: false,
                                  headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                                  dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                                  dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                                  headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),
                                  columns: const [
                                    DataColumn(label: Text('#')),
                                    DataColumn(label: Text('ULD Number')),
                                    DataColumn(label: Text('Ref. Flight')),
                                    DataColumn(label: Text('Time Received')),
                                    DataColumn(label: Text('Total Pieces')),
                                    DataColumn(label: Text('Total Weight')),
                                    DataColumn(label: Text('Status')),
                                  ],
                                  rows: List.generate(ulds.length, (index) {
                                    final u = ulds[index];
                                    final uldNum = u['uld_number']?.toString() ?? u['ULD-number']?.toString() ?? '-';
                                    int totalPieces = int.tryParse(u['pieces_total']?.toString() ?? '0') ?? 0;
                                    double totalWeight = double.tryParse(u['weight_total']?.toString() ?? '0') ?? 0.0;
                                    String status = FlightsV2StatusLogic.getUldStatus(u);

                                    final flightId = u['id_flight']?.toString();
                                    String flightDisplay = '-';
                                    if (flightId != null) {
                                      try {
                                        final fList = realtimeService.flights.value;
                                        final flight = fList.firstWhere((f) => f['id_flight'].toString() == flightId, orElse: () => <String, dynamic>{});
                                        if (flight.isNotEmpty) {
                                          flightDisplay = '${flight['carrier'] ?? ''} ${flight['number'] ?? ''}'.trim();
                                          final fDate = flight['date']?.toString();
                                          if (fDate != null && fDate.isNotEmpty && fDate != '-') {
                                            try {
                                              final dt = DateTime.parse(fDate).toLocal();
                                              final padDate = "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
                                              if (flightDisplay.isNotEmpty) {
                                                flightDisplay += ' ($padDate)';
                                              } else {
                                                flightDisplay = padDate;
                                              }
                                            } catch (_) {}
                                          }
                                        }
                                      } catch (_) {}
                                    }

                                    String timeReceivedDisplay = '-';
                                    final timeRecvStr = u['time_received']?.toString() ?? u['time-received']?.toString();
                                    if (timeRecvStr != null && timeRecvStr.isNotEmpty) {
                                      try {
                                        final dt = DateTime.parse(timeRecvStr).toLocal();
                                        final padDate = "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
                                        int hour = dt.hour;
                                        final isPm = hour >= 12;
                                        if (hour == 0) {
                                          hour = 12;
                                        } else if (hour > 12) {
                                          hour -= 12;
                                        }
                                        final amPm = isPm ? 'PM' : 'AM';
                                        final padMin = dt.minute.toString().padLeft(2, '0');
                                        timeReceivedDisplay = '$padDate $hour:$padMin $amPm';
                                      } catch (_) {}
                                    }

                                    return DataRow(
                                      onSelectChanged: (_) {
                                        AwbsV2UldDrawer.show(context, u, dark, status, flightDisplay);
                                      },
                                      cells: [
                                        DataCell(Text('${index + 1}')),
                                        DataCell(Text(uldNum, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                                        DataCell(Text(flightDisplay, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        DataCell(Text(timeReceivedDisplay)),
                                        DataCell(Text(totalPieces.toString())),
                                        DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\.$|\.0$'), '')} kg')),
                                        DataCell(_buildStatusBadge(status)),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  var awbs = dataList;
                  
                  if (_searchController.text.isNotEmpty) {
                    final terms = _searchController.text.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
                    awbs = awbs.where((u) {
                      final awbSearch = u['awb_number']?.toString().toLowerCase() ?? '';
                      final statusSearch = _computeAwbStatus(u).toLowerCase();
                      
                      final combinedString = '$awbSearch $statusSearch';
                      
                      return terms.every((term) => combinedString.contains(term));
                    }).toList();
                  }

                  if (awbs.isEmpty) {
                    return Center(child: Text(appLanguage.value == 'es' ? 'No se encontraron AWBs con esa búsqueda.' : 'No AWBs found matching the search.', style: const TextStyle(color: Colors.grey)));
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            thickness: 8,
                            radius: const Radius.circular(8),
                            interactive: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 28,
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                        dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                        headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),
                        columns: [
                          const DataColumn(label: Text('#')),
                          const DataColumn(label: Text('AWB Number')),
                          const DataColumn(label: Text('Expected')),
                          const DataColumn(label: Text('Received')),
                          const DataColumn(label: Text('In Process')),
                          const DataColumn(label: Text('Remaining')),
                          const DataColumn(label: Text('Delivered')),
                          const DataColumn(label: Text('Total')),
                          const DataColumn(label: Text('Weight')),
                          const DataColumn(label: Text('Status')),
                          DataColumn(
                            label: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: _selectedAwbIds.length == awbs.length && awbs.isNotEmpty,
                              onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedAwbIds.addAll(awbs.map((e) => e['id'].toString()));
                                    } else {
                                      _selectedAwbIds.clear();
                                    }
                                  });
                              },
                              activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)),
                            ),
                          ),
                        ],
                        rows: List.generate(awbs.length, (index) {
                          final u = awbs[index];
                          
                          int expectedPieces = int.tryParse(u['total_espected']?.toString() ?? '0') ?? 0;
                          int receivedPieces = int.tryParse(u['pieces_received']?.toString() ?? '0') ?? 0;
                          int deliveredPieces = int.tryParse(u['pieces_delivered']?.toString() ?? '0') ?? 0;
                          int inProcessPieces = int.tryParse(u['pieces_in_process']?.toString() ?? '0') ?? 0;
                          
                          int remainingPieces = u['pieces_remaining'] != null 
                              ? (int.tryParse(u['pieces_remaining'].toString()) ?? 0) 
                              : (receivedPieces - deliveredPieces - inProcessPieces);
                          if (remainingPieces < 0) remainingPieces = 0;
                          
                          int totalPieces = int.tryParse(u['total_pieces']?.toString() ?? '0') ?? 0;
                          double totalWeight = double.tryParse(u['total_weight']?.toString() ?? '0') ?? 0.0;

                          String status = u['status']?.toString() ?? '';
                          if (status.isEmpty) {
                            status = 'Waiting';
                            if (deliveredPieces >= expectedPieces && expectedPieces > 0) {
                               status = 'Delivered';
                            } else if (deliveredPieces > 0) {
                               status = 'In Process';
                            } else if (receivedPieces > 0) {
                               status = 'Received';
                            }
                          }
                          return DataRow(
                            onSelectChanged: (_) => AwbsV2Drawer.show(context, u, dark, 0, expectedPieces, status),
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(u['awb_number']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                              DataCell(Text(expectedPieces.toString())),
                              DataCell(Text(receivedPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFf59e0b)))), // Pieces Received (Amber)
                              DataCell(Text(inProcessPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF06b6d4)))), // In Process Pieces (Cyan)
                              DataCell(Text(remainingPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366f1)))), // Pieces Remaining (Purple)
                              DataCell(Text(deliveredPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10b981)))), // Delivered Pieces (Green)
                              DataCell(Text(totalPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3b82f6)))), // Total Pieces (Blue)
                              DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\\.$|\\.0$'), '')} kg', style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(_buildStatusBadge(status)),
                                DataCell(
                                  Checkbox(
                                    visualDensity: VisualDensity.compact,
                                    value: _selectedAwbIds.contains(u['id']?.toString()),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedAwbIds.add(u['id'].toString());
                                        } else {
                                          _selectedAwbIds.remove(u['id'].toString());
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ));
              },
            );
          },
        ),
                  ),
                ),
              ),
              if (_selectedAwbIds.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1e293b) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
                        border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366f1).withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_selectedAwbIds.length} Selected',
                              style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(height: 24, width: 1, color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () async {
                                  final res = await Supabase.instance.client.from('awbs').select().inFilter('id', _selectedAwbIds.toList());
                                final selected = List<Map<String, dynamic>>.from(res);
                                if (selected.isNotEmpty) {
                                  AwbsV2PdfExporter.printAwbs(selected);
                                }
                            }, 
                            icon: const Icon(Icons.print_rounded, color: Color(0xFF6366f1)), 
                            tooltip: 'Print Selected', 
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                                  final res = await Supabase.instance.client.from('awbs').select().inFilter('id', _selectedAwbIds.toList());
                                final selected = List<Map<String, dynamic>>.from(res);
                                if (selected.isNotEmpty) {
                                  AwbsV2PdfExporter.downloadPdf(selected);
                                }
                            }, 
                            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF6366f1)), 
                            tooltip: 'Download PDF', 
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete AWBs'),
                                    content: Text('Are you sure you want to delete ${_selectedAwbIds.length} AWB(s)?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete'),
                                      )
                                    ],
                                  )
                                );
                                if (confirm == true) {
                                  for (var id in _selectedAwbIds) {
                                    await Supabase.instance.client.from('awbs').delete().eq('id', id);
                                  }
                                  setState(() => _selectedAwbIds.clear());
                                }
                            }, 
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), 
                            tooltip: 'Delete Selected', 
                            style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withAlpha(15))
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            ],
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
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('process') || s.contains('progress')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('checked') || s.contains('received')) {
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
    } else if (s.contains('ready') || s.contains('saved') || s.contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('pending')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
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
        status, 
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}


