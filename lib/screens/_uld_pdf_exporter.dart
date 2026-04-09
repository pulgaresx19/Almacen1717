import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UldPdfExporter {
  static Future<Map<String, Map<String, dynamic>>> _fetchAwbDetails(List awbList) async {
    List<String> awbNumbers = awbList.map((a) => (a['AWB-number']?.toString() ?? a['awb_number']?.toString()) ?? '').where((n) => n.isNotEmpty).toList();
    if (awbNumbers.isEmpty) return {};
    
    Map<String, Map<String, dynamic>> dbAwbs = {};
    try {
      final res = await Supabase.instance.client.from('AWB').select('AWB-number, data-coordinator, data-location').inFilter('AWB-number', awbNumbers);
      for (var r in res) {
         dbAwbs[r['AWB-number'].toString()] = r;
      }
    } catch (_) {}
    return dbAwbs;
  }

  static Future<Uint8List> generateUldsPdf(List<Map<String, dynamic>> ulds) async {
    final pdf = pw.Document();

    for (var uldEditor in ulds) {
      final uld = Map<String, dynamic>.from(uldEditor);
      // Determine AWBs
      List awbList = [];
      if (uld['data-ULD'] is List) {
         awbList = uld['data-ULD'] as List;
      }
      final dbAwbs = await _fetchAwbDetails(awbList);
      _addDetailedUldPage(pdf, uld, awbList, dbAwbs);
    }
    
    return pdf.save();
  }

  static Future<void> printUlds(List<Map<String, dynamic>> ulds) async {
    final pdfBytes = await generateUldsPdf(ulds);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'ulds_detailed_report.pdf',
    );
  }

  static Future<void> downloadPdf(List<Map<String, dynamic>> ulds) async {
    final pdfBytes = await generateUldsPdf(ulds);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'ulds_detailed_report.pdf');
  }

  static Future<Uint8List> generateDetailedUldPdf(Map<String, dynamic> uld, List awbList) async {
    final pdf = pw.Document();
    final dbAwbs = await _fetchAwbDetails(awbList);
    _addDetailedUldPage(pdf, uld, awbList, dbAwbs);
    return pdf.save();
  }

  static void _addDetailedUldPage(pw.Document pdf, Map<String, dynamic> uld, List awbList, Map<String, Map<String, dynamic>> dbAwbs) {
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
                      pw.Text('ULD NUMBER', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${uld['ULD-number'] ?? '-'}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REF FLIGHT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(uld['refCarrier'] == null ? 'Standalone ULD' : '${uld['refCarrier']} ${uld['refNumber'] ?? ''}'.trim(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FLIGHT DATE', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(formatDate(uld['refDate']?.toString()), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                ]
              )
            ),

            pw.SizedBox(height: 12),
            
            // SECONDARY BOX
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
                      pw.Text('TOTAL AWB', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${awbList.length}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('TOTAL PCS', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${uld['pieces'] ?? 0}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('TOTAL WEIGHT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${uld['weight'] ?? 0} kg', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('TYPE', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text((uld['isBreak'] == true || uld['isBreak']?.toString().toLowerCase() == 'true') ? 'BREAK' : 'NO BREAK', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                ]
              )
            ),
            
            pw.SizedBox(height: 16),
            pw.Text('ASSOCIATED AWBs', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
            pw.SizedBox(height: 8),

            // AWB LIST WITH CHILD ROWS
            pw.Container(
              decoration: pw.BoxDecoration(
                 border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Column(
                 children: [
                    // HEADER ROW
                    pw.Container(
                       color: PdfColor.fromInt(0xFFF1F5F9),
                       padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                       child: pw.Row(
                          children: [
                             pw.SizedBox(width: 25, child: pw.Text('#', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)), textAlign: pw.TextAlign.center)),
                             pw.SizedBox(width: 110, child: pw.Text('AWB NUMBER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)))),
                             pw.SizedBox(width: 40, child: pw.Text('PCS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)), textAlign: pw.TextAlign.center)),
                             pw.SizedBox(width: 60, child: pw.Text('WEIGHT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)), textAlign: pw.TextAlign.center)),
                             pw.Expanded(child: pw.Text('REMARKS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)))),
                          ]
                       )
                    ),
                    // DATA ROWS
                    if (awbList.isEmpty)
                       pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('No AWBs associated', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                       )
                    else
                       ...awbList.asMap().entries.map((e) {
                          final idx = e.key;
                          final a = e.value as Map;
                          String awbNum = a['AWB-number']?.toString() ?? a['awb_number']?.toString() ?? '-';
                          
                          int agiSkidsCount = 0;
                          int agiSkidsPieces = 0;
                          int preSkid = 0;
                          int crate = 0;
                          int box = 0;
                          int other = 0;
                          String locationStr = '';
                          bool hasCoordData = false;
                          bool isNotFound = false;
                          bool isAdded = false;
                          String discrepancyStr = '';

                          if (dbAwbs.containsKey(awbNum)) {
                             final dbData = dbAwbs[awbNum]!;

                             if (dbData['data-AWB'] != null) {
                                List awbList = dbData['data-AWB'] is List ? dbData['data-AWB'] : [dbData['data-AWB']];
                                for (var item in awbList) {
                                   if (item is Map && item['refCarrier'] == uld['refCarrier'] && item['refNumber'] == uld['refNumber'] && (item['refDate'] == uld['refDate'] || uld['refDate'] == null)) {
                                      if (item['isNew'] == true) {
                                         isAdded = true;
                                         hasCoordData = true;
                                      }
                                   }
                                }
                             }

                             if (dbData['data-coordinator'] != null) {
                                List dcList = dbData['data-coordinator'] is List ? dbData['data-coordinator'] : [dbData['data-coordinator']];
                                for (var item in dcList) {
                                   if (item is Map && item['refCarrier'] == uld['refCarrier'] && item['refNumber'] == uld['refNumber'] && (item['refDate'] == uld['refDate'] || uld['refDate'] == null)) {
                                      if (item['discrepancy'] != null && item['discrepancy']['confirmed'] == true) {
                                         if (item['discrepancy']['notFound'] == true) {
                                            isNotFound = true;
                                            hasCoordData = true;
                                         } else {
                                            int exp = int.tryParse(item['discrepancy']['expected']?.toString() ?? '0') ?? 0;
                                            int rec = int.tryParse(item['discrepancy']['received']?.toString() ?? '0') ?? 0;
                                            if (exp != rec) {
                                                int diff = (exp - rec).abs();
                                                String term = exp > rec ? 'SHORT' : 'OVER';
                                                discrepancyStr = '$diff PCs $term';
                                                hasCoordData = true;
                                            }
                                         }
                                      }
                                      if (item.containsKey('breakdown') && item['breakdown'] is Map) {
                                         hasCoordData = true;
                                         Map b = item['breakdown'];
                                         if (b['AGI Skid'] is List) {
                                            agiSkidsCount = (b['AGI Skid'] as List).length;
                                            for (var val in (b['AGI Skid'] as List)) {
                                               agiSkidsPieces += int.tryParse(val.toString()) ?? 0;
                                            }
                                         }
                                         preSkid = int.tryParse(b['Pre Skid']?.toString() ?? '0') ?? 0;
                                         crate = int.tryParse(b['Crate']?.toString() ?? '0') ?? 0;
                                         box = int.tryParse(b['Box']?.toString() ?? '0') ?? 0;
                                         other = int.tryParse(b['Other']?.toString() ?? '0') ?? 0;
                                      }
                                   }
                                }
                             }

                             if (dbData['data-location'] != null) {
                                List locList = dbData['data-location'] is List ? dbData['data-location'] : [dbData['data-location']];
                                for (var item in locList) {
                                   if (item is Map && item['refCarrier'] == uld['refCarrier'] && item['refNumber'] == uld['refNumber'] && (item['refDate'] == uld['refDate'] || uld['refDate'] == null)) {
                                      if (item.containsKey('manual_entry') && item['manual_entry'] is List) {
                                         locationStr = (item['manual_entry'] as List).join(', ');
                                      } else if (item.containsKey('itemLocations') && item['itemLocations'] is Map) {
                                         final Map itemLocs = item['itemLocations'];
                                         locationStr = itemLocs.values.where((v) => v.toString().trim().isNotEmpty).toSet().join(', ');
                                      }
                                      if (locationStr.isNotEmpty && locationStr != '-') hasCoordData = true;
                                   }
                                }
                             }
                          }

                          return pw.Container(
                             decoration: pw.BoxDecoration(
                                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                             ),
                             child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                   // MAIN ROW
                                   pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: pw.Row(
                                         crossAxisAlignment: pw.CrossAxisAlignment.center,
                                         children: [
                                            pw.SizedBox(width: 25, child: pw.Text('${idx + 1}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black), textAlign: pw.TextAlign.center)),
                                            pw.SizedBox(width: 110, child: pw.Text(awbNum, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black))),
                                            pw.SizedBox(width: 40, child: pw.Text(a['pieces']?.toString() ?? '0', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black), textAlign: pw.TextAlign.center)),
                                            pw.SizedBox(width: 60, child: pw.Text('${a['weight'] ?? 0} kg', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black), textAlign: pw.TextAlign.center)),
                                            pw.Expanded(child: pw.Text(a['remarks']?.toString() ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black))),
                                            if (a['isNew'] == true || isAdded) ...[
                                               pw.SizedBox(width: 4),
                                               pw.Container(
                                                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)), border: pw.Border.all(color: PdfColor.fromInt(0xFF3B82F6))),
                                                  child: pw.Text('NEW', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB))),
                                               )
                                            ],
                                         ]
                                      )
                                   ),
                                   // CHILD ROW
                                   if (hasCoordData)
                                      pw.Container(
                                         margin: const pw.EdgeInsets.only(left: 35, right: 4, bottom: 6),
                                         padding: const pw.EdgeInsets.all(6),
                                         decoration: pw.BoxDecoration(
                                            color: PdfColor.fromInt(0xFFF8FAFC),
                                            border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                         ),
                                         child: pw.Row(
                                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                                            children: [
                                               pw.Expanded(
                                                  flex: 1,
                                                  child: pw.Column(
                                                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                     children: [
                                                         pw.Row(
                                                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                                                            children: [
                                                               pw.Text('BREAKDOWN', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                                                               if (isNotFound) ...[
                                                                  pw.SizedBox(width: 4),
                                                                  pw.Container(
                                                                     padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                                     decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFEF2F2), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)), border: pw.Border.all(color: PdfColor.fromInt(0xFFFECACA))),
                                                                     child: pw.Text('NOT FOUND', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFDC2626))),
                                                                  )
                                                               ] else if (discrepancyStr.isNotEmpty) ...[
                                                                  pw.SizedBox(width: 4),
                                                                  pw.Container(
                                                                     padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                                     decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF7ED), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)), border: pw.Border.all(color: PdfColor.fromInt(0xFFFED7AA))),
                                                                     child: pw.Text(discrepancyStr, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFEA580C))),
                                                                  )
                                                               ]
                                                            ]
                                                         ),
                                                         pw.SizedBox(height: 4),
                                                         if (isNotFound)
                                                            pw.Text('Record marked as Not Found.', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFDC2626), fontWeight: pw.FontWeight.bold))
                                                         else
                                                            pw.Wrap(
                                                               spacing: 8,
                                                               runSpacing: 4,
                                                               children: [
                                                                  if (agiSkidsCount > 0) pw.Text('AGI Skid: $agiSkidsCount ($agiSkidsPieces pcs)', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155))),
                                                                  if (preSkid > 0) pw.Text('Pre Skid: $preSkid', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155))),
                                                                  if (crate > 0) pw.Text('Crate: $crate', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155))),
                                                                  if (box > 0) pw.Text('Box: $box', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155))),
                                                                  if (other > 0) pw.Text('Other: $other', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155))),
                                                                  if (agiSkidsCount == 0 && preSkid == 0 && crate == 0 && box == 0 && other == 0) pw.Text('-', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155))),
                                                               ]
                                                            )
                                                     ]
                                                  )
                                               ),
                                               if (locationStr.isNotEmpty) ...[
                                                  pw.SizedBox(width: 8),
                                                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                                                  pw.SizedBox(width: 8),
                                                  pw.Expanded(
                                                     flex: 1,
                                                     child: pw.Column(
                                                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                        children: [
                                                           pw.Text('LOCATION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                                                           pw.SizedBox(height: 4),
                                                           pw.Text(locationStr, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                                                        ]
                                                     )
                                                  )
                                               ]
                                            ]
                                         )
                                      )
                                ]
                             )
                           );
                       })
                 ]
              )
            ),
          ];
        },
        footer: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (_hasAuditData(uld)) ...[
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
                         buildAuditColumn('RECEIVED', uld['data-received']),
                         pw.Container(width: 1, height: 24, color: PdfColor.fromInt(0xFFE2E8F0)),
                         buildAuditColumn('CHECKED', uld['data-checked']),
                         pw.Container(width: 1, height: 24, color: PdfColor.fromInt(0xFFE2E8F0)),
                         buildAuditColumn('SAVED', uld['data-saved']),
                         pw.Container(width: 1, height: 24, color: PdfColor.fromInt(0xFFE2E8F0)),
                         buildAuditColumn('DELIVERED', uld['data-delivery']),
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
           hasData(uld['data-delivery']);
  }
}
