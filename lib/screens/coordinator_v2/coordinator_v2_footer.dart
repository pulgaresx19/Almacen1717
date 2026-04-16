import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage;
import 'coordinator_v2_logic.dart';

class CoordinatorV2Footer extends StatelessWidget {
  final bool dark;
  final CoordinatorV2Logic logic;

  const CoordinatorV2Footer({super.key, required this.dark, required this.logic});

  Widget _buildTotalStat(String label, int rem, int total, Color color) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$rem', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              TextSpan(text: ' / $total', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showDiscrepanciesDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: dark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 16,
            child: Container(
              width: 350,
              height: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                      const SizedBox(width: 8),
                      Text(
                        appLanguage.value == 'es' ? 'Discrepancias Totales' : 'Total Discrepancies',
                        style: TextStyle(
                          color: dark ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: ListView(
                      children: logic.ulds.map((uld) {
                        final list = uld['discrepancies_summary'] is List ? uld['discrepancies_summary'] as List : [];
                        if (list.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ULD: ${uld['uld_number'] ?? '-'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ...list.map((d) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'AWB: ${d['awb']}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: dark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                    Text(
                                      '${d['amount']} ${d['type']}',
                                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      int tItems = logic.ulds.length;
                      int cItems = logic.ulds.where((u) => u['time_checked'] != null && u['time_checked'].toString().isNotEmpty).length;
                      bool allReady = tItems > 0 && cItems == tItems;
                      
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: allReady ? () {} : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: dark ? Colors.white.withAlpha(20) : Colors.grey.shade300,
                            disabledForegroundColor: dark ? Colors.white30 : Colors.black26,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Verify all discrepancies',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color borderC = dark ? Colors.white.withAlpha(20) : Colors.grey.shade300;
    
    int totalItems = logic.ulds.length;
    int checkedItems = logic.ulds.where((u) => u['time_checked'] != null && u['time_checked'].toString().isNotEmpty).length;
    int totalDiscrepancies = logic.ulds.fold(0, (sum, uld) {
      if (uld['discrepancies_summary'] is List) {
        return sum + (uld['discrepancies_summary'] as List).length;
      }
      return sum;
    });

    Map<String, dynamic>? selectedFlight;
    if (logic.selectedFlightId != null) {
      try {
        selectedFlight = logic.flights.firstWhere((f) => f['id_flight']?.toString() == logic.selectedFlightId);
      } catch (_) {}
    }

    String startBreakStr = 'Start Break: -';
    if (selectedFlight != null && selectedFlight['start_break'] != null) {
      final dt = DateTime.tryParse(selectedFlight['start_break'].toString())?.toLocal();
      if (dt != null) {
        startBreakStr = 'Start Break: ${dt.day}/${dt.month} ${DateFormat('h:mm a').format(dt).toLowerCase()}';
      }
    }

    String endBreakStr = 'End Break: -';
    if (selectedFlight != null && selectedFlight['end_break'] != null) {
      final dt = DateTime.tryParse(selectedFlight['end_break'].toString())?.toLocal();
      if (dt != null) {
        endBreakStr = 'End Break: ${dt.day}/${dt.month} ${DateFormat('h:mm a').format(dt).toLowerCase()}';
      }
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 6),
                  Text(startBreakStr, style: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8), fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 6),
                  Text(endBreakStr, style: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderC),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTotalStat('Checked', checkedItems, totalItems, const Color(0xFF10b981)),
                    _buildTotalStat('No Break', 
                      logic.ulds.where((u) => u['is_break'] == false && u['time_checked'] != null).length, 
                      logic.ulds.where((u) => u['is_break'] == false).length, 
                      const Color(0xFFef4444)
                    ),
                    _buildTotalStat('Total', checkedItems, totalItems, const Color(0xFF6366f1)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 16), color: borderC),
              ElevatedButton.icon(
                onPressed: totalDiscrepancies > 0 
                    ? () => _showDiscrepanciesDrawer(context)
                    : ((totalItems > 0 && checkedItems == totalItems) ? () {} : null),
                icon: totalDiscrepancies > 0 
                  ? Badge(
                      label: Text('$totalDiscrepancies', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      backgroundColor: Colors.red.shade900,
                      child: const Icon(Icons.warning_amber_rounded, size: 20),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
                label: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('Mark Flight as Checked', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.transparent)),
                    Text(
                      totalDiscrepancies > 0 ? (appLanguage.value == 'es' ? 'Discrepancias' : 'Discrepancies') : 'Mark Flight as Checked',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: totalDiscrepancies > 0 ? const Color(0xFFef4444) : const Color(0xFF10b981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: totalDiscrepancies > 0 ? const Color(0xFFef4444).withAlpha(60) : const Color(0xFF10b981).withAlpha(60),
                  disabledForegroundColor: dark ? Colors.white.withAlpha(100) : Colors.black38,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
