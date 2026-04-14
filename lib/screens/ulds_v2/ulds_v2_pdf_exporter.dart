import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UldsV2PdfExporter {
  
  static Future<Uint8List> generateUldsPdf(List<Map<String, dynamic>> ulds, Map<String, dynamic> flightsMap) async {
    final pdf = pw.Document();

    for (var uldEditor in ulds) {
      final uld = Map<String, dynamic>.from(uldEditor);
      final uldId = uld['id_uld']?.toString() ?? '';
      
      List<Map<String, dynamic>> awbList = [];
      if (uldId.isNotEmpty) {
        try {
          final res = await Supabase.instance.client
              .from('awb_splits')
              .select('id_split, pieces, weight, remarks, is_new, is_not_found, awbs(*)')
              .eq('uld_id', uldId)
              .order('created_at', ascending: true);
          awbList = List<Map<String, dynamic>>.from(res);
        } catch (_) {}
      }
      
      _addDetailedUldPage(pdf, uld, awbList, flightsMap);
    }
    
    return pdf.save();
  }

  static Future<void> printUlds(List<Map<String, dynamic>> ulds, Map<String, dynamic> flightsMap) async {
    final pdfBytes = await generateUldsPdf(ulds, flightsMap);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'ulds_detailed_report_v2.pdf',
    );
  }

  static Future<void> downloadPdf(List<Map<String, dynamic>> ulds, Map<String, dynamic> flightsMap) async {
    final pdfBytes = await generateUldsPdf(ulds, flightsMap);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'ulds_detailed_report_v2.pdf');
  }

  static Future<void> printSingleUld(Map<String, dynamic> uld, List<Map<String, dynamic>> awbList, Map<String, dynamic> flightsMap) async {
     final pdfBytes = await generateDetailedUldPdf(uld, awbList, flightsMap);
     await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'uld_detailed_report_v2.pdf',
    );
  }

  static Future<Uint8List> generateDetailedUldPdf(Map<String, dynamic> uld, List<Map<String, dynamic>> awbList, Map<String, dynamic> flightsMap) async {
    final pdf = pw.Document();
    _addDetailedUldPage(pdf, uld, awbList, flightsMap);
    return pdf.save();
  }

  static void _addDetailedUldPage(pw.Document pdf, Map<String, dynamic> uld, List<Map<String, dynamic>> awbList, Map<String, dynamic> flightsMap) {
    String formatDate(String? ts) {
       if (ts == null || ts.trim().isEmpty || ts == '-') return '';
       try {
         final dt = DateTime.parse(ts).toLocal();
         return DateFormat('MM/dd/yyyy').format(dt);
       } catch (_) {}
       return '';
    }

    final flightId = uld['id_flight']?.toString();
    String refFlight = 'Standalone ULD';
    String flightDate = '-';
    
    if (flightId != null && flightsMap.containsKey(flightId)) {
        final f = flightsMap[flightId];
        if (f != null) {
            refFlight = '${f['carrier'] ?? ''} ${f['number'] ?? ''}'.trim();
            flightDate = formatDate(f['date']?.toString());
        }
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
                      pw.Text('${uld['uld_number'] ?? '-'}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REF FLIGHT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(refFlight, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FLIGHT DATE', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(flightDate, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
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
                      pw.Text('${uld['pieces_total'] ?? 0}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('TOTAL WEIGHT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${uld['weight_total'] ?? 0} kg', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('TYPE', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text((uld['is_break'] == true) ? 'BREAK' : 'NO BREAK', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
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
                             pw.SizedBox(width: 95, child: pw.Text('AWB NUMBER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)))),
                             pw.SizedBox(width: 35, child: pw.Text('PCS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)), textAlign: pw.TextAlign.center)),
                             pw.SizedBox(width: 35, child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)), textAlign: pw.TextAlign.center)),
                             pw.SizedBox(width: 45, child: pw.Text('WEIGHT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)), textAlign: pw.TextAlign.center)),
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
                          final a = e.value as Map; // This is an awb_split struct
                          final awbNode = (a['awbs'] as Map<String, dynamic>?) ?? {};
                          final awbNum = awbNode['awb_number']?.toString() ?? awbNode['awb']?.toString() ?? '-';
                          final totalPcs = awbNode['total_pieces']?.toString() ?? awbNode['pieces']?.toString() ?? '0';
                          
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
                                            pw.SizedBox(width: 95, child: pw.Text(awbNum, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black))),
                                            pw.SizedBox(width: 35, child: pw.Text(a['pieces']?.toString() ?? '0', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black), textAlign: pw.TextAlign.center)),
                                            pw.SizedBox(width: 35, child: pw.Text(totalPcs, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black), textAlign: pw.TextAlign.center)),
                                            pw.SizedBox(width: 45, child: pw.Text('${a['weight'] ?? 0} kg', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black), textAlign: pw.TextAlign.center)),
                                            pw.Expanded(child: pw.Text(a['remarks']?.toString() ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black))),
                                            if (a['is_new'] == true) ...[
                                               pw.SizedBox(width: 4),
                                               pw.Container(
                                                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)), border: pw.Border.all(color: PdfColor.fromInt(0xFF3B82F6))),
                                                  child: pw.Text('NEW', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB))),
                                               )
                                            ],
                                            if (a['is_not_found'] == true) ...[
                                               pw.SizedBox(width: 4),
                                               pw.Container(
                                                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFEF2F2), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)), border: pw.Border.all(color: PdfColor.fromInt(0xFFFECACA))),
                                                  child: pw.Text('NOT FOUND', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFDC2626))),
                                               )
                                            ]
                                         ]
                                      )
                                   ),
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
}
