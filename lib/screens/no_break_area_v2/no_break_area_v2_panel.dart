import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show isDarkMode;
import '../../services/realtime_service.dart';
import 'no_break_area_v2_deliver_dialog.dart';

class NoBreakAreaV2Panel extends StatefulWidget {
  final String searchQuery;
  const NoBreakAreaV2Panel({super.key, required this.searchQuery});

  @override
  State<NoBreakAreaV2Panel> createState() => _NoBreakAreaV2PanelState();
}

class _NoBreakAreaV2PanelState extends State<NoBreakAreaV2Panel> {
  final Map<String, Map<String, dynamic>> _selectedUlds = {};
  List<Map<String, dynamic>> _uldsList = [];
  StreamSubscription? _uldsSubscription;

  @override
  void initState() {
    super.initState();
    _startRealtime();
  }

  void _startRealtime() {
    _uldsSubscription = Supabase.instance.client
        .from('ulds')
        .stream(primaryKey: ['id_uld'])
        .listen((data) {
      if (mounted) {
        setState(() {
          _uldsList = List<Map<String, dynamic>>.from(data);
        });
      }
    });
  }

  @override
  void dispose() {
    _uldsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: realtimeService.flights,
          builder: (context, flightsList, child) {
            var items = List<Map<String, dynamic>>.from(_uldsList);
            
            // Filter only No Break ULDs that are Received
            items = items.where((u) {
              if (u['is_break'] != false) return false;

              final hasTimeReceived = u['time_received'] != null && u['time_received'].toString().isNotEmpty;
              final isInProcess = u['in_process'] == true;
              final isWaiting = u['waiting'] == true;
              final isSendDriver = u['send_driver'] == true;
              final hasTimeDeliver = u['time_deliver'] != null && u['time_deliver'].toString().isNotEmpty;
              final isSendUld = u['send_uld'] == true;
              final isSendBreak = u['send_break'] == true;
              final isInFlight = u['in_flight'] == true;

              if (!hasTimeReceived) return false;
              if (isInProcess || isWaiting || isSendDriver || hasTimeDeliver || isSendUld || isSendBreak || isInFlight) return false;
              
              return true;
            }).toList();

            // Apply search
            if (widget.searchQuery.isNotEmpty) {
              final query = widget.searchQuery.toLowerCase();
              items = items.where((u) {
                final uldNumber = u['uld_number']?.toString().toLowerCase() ?? '';
                
                String flightNumber = '';
                if (u['id_flight'] != null) {
                  final f = flightsList.firstWhere((x) => x['id_flight'] == u['id_flight'], orElse: () => {});
                  if (f.isNotEmpty) {
                    final carrier = f['carrier']?.toString() ?? '';
                    final number = f['number']?.toString() ?? '';
                    final dateRaw = f['date']?.toString();
                    String dateStr = '';
                    if (dateRaw != null && dateRaw.isNotEmpty) {
                      try {
                        final dt = DateTime.parse(dateRaw);
                        dateStr = DateFormat('MM/dd/yyyy').format(dt);
                      } catch (_) {}
                    }
                    flightNumber = '$carrier$number $dateStr'.trim().toLowerCase();
                  }
                }
                
                final trackingNumber = u['tracking_number']?.toString().toLowerCase() ?? '';
                return uldNumber.contains(query) || flightNumber.contains(query) || trackingNumber.contains(query);
              }).toList();
            }

            // Sort by uld_number
            items.sort((a, b) {
               final uA = a['uld_number']?.toString() ?? '';
               final uB = b['uld_number']?.toString() ?? '';
               return uA.compareTo(uB);
            });

            final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

            Widget mainContent = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Panel: ULD List
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text('No "No Break" ULDs found.', style: TextStyle(color: dark ? Colors.white54 : Colors.black54)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final u = items[index];
                            
                            String uldNumber = u['uld_number']?.toString() ?? '-';
                            String flightNumber = '-';
                            if (u['id_flight'] != null) {
                              final f = flightsList.firstWhere((x) => x['id_flight'] == u['id_flight'], orElse: () => {});
                              if (f.isNotEmpty) {
                                final carrier = f['carrier']?.toString() ?? '';
                                final number = f['number']?.toString() ?? '';
                                final dateRaw = f['date']?.toString();
                                String dateStr = '';
                                if (dateRaw != null && dateRaw.isNotEmpty) {
                                  try {
                                    final dt = DateTime.parse(dateRaw);
                                    dateStr = DateFormat('MM/dd/yyyy').format(dt);
                                  } catch (_) {}
                                }
                                flightNumber = '$carrier$number';
                                if (dateStr.isNotEmpty) {
                                  flightNumber += ' - $dateStr';
                                }
                                if (flightNumber.trim() == '-' || flightNumber.trim().isEmpty) {
                                  flightNumber = '-';
                                }
                              }
                            }
                            String pieces = u['pieces_total']?.toString() ?? u['pieces']?.toString() ?? '-';
                            String weight = u['weight_total']?.toString() ?? u['weight']?.toString() ?? '-';
                            
                            String status = 'Waiting';
                            if (u['time_deliver'] != null && u['time_deliver'].toString().isNotEmpty) {
                              status = 'Delivered';
                            } else if (u['in_process'] == true) {
                              status = 'In Process';
                            } else if (u['time_received'] != null && u['time_received'].toString().isNotEmpty) {
                              status = 'Received';
                            }
                            
                            String remarks = u['remarks']?.toString() ?? '-';
                            if (remarks.isEmpty) remarks = '-';
                            
                            bool isSelected = _selectedUlds.containsKey(uldNumber);

                            return _buildUldItem(
                              index: index + 1,
                              uldNumber: uldNumber,
                              flightNumber: flightNumber,
                              status: status,
                              pieces: pieces,
                              weight: weight,
                              remarks: remarks,
                              dark: dark,
                              isSelected: isSelected,
                              onToggle: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedUlds.remove(uldNumber);
                                  } else {
                                    _selectedUlds[uldNumber] = u;
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                if (isWide) ...[
                  Container(width: 1, color: borderC),
                  // Right Panel: Selected ULDs
                  SizedBox(
                    width: 360,
                    child: _buildSelectedPanel(dark, borderC),
                  ),
                ]
              ],
            );

            if (!isWide && _selectedUlds.isNotEmpty) {
              return Stack(
                children: [
                  mainContent,
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        showNoBreakDeliverDialog(
                          context: context,
                          selectedUlds: _selectedUlds.values.toList(),
                          dark: dark,
                          onSuccess: () {
                            setState(() {
                              _selectedUlds.clear();
                            });
                          },
                        );
                      },
                      backgroundColor: const Color(0xFF6366f1),
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text('Send ${_selectedUlds.length} ULD${_selectedUlds.length > 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }

            return mainContent;
          },
        );
      },
    );
      },
    );
  }

  Widget _buildUldItem({
    required int index,
    required String uldNumber,
    required String flightNumber,
    required String status,
    required String pieces,
    required String weight,
    required String remarks,
    required bool dark,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFFe0e7ff)) 
              : (dark ? Colors.white.withAlpha(10) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366f1)
                : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) => onToggle(),
              activeColor: const Color(0xFF6366f1),
              side: BorderSide(color: dark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 8),
            // Index Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withAlpha(30),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                index.toString(),
                style: const TextStyle(
                  color: Color(0xFF6366f1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 24),
            
            // ULD Number
            Expanded(
              flex: 2,
              child: _buildColumnInfo('ULD NUMBER', uldNumber, dark),
            ),
            
            // Pieces
            Expanded(
              flex: 1,
              child: _buildColumnInfo('PIECES', pieces, dark),
            ),
            
            // Weight
            Expanded(
              flex: 1,
              child: _buildColumnInfo('WEIGHT', weight, dark),
            ),

            // Remarks
            Expanded(
              flex: 3,
              child: _buildColumnInfo('REMARKS', remarks, dark),
            ),

            // Flight
            Expanded(
              flex: 2,
              child: _buildColumnInfo('FLIGHT', flightNumber, dark),
            ),
            
            // Status
            Expanded(
              flex: 2,
              child: _buildColumnInfo('STATUS', status, dark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPanel(bool dark, Color borderC) {
    final selectedList = _selectedUlds.values.toList();
    
    return Container(
      color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: dark ? Colors.white : Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selected ULDs (${selectedList.length})',
                  style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedList.isEmpty
                ? Center(
                    child: Text(
                      'No ULDs selected',
                      style: TextStyle(color: dark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedList.length,
                    itemBuilder: (context, index) {
                      final u = selectedList[index];
                      final uldNumber = u['uld_number']?.toString() ?? '-';
                      final pieces = u['pieces_total']?.toString() ?? u['pieces']?.toString() ?? '-';
                      final weight = u['weight_total']?.toString() ?? u['weight']?.toString() ?? '-';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withAlpha(10) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderC),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(uldNumber, style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('$pieces pcs • ${weight == '-' ? '0' : weight} kg', style: TextStyle(color: dark ? Colors.white54 : Colors.black54, fontSize: 12)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _selectedUlds.remove(uldNumber);
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: borderC))),
            child: ElevatedButton.icon(
              onPressed: selectedList.isEmpty ? null : () {
                showNoBreakDeliverDialog(
                  context: context,
                  selectedUlds: selectedList,
                  dark: dark,
                  onSuccess: () {
                    setState(() {
                      _selectedUlds.clear();
                    });
                  },
                );
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send ULD', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366f1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnInfo(String label, String value, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: dark ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
