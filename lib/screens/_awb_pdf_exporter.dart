import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class AwbPdfExporter {
  static String _computeAwbStatus(Map<String, dynamic> u) {
    int deliveredPieces = 0;
    if (u['data-deliver'] != null) {
      if (u['data-deliver'] is List) {
        for (var item in u['data-deliver']) {
          if (item is Map && item.containsKey('found')) {
            deliveredPieces += int.tryParse(item['found']?.toString() ?? '0') ?? 0;
          }
        }
      } else if (u['data-deliver'] is Map) {
        deliveredPieces = int.tryParse(u['data-deliver']['found']?.toString() ?? '0') ?? 0;
      }
    }
    
    final int totalValInt = int.tryParse(u['total']?.toString() ?? '0') ?? 0;
    if (deliveredPieces == totalValInt && totalValInt > 0) {
       return 'READY';
    } else if (deliveredPieces > 0) {
       return 'IN PROCESS';
    }
    return 'WAITING';
  }

  static Future<Uint8List> generateAwbsPdf(List<Map<String, dynamic>> awbs) async {
    final pdf = pw.Document();

    for (var awb in awbs) {
      _addDetailedAwbPage(pdf, awb);
    }
    
    return pdf.save();
  }

  static Future<void> printAwbs(List<Map<String, dynamic>> awbs) async {
    final pdfBytes = await generateAwbsPdf(awbs);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'awbs_detailed_report.pdf',
    );
  }

  static Future<void> downloadPdf(List<Map<String, dynamic>> awbs) async {
    final pdfBytes = await generateAwbsPdf(awbs);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'awbs_detailed_report.pdf');
  }

  static Future<Uint8List> generateDetailedAwbPdf(Map<String, dynamic> awb) async {
    final pdf = pw.Document();
    _addDetailedAwbPage(pdf, awb);
    return pdf.save();
  }

  static void _addDetailedAwbPage(pw.Document pdf, Map<String, dynamic> u) {

    String formatTime(String? ts) {
       if (ts == null || ts.trim().isEmpty || ts == '-') return '';
       if (ts.toUpperCase().contains('AM') || ts.toUpperCase().contains('PM')) return ts;
       try {
         if (ts.contains('T') || ts.contains('-')) {
           final dt = DateTime.parse(ts).toUtc();
           final chicago = dt.subtract(const Duration(hours: 5, minutes: 0));
           return DateFormat('hh:mm a').format(chicago).toUpperCase();
         } else {
           final parts = ts.trim().split(':');
           if (parts.length >= 2) {
              return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]))).toUpperCase();
           }
         }
       } catch (_) {}
       return ts;
    }

    String formatDate(String? ts) {
       if (ts == null || ts.trim().isEmpty || ts == '-') return '';
       try {
         if (ts.contains('T') || ts.contains('-')) {
           final dt = DateTime.parse(ts).toLocal();
           return DateFormat('MM/dd/yyyy').format(dt);
         }
       } catch (_) {}
       return '';
    }

    pw.Widget buildAuditColumn(String title, dynamic data) {
      Map<String, dynamic> rec = {};
      if (data is List && data.isNotEmpty) {
        rec = data.last is Map ? Map<String, dynamic>.from(data.last) : {};
      } else if (data is Map && data.isNotEmpty) {
        rec = Map<String, dynamic>.from(data);
      }
      
      String user = rec.isNotEmpty ? (rec['user']?.toString() ?? '-') : '-';
      String dateStr = rec.isNotEmpty ? formatDate(rec['date']?.toString()) : '';
      String timeStr = rec.isNotEmpty ? formatTime(rec['time']?.toString() ?? rec['time-receive']?.toString() ?? rec['time-delivery']?.toString() ?? rec['time-saved']?.toString()) : '-';
      String dateTime = '$dateStr $timeStr'.trim();
      if (dateTime.isEmpty || dateTime == '-') dateTime = '-';

      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
            pw.SizedBox(height: 4),
            pw.Text(user, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)), maxLines: 1),
            pw.SizedBox(height: 2),
            pw.Text(dateTime, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ]
        )
      );
    }
    
    // Compute details
    String awbNumber = u['AWB-number']?.toString() ?? '-';

    int expectedPieces = 0;
    double totalWeight = 0.0;
    if (u['data-AWB'] is List) {
      for (var item in u['data-AWB']) {
          expectedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
          totalWeight += double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
      }
    } else if (u['data-AWB'] is Map) {
          expectedPieces += int.tryParse(u['data-AWB']['pieces']?.toString() ?? '0') ?? 0;
          totalWeight += double.tryParse(u['data-AWB']['weight']?.toString() ?? '0') ?? 0.0;
    }

    int receivedPieces = 0;
    if (u['data-coordinator'] != null) {
      List dcList = [];
      if (u['data-coordinator'] is List) {
        dcList = u['data-coordinator'] as List;
      } else if (u['data-coordinator'] is Map && u['data-coordinator'].isNotEmpty) {
        dcList = [u['data-coordinator']];
      }
      
      for (var item in dcList) {
          if (item is Map) {
            if (item.containsKey('breakdown') && item['breakdown'] is Map) {
                Map breakdown = item['breakdown'];
                if (breakdown['AGI Skid'] is List) {
                  for (var val in breakdown['AGI Skid']) {
                      receivedPieces += int.tryParse(val.toString()) ?? 0;
                  }
                }
                for (String k in ['Pre Skid', 'Crate', 'Box', 'Other']) {
                  receivedPieces += int.tryParse(breakdown[k]?.toString() ?? '0') ?? 0;
                }
            } else {
                receivedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
            }
          }
      }
    }

    int deliveredPieces = 0;
    List deliverHistory = [];
    if (u['data-deliver'] != null) {
      if (u['data-deliver'] is List) {
        deliverHistory = u['data-deliver'] as List;
        for (var item in deliverHistory) {
          if (item is Map && item.containsKey('found')) {
            deliveredPieces += int.tryParse(item['found']?.toString() ?? '0') ?? 0;
          }
        }
      } else if (u['data-deliver'] is Map) {
        deliverHistory = [u['data-deliver']];
        deliveredPieces = int.tryParse(u['data-deliver']['found']?.toString() ?? '0') ?? 0;
      }
    }
    
    int remainingPieces = expectedPieces - deliveredPieces;
    if (remainingPieces < 0) remainingPieces = 0;

    String status = _computeAwbStatus(u);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // SUMMARY BOX
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('AWB NUMBER', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(awbNumber, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('STATUS', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(status, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: status == 'READY' ? PdfColor.fromInt(0xFF10B981) : (status == 'IN PROCESS' ? PdfColor.fromInt(0xFFF59E0B) : PdfColor.fromInt(0xFF64748B)))),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL WEIGHT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${totalWeight.toString().replaceAll(RegExp(r'\.$|\.0$'), '')} kg', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                ]
              )
            ),

            pw.SizedBox(height: 12),
            
            // SECONDARY BOX (PIECES)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('EXPECTED', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('$expectedPieces', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('RECEIVED', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('$receivedPieces', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('DELIVERED', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('$deliveredPieces', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('REMAINING', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('$remainingPieces', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                ]
              )
            ),
            
            pw.SizedBox(height: 16),
            pw.Text('DELIVERY HISTORY', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
            pw.SizedBox(height: 8),
            
            // DELIVERY TABLE
            pw.TableHelper.fromTextArray(
              headers: ['#', 'DRIVER', 'DO/HAWB', 'FOUND', 'STATUS', 'TIME'],
              data: deliverHistory.isEmpty ? [
                ['-', '-', '-', '-', '-', '-']
              ] : deliverHistory.asMap().entries.map((e) {
                 final idx = e.key;
                 final d = e.value as Map;
                 return [
                   '${idx + 1}',
                   d['driver']?.toString() ?? '-',
                   d['haWB']?.toString() ?? d['doNumber']?.toString() ?? '-',
                   d['found']?.toString() ?? '0',
                   d['status']?.toString() ?? '-',
                   _formatActionTime(d)
                 ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A), fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
              cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155)),
              cellHeight: 28,
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(),
                2: const pw.FlexColumnWidth(),
                3: const pw.FixedColumnWidth(45),
                4: const pw.FixedColumnWidth(55),
                5: const pw.FixedColumnWidth(65),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
            ),
          ];
        },
        footer: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (_hasAuditData(u)) ...[
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                         buildAuditColumn('RECEIVED', u['data-received']),
                         pw.Container(width: 1, height: 24, color: PdfColor.fromInt(0xFFE2E8F0)),
                         buildAuditColumn('CHECKED', u['data-checked']),
                         pw.Container(width: 1, height: 24, color: PdfColor.fromInt(0xFFE2E8F0)),
                         buildAuditColumn('SAVED', u['data-saved']),
                         pw.Container(width: 1, height: 24, color: PdfColor.fromInt(0xFFE2E8F0)),
                         buildAuditColumn('DELIVERED', u['data-deliver']),
                      ]
                    )
                  )
              ],
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              )
            ]
          );
        }
      )
    );
  }

  static String _formatActionTime(Map d) {
      if (d['time'] != null && d['time'].toString().isNotEmpty) {
          try {
             if (d['time'].toString().contains('T') || d['time'].toString().contains('-')) {
                 final dt = DateTime.parse(d['time'].toString()).toLocal();
                 return DateFormat('MM/dd hh:mm a').format(dt).toUpperCase();
             }
          } catch (_) {}
          return d['time'].toString();
      }
      return '-';
  }

  static bool _hasAuditData(Map<String, dynamic> uld) {
    bool hasData(dynamic d) {
       if (d == null) return false;
       if (d is Map) return d.isNotEmpty;
       if (d is List) return d.isNotEmpty;
       return false;
    }
    return hasData(uld['data-received']) || 
           hasData(uld['data-checked']) || 
           hasData(uld['data-saved']) || 
           hasData(uld['data-deliver']);
  }
}
