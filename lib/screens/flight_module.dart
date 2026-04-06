import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;
import 'add_flight_screen.dart';

class FlightModule extends StatefulWidget {
  final bool isActive;
  const FlightModule({super.key, this.isActive = true});

  @override
  State<FlightModule> createState() => _FlightModuleState();
}

class _FlightModuleState extends State<FlightModule> {

  @override
  void didUpdateWidget(covariant FlightModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_showAddForm && _addFlightKey.currentState != null) {
        if (!_addFlightKey.currentState!.hasDataSync) {
          setState(() => _showAddForm = false);
        }
      }
    }
  }
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddFlightScreenState> _addFlightKey = GlobalKey<AddFlightScreenState>();
  late Stream<List<Map<String, dynamic>>> _flightStream;

  @override
  void initState() {
    super.initState();
    _flightStream = Supabase.instance.client.from('Flight').stream(primaryKey: ['id']).order('date-arrived', ascending: false).order('time-arrived', ascending: true);
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
            
            // Add Flight Button
            if (!_showAddForm)
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showAddForm = true);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(appLanguage.value == 'es' ? 'Añadir Vuelo' : 'Add Flight', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
        
        // Flight Table
        if (_showAddForm)
          Expanded(
            child: AddFlightScreen(
              key: _addFlightKey,
              isInline: true,
              onPop: (bool isSaved) {
                setState(() {
                  _showAddForm = false;
                });
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
                child: _buildFlightList(dark),
              ),
            ),
          ),
      ],
    );
     }
    );
  }

  Widget _buildFlightList(bool dark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _flightStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        var flights = List<Map<String, dynamic>>.from(snapshot.data ?? []);
        
        flights.sort((a, b) {
           DateTime getEffectiveArriveTime(Map<String, dynamic> f) {
               if (f['status']?.toString().toLowerCase() == 'delayed' && f['time-delayed'] != null && f['time-delayed'].toString().isNotEmpty) {
                  try {
                    return DateTime.parse(f['time-delayed'].toString()).toLocal();
                  } catch (_) {}
               }
               final dateStr = f['date-arrived']?.toString() ?? '2000-01-01';
               final timeStr = f['time-arrived']?.toString() ?? '00:00:00';
               try {
                  final fDate = dateStr.contains('T') ? dateStr.split('T').first : dateStr;
                  return DateTime.parse('$fDate $timeStr');
               } catch (_) {
                  try { return DateTime.parse(dateStr); } catch (_) { return DateTime(2000); }
               }
           }

           final dtA = getEffectiveArriveTime(a);
           final dtB = getEffectiveArriveTime(b);
           
           if (dtA.year != dtB.year) return dtB.year.compareTo(dtA.year);
           if (dtA.month != dtB.month) return dtB.month.compareTo(dtA.month);
           if (dtA.day != dtB.day) return dtB.day.compareTo(dtA.day);
           return dtA.compareTo(dtB);
        });
        
        if (_searchController.text.isNotEmpty) {
          final term = _searchController.text.toLowerCase();
          flights = flights.where((f) {
            final str = '${f['carrier']} ${f['number']}'.toLowerCase();
            return str.contains(term);
          }).toList();
        }

        if (flights.isEmpty) return const Center(child: Text('No flights found.', style: TextStyle(color: Color(0xFF94a3b8))));

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Vuelo (Aerolínea/No.)' : 'Carrier / Number')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Datos Llegada' : 'Arrive Date')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'B / No B' : 'Break / No B.')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Total ULD' : 'Total ULD')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Inicio Desarme' : 'Start Break')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Fin Desarme' : 'End Break')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Primer Camión' : 'First Truck')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Último Camión' : 'Last Truck')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Observaciones' : 'Remarks')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
              ],
              rows: List.generate(flights.length, (index) {
                final f = flights[index];
                
                final bool isDelayed = f['status']?.toString().toLowerCase() == 'delayed';
                
                String dateStr = f['date-arrived']?.toString() ?? '';
                String timeStr = f['time-arrived']?.toString() ?? '-';

                if (isDelayed && f['time-delayed'] != null && f['time-delayed'].toString().isNotEmpty) {
                    try {
                      final ddt = DateTime.parse(f['time-delayed'].toString()).toLocal();
                      dateStr = DateFormat('yyyy-MM-dd').format(ddt);
                      timeStr = DateFormat('HH:mm:ss').format(ddt);
                    } catch (_) {}
                }

                String formattedDate = dateStr.isNotEmpty ? dateStr : '-';

                try {
                  if (dateStr.isNotEmpty) {
                    final dt = DateTime.parse(dateStr);
                    formattedDate = DateFormat('MM/dd').format(dt);
                  }
                } catch (_) {}

                return DataRow(
                  onSelectChanged: (_) => _showFlightDrawer(context, f, dark),
                  cells: [
                    // Index
                    DataCell(Text('${index + 1}', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
                    // Carrier / Number
                    DataCell(Row(
                      children: [
                        Icon(Icons.flight_land_rounded, size: 16, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Text(
                          '${f['carrier'] ?? ''} ${f['number'] ?? ''}',
                          style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold),
                        ),
                      ],
                    )),
                    // Arrival (Merged Time and Date)
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatTime(timeStr), style: TextStyle(color: isDelayed ? const Color(0xFFfb923c) : (dark ? Colors.white : const Color(0xFF111827)), fontWeight: FontWeight.bold)),
                        if (formattedDate != '-') ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text('($formattedDate)', style: TextStyle(color: isDelayed ? const Color(0xFFfdba74) : (dark ? const Color(0xFF64748b) : const Color(0xFF94a3b8)), fontSize: 11)),
                          )
                        ],
                      ],
                    )),
                    // Break / No Break
                    DataCell(Text('${f['cant-break'] ?? 0} / ${f['cant-noBreak'] ?? 0}', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)))),
                    // Total ULD
                    DataCell(Builder(builder: (context) {
                      final b = int.tryParse(f['cant-break']?.toString() ?? '0') ?? 0;
                      final nb = int.tryParse(f['cant-noBreak']?.toString() ?? '0') ?? 0;
                      final total = b + nb;
                      return Text('$total', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold));
                    })),
                    // Start Break
                    DataCell(_buildTimestampCell(f['start-break']?.toString(), dark)),
                    // End Break
                    DataCell(_buildTimestampCell(f['end-break']?.toString(), dark)),
                    // First Truck
                    DataCell(_buildTimestampCell(f['first-truck']?.toString(), dark)),
                    // Last Truck
                    DataCell(_buildTimestampCell(f['last-truck']?.toString(), dark)),
                    // Remarks
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Text(
                          f['remarks']?.toString().isNotEmpty == true ? f['remarks'].toString() : '-',
                          style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ),
                    // Status
                    DataCell(_buildStatusBadge(f['status']?.toString() ?? 'N/A')),
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
);
  }

  void _showFlightDrawer(BuildContext context, Map<String, dynamic> flight, bool dark) {
    bool hasUpdates = false;
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
              child: FlightDrawerDetails(
                flight: flight, 
                dark: dark,
                onFlightUpdated: () {
                  hasUpdates = true;
                }
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
      if (hasUpdates && mounted) {
        setState(() {});
      }
    });
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty || timeStr == '-') return '-';
    try {
      if (timeStr.contains('T') || timeStr.contains('-')) {
        final dt = DateTime.parse(timeStr).toLocal();
        return DateFormat('hh:mm a').format(dt).toUpperCase();
      }
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        int hr = int.parse(parts[0]);
        int min = int.parse(parts[1]);
        final dt = DateTime(2000, 1, 1, hr, min);
        return DateFormat('hh:mm a').format(dt).toUpperCase();
      }
    } catch (_) {}
    return timeStr;
  }

  Widget _buildTimestampCell(String? timeStr, bool dark) {
    if (timeStr == null || timeStr.trim().isEmpty || timeStr == '-') {
       return Text('-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827)));
    }
    
    String fTime = '-';
    String fDate = '';
    
    try {
      if (timeStr.contains('T') || timeStr.contains('-')) {
        final dt = DateTime.parse(timeStr).toLocal();
        fTime = DateFormat('hh:mm a').format(dt).toUpperCase();
        fDate = DateFormat('MM/dd').format(dt);
      } else {
        final parts = timeStr.trim().split(':');
        if (parts.length >= 2) {
          int hr = int.parse(parts[0]);
          int min = int.parse(parts[1]);
          fTime = DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hr, min)).toUpperCase();
        } else {
          fTime = timeStr;
        }
      }
    } catch (_) {
      fTime = timeStr;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(fTime, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: fTime != '-' ? FontWeight.bold : FontWeight.normal)),
        if (fDate.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text('($fDate)', style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF94a3b8), fontSize: 11)),
          )
        ]
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
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
      case 'saved':
        bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
        break;
      case 'pending':
        bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
        break;
      case 'delayed':
        bg = const Color(0xFFc2410c).withAlpha(51); fg = const Color(0xFFfdba74); // Orange tint
        break;
      case 'canceled':
      case 'cancelled':
        bg = const Color(0xFF991b1b).withAlpha(51); fg = const Color(0xFFfca5a5);
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
}

class FlightDrawerDetails extends StatefulWidget {
  final Map<String, dynamic> flight;
  final bool dark;
  final VoidCallback? onFlightUpdated;
  const FlightDrawerDetails({super.key, required this.flight, required this.dark, this.onFlightUpdated});

  @override
  State<FlightDrawerDetails> createState() => _FlightDrawerDetailsState();
}

class _FlightDrawerDetailsState extends State<FlightDrawerDetails> {
  List<Map<String, dynamic>> _ulds = [];
  bool _isLoading = true;
  String? _selectedUldId;
  List<Map<String, dynamic>> _selectedAwbs = [];
  
  bool _isEditingGeneralInfo = false;
  late Map<String, dynamic> _editedFlight;

  @override
  void initState() {
    super.initState();
    _editedFlight = Map<String, dynamic>.from(widget.flight);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final fCarrier = widget.flight['carrier']?.toString() ?? '';
      final fNumber = widget.flight['number']?.toString() ?? '';
      final fDate = widget.flight['date-arrived']?.toString() ?? '';

      final resUlds = await Supabase.instance.client
          .from('ULD')
          .select()
          .eq('refCarrier', fCarrier)
          .eq('refNumber', fNumber)
          .eq('refDate', fDate);

      if (mounted) {
        setState(() {
          var fetchedUlds = List<Map<String, dynamic>>.from(resUlds);
          fetchedUlds.sort((a, b) {
            String numA = a['ULD-number']?.toString().toUpperCase() ?? '';
            String numB = b['ULD-number']?.toString().toUpperCase() ?? '';
            
            bool isBulkA = numA.contains('BULK');
            bool isBulkB = numB.contains('BULK');
            
            if (isBulkA && !isBulkB) return -1;
            if (!isBulkA && isBulkB) return 1;
            
            bool isBreakA = a['isBreak'] == true;
            bool isBreakB = b['isBreak'] == true;
            
            if (isBreakA && !isBreakB) return -1;
            if (!isBreakA && isBreakB) return 1;
            
            return numA.compareTo(numB);
          });
          
          _ulds = fetchedUlds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch ULDs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectUld(String uldNumber) {
    setState(() {
      if (_selectedUldId == uldNumber) {
        _selectedUldId = null;
        _selectedAwbs = [];
      } else {
        _selectedUldId = uldNumber;
        final selectedUld = _ulds.firstWhere((element) => element['ULD-number'] == uldNumber, orElse: () => {});
        if (selectedUld['data-ULD'] is List) {
           _selectedAwbs = List<Map<String, dynamic>>.from(selectedUld['data-ULD']);
        } else {
           _selectedAwbs = [];
        }
      }
    });
  }

  String _formatDisplayTime(String? ts) {
    if (ts == null || ts == '-' || ts.isEmpty) return '--:--';
    // If it's already in 12h format from previous edits
    if (ts.toUpperCase().contains('AM') || ts.toUpperCase().contains('PM')) {
       return ts;
    }
    try {
      if (ts.contains('T') || ts.contains('-')) {
        final dt = DateTime.parse(ts).toLocal();
        return DateFormat('hh:mm a').format(dt).toUpperCase();
      } else {
        final parts = ts.trim().split(':');
        if (parts.length >= 2) {
           final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
           return DateFormat('hh:mm a').format(dt).toUpperCase();
        }
      }
    } catch (_) {}
    return ts;
  }

  String _formatDisplayDate(String? ts) {
    if (ts == null || ts == '-' || ts.isEmpty) return '';
    try {
      if (ts.contains('T') || ts.contains('-')) {
        final dt = DateTime.parse(ts).toLocal();
        return '(${dt.month}/${dt.day})';
      }
    } catch (_) {}
    return '';
  }

  Widget _buildEditableCard(String label, String key, Color colorL, Color colorP, {bool isTime = false, bool isStatus = false, bool isTimestamp = false, String? appendDateStr, IconData? icon}) {
    final isEditingThisField = _isEditingGeneralInfo;

    if (!isEditingThisField) {
      String displayValue = '${_editedFlight[key] ?? '-'}';
      if (isTime || isTimestamp) {
        displayValue = _formatDisplayTime(_editedFlight[key]?.toString());
      }
      
      Widget valueWidget;
      if (isTimestamp && displayValue != '-' && displayValue != '--:--') {
         final dStr = _formatDisplayDate(_editedFlight[key]?.toString());
         valueWidget = Row(
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
             Text(displayValue, style: TextStyle(color: colorP, fontSize: 13, fontWeight: FontWeight.bold)),
             if (dStr.isNotEmpty) ...[
               const SizedBox(width: 4),
               Text(dStr, style: TextStyle(color: colorL, fontSize: 11)),
             ]
           ]
         );
      } else if (appendDateStr != null && displayValue != '-' && displayValue != '--:--') {
         valueWidget = Row(
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
             Text(displayValue, style: TextStyle(color: colorP, fontSize: 13, fontWeight: FontWeight.bold)),
             if (appendDateStr.isNotEmpty && appendDateStr != '-') ...[
               const SizedBox(width: 4),
               Text(appendDateStr, style: TextStyle(color: colorL, fontSize: 11)),
             ]
           ]
         );
      } else if (isTime || isTimestamp) {
         valueWidget = Text(displayValue, style: TextStyle(color: colorP, fontSize: 13, fontWeight: FontWeight.bold));
      } else {
         valueWidget = Text(displayValue, style: TextStyle(color: colorP, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis);
      }
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: colorL, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            valueWidget,
          ],
        ),
      );
    }
    
    Widget editor;
    final inputBorderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    
    if (isTimestamp) {
      editor = InkWell(
        onTap: () async {
          DateTime initialDate = DateTime.now();
          TimeOfDay initialTime = TimeOfDay.now();
          final String tsString = _editedFlight[key]?.toString() ?? '';
          if (tsString.isNotEmpty && tsString != '-') {
            try {
              if (tsString.contains('T') || tsString.contains('-')) {
                final dt = DateTime.parse(tsString).toLocal();
                initialDate = dt;
                initialTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
              }
            } catch (_) {}
          }
          final DateTime? pickedDate = await showDatePicker(
             context: context,
             initialDate: initialDate,
             firstDate: DateTime(2020),
             lastDate: DateTime(2035),
             builder: (context, child) => Theme(
                 data: ThemeData.dark().copyWith(
                   colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b)),
                 ),
                 child: child!,
             )
          );
          if (pickedDate != null) {
              if (!mounted) return;
              final TimeOfDay? pickedTime = await showTimePicker(
                 context: context,
                 initialTime: initialTime,
                 builder: (context, child) => Theme(
                     data: ThemeData.dark().copyWith(
                       colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b)),
                     ),
                     child: child!,
                 )
              );
              if (pickedTime != null) {
                 final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                 setState(() => _editedFlight[key] = dt.toUtc().toIso8601String());
              }
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
               Text(_formatDisplayTime(_editedFlight[key]?.toString()), style: TextStyle(color: colorP, fontSize: 12), textAlign: TextAlign.center),
               const SizedBox(width: 4),
               Text(_formatDisplayDate(_editedFlight[key]?.toString()), style: TextStyle(color: colorL, fontSize: 10)),
            ]
          )
        ),
      );
    } else if (isTime) {
      editor = InkWell(
        onTap: () async {
          TimeOfDay initial = TimeOfDay.now();
          final String tsString = _editedFlight[key]?.toString() ?? '';
          if (tsString.isNotEmpty && tsString != '-') {
            try {
              if (tsString.contains('T') || tsString.contains('-')) {
                final dt = DateTime.parse(tsString).toLocal();
                initial = TimeOfDay(hour: dt.hour, minute: dt.minute);
              } else if (tsString.toUpperCase().contains('AM') || tsString.toUpperCase().contains('PM')) {
                final dt = DateFormat('hh:mm a').parse(tsString);
                initial = TimeOfDay(hour: dt.hour, minute: dt.minute);
              } else {
                final parts = tsString.trim().split(':');
                if (parts.length >= 2) {
                   initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                }
              }
            } catch (_) {}
          }

          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: initial,
            builder: (context, child) {
               return Theme(
                 data: ThemeData.dark().copyWith(
                   colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b)),
                 ),
                 child: child!,
               );
            },
          );
          if (picked != null) {
             final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
             final formatted = DateFormat('hh:mm a').format(dt).toUpperCase();
             setState(() => _editedFlight[key] = formatted);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
               Text(_formatDisplayTime(_editedFlight[key]?.toString()), style: TextStyle(color: colorP, fontSize: 12), textAlign: TextAlign.center),
               if (appendDateStr != null && appendDateStr.isNotEmpty && appendDateStr != '-') ...[
                  const SizedBox(width: 4),
                  Text(appendDateStr, style: TextStyle(color: colorL, fontSize: 10)),
               ]
            ]
          )
        ),
      );
    } else if (isStatus) {
      String currentVal = _editedFlight[key]?.toString() ?? 'Waiting';
      if (!['Waiting', 'Received', 'Pending', 'Checked', 'Ready', 'Delayed', 'Canceled'].contains(currentVal)) {
        currentVal = 'Waiting';
      }
      editor = Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentVal,
            dropdownColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 12),
            items: const [
              DropdownMenuItem(value: 'Waiting', child: Text('Waiting')),
              DropdownMenuItem(value: 'Received', child: Text('Received')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Checked', child: Text('Checked')),
              DropdownMenuItem(value: 'Ready', child: Text('Ready')),
              DropdownMenuItem(value: 'Delayed', child: Text('Delayed')),
              DropdownMenuItem(value: 'Canceled', child: Text('Canceled')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _editedFlight[key] = v);
            },
          ),
        ),
      );
    } else {
      editor = SizedBox(
        height: 32,
        child: TextField(
          style: TextStyle(color: colorP, fontSize: 12),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
          ),
          controller: TextEditingController(text: _editedFlight[key]?.toString() ?? '')..selection = TextSelection.collapsed(offset: (_editedFlight[key]?.toString() ?? '').length),
          onChanged: (v) => _editedFlight[key] = v,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colorL, size: 14),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          editor,
        ],
      ),
    );
  }

  Widget _buildDoubleEditableCard(String label, String key1, String key2, Color colorL, Color colorP, {IconData? icon}) {
    final isEditingThisField = _isEditingGeneralInfo;

    if (!isEditingThisField) {
      String displayValue = '${_editedFlight[key1] ?? 0} / ${_editedFlight[key2] ?? 0}';
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: colorL, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(displayValue, style: TextStyle(color: colorP, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }
    
    final inputBorderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    
    Widget editor = Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: TextField(
              style: TextStyle(color: colorP, fontSize: 12),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
              ),
              controller: TextEditingController(text: _editedFlight[key1]?.toString() ?? '')..selection = TextSelection.collapsed(offset: (_editedFlight[key1]?.toString() ?? '').length),
              onChanged: (v) => _editedFlight[key1] = int.tryParse(v),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('/', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: SizedBox(
            height: 32,
            child: TextField(
              style: TextStyle(color: colorP, fontSize: 12),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
              ),
              controller: TextEditingController(text: _editedFlight[key2]?.toString() ?? '')..selection = TextSelection.collapsed(offset: (_editedFlight[key2]?.toString() ?? '').length),
              onChanged: (v) => _editedFlight[key2] = int.tryParse(v),
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colorL, size: 14),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          editor,
        ],
      ),
    );
  }

  Future<void> _saveFields(Map<String, dynamic> updates) async {
    try {
      if (updates.containsKey('time-arrived') && updates['time-arrived'] != null) {
         try {
           final parsedTime = DateFormat('hh:mm a').parse(updates['time-arrived'].toString());
           updates['time-arrived'] = DateFormat('HH:mm:ss').format(parsedTime);
         } catch (_) {}
      }

      await Supabase.instance.client
        .from('Flight')
        .update(updates)
        .eq('carrier', widget.flight['carrier'])
        .eq('number', widget.flight['number'])
        .eq('date-arrived', widget.flight['date-arrived']);

      if (widget.onFlightUpdated != null) {
        widget.onFlightUpdated!();
      }
    } catch (e) {
      debugPrint('Error updating fields: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage.value == 'es' ? 'Error al guardar.' : 'Error saving.'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
    final f = widget.flight;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appLanguage.value == 'es' ? 'Detalles de Vuelo' : 'Flight Details', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.flight_land_rounded, color: textP, size: 24),
                      const SizedBox(width: 8),
                      Text('${f['carrier']} ${f['number']}', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Builder(builder: (context) {
                         String dStr = f['date-arrived']?.toString() ?? '';
                         try { if (dStr.isNotEmpty && dStr != '-') dStr = DateFormat('MM/dd').format(DateTime.parse(dStr)); } catch (_) {}
                         if (dStr.isEmpty) return const SizedBox();
                         return Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
                             borderRadius: BorderRadius.circular(6),
                             border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.calendar_today_rounded, size: 12, color: textS),
                               const SizedBox(width: 4),
                               Text(dStr, style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                             ]
                           )
                         );
                      }),
                    ]
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(icon: Icon(Icons.close_rounded, color: textP), onPressed: () => Navigator.pop(context)),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Row(
                             children: [
                               Icon(Icons.flight_outlined, size: 16, color: textP),
                               const SizedBox(width: 8),
                               Text(appLanguage.value == 'es' ? 'Información General' : 'General Info', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                             ],
                           ),
                           if (!_isEditingGeneralInfo)
                             InkWell(
                               onTap: () => setState(() => _isEditingGeneralInfo = true),
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(color: textP.withAlpha(10), borderRadius: BorderRadius.circular(6)),
                                 child: Icon(Icons.edit_rounded, color: textP.withAlpha(200), size: 14),
                               ),
                             )
                           else
                             Row(
                               children: [
                                 InkWell(
                                   onTap: () {
                                     setState(() {
                                       _isEditingGeneralInfo = false;
                                       _editedFlight = Map<String, dynamic>.from(widget.flight); 
                                     });
                                   }, 
                                   child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20)
                                 ),
                                 const SizedBox(width: 16),
                                 InkWell(
                                   onTap: () async {
                                     await _saveFields({
                                       'time-arrived': _editedFlight['time-arrived'],
                                       'status': _editedFlight['status'],
                                       'cant-break': _editedFlight['cant-break'],
                                       'cant-noBreak': _editedFlight['cant-noBreak'],
                                       'time-delayed': _editedFlight['time-delayed'],
                                       'start-break': _editedFlight['start-break'],
                                       'end-break': _editedFlight['end-break'],
                                       'first-truck': _editedFlight['first-truck'],
                                       'last-truck': _editedFlight['last-truck'],
                                       'remarks': _editedFlight['remarks'],
                                     });
                                     if (mounted) setState(() => _isEditingGeneralInfo = false);
                                   }, 
                                   child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                                 ),
                               ],
                             ),
                         ],
                       ),
                       const SizedBox(height: 12),
                       Row(children: [
                         Expanded(child: _buildEditableCard(appLanguage.value == 'es' ? 'Llegada' : 'Arrive Time', 'time-arrived', textS, textP, isTime: true, icon: Icons.schedule)),
                         Expanded(child: _buildEditableCard(appLanguage.value == 'es' ? 'Estado' : 'Status', 'status', textS, textP, isStatus: true, icon: Icons.info_outline)),
                       ]),

                       if (_editedFlight['status']?.toString().toLowerCase() == 'delayed') ...[
                         const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                         Container(
                           decoration: BoxDecoration(color: const Color(0xFFfb923c).withAlpha(10), borderRadius: BorderRadius.circular(8)),
                           padding: const EdgeInsets.all(8),
                           child: Row(children: [
                             Expanded(child: _buildEditableCard(appLanguage.value == 'es' ? 'Datos Delay' : 'Delayed Timestamp', 'time-delayed', const Color(0xFFfb923c), const Color(0xFFfdba74), isTimestamp: true, icon: Icons.history_toggle_off_rounded)),
                           ]),
                         ),
                       ],
                       const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                       Row(children: [
                         Expanded(child: _buildEditableCard(appLanguage.value == 'es' ? 'Inicio Brk' : 'Start Brk', 'start-break', textS, textP, isTimestamp: true, icon: Icons.play_circle_outline)),
                         Expanded(child: _buildEditableCard(appLanguage.value == 'es' ? 'Fin Brk' : 'End Brk', 'end-break', textS, textP, isTimestamp: true, icon: Icons.stop_circle_outlined)),
                       ]),
                       const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                       Row(children: [
                         Expanded(child: _buildEditableCard(appLanguage.value == 'es' ? '1er Camión' : 'First Truck', 'first-truck', textS, textP, isTimestamp: true, icon: Icons.local_shipping_outlined)),
                         Expanded(child: _buildEditableCard(appLanguage.value == 'es' ? 'Último Camión' : 'Last Truck', 'last-truck', textS, textP, isTimestamp: true, icon: Icons.local_shipping)),
                       ]),
                       const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                         Expanded(flex: 3, child: _buildDoubleEditableCard('Break / No Brk', 'cant-break', 'cant-noBreak', textS, textP, icon: Icons.inventory_2_outlined)),
                         Expanded(flex: 6, child: _buildEditableCard(appLanguage.value == 'es' ? 'Observaciones' : 'Remarks', 'remarks', textS, textP, icon: Icons.notes)),
                       ]),
                     ]
                  )
                ),
                
                const SizedBox(height: 32),
                Text(appLanguage.value == 'es' ? 'ULDs del Vuelo' : 'ULDs in Flight', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (_ulds.isEmpty) Text(appLanguage.value == 'es' ? 'No se encontraron ULDs.' : 'No ULDs found.', style: TextStyle(color: textS))
                else ..._ulds.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final Map<String, dynamic> u = entry.value;
                  final isSelected = _selectedUldId == u['ULD-number'];
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _selectUld(u['ULD-number'].toString()),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6366f1).withAlpha(30) : bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? const Color(0xFF6366f1) : (widget.dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text('${index + 1}. ', style: TextStyle(color: isSelected ? const Color(0xFF818cf8) : textS, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Icon(isSelected ? Icons.folder_open_rounded : Icons.folder_rounded, color: isSelected ? const Color(0xFF818cf8) : textS, size: 18),
                                    const SizedBox(width: 8),
                                    SizedBox(width: 100, child: Text('${u['ULD-number']}', style: TextStyle(color: isSelected ? Colors.white : textP, fontWeight: FontWeight.bold, fontSize: 14))),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text('Pieces: ${u['pieces'] ?? 0}', style: TextStyle(color: isSelected ? const Color(0xFFcbd5e1) : textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                    Expanded(child: Text('Weight: ${u['weight'] ?? 0} kg', style: TextStyle(color: isSelected ? const Color(0xFFcbd5e1) : textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(
                                    color: (u['isBreak'] == true) ? const Color(0xFF10b981).withAlpha(20) : const Color(0xFFf43f5e).withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: (u['isBreak'] == true) ? const Color(0xFF10b981).withAlpha(80) : const Color(0xFFf43f5e).withAlpha(80)),
                                 ),
                                 child: Text(
                                    (u['isBreak'] == true) ? 'BREAK' : 'NO BREAK',
                                    style: TextStyle(
                                       fontSize: 10,
                                       fontWeight: FontWeight.bold,
                                       color: (u['isBreak'] == true) ? const Color(0xFF10b981) : const Color(0xFFf43f5e),
                                    ),
                                 )
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctxD) {
                                      Widget buildInfoCard(String title, String value, IconData icon) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: widget.dark ? Colors.white.withAlpha(10) : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(icon, size: 16, color: textS),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(title, style: TextStyle(color: textS, fontSize: 11)),
                                                    Text(value, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                                  ]
                                                )
                                              ),
                                            ]
                                          )
                                        );
                                      }
                                      
                                      return AlertDialog(
                                        backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Text('ULD Information', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                        content: SizedBox(
                                          width: 450,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.inventory_2_rounded, color: Color(0xFF6366f1), size: 20),
                                                      const SizedBox(width: 12),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('ULD Number', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                                          Text(u['ULD-number']?.toString() ?? '-', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                                                        ]
                                                      ),
                                                    ]
                                                  )
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                     Expanded(child: buildInfoCard('Pieces', '${u['pieces'] ?? 0}', Icons.extension_outlined)),
                                                     const SizedBox(width: 12),
                                                     Expanded(child: buildInfoCard('Weight', '${u['weight'] ?? 0} kg', Icons.scale_outlined)),
                                                  ]
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                     Expanded(child: buildInfoCard('Priority', (u['isPriority'] == true) ? 'Yes' : 'No', Icons.star_rounded)),
                                                     const SizedBox(width: 12),
                                                     Expanded(child: buildInfoCard('Break', (u['isBreak'] == true) ? 'Yes' : 'No', Icons.broken_image_rounded)),
                                                     const SizedBox(width: 12),
                                                     Expanded(child: buildInfoCard('Status', u['status']?.toString() ?? 'Pending', Icons.info_outline_rounded)),
                                                  ]
                                                ),
                                                if (u['remarks'] != null && u['remarks'].toString().trim().isNotEmpty == true) ...[
                                                  const SizedBox(height: 20),
                                                  Text('Remarks', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(color: widget.dark ? const Color(0xFFfef3c7).withAlpha(20) : const Color(0xFFfef3c7).withAlpha(120), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFf59e0b).withAlpha(50))),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFf59e0b)),
                                                        const SizedBox(width: 8),
                                                        Expanded(child: SelectableText('${u['remarks']}', style: TextStyle(color: textP, fontSize: 13))),
                                                      ]
                                                    )
                                                  ),
                                                ],
                                              ]
                                            )
                                          )
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctxD),
                                            child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
                                          )
                                        ]
                                      );
                                    }
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(Icons.info_outline_rounded, size: 18, color: textS),
                                )
                              )
                            ],
                          ),
                        ),
                      ),
                      if (isSelected) 
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), 
                            border: const Border(left: BorderSide(color: Color(0xFF6366f1), width: 2))
                          ),
                          child: _selectedAwbs.isEmpty 
                               ? Row(
                                   children: [
                                     Icon(Icons.info_outline, color: textS, size: 16),
                                     const SizedBox(width: 8),
                                     Text(appLanguage.value == 'es' ? 'No hay AWBs en este ULD.' : 'No AWBs found in this ULD.', style: TextStyle(color: textS, fontSize: 13)),
                                   ],
                                 )
                               : Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Padding(
                                       padding: const EdgeInsets.only(bottom: 8),
                                       child: Text('Air Waybills:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                     ),
                                     ..._selectedAwbs.asMap().entries.map((awbEntry) {
                                       final awbIndex = awbEntry.key;
                                       final a = awbEntry.value;
                                       List<String> validHawbs = [];
                                       if (a['house_number'] != null) {
                                         var hRaw = a['house_number'];
                                         if (hRaw is List) {
                                           validHawbs = hRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
                                         } else if (hRaw is String) {
                                           validHawbs = hRaw.toString().split(RegExp(r'[,\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                         }
                                       } else if (a['house'] != null) {
                                         validHawbs = a['house'].toString().split(RegExp(r'[,\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                       }

                                       return Padding(
                                         padding: const EdgeInsets.only(bottom: 6),
                                         child: Row(
                                           children: [
                                              Container(
                                                width: 20, height: 20,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(color: Color(0x326366f1), shape: BoxShape.circle),
                                                child: Text('${awbIndex + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.description_rounded, color: Color(0xFF6366f1), size: 14),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Row(
                                                   children: [
                                                      SizedBox(width: 120, child: Text(a['awb_number']?.toString() ?? '', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w500))),
                                                      const SizedBox(width: 8),
                                                      Expanded(child: Text('Pieces: ${a['pieces'] ?? 0}', style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                      Expanded(child: Text('Weight: ${a['weight'] ?? 0} kg', style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                   ],
                                                )
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) {
                                                      Widget buildInfoCard(String title, String value, IconData icon) {
                                                        return Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: widget.dark ? Colors.white.withAlpha(10) : Colors.white,
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(icon, size: 16, color: textS),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(title, style: TextStyle(color: textS, fontSize: 11)),
                                                                    Text(value, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                                                  ]
                                                                )
                                                              ),
                                                            ]
                                                          )
                                                        );
                                                      }

                                                      return AlertDialog(
                                                        backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                        title: Text('AWB Information', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                                        content: SizedBox(
                                                          width: 450,
                                                          child: SingleChildScrollView(
                                                            child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.all(12),
                                                                  decoration: BoxDecoration(
                                                                    color: widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
                                                                    borderRadius: BorderRadius.circular(10),
                                                                    border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF6366f1), size: 20),
                                                                      const SizedBox(width: 12),
                                                                      Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text('AWB Number', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                                                          Text(a['awb_number']?.toString() ?? '-', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                        ]
                                                                      ),
                                                                    ]
                                                                  )
                                                                ),
                                                                const SizedBox(height: 16),
                                                                Row(
                                                                  children: [
                                                                     Expanded(child: buildInfoCard('Pieces', '${a['pieces'] ?? 0}', Icons.extension_outlined)),
                                                                     const SizedBox(width: 12),
                                                                     Expanded(child: buildInfoCard('Total Pcs', '${a['total'] ?? 0}', Icons.all_inbox_outlined)),
                                                                     const SizedBox(width: 12),
                                                                     Expanded(child: buildInfoCard('Weight', '${a['weight'] ?? 0} kg', Icons.scale_outlined)),
                                                                  ]
                                                                ),
                                                                if (validHawbs.isNotEmpty) ...[
                                                                  const SizedBox(height: 20),
                                                                  Text('House AWBs (HAWBs)', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                                                  const SizedBox(height: 8),
                                                                  Container(
                                                                    padding: const EdgeInsets.all(12),
                                                                    decoration: BoxDecoration(color: widget.dark ? Colors.black.withAlpha(30) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))),
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: validHawbs.map((h) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.layers_outlined, size: 14, color: textS), const SizedBox(width: 8), Expanded(child: SelectableText(h, style: TextStyle(color: textP, fontSize: 13)))]))).toList(),
                                                                    ),
                                                                  ),
                                                                ],
                                                                if (a['remarks'] != null && a['remarks'].toString().trim().isNotEmpty == true) ...[
                                                                  const SizedBox(height: 20),
                                                                  Text('Remarks', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                                                  const SizedBox(height: 8),
                                                                  Container(
                                                                    padding: const EdgeInsets.all(12),
                                                                    decoration: BoxDecoration(color: widget.dark ? const Color(0xFFfef3c7).withAlpha(20) : const Color(0xFFfef3c7).withAlpha(120), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFf59e0b).withAlpha(50))),
                                                                    child: Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        const Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFf59e0b)),
                                                                        const SizedBox(width: 8),
                                                                        Expanded(child: SelectableText('${a['remarks']}', style: TextStyle(color: textP, fontSize: 13))),
                                                                      ]
                                                                    )
                                                                  ),
                                                                ],
                                                              ]
                                                            ),
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx),
                                                            child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
                                                          )
                                                        ]
                                                      );
                                                    }
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Icon(Icons.info_outline_rounded, color: textS, size: 18),
                                                )
                                              ),
                                           ]
                                         ),
                                       );
                                     }),
                                   ]
                                 ),
                        )
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}


