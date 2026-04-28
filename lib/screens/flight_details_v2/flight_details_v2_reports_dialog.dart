import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;

Future<void> showFlightReportsDialog(BuildContext context, Map<String, dynamic> flight, bool dark) {
  return showDialog(
    context: context,
    builder: (ctx) => FlightReportsDialogComponent(flight: flight, dark: dark),
  );
}

class FlightReportsDialogComponent extends StatelessWidget {
  final Map<String, dynamic> flight;
  final bool dark;

  const FlightReportsDialogComponent({super.key, required this.flight, required this.dark});

  @override
  Widget build(BuildContext context) {
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);
    final bgCard = dark ? const Color(0xFF0f172a) : Colors.white;
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    final discrepancyReport = flight['final_discrepancy_report'];
    
    dynamic parsedData;
    if (discrepancyReport != null) {
      if (discrepancyReport is Map || discrepancyReport is List) {
        parsedData = discrepancyReport;
      } else if (discrepancyReport is String && discrepancyReport.isNotEmpty && discrepancyReport != 'null') {
        try {
          parsedData = jsonDecode(discrepancyReport);
        } catch (e) {
          // Ignore
        }
      }
    }
    
    bool isEmpty = parsedData == null || (parsedData is Map && parsedData.isEmpty) || (parsedData is List && parsedData.isEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderC, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_rounded, color: Colors.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        appLanguage.value == 'es' ? 'Reporte de Discrepancias' : 'Discrepancy Report',
                        style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textS),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Body
            Flexible(
              child: isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_late_rounded, color: textS.withAlpha(100), size: 64),
                          const SizedBox(height: 16),
                          Text(
                            appLanguage.value == 'es' ? 'No hay reporte disponible' : 'No report available',
                            style: TextStyle(color: textS, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (parsedData is Map)
                            ...parsedData.entries.map((entry) => _buildCard(entry.key.toString(), entry.value, textP, textS, dark, borderC))
                          else if (parsedData is List)
                            ...parsedData.asMap().entries.map((entry) => _buildCard('Discrepancy #${entry.key + 1}', entry.value, textP, textS, dark, borderC))
                          else
                            _buildCard('Report Details', parsedData, textP, textS, dark, borderC)
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, dynamic value, Color textP, Color textS, bool dark, Color borderC) {
    if (value is Map && value.containsKey('awb_number')) {
      final awb = value['awb_number']?.toString() ?? 'Unknown';
      final expected = value['expected'] ?? 0;
      final checked = value['checked'] ?? 0;
      final type = value['type']?.toString() ?? 'Unknown';
      final amount = value['amount'] ?? 0;
      final comment = value['comment']?.toString() ?? '';
      final user = value['reported_by']?.toString() ?? 'System';
      final rawDate = value['reported_at']?.toString() ?? '';
      
      String dateStr = rawDate;
      if (rawDate.isNotEmpty) {
         final dt = DateTime.tryParse(rawDate)?.toLocal();
         if (dt != null) {
           dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
         }
      }

      Color typeColor = Colors.orangeAccent;
      if (type == 'OVER' || type == 'NEW') typeColor = Colors.greenAccent;
      if (type == 'SHORT' || type == 'NOT FOUND') typeColor = Colors.redAccent;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderC),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Row(
                   children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.blueAccent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.blueAccent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        awb,
                        style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                   ],
                 ),
                 Row(
                   children: [
                     Icon(Icons.access_time_rounded, color: textS, size: 14),
                     const SizedBox(width: 6),
                     Text(dateStr, style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w500)),
                   ],
                 ),
               ],
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 Icon(Icons.person_outline_rounded, color: textS, size: 16),
                 const SizedBox(width: 6),
                 Text(user, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w600)),
               ],
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(child: _buildStatBox('Expected', expected.toString(), textP, dark, borderC)),
                 const SizedBox(width: 12),
                 Expanded(child: _buildStatBox('Checked', checked.toString(), textP, dark, borderC)),
                 const SizedBox(width: 12),
                 Expanded(
                   child: _buildStatBox(
                     'Discrepancy', 
                     '${type == 'OVER' || type == 'NEW' ? '+' : '-'}$amount ($type)', 
                     typeColor, dark, borderC, isHighlighted: true
                   ),
                 ),
               ],
             ),
             if (comment.isNotEmpty) ...[
               const SizedBox(height: 16),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: dark ? Colors.black.withAlpha(50) : Colors.white,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: borderC.withAlpha(50)),
                 ),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Icon(Icons.comment_rounded, color: textS, size: 16),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         comment,
                         style: TextStyle(color: textP.withAlpha(200), fontSize: 13, height: 1.4),
                       ),
                     ),
                   ],
                 ),
               ),
             ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(color: const Color(0xFF6366f1), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildValueWidget(value, textP, dark, borderC),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, bool dark, Color borderC, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withAlpha(20) : (dark ? Colors.black.withAlpha(40) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isHighlighted ? color.withAlpha(50) : borderC.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(color: isHighlighted ? color.withAlpha(200) : const Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildValueWidget(dynamic value, Color textP, bool dark, Color borderC) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.key}: ', style: TextStyle(color: textP.withAlpha(150), fontWeight: FontWeight.w600, fontSize: 14)),
                Expanded(child: Text('${e.value}', style: TextStyle(color: textP, fontSize: 14))),
              ],
            ),
          );
        }).toList(),
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.map((item) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dark ? Colors.black.withAlpha(50) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderC.withAlpha(50)),
              ),
              child: _buildValueWidget(item, textP, dark, borderC),
            ),
          );
        }).toList(),
      );
    }
    return Text(
      value.toString(),
      style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }
}
