import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode;
import 'add_flight_screen.dart';

class FlightModule extends StatefulWidget {
  const FlightModule({super.key});

  @override
  State<FlightModule> createState() => _FlightModuleState();
}

class _FlightModuleState extends State<FlightModule> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddFlightScreenState> _addFlightKey = GlobalKey<AddFlightScreenState>();

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
                              if (_addFlightKey.currentState != null) {
                                final canPop = await _addFlightKey.currentState!.handleBackRequest();
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
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showAddForm = true);
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(appLanguage.value == 'es' ? 'Añadir Vuelo' : 'Add Flight', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            if (!_showAddForm)
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
        
        // Flight Table
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
                  ? AddFlightScreen(
                      key: _addFlightKey,
                      isInline: true,
                      onPop: (bool isSaved) {
                        setState(() {
                          _showAddForm = false;
                        });
                      },
                    )
                  : _buildFlightList(dark),
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
      stream: Supabase.instance.client.from('Flight').stream(primaryKey: ['id']).order('date-arrived', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        var flights = snapshot.data ?? [];
        
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
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
              dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
              dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
              headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),
              columns: [
                DataColumn(label: Text(appLanguage.value == 'es' ? 'No.' : 'No.')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Vuelo (Aerolínea/No.)' : 'Carrier / Number')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Fecha Llegada' : 'Arrive Date')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Hora Llegada' : 'Arrive Time')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'B / No B' : 'Break / No B.')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Inicio Desarme' : 'Start Break')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Fin Desarme' : 'End Break')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Primer Camión' : 'First Truck')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Último Camión' : 'Last Truck')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Observaciones' : 'Remarks')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
              ],
              rows: List.generate(flights.length, (index) {
                final f = flights[index];
                
                final String dateStr = f['date-arrived']?.toString() ?? '';
                final String timeStr = f['time-arrived']?.toString() ?? '-';
                String formattedDate = dateStr.isNotEmpty ? dateStr : '-';

                try {
                  if (dateStr.isNotEmpty) {
                    final dt = DateTime.parse(dateStr);
                    formattedDate = DateFormat('MM/dd/yyyy').format(dt);
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
                    // Arrive Date
                    DataCell(Text(formattedDate)),
                    // Arrive Time
                    DataCell(Text(_formatTime(timeStr), style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF6B7280)))),
                    // Break / No Break
                    DataCell(Text('${f['cant-break'] ?? 0} / ${f['cant-noBreak'] ?? 0}', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)))),
                    // Start Break
                    DataCell(Text(_formatTime(f['start-break']?.toString()), style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827)))),
                    // End Break
                    DataCell(Text(_formatTime(f['end-break']?.toString()), style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827)))),
                    // First Truck
                    DataCell(Text(_formatTime(f['first-truck']?.toString()), style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827)))),
                    // Last Truck
                    DataCell(Text(_formatTime(f['last-truck']?.toString()), style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827)))),
                    // Remarks
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 350),
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
              width: 400,
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
  List<Map<String, dynamic>> _allAwbs = [];
  bool _isLoading = true;
  String? _selectedUldId;
  List<Map<String, dynamic>> _selectedAwbs = [];
  
  final Set<String> _editingKeys = {};
  bool _isEditing = false;
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
          _ulds = List<Map<String, dynamic>>.from(resUlds);
        });
      }
    } catch (e) {
      debugPrint('Error fetch ULDs: $e');
    }

    try {
      // Robust AWB fetching: Fetch all and filter in memory to avoid JSONB dialect errors
      final resAwbs = await Supabase.instance.client.from('AWB').select();
      
      if (mounted) {
        setState(() {
          _allAwbs = List<Map<String, dynamic>>.from(resAwbs);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch AWBs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectUld(String uldNumber) {
    setState(() {
      if (_selectedUldId == uldNumber) {
        _selectedUldId = null;
      } else {
        _selectedUldId = uldNumber;
        final fCarrier = widget.flight['carrier']?.toString() ?? '';
        final fNumber = widget.flight['number']?.toString() ?? '';
        
        _selectedAwbs = _allAwbs.where((awb) {
          final dataAwb = awb['data-AWB'] as List?;
          if (dataAwb == null) return false;
          return dataAwb.any((entry) => 
               entry['refCarrier']?.toString() == fCarrier && 
               entry['refNumber']?.toString() == fNumber &&
               entry['refULD']?.toString() == uldNumber);
        }).toList();
      }
    });
  }

  Widget _buildInfoRow(String label, String value, Color colorL, Color colorV) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: colorL, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: colorV, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, String key, Color colorL, Color colorP, {bool isTime = false, bool isStatus = false}) {
    final isEditingThisField = _editingKeys.contains(key);

    if (!isEditingThisField) {
      String displayValue = '${_editedFlight[key] ?? '-'}';
      if (isTime) {
        String ts = _editedFlight[key]?.toString() ?? '-';
        if (ts != '-') {
            try {
              if (ts.contains('T') || ts.contains('-')) {
                final dt = DateTime.parse(ts).toLocal();
                ts = DateFormat('hh:mm a').format(dt).toUpperCase();
              } else {
                final parts = ts.trim().split(':');
                if (parts.length >= 2) {
                   final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
                   ts = DateFormat('hh:mm a').format(dt).toUpperCase();
                }
              }
            } catch (_) {}
        }
        displayValue = ts;
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 130, child: Text(label, style: TextStyle(color: colorL, fontSize: 13))),
            Expanded(child: Text(displayValue, style: TextStyle(color: colorP, fontSize: 14, fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            if (_isEditing)
              IconButton(
                icon: Icon(Icons.edit_rounded, color: colorL, size: 16),
                onPressed: () {
                  setState(() => _editingKeys.add(key));
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: appLanguage.value == 'es' ? 'Editar' : 'Edit',
              ),
          ],
        ),
      );
    }
    
    Widget editor;
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    
    if (isTime) {
      editor = InkWell(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
          child: Text('${_editedFlight[key] ?? '__:__ --'}', style: TextStyle(color: colorP, fontSize: 13)),
        ),
      );
    } else if (isStatus) {
      String currentVal = _editedFlight[key]?.toString() ?? 'Waiting';
      if (!['Waiting', 'Pending', 'Ready'].contains(currentVal)) {
        currentVal = 'Waiting';
      }
      editor = Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentVal,
            dropdownColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 13),
            items: const [
              DropdownMenuItem(value: 'Waiting', child: Text('Waiting')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Ready', child: Text('Ready'))
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _editedFlight[key] = v);
              }
            },
          ),
        ),
      );
    } else {
      editor = SizedBox(
        height: 36,
        child: TextField(
          style: TextStyle(color: colorP, fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
          ),
          controller: TextEditingController(text: _editedFlight[key]?.toString() ?? '')..selection = TextSelection.collapsed(offset: (_editedFlight[key]?.toString() ?? '').length),
          onChanged: (v) {
            _editedFlight[key] = v;
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: colorL, fontSize: 13))),
          Expanded(child: editor),
          if (isEditingThisField) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
              ),
              child: IconButton(
                icon: const Icon(Icons.save_rounded, color: Color(0xFF6366f1), size: 18),
                onPressed: () {
                  _saveField(key, _editedFlight[key]);
                  setState(() => _editingKeys.remove(key));
                },
                tooltip: appLanguage.value == 'es' ? 'Guardar' : 'Save',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                onPressed: () {
                  setState(() {
                    _editedFlight[key] = widget.flight[key];
                    _editingKeys.remove(key);
                  });
                },
                tooltip: appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _saveField(String key, dynamic value) async {
    try {
      if (['time-arrived', 'start-break', 'end-break', 'first-truck', 'last-truck'].contains(key)) {
         try {
           final parsedTime = DateFormat('hh:mm a').parse(value.toString());
           value = DateFormat('HH:mm:ss').format(parsedTime);
         } catch (_) {}
      }
      
      await Supabase.instance.client
        .from('Flight')
        .update({key: value})
        .eq('carrier', widget.flight['carrier'])
        .eq('number', widget.flight['number'])
        .eq('date-arrived', widget.flight['date-arrived']);

      if (widget.onFlightUpdated != null) {
        widget.onFlightUpdated!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage.value == 'es' ? 'Se ha guardado correctamente.' : 'Saved successfully.'),
            backgroundColor: const Color(0xFF166534),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating \$key: \$e');
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
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 24, right: 16),
          decoration: BoxDecoration(
            color: widget.dark ? const Color(0xFF1e293b) : const Color(0xFFf8fafc),
            border: Border(bottom: BorderSide(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appLanguage.value == 'es' ? 'Detalles de Vuelo' : 'Flight Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('Edit', style: TextStyle(color: textS, fontSize: 12)),
                  Switch(
                    value: _isEditing, 
                    activeThumbColor: const Color(0xFF6366f1),
                    onChanged: (v) {
                      setState(() {
                        _isEditing = v;
                        if (!v) {
                          _editingKeys.clear();
                          _editedFlight = Map<String, dynamic>.from(widget.flight);
                        }
                      });
                    }
                  ),
                  IconButton(icon: Icon(Icons.close, color: textS), onPressed: () => Navigator.pop(context)),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(appLanguage.value == 'es' ? 'Aerolínea / No.' : 'Carrier / No.', '${f['carrier']} ${f['number']}', textS, textP),
                Builder(builder: (context) {
                   String dStr = f['date-arrived']?.toString() ?? '-';
                   try {
                     if (dStr.isNotEmpty && dStr != '-') {
                       dStr = DateFormat('MM/dd/yyyy').format(DateTime.parse(dStr));
                     }
                   } catch (_) {}
                   return _buildInfoRow(appLanguage.value == 'es' ? 'Fecha Llegada' : 'Arrive Date', dStr, textS, textP);
                }),
                _buildInfoRow('Break / No Break', '${f['cant-break'] ?? 0} / ${f['cant-noBreak'] ?? 0}', textS, textP),
                _buildEditableRow(appLanguage.value == 'es' ? 'Hora Llegada' : 'Arrive Time', 'time-arrived', textS, textP, isTime: true),
                _buildEditableRow(appLanguage.value == 'es' ? 'Inicio Desarme' : 'Start Break', 'start-break', textS, textP, isTime: true),
                _buildEditableRow(appLanguage.value == 'es' ? 'Fin Desarme' : 'End Break', 'end-break', textS, textP, isTime: true),
                _buildEditableRow(appLanguage.value == 'es' ? 'Primer Camión' : 'First Truck', 'first-truck', textS, textP, isTime: true),
                _buildEditableRow(appLanguage.value == 'es' ? 'Último Camión' : 'Last Truck', 'last-truck', textS, textP, isTime: true),
                _buildEditableRow(appLanguage.value == 'es' ? 'Estado' : 'Status', 'status', textS, textP, isStatus: true),
                _buildEditableRow(appLanguage.value == 'es' ? 'Observaciones' : 'Remarks', 'remarks', textS, textP),
                
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
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? const Color(0xFF6366f1) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text('${index + 1}. ', style: TextStyle(color: isSelected ? const Color(0xFF818cf8) : textS, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Icon(isSelected ? Icons.folder_open_rounded : Icons.folder_rounded, color: isSelected ? const Color(0xFF818cf8) : textS, size: 18),
                                  const SizedBox(width: 8),
                                  Text('${u['ULD-number']}', style: TextStyle(color: isSelected ? Colors.white : textP, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              Text('${u['pieces'] ?? 0} pcs  |  ${u['weight'] ?? 0} kg', style: TextStyle(color: isSelected ? const Color(0xFFcbd5e1) : textS, fontSize: 12)),
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
                                     ..._selectedAwbs.map((a) {
                                       Map<String, dynamic>? matchAwbData;
                                       try {
                                          matchAwbData = (a['data-AWB'] as List).firstWhere((e) => e['refULD'] == u['ULD-number'].toString() && e['refCarrier'] == widget.flight['carrier'] && e['refNumber'] == widget.flight['number']);
                                       } catch (_) {}
                                       
                                       return Padding(
                                         padding: const EdgeInsets.only(bottom: 6),
                                         child: Row(
                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                           children: [
                                             Row(
                                               children: [
                                                  const Icon(Icons.description_rounded, color: Color(0xFF6366f1), size: 14),
                                                  const SizedBox(width: 6),
                                                  Text(a['AWB-number'], style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w500)),
                                               ],
                                             ),
                                             Text('${matchAwbData?['pieces'] ?? 0} pcs | ${matchAwbData?['weight'] ?? 0} kg', style: TextStyle(color: textS, fontSize: 12)),
                                           ]
                                         ),
                                       );
                                     }),
                                   ]
                                 )
                        )
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
