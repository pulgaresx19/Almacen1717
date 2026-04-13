import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;
import '../add_flight_v2/add_flight_v2_screen.dart'; // Ensure correct import route to V2
import 'flights_v2_logic.dart';
import 'flights_v2_drawer.dart';
import 'flights_v2_pdf_exporter.dart';

class FlightsV2Screen extends StatefulWidget {
  final bool isActive;
  const FlightsV2Screen({super.key, required this.isActive});

  @override
  State<FlightsV2Screen> createState() => FlightsV2ScreenState();
}

class FlightsV2ScreenState extends State<FlightsV2Screen> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddFlightV2ScreenState> _addFlightKey = GlobalKey<AddFlightV2ScreenState>();
  final Set<String> _selectedFlightIds = {};
  
  late FlightsV2Logic logic;

  @override
  void initState() {
    super.initState();
    logic = FlightsV2Logic();
    logic.fetchFlights();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant FlightsV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_showAddForm && _addFlightKey.currentState != null) {
      }
    }
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
                                  if (_addFlightKey.currentState != null) {
                                    final canPop = await _addFlightKey.currentState!.handleBackRequest();
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
                              Text(appLanguage.value == 'es' ? 'Añadir Nuevo Vuelo' : 'Add New Flight', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                            ],
                          )
                        else
                          Text(appLanguage.value == 'es' ? 'Vuelos' : 'Flight Documents', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        if (_showAddForm)
                          Text(appLanguage.value == 'es' ? 'Crea y vincula ULDs y AWBs a un Vuelo.' : 'Create and link ULDs and AWBs to a Flight.', style: TextStyle(color: textS, fontSize: 13))
                        else
                          Text(appLanguage.value == 'es' ? 'Administración y estado de los vuelos registrados.' : 'Manage and track all incoming flights.', style: TextStyle(color: textS, fontSize: 13)),
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
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))],
                          style: TextStyle(color: textP, fontSize: 13),
                          onChanged: (v) => setState(() {}), // We can attach logic filter here later
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
                    
                    // Add Flight Button
                    if (!_showAddForm && currentUserData.value?['position'] != 'Supervisor')
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _showAddForm = true);
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(appLanguage.value == 'es' ? 'Añadir Vuelo V2' : 'Add Flight V2', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                
                // Internal layout
                if (_showAddForm)
                  Expanded(
                    child: AddFlightV2Screen(
                      key: _addFlightKey,
                      isInline: true,
                      onPop: (bool isSaved) {
                        setState(() {
                          _showAddForm = false;
                        });
                        if (isSaved) {
                          logic.fetchFlights();
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
                      child: _buildEmptyFlightListState(dark, textP, textS),
                    ),
                  )
              ],
            );
          },
        );
      }
    );
  }

  Widget _buildEmptyFlightListState(bool dark, Color textP, Color textS) {
    if (logic.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logic.flightsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff_rounded, size: 64, color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
            const SizedBox(height: 16),
            Text(appLanguage.value == 'es' ? 'Listado en construcción...' : 'List under construction...', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(appLanguage.value == 'es' ? 'Este diseño listará los vuelos pronto.' : 'This layout will list flights soon.', style: TextStyle(color: textS)),
          ],
        )
      );
    }

    var flightsToDisplay = List<Map<String, dynamic>>.from(logic.flightsList);
    
    if (_searchController.text.isNotEmpty) {
      final terms = _searchController.text.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
      flightsToDisplay = flightsToDisplay.where((f) {
        final carrier = (f['carrier'] ?? '').toString().toLowerCase();
        final number = (f['number'] ?? '').toString().toLowerCase();
        final status = (f['status'] ?? '').toString().toLowerCase();
        
        String dateStr = f['date']?.toString() ?? '';
        String formattedDate = '';
        if (dateStr.isNotEmpty) {
           try {
             final dt = DateTime.parse(dateStr).toLocal();
             formattedDate = DateFormat('MM/dd/yyyy hh:mm a').format(dt).toLowerCase();
             final shortDate = DateFormat('MM/dd/yyyy').format(dt).toLowerCase();
             formattedDate = '$formattedDate $shortDate';
           } catch (_) {}
        }
        
        final combinedStr = '$carrier $number $carrier$number $formattedDate $status';
        return terms.every((term) => combinedStr.contains(term));
      }).toList();
    }

    if (flightsToDisplay.isEmpty && logic.flightsList.isNotEmpty) {
      return const Center(child: Text('No flights found matching the search.', style: TextStyle(color: Colors.grey)));
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
              DataColumn(label: Text(appLanguage.value == 'es' ? 'No.' : 'No.')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Vuelo' : 'Flight')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Fecha Arrival' : 'Arrive Date')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Break / No-B' : 'Break / No-B')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Total ULD' : 'Total ULD')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Inicio Desarme' : 'Start Break')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Fin Desarme' : 'End Break')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Primer Cam.' : 'First Truck')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Último Cam.' : 'Last Truck')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Remarks' : 'Remarks')),
              DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
              DataColumn(
                label: Checkbox(
                  visualDensity: VisualDensity.compact,
                  value: _selectedFlightIds.length == flightsToDisplay.length && flightsToDisplay.isNotEmpty,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedFlightIds.addAll(flightsToDisplay.map((e) => e['id_flight'].toString()));
                      } else {
                        _selectedFlightIds.clear();
                      }
                    });
                  },
                ),
              ),
            ],
            rows: List.generate(flightsToDisplay.length, (index) {
              final flight = flightsToDisplay[index];
              final carrier = flight['carrier'] ?? '';
              final number = flight['number'] ?? '';
              final cantBreak = flight['cant_break'] ?? 0;
              final cantNoBreak = flight['cant_nobreak'] ?? 0;
              final status = flight['status']?.toString() ?? 'Waiting';
              final remarks = flight['remarks']?.toString() ?? '-';
              Widget buildFormatTimestamp(String? val) {
                if (val == null || val.isEmpty || val == '-') return const Text('-');
                try {
                  final dt = DateTime.parse(val).toLocal();
                  final timeStr = DateFormat('hh:mm a').format(dt);
                  final dateStr = DateFormat('MM/dd').format(dt);
                  return RichText(
                    text: TextSpan(
                      text: timeStr,
                      style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      children: [
                        TextSpan(
                          text: ' ($dateStr)',
                          style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 11, fontWeight: FontWeight.normal),
                        )
                      ]
                    ),
                  );
                } catch (_) {
                  return Text(val, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827)));
                }
              }

              return DataRow(
                onSelectChanged: (_) {
                   _showFlightDrawer(context, flight, dark);
                },
                cells: [
                  DataCell(Text('${index + 1}', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
                  DataCell(Row(
                    children: [
                      Icon(Icons.flight_land_rounded, size: 16, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      Text('$carrier $number', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold)),
                    ],
                  )),
                  DataCell(buildFormatTimestamp(flight['date']?.toString())),
                  DataCell(Text('$cantBreak / $cantNoBreak')),
                  DataCell(Text('${cantBreak + cantNoBreak}', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                  DataCell(buildFormatTimestamp(flight['start_break']?.toString())),
                  DataCell(buildFormatTimestamp(flight['end_break']?.toString())),
                  DataCell(buildFormatTimestamp(flight['first_truck']?.toString())),
                  DataCell(buildFormatTimestamp(flight['last_truck']?.toString())),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        remarks.isNotEmpty ? remarks : '-',
                        style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ),
                  DataCell(_buildStatusBadge(status)),
                  DataCell(
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      value: _selectedFlightIds.contains(flight['id_flight']?.toString()),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedFlightIds.add(flight['id_flight'].toString());
                          } else {
                            _selectedFlightIds.remove(flight['id_flight'].toString());
                          }
                        });
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    ),
  );
  },
),
),
if (_selectedFlightIds.isNotEmpty)
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
                        '${_selectedFlightIds.length} Selected',
                        style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                         final selectedData = logic.flightsList.where((f) => _selectedFlightIds.contains(f['id_flight'].toString())).toList();
                         FlightPdfExporter.printFlights(selectedData);
                      },
                      icon: const Icon(Icons.print_rounded, color: Color(0xFF818cf8), size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(20)),
                      tooltip: 'Print Selected',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                         final selectedData = logic.flightsList.where((f) => _selectedFlightIds.contains(f['id_flight'].toString())).toList();
                         FlightPdfExporter.downloadPdf(selectedData);
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
                             title: Text(appLanguage.value == 'es' ? 'Eliminar Vuelos' : 'Delete Flights', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                             content: Text(appLanguage.value == 'es' 
                               ? '¿Estás seguro de eliminar los ${_selectedFlightIds.length} vuelos seleccionados? Esta acción es permanente.' 
                               : 'Are you sure you want to delete ${_selectedFlightIds.length} selected flights? This action is permanent.',
                               style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563))),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                             actions: [
                               TextButton(
                                 onPressed: () => Navigator.pop(c, false),
                                 child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                               ),
                               ElevatedButton(
                                 onPressed: () => Navigator.pop(c, true),
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                 child: Text(appLanguage.value == 'es' ? 'Eliminar' : 'Delete'),
                               ),
                             ],
                           ),
                         );

                         if (confirm == true) {
                           final toDelete = _selectedFlightIds.toList();
                           setState(() {
                             _selectedFlightIds.clear();
                           });
                           await logic.deleteFlights(toDelete);
                         }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withAlpha(20)),
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

  void _showFlightDrawer(BuildContext context, Map<String, dynamic> flight, bool dark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 520,
              height: double.infinity,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0f172a) : Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: FlightsV2Drawer(
                flight: flight, 
                dark: dark,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
          child: child,
        );
      },
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    switch (status.toLowerCase()) {
      case 'waiting':
        bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1); break;
      case 'received':
        bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd); break;
      case 'pending':
        bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047); break;
      case 'ready':
      case 'checked':
      case 'saved':
        bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac); break;
      case 'delayed':
        bg = const Color(0xFFc2410c).withAlpha(51); fg = const Color(0xFFfdba74); break;
      default: break;
    }

    return Container(
      width: 90, height: 28, alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
