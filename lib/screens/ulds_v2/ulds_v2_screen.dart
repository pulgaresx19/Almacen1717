import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;
import '../add_uld_v2/add_uld_v2_screen.dart';
import 'ulds_v2_logic.dart';
import 'ulds_v2_drawer.dart';
import 'ulds_v2_pdf_exporter.dart';

class UldsV2Screen extends StatefulWidget {
  final bool isActive;
  const UldsV2Screen({super.key, required this.isActive});

  @override
  State<UldsV2Screen> createState() => UldsV2ScreenState();
}

class UldsV2ScreenState extends State<UldsV2Screen> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddUldV2ScreenState> _addUldKey = GlobalKey<AddUldV2ScreenState>();
  
  late UldsV2Logic logic;
  List<String> _selectedUldIds = [];
  final Set<String> _expandedFlights = {};

  @override
  void initState() {
    super.initState();
    logic = UldsV2Logic();
    logic.fetchUlds();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logic,
      builder: (context, _) {
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
                                  if (_addUldKey.currentState != null) {
                                    final canPop = await _addUldKey.currentState!.handleBackRequest();
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
                              Text(appLanguage.value == 'es' ? 'Añadir New ULD' : 'Add New ULD', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                            ],
                          )
                        else
                          Text('Unit Load Devices (ULD)', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        if (_showAddForm)
                          Text(appLanguage.value == 'es' ? 'Registra un ULD en la nueva base de datos.' : 'Register a ULD in the new database.', style: TextStyle(color: textS, fontSize: 13))
                        else
                          Text(appLanguage.value == 'es' ? 'Lista moderna de la tabla ulds.' : 'Modern list of the ulds table.', style: TextStyle(color: textS, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
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
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))],
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
                    if (!_showAddForm && currentUserData.value?['position'] != 'Supervisor')
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _showAddForm = true);
                          },
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
                ),
                const SizedBox(height: 30),
                if (_showAddForm)
                  Expanded(
                    child: AddUldV2Screen(
                      key: _addUldKey,
                      isInline: true,
                      onPop: (bool isSaved) {
                        setState(() {
                          _showAddForm = false;
                        });
                        if (isSaved) {
                          logic.fetchUlds();
                        }
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
                      child: _buildUldsListState(dark, textP, textS),
                    ),
                  )
              ],
            );
          },
        );
      }
    );
  }

  Widget _buildUldsListState(bool dark, Color textP, Color textS) {
    if (logic.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logic.uldsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 64, color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
            const SizedBox(height: 16),
            Text(appLanguage.value == 'es' ? 'No hay ULDs' : 'No ULDs', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(appLanguage.value == 'es' ? 'Aún no hay ULDs registrados.' : 'There are no registered ULDs yet.', style: TextStyle(color: textS)),
          ],
        )
      );
    }

    var listToDisplay = List<Map<String, dynamic>>.from(logic.uldsList);
    
    if (_searchController.text.isNotEmpty) {
      final terms = _searchController.text.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
      listToDisplay = listToDisplay.where((u) {
        final uldNum = (u['uld_number'] ?? '').toString().toLowerCase();
        final status = (u['status'] ?? '').toString().toLowerCase();
        final flightId = u['id_flight']?.toString();
        
        String refDetails = '';
        if (flightId != null && logic.flightsMap.containsKey(flightId)) {
           final f = logic.flightsMap[flightId]!;
           refDetails = '${f['carrier'] ?? ''} ${f['number'] ?? ''}'.toLowerCase();
        }

        final combinedStr = '$uldNum $status $refDetails';
        return terms.every((term) => combinedStr.contains(term));
      }).toList();
    }

    if (listToDisplay.isEmpty) {
      return const Center(child: Text('No ULDs found matching the search.', style: TextStyle(color: Colors.grey)));
    }

    listToDisplay.sort((a, b) {
      final fIdA = a['id_flight']?.toString();
      final fIdB = b['id_flight']?.toString();
      String fa = 'Standalone';
      if (fIdA != null && logic.flightsMap.containsKey(fIdA)) {
         final f = logic.flightsMap[fIdA]!;
         fa = '${f['date'] ?? ''} ${f['carrier'] ?? ''} ${f['number'] ?? ''}';
      }
      String fb = 'Standalone';
      if (fIdB != null && logic.flightsMap.containsKey(fIdB)) {
         final f = logic.flightsMap[fIdB]!;
         fb = '${f['date'] ?? ''} ${f['carrier'] ?? ''} ${f['number'] ?? ''}';
      }
      int cmp = fa.compareTo(fb);
      if (cmp != 0) return cmp;
      
      bool breakA = a['is_break'] == true;
      bool breakB = b['is_break'] == true;
      if (breakA && !breakB) return -1;
      if (!breakA && breakB) return 1;

      final nA = (a['uld_number'] ?? '').toString().toUpperCase();
      final nB = (b['uld_number'] ?? '').toString().toUpperCase();
      
      bool isBulkA = nA == 'BULK' || nA.startsWith('BULK');
      bool isBulkB = nB == 'BULK' || nB.startsWith('BULK');
      if (isBulkA && !isBulkB) return -1;
      if (!isBulkA && isBulkB) return 1;

      return nA.compareTo(nB);
    });

    Map<String, int> flightCounts = {};
    for (var u in listToDisplay) {
      final flightId = u['id_flight']?.toString();
      String flightDisplay = 'Standalone';
      if (flightId != null && logic.flightsMap.containsKey(flightId)) {
         final f = logic.flightsMap[flightId]!;
         flightDisplay = '${f['carrier'] ?? ''} ${f['number'] ?? ''}';
         final stringDate = f['date']?.toString();
         if (stringDate != null && stringDate.isNotEmpty && stringDate != '-') {
           try {
             final dt = DateTime.parse(stringDate).toLocal();
             final padDate = "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
             flightDisplay += ' ($padDate)';
           } catch (_) {}
         }
      }
      flightCounts[flightDisplay] = (flightCounts[flightDisplay] ?? 0) + 1;
    }

    List<dynamic> groupedList = [];
    String lastFlightHeader = '';
    for (var u in listToDisplay) {
      final flightId = u['id_flight']?.toString();
      String flightDisplay = 'Standalone';
      if (flightId != null && logic.flightsMap.containsKey(flightId)) {
         final f = logic.flightsMap[flightId]!;
         flightDisplay = '${f['carrier'] ?? ''} ${f['number'] ?? ''}';
         final stringDate = f['date']?.toString();
         if (stringDate != null && stringDate.isNotEmpty && stringDate != '-') {
           try {
             final dt = DateTime.parse(stringDate).toLocal();
             final padDate = "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
             flightDisplay += ' ($padDate)';
           } catch (_) {}
         }
      }

      if (flightDisplay != lastFlightHeader) {
         groupedList.add(flightDisplay);
         lastFlightHeader = flightDisplay;
      }
      
      if (_expandedFlights.contains(flightDisplay)) {
        groupedList.add(u);
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth > 1000 ? constraints.maxWidth : 1000),
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
                          const DataColumn(label: Text('ULD Number')),
                          const DataColumn(label: Text('Ref. Flight')),
                          const DataColumn(label: Text('Pcs')),
                          const DataColumn(label: Text('Weight')),
                          const DataColumn(label: Text('Priority')),
                          const DataColumn(label: Text('Break')),
                          const DataColumn(label: SizedBox(width: 150, child: Text('Remarks'))),
                          const DataColumn(numeric: true, label: SizedBox(width: 100, child: Text('Status', textAlign: TextAlign.center))),
                          DataColumn(
                            label: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: _selectedUldIds.length == listToDisplay.length && listToDisplay.isNotEmpty,
                              onChanged: (val) {
                                 setState(() {
                                    if (val == true) {
                                       _selectedUldIds = listToDisplay.map((e) => e['id_uld'].toString()).toList();
                                    } else {
                                       _selectedUldIds.clear();
                                    }
                                 });
                              },
                              activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)),
                            )
                          ),
                        ],
                        rows: List.generate(groupedList.length, (index) {
                          final item = groupedList[index];

                          if (item is String) {
                            return DataRow(
                              color: WidgetStateProperty.all(dark ? const Color(0xFF334155).withAlpha(150) : const Color(0xFFE5E7EB)),
                              onSelectChanged: (_) {
                                setState(() {
                                  if (_expandedFlights.contains(item)) {
                                    _expandedFlights.remove(item);
                                  } else {
                                    _expandedFlights.add(item);
                                  }
                                });
                              },
                              cells: List.generate(10, (cellIdx) {
                                if (cellIdx == 0) {
                                  final count = flightCounts[item] ?? 0;
                                  return DataCell(
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6366f1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (cellIdx == 1) {
                                  return DataCell(
                                    Row(
                                      children: [
                                        Icon(Icons.flight_land_rounded, size: 16, color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)),
                                        const SizedBox(width: 8),
                                        Text(item, style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ]
                                    )
                                  );
                                }
                                return DataCell(const SizedBox.shrink());
                              }),
                            );
                          }

                          final u = item as Map<String, dynamic>;
                          
                          int displayIndex = 1;
                          for (int i = index - 1; i >= 0; i--) {
                            if (groupedList[i] is String) {
                              displayIndex = index - i;
                              break;
                            }
                          }
                          
                          final flightId = u['id_flight']?.toString();
                          String flightDisplay = 'Standalone';
                          
                          if (flightId != null && logic.flightsMap.containsKey(flightId)) {
                             final f = logic.flightsMap[flightId]!;
                             flightDisplay = '${f['carrier'] ?? ''} ${f['number'] ?? ''}';
                             final stringDate = f['date']?.toString();
                             if (stringDate != null && stringDate.isNotEmpty && stringDate != '-') {
                               try {
                                 final dt = DateTime.parse(stringDate).toLocal();
                                 final padDate = "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
                                 flightDisplay += ' ($padDate)';
                               } catch (_) {}
                             }
                          }

                          return DataRow(
                            onSelectChanged: (_) => _showUldDrawer(context, u, dark, flightDisplay),
                            cells: [
                              DataCell(Text('$displayIndex', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
                              DataCell(Text(u['uld_number']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                              DataCell(Text(flightDisplay, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(u['pieces_total']?.toString() ?? '0')),
                              DataCell(Text('${u['weight_total']?.toString() ?? '0'} kg')),
                              DataCell(u['is_priority'] == true ? const Icon(Icons.star_rounded, color: Colors.orange, size: 20) : const Icon(Icons.star_border_rounded, color: Colors.grey, size: 20)),
                              DataCell(Text(u['is_break'] == true ? 'BREAK' : 'NO BREAK', style: TextStyle(color: u['is_break'] == true ? const Color(0xFF10b981) : const Color(0xFFef4444), fontWeight: FontWeight.bold))),
                              DataCell(SizedBox(width: 150, child: Text(u['remarks']?.toString() ?? '-', overflow: TextOverflow.ellipsis, maxLines: 2, style: const TextStyle(fontSize: 12)))),
                              DataCell(_buildV2StatusBadge(u['status']?.toString() ?? 'Waiting')),
                              DataCell(
                                Checkbox(
                                  visualDensity: VisualDensity.compact,
                                  value: _selectedUldIds.contains(u['id_uld'].toString()),
                                  onChanged: (val) {
                                     setState(() {
                                        if (val == true) {
                                          _selectedUldIds.add(u['id_uld'].toString());
                                        } else {
                                          _selectedUldIds.remove(u['id_uld'].toString());
                                        }
                                     });
                                  },
                                  activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)),
                                )
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ),
        if (_selectedUldIds.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1e293b) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedUldIds.length} Selected',
                        style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                         final selectedData = logic.uldsList.where((u) => _selectedUldIds.contains(u['id_uld'].toString())).toList();
                         UldsV2PdfExporter.printUlds(selectedData, logic.flightsMap);
                      },
                      icon: const Icon(Icons.print_rounded, color: Color(0xFF818cf8), size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(20)),
                      tooltip: 'Print Selected',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                         final selectedData = logic.uldsList.where((u) => _selectedUldIds.contains(u['id_uld'].toString())).toList();
                         UldsV2PdfExporter.downloadPdf(selectedData, logic.flightsMap);
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF818cf8), size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(20)),
                      tooltip: 'Download PDF',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                         final confirm = await showDialog<bool>(
                           context: context,
                           builder: (c) => AlertDialog(
                             backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                             title: Text(appLanguage.value == 'es' ? 'Eliminar ULDs' : 'Delete ULDs', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                             content: Text(appLanguage.value == 'es' 
                               ? '¿Estás seguro de eliminar los ${_selectedUldIds.length} ULDs seleccionados? Esta acción es permanente y borrará también sus AWBs hijos.' 
                               : 'Are you sure you want to delete the ${_selectedUldIds.length} selected ULDs? This action is permanent and will delete their child AWBs.', 
                               style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563))
                             ),
                             actions: [
                               TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8)))),
                               ElevatedButton(
                                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444)),
                                 onPressed: () => Navigator.pop(c, true),
                                 child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                               )
                             ],
                           )
                         );
                         if (confirm == true) {
                            try {
                               await Supabase.instance.client.from('ulds').delete().inFilter('id_uld', _selectedUldIds);
                               setState(() { _selectedUldIds.clear(); });
                               logic.fetchUlds();
                            } catch (e) {
                               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                         }
                      },
                      icon: const Icon(Icons.delete_rounded, color: Color(0xFFef4444), size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFef4444).withAlpha(20)),
                      tooltip: 'Delete Selected',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

   Widget _buildV2StatusBadge(String status) {
     Color bg = const Color(0xFF334155);
     Color fg = const Color(0xFFcbd5e1);
     
     switch (status.toLowerCase()) {
       case 'waiting':
         bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
         break;
       case 'received':
         bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
         break;
       case 'checked':
         bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
         break;
       case 'ready':
         bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
         break;
       case 'delivered':
       case 'entregado':
         bg = const Color(0xFF047857).withAlpha(51); fg = const Color(0xFF34d399); 
         break;
       case 'pending':
         bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
         break;
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

   void _showUldDrawer(BuildContext context, Map<String, dynamic> uld, bool dark, String flightDisplay) async {
     await showGeneralDialog(
       context: context,
       barrierDismissible: true,
       barrierLabel: 'Dismiss',
       barrierColor: Colors.black54,
       transitionDuration: const Duration(milliseconds: 300),
       pageBuilder: (ctx, anim1, anim2) {
         return Align(
           alignment: Alignment.centerRight,
           child: Material(
             color: dark ? const Color(0xFF0f172a) : Colors.white,
             elevation: 16,
             child: SizedBox(
               width: 520,
               height: double.infinity,
               child: UldsV2Drawer(uld: uld, dark: dark, flightDisplay: flightDisplay),
             ),
           ),
         );
       },
       transitionBuilder: (ctx, anim1, anim2, child) {
         return SlideTransition(
           position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
           child: child,
         );
       },
     );
     
     // The ULD map is updated by reference inside the drawer.
     // Call setState to instantly reflect changes on the table.
     if (mounted) setState(() {});
  }
}
