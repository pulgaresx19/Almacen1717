import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage;
import 'coordinator_v2_logic.dart';
import 'coordinator_v2_report_drawer.dart';

class CoordinatorV2Footer extends StatefulWidget {
  final bool dark;
  final CoordinatorV2Logic logic;

  const CoordinatorV2Footer({super.key, required this.dark, required this.logic});

  @override
  State<CoordinatorV2Footer> createState() => _CoordinatorV2FooterState();
}

class _CoordinatorV2FooterState extends State<CoordinatorV2Footer> {
  bool get dark => widget.dark;
  CoordinatorV2Logic get logic => widget.logic;

  Widget _buildTotalStat(String label, int rem, int total, Color color, {VoidCallback? onTap}) {
    final body = Column(
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

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          splashColor: color.withAlpha(30),
          highlightColor: color.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: body,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: body,
    );
  }

  void _showDiscrepanciesDrawer(BuildContext context) {
    logic.resetVerificationState();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: dark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 16,
            child: AnimatedBuilder(
              animation: logic,
              builder: (context, _) {
                // Determine raw local discrepancies (State 0 info)
                int totalLocalDiscrepancies = logic.ulds.fold(0, (sum, uld) {
                  if (uld['discrepancies_summary'] is List) {
                    return sum + (uld['discrepancies_summary'] as List).length;
                  }
                  return sum;
                });

                List<Map<String, dynamic>> localDiscrepancies = [];
                for (var uld in logic.ulds) {
                  final summary = uld['discrepancies_summary'];
                  if (summary is List) {
                    for (var d in summary) {
                      localDiscrepancies.add({
                        'uld_number': uld['uld_number'],
                        'awb': d['awb'],
                        'amount': d['amount'],
                        'type': d['type'],
                      });
                    }
                  }
                }

                if (logic.verificationState == 2) {
                  // SUCCESS STATE
                  return Container(
                    width: 380,
                    height: double.infinity,
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10b981).withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 70),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          appLanguage.value == 'es' ? '¡Verificación Completa!' : 'Verification Complete!',
                          style: TextStyle(
                            color: dark ? Colors.white : Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appLanguage.value == 'es' 
                            ? 'Este vuelo ha sido cotejado completamente.' 
                            : 'This flight is fully cross-checked.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 15),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10b981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              appLanguage.value == 'es' ? 'Cerrar' : 'Close',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }

                return Container(
                  width: 380,
                  height: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: logic.verificationState == 3 
                                  ? const Color(0xFFF59E0B).withAlpha(25) 
                                  : const Color(0xFFEF4444).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              logic.verificationState == 3 ? Icons.fact_check_rounded : Icons.warning_amber_rounded, 
                              color: logic.verificationState == 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444), 
                              size: 24
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  logic.verificationState == 3
                                      ? (appLanguage.value == 'es' ? 'Reporte Final' : 'Final Report')
                                      : (appLanguage.value == 'es' ? 'Discrepancias de Vuelo' : 'Flight Discrepancies'),
                                  style: TextStyle(
                                    color: dark ? Colors.white : Colors.black87,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  logic.verificationState == 3
                                      ? '${logic.finalDiscrepancies.length} ${appLanguage.value == 'es' ? 'pendientes por justificar' : 'pending justifications'}'
                                      : '$totalLocalDiscrepancies ${appLanguage.value == 'es' ? 'ítems locales detectados' : 'local items detected'}',
                                  style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: dark ? Colors.white70 : Colors.black54),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(height: 1, thickness: 1, color: dark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                      const SizedBox(height: 24),
                      
                      // CONTENT
                      Expanded(
                        child: logic.verificationState == 1
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
                            : logic.verificationState == 3
                                ? ListView.builder(
                                    itemCount: logic.finalDiscrepancies.length,
                                    itemBuilder: (context, index) {
                                      final d = logic.finalDiscrepancies[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: dark ? const Color(0xFF1E293B) : Colors.white,
                                          border: Border.all(color: const Color(0xFFF59E0B).withAlpha(100)),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'AWB: ${d['awb_number']}',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: dark ? Colors.white : Colors.black87, fontSize: 15),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEF4444).withAlpha(25),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    '${d['diff']} PCs ${d['type']}',
                                                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: d['reportCtrl'] as TextEditingController,
                                              style: TextStyle(color: dark ? Colors.white : Colors.black87, fontSize: 14),
                                              maxLines: 2,
                                              decoration: InputDecoration(
                                                hintText: appLanguage.value == 'es' ? 'Justifique esta discrepancia...' : 'Justify this discrepancy...',
                                                hintStyle: const TextStyle(color: Color(0xFF64748b), fontSize: 14),
                                                filled: true,
                                                fillColor: dark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                                contentPadding: const EdgeInsets.all(12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: localDiscrepancies.length,
                                    itemBuilder: (context, index) {
                                      final d = localDiscrepancies[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: dark ? const Color(0xFF1E293B) : Colors.white,
                                          border: Border.all(color: dark ? Colors.white.withAlpha(15) : Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'AWB: ${d['awb']}',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: dark ? Colors.white : Colors.black87, fontSize: 15),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEF4444).withAlpha(25),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    '${d['amount']} PCs ${d['type']}',
                                                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF94a3b8)),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'ULD: ${d['uld_number'] ?? '-'}',
                                                  style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      
                      const SizedBox(height: 16),
                      // BOTTOM BUTTON
                      Builder(
                        builder: (context) {
                          if (logic.verificationState == 3) {
                            bool canSubmit = logic.allReportsFilled;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: canSubmit ? () {
                                  logic.submitFinalReport();
                                } : null,
                                icon: const Icon(Icons.send_rounded, size: 20),
                                label: Text(
                                  appLanguage.value == 'es' ? 'Enviar Reporte y Cerrar' : 'Submit Report & Close',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canSubmit ? const Color(0xFF6366f1) : (dark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
                                  foregroundColor: canSubmit ? Colors.white : (dark ? Colors.white54 : Colors.black54),
                                  disabledBackgroundColor: dark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                                  disabledForegroundColor: dark ? Colors.white54 : Colors.black54,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            );
                          }

                          int tItems = logic.ulds.length;
                          int cItems = logic.ulds.where((u) => u['time_checked'] != null && u['time_checked'].toString().isNotEmpty).length;
                          bool allReady = tItems > 0 && cItems == tItems;
                          
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (allReady && logic.verificationState != 1) 
                                ? () => logic.verifyFlightDiscrepancies() 
                                : null,
                              icon: Icon(allReady ? Icons.check_circle_outline : Icons.lock_outline, size: 20),
                              label: Text(
                                allReady 
                                    ? (appLanguage.value == 'es' ? 'Verificar por discrepancias' : 'Verify all discrepancies')
                                    : (appLanguage.value == 'es' ? 'Revise todos los ULDs primero' : 'Check all ULDs first'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: allReady ? const Color(0xFF6366f1) : (dark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
                                foregroundColor: allReady ? Colors.white : (dark ? Colors.white54 : Colors.black54),
                                disabledBackgroundColor: dark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                                disabledForegroundColor: dark ? Colors.white54 : Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                );
              }
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

  void _showLocationRequiredDialog(BuildContext context, CoordinatorV2Logic logic) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: ListenableBuilder(
                listenable: logic,
                builder: (context, child) {
                  final awbs = logic.locationRequiredAwbs;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(appLanguage.value == 'es' ? 'Locaciones Requeridas' : 'Required Locations', style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                           IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), color: dark ? Colors.white54 : Colors.black54),
                        ],
                       ),
                       const SizedBox(height: 16),
                       if (awbs.isEmpty)
                         Padding(
                           padding: const EdgeInsets.all(32),
                           child: Center(child: Text(appLanguage.value == 'es' ? 'No hay items con locación especial.' : 'No items with required location.', style: const TextStyle(color: Colors.grey))),
                         )
                       else
                         Flexible(
                           child: ListView.separated(
                             shrinkWrap: true,
                             itemCount: awbs.length,
                             separatorBuilder: (context, index) => Divider(color: dark ? Colors.white12 : Colors.black12, height: 1),
                             itemBuilder: (context, index) {
                               final a = awbs[index];
                               final isConfirmed = a['is_location_confirmed'] == true;
                               final String reqLoc = a['required_location']?.toString() ?? 'N/A';
                               final awbNum = a['awbs'] != null ? a['awbs']['awb_number']?.toString() ?? 'Unknown' : 'Unknown';
                               final pieces = a['awbs'] != null ? a['awbs']['total_pieces']?.toString() ?? '-' : '-';
                               return Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 12),
                                 child: Row(
                                   children: [
                                      Icon(isConfirmed ? Icons.check_circle_rounded : Icons.warning_amber_rounded, size: 24, color: isConfirmed ? const Color(0xFF10b981) : const Color(0xFFf59e0b)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('AWB: $awbNum', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text('Pieces: $pieces', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isConfirmed ? const Color(0xFF10b981) : const Color(0xFFf59e0b)).withAlpha(25),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: (isConfirmed ? const Color(0xFF10b981) : const Color(0xFFf59e0b)).withAlpha(50)),
                                        ),
                                        child: Text(reqLoc, style: TextStyle(color: isConfirmed ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                   ],
                                 ),
                               );
                             },
                           ),
                         ),
                    ],
                  );
                }
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color borderC = dark ? Colors.white.withAlpha(20) : Colors.grey.shade300;
    
    int totalItems = logic.ulds.length;
    int checkedItems = logic.ulds.where((u) => u['time_checked'] != null && u['time_checked'].toString().isNotEmpty).length;
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
                    _buildTotalStat('Priority', 
                      logic.ulds.where((u) => u['is_priority'] == true && u['time_checked'] != null && u['time_checked'].toString().isNotEmpty).length, 
                      logic.ulds.where((u) => u['is_priority'] == true).length, 
                      const Color(0xFFF59E0B) // Orange
                    ),
                    Builder(
                      builder: (ctx) {
                        int locTotal = logic.locationRequiredAwbs.length;
                        int locConfirmed = logic.locationRequiredAwbs.where((a) => a['is_location_confirmed'] == true).length;
                        return _buildTotalStat(
                          appLanguage.value == 'es' ? 'Locación Req.' : 'Req. Location',
                          locConfirmed,
                          locTotal,
                          const Color(0xFF38bdf8),
                          onTap: () {
                            _showLocationRequiredDialog(context, logic);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 16), color: borderC),
              Builder(
                builder: (context) {
                  int totalDiscrepancies = logic.ulds.fold(0, (sum, uld) {
                    if (uld['discrepancies_summary'] is List) {
                      return sum + (uld['discrepancies_summary'] as List).length;
                    }
                    return sum;
                  });

                  bool flightIsCheckedInDb = false; 
                  if (selectedFlight != null) {
                    flightIsCheckedInDb = selectedFlight['is_checked'] == true;
                  }
                  bool isVerified = logic.verificationState == 2;
                  bool allLocalUldsChecked = totalItems > 0 && checkedItems == totalItems;

                  String buttonText;
                  Widget buttonIconWidget;
                  Color buttonColor;
                  VoidCallback? onBtnPressed;

                  if (flightIsCheckedInDb) {
                    buttonText = appLanguage.value == 'es' ? 'Vuelo Finalizado' : 'Flight Checked';
                    buttonIconWidget = const Icon(Icons.done_all, size: 20);
                    buttonColor = const Color(0xFF10b981); // green
                    onBtnPressed = null;
                  } else if (isVerified) {
                    buttonText = appLanguage.value == 'es' ? 'Marcar como Chequeado' : 'Mark Flight as Checked';
                    buttonIconWidget = const Icon(Icons.check_circle_rounded, size: 20);
                    buttonColor = const Color(0xFF10b981);
                    onBtnPressed = () => logic.markFlightAsChecked();
                  } else if (allLocalUldsChecked) {
                    if (totalDiscrepancies > 0) {
                      buttonText = appLanguage.value == 'es' ? 'Verificar Discrepancias' : 'Verify Discrepancies';
                      buttonIconWidget = Badge(
                        label: Text('$totalDiscrepancies', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: Colors.red.shade900,
                        child: const Icon(Icons.warning_amber_rounded, size: 20),
                      );
                      buttonColor = const Color(0xFFef4444); // red
                      onBtnPressed = () => _showDiscrepanciesDrawer(context);
                    } else {
                      buttonText = appLanguage.value == 'es' ? 'Marcar como Chequeado' : 'Mark Flight as Checked';
                      buttonIconWidget = const Icon(Icons.check_circle_rounded, size: 20);
                      buttonColor = const Color(0xFF10b981); // green
                      onBtnPressed = () => logic.markFlightAsChecked();
                    }
                  } else {
                    buttonText = appLanguage.value == 'es' ? 'ULDs Pendientes' : 'Pending ULDs';
                    buttonIconWidget = const Icon(Icons.lock_outline, size: 20);
                    buttonColor = dark ? Colors.white.withAlpha(20) : Colors.grey.shade300;
                    onBtnPressed = null;
                  }

                  final btn = ElevatedButton.icon(
                    onPressed: onBtnPressed,
                    icon: buttonIconWidget,
                    label: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          appLanguage.value == 'es' ? 'Marcar como Chequeado' : 'Mark Flight as Checked', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.transparent)
                        ),
                        Text(
                          buttonText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: onBtnPressed != null ? Colors.white : (dark ? Colors.white54 : Colors.black54),
                      disabledBackgroundColor: flightIsCheckedInDb ? Colors.green.withAlpha(dark ? 40 : 100) : buttonColor,
                      disabledForegroundColor: flightIsCheckedInDb ? (dark ? Colors.green.shade300 : Colors.green.shade700) : (dark ? Colors.white54 : Colors.black54),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  );

                  bool hasReport = selectedFlight != null && selectedFlight['final_discrepancy_report'] != null && (selectedFlight['final_discrepancy_report'] is List) && (selectedFlight['final_discrepancy_report'] as List).isNotEmpty;

                  if (hasReport) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        btn,
                        Positioned(
                          top: -6,
                          right: -6,
                          child: InkWell(
                            onTap: () => showReadonlyReportDrawer(context, selectedFlight!['final_discrepancy_report'] as List, dark),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366f1),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: const Icon(Icons.receipt_long, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  return btn;
                }
              ),
            ],
          ),
        )
      ],
    );
  }
}
