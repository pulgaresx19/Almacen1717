import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage;

void showReadonlyReportDrawer(BuildContext context, List<dynamic> reportParams, bool dark) {
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
          child: SizedBox(
            width: 380,
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: Border(bottom: BorderSide(color: dark ? Colors.white.withAlpha(20) : Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF6366f1)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appLanguage.value == 'es' ? 'Reporte de Vuelo' : 'Flight Report', style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                            Builder(
                              builder: (context) {
                                String reporter = '';
                                String timeFmt = '';
                                if (reportParams.isNotEmpty) {
                                  reporter = reportParams[0]['reported_by']?.toString() ?? '';
                                  final dateStr = reportParams[0]['reported_at']?.toString() ?? '';
                                  if (dateStr.isNotEmpty) {
                                    try {
                                      final dt = DateTime.parse(dateStr).toLocal();
                                      timeFmt = DateFormat('MMM d, h:mm a').format(dt);
                                    } catch (_) {}
                                  }
                                }
                                String subtitle = reporter.isNotEmpty ? reporter : (appLanguage.value == 'es' ? 'Solo Lectura' : 'Read-Only');
                                if (timeFmt.isNotEmpty && reporter.isNotEmpty) {
                                  subtitle += ' • $timeFmt';
                                } else if (timeFmt.isNotEmpty) {
                                  subtitle += ' - $timeFmt';
                                }
                                return Text(subtitle, style: const TextStyle(color: Color(0xFF10b981), fontSize: 13, fontWeight: FontWeight.w600));
                              }
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: reportParams.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final d = reportParams[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dark ? Colors.white.withAlpha(20) : Colors.grey.shade300),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('AWB: ${d['awb_number']}', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: d['type'] == 'SHORT' ? const Color(0xFFEF4444).withAlpha(25) : const Color(0xFFF59E0B).withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${d['amount']} ${d['type']}',
                                    style: TextStyle(
                                      color: d['type'] == 'SHORT' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.bold, fontSize: 12
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.black26 : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Expected', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        Text('${d['expected']}', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.black26 : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Checked', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        Text('${d['checked']}', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (d['comment'] != null && d['comment'].toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (dark ? const Color(0xFF3b82f6) : const Color(0xFFbfdbfe)).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: (dark ? const Color(0xFF3b82f6) : const Color(0xFFbfdbfe)).withAlpha(50)),
                                ),
                                child: Text('"${d['comment']}"', style: TextStyle(color: dark ? const Color(0xFF93c5fd) : const Color(0xFF1d4ed8), fontStyle: FontStyle.italic, fontSize: 13)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
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
