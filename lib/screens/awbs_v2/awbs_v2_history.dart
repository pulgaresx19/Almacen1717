import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import '../flights_v2/flights_v2_status_logic.dart';
import 'awbs_v2_drawer.dart';
import 'awbs_v2_uld_drawer.dart';
import '../../services/realtime_service.dart';

class AwbsV2History extends StatefulWidget {
  final VoidCallback onBackToMain;
  const AwbsV2History({super.key, required this.onBackToMain});

  @override
  State<AwbsV2History> createState() => _AwbsV2HistoryState();
}

class _AwbsV2HistoryState extends State<AwbsV2History> {
  String? _selectedDate; // The date folder currently opened
  bool _isLoadingSummary = true;
  List<Map<String, dynamic>> _summaryList = [];
  
  bool _isLoadingDay = false;
  bool _showUldTab = false;

  List<Map<String, dynamic>> _dayAwbs = [];
  List<Map<String, dynamic>> _dayUlds = [];

  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    try {
      final res = await Supabase.instance.client.rpc('rpc_get_storage_deliveries_summary');
      if (mounted) {
        setState(() {
          _summaryList = List<Map<String, dynamic>>.from(res);
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching storage summary: $e');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  Future<void> _fetchDayItems(String dateStr) async {
    setState(() {
      _selectedDate = dateStr;
      _isLoadingDay = true;
      _dayAwbs = [];
      _dayUlds = [];
    });
    try {
      final start = DateTime.parse(dateStr);
      final end = start.add(const Duration(days: 1));
      
      final resAwbs = await Supabase.instance.client
          .from('awbs')
          .select()
          .eq('status', 'Delivered')
          .gte('time_deliver', start.toIso8601String())
          .lt('time_deliver', end.toIso8601String())
          .order('time_deliver', ascending: false);

      final resUlds = await Supabase.instance.client
          .from('ulds')
          .select()
          .eq('status', 'Delivered')
          .gte('time_deliver', start.toIso8601String())
          .lt('time_deliver', end.toIso8601String())
          .order('time_deliver', ascending: false);

      if (mounted && _selectedDate == dateStr) {
        setState(() {
          _dayAwbs = List<Map<String, dynamic>>.from(resAwbs);
          _dayUlds = List<Map<String, dynamic>>.from(resUlds);
          _isLoadingDay = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching items for day: $e');
      if (mounted && _selectedDate == dateStr) {
        setState(() => _isLoadingDay = false);
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting') || s.contains('pending')) {
      bg = const Color(0xFFca8a04).withAlpha(51); fg = const Color(0xFFfef08a);
    } else if (s.contains('in process') || s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('ready') || s.contains('deliver') || s.contains('saved')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s == 'checked') {
      bg = const Color(0xFF1d4ed8).withAlpha(90); fg = const Color(0xFFbfdbfe);
    } else if (s == 'checking') {
      bg = const Color(0xFF2563eb).withAlpha(40); fg = const Color(0xFF93c5fd);
    } else if (s == 'received' || s == 'stored') {
      bg = const Color(0xFF7e22ce).withAlpha(90); fg = const Color(0xFFe9d5ff);
    } else if (s == 'receiving') {
      bg = const Color(0xFF9333ea).withAlpha(40); fg = const Color(0xFFd8b4fe);
    }

    return Container(
      width: 100,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color bgCard = dark ? Colors.white.withAlpha(10) : Colors.white;
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        return Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_selectedDate != null) {
                          setState(() {
                            _selectedDate = null;
                          });
                        } else {
                          widget.onBackToMain();
                        }
                      },
                      icon: Icon(Icons.arrow_back_rounded, color: textP),
                      tooltip: appLanguage.value == 'es' ? 'Atrás' : 'Back',
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _selectedDate == null ? Icons.folder_special_rounded : Icons.folder_open_rounded,
                      color: const Color(0xFF6366f1),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? (appLanguage.value == 'es' ? 'Historial de Storage' : 'Storage History')
                          : (appLanguage.value == 'es' ? 'Entregados el $_selectedDate' : 'Delivered on $_selectedDate'),
                      style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_selectedDate != null) ...[
                      const Spacer(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_showUldTab) {
                                setState(() {
                                  _showUldTab = false;
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
                    ]
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.transparent),

              // Content
              Expanded(
                child: _selectedDate == null
                    ? _buildFoldersView(dark, textP, textS, borderCard)
                    : _buildDayView(dark, textP, textS, borderCard),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoldersView(bool dark, Color textP, Color textS, Color borderCard) {
    if (_isLoadingSummary) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
    }

    if (_summaryList.isEmpty) {
      return Center(
        child: Text(
          appLanguage.value == 'es' ? 'No hay historial disponible.' : 'No history available.',
          style: TextStyle(color: textS),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.0,
      ),
      itemCount: _summaryList.length,
      itemBuilder: (context, index) {
        final item = _summaryList[index];
        final dateKey = item['date_group']?.toString() ?? 'Unknown';
        final count = item['delivery_count']?.toString() ?? '0';
        
        String niceDate = dateKey;
        if (dateKey != 'Unknown') {
          try {
            final d = DateTime.parse(dateKey);
            niceDate = DateFormat('MMM dd, yyyy').format(d);
          } catch (_) {}
        }

        return InkWell(
          onTap: () {
            _fetchDayItems(dateKey);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCard),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_rounded,
                  color: Color(0xFFeab308),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(niceDate, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count items',
                    style: const TextStyle(color: Color(0xFF6366f1), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayView(bool dark, Color textP, Color textS, Color borderCard) {
    if (_isLoadingDay) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
    }

    final dataList = _showUldTab ? _dayUlds : _dayAwbs;

    if (dataList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 64, color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
            const SizedBox(height: 16),
            Text(appLanguage.value == 'es' ? 'No hay ítems' : 'No Items', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(appLanguage.value == 'es' ? 'No hay ítems entregados en esta fecha.' : 'There are no items delivered on this date.', style: TextStyle(color: textS)),
          ],
        )
      );
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
                  columns: _showUldTab ? const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('ULD Number')),
                    DataColumn(label: Text('Ref. Flight')),
                    DataColumn(label: Text('Total Pieces')),
                    DataColumn(label: Text('Total Weight')),
                    DataColumn(label: Text('Time Delivered')),
                    DataColumn(label: Text('Status')),
                  ] : const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('AWB Number')),
                    DataColumn(label: Text('Expected')),
                    DataColumn(label: Text('Received')),
                    DataColumn(label: Text('Arrived')),
                    DataColumn(label: Text('Time Delivered')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: List.generate(dataList.length, (index) {
                    final u = dataList[index];

                    if (_showUldTab) {
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

                      String timeDeliverDisplay = '-';
                      final timeDelStr = u['time_deliver']?.toString();
                      if (timeDelStr != null && timeDelStr.isNotEmpty) {
                        try {
                          final dt = DateTime.parse(timeDelStr).toLocal();
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
                          timeDeliverDisplay = '$padDate $hour:$padMin $amPm';
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
                          DataCell(Text(totalPieces.toString())),
                          DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\.$|\.0$'), '')} kg')),
                          DataCell(Text(timeDeliverDisplay)),
                          DataCell(_buildStatusBadge(status)),
                        ],
                      );
                    } else {
                      final awbNum = u['awb_number']?.toString() ?? u['AWB-number']?.toString() ?? '-';
                      int expectedPieces = int.tryParse(u['total_espected']?.toString() ?? u['expected_pieces']?.toString() ?? '0') ?? 0;
                      int receivedPieces = int.tryParse(u['pieces_received']?.toString() ?? '0') ?? 0;
                      int arrivedPieces = int.tryParse(u['pieces_arrived']?.toString() ?? '0') ?? 0;
                      String status = u['status']?.toString() ?? 'Waiting';

                      String timeDeliverDisplay = '-';
                      final timeDelStr = u['time_deliver']?.toString();
                      if (timeDelStr != null && timeDelStr.isNotEmpty) {
                        try {
                          final dt = DateTime.parse(timeDelStr).toLocal();
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
                          timeDeliverDisplay = '$padDate $hour:$padMin $amPm';
                        } catch (_) {}
                      }

                      return DataRow(
                        onSelectChanged: (_) {
                          AwbsV2Drawer.show(context, u, dark, receivedPieces, expectedPieces, status);
                        },
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(awbNum, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                          DataCell(Text(expectedPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(receivedPieces.toString())),
                          DataCell(Text(arrivedPieces.toString())),
                          DataCell(Text(timeDeliverDisplay)),
                          DataCell(_buildStatusBadge(status)),
                        ],
                      );
                    }
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
