import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class FlightsV2UldPdfExporter {
  static Future<Uint8List> generateUldPdf(Map<String, dynamic> flight, List<Map<String, dynamic>> ulds) async {
    final pdf = pw.Document();

    for (var uld in ulds) {
      List awbsList = [];
      
      if (uld['awb_splits'] != null && uld['awb_splits'] is List) {
        awbsList = List.from(uld['awb_splits']);
      } else {
        final uldId = uld['id_uld']?.toString() ?? '';
        if (uldId.isNotEmpty) {
          try {
            final res = await Supabase.instance.client
                .from('awb_splits')
                .select('*, awbs(*)')
                .eq('uld_id', uldId)
                .order('created_at', ascending: true);
            awbsList = List.from(res);
          } catch (e) {
            // Error fetching AWBs
          }
        }
      }

      _addDetailedUldPage(pdf, flight, uld, awbsList);
    }
    
    return pdf.save();
  }

  static void _addDetailedUldPage(pw.Document pdf, Map<String, dynamic> flight, Map<String, dynamic> uld, List awbsList) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Header for ULD
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
                      pw.Text('FLIGHT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${flight["carrier"] ?? ""} ${flight["number"] ?? ""}'.trim(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ULD NUMBER', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(uld['uld_number']?.toString() ?? '-', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF4F46E5))),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PIECES', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(uld['pieces_total']?.toString() ?? '0', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('WEIGHT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${uld['weight_total'] ?? 0} kg', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TYPE', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text((uld['is_break'] == true || uld['is_break']?.toString().toLowerCase() == 'true') ? 'BREAK' : 'NO BREAK', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                ]
              )
            ),

            pw.SizedBox(height: 16),
            pw.Text('AWB CONTENTS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
            pw.SizedBox(height: 8),
            
            // AWB TABLE
            pw.TableHelper.fromTextArray(
              headers: ['#', 'AWB NUMBER', 'PCS', 'WEIGHT', 'STATUS', 'REMARKS'],
              data: awbsList.isEmpty ? [
                ['-', '-', '-', '-', '-', '-']
              ] : awbsList.asMap().entries.map((e) {
                 final idx = e.key;
                 final a = e.value as Map;
                 
                 final masterAwb = a['awbs'] as Map?;
                 final awbNumber = masterAwb != null ? masterAwb['awb_number']?.toString() : a['awb_number']?.toString();
                 
                 final splitPieces = a['pieces']?.toString() ?? '0';
                 final masterPieces = masterAwb != null ? masterAwb['total_pieces']?.toString() ?? '0' : '0';
                 final splitWeight = a['weight']?.toString() ?? '0';
                 final remarks = a['remarks']?.toString() ?? '';
                 
                 String status = 'OK';
                 if (a['not_found'] == true) {
                   status = 'NOT FOUND';
                 } else {
                    final dc = a['data_coordinator'] as Map<String, dynamic>?;
                    if (dc != null && dc.isNotEmpty) {
                       final dType = dc['discrepancy_type']?.toString();
                       final dAmount = dc['discrepancy_amount']?.toString();
                       if (dType != null && dType.trim().isNotEmpty && dType != 'NONE') {
                         status = '$dAmount $dType';
                       }
                    }
                 }

                 return [
                   '${idx + 1}',
                   awbNumber ?? '-',
                   '$splitPieces/$masterPieces',
                   '$splitWeight kg',
                   status,
                   remarks
                 ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A), fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
              cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF334155)),
              cellHeight: 28,
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FixedColumnWidth(90),
                2: const pw.FixedColumnWidth(45),
                3: const pw.FixedColumnWidth(55),
                4: const pw.FixedColumnWidth(70),
                5: const pw.FlexColumnWidth(),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
        footer: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _buildProcessHistoryBox(uld),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 8),
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        }
      )
    );
  }

  static pw.Widget _buildProcessHistoryBox(Map<String, dynamic> uld) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PROCESS HISTORY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _buildProcessColumn('RECEIVED', uld['time_received'] ?? uld['time-received'], uld['user_received'] ?? uld['received_by'] ?? uld['received-by'])),
                _buildDivider(),
                pw.Expanded(child: _buildProcessColumn('CHECKED', uld['time_checked'] ?? uld['time-checked'], uld['user_checked'] ?? uld['checked_by'] ?? uld['checked-by'])),
                _buildDivider(),
                pw.Expanded(child: _buildProcessColumn('SAVED', uld['time_saved'] ?? uld['time-saved'], uld['user_saved'] ?? uld['saved_by'] ?? uld['saved-by'])),
                _buildDivider(),
                pw.Expanded(child: _buildProcessColumn('DELIVERED', uld['time_delivered'] ?? uld['time-delivered'], uld['user_delivered'] ?? uld['delivered_by'] ?? uld['delivered-by'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(width: 1, height: 40, color: PdfColor.fromInt(0xFFCBD5E1), margin: const pw.EdgeInsets.symmetric(vertical: 4));
  }

  static pw.Widget _buildProcessColumn(String label, dynamic time, dynamic user) {
     String timeStr = time?.toString() ?? '';
     String userStr = user?.toString() ?? '';
     
     if (timeStr.isNotEmpty && timeStr != '-' && timeStr.length > 10) {
        try {
           final dt = DateTime.parse(timeStr).toLocal();
           final padDate = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
           final amPm = dt.hour >= 12 ? 'PM' : 'AM';
           var h = dt.hour % 12;
           if (h == 0) h = 12;
           final padTime = "${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm";
           timeStr = "$padDate\n$padTime";
        } catch (_) {}
     }
     
     return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
           crossAxisAlignment: pw.CrossAxisAlignment.center,
           mainAxisAlignment: pw.MainAxisAlignment.start,
           children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              if (userStr.isNotEmpty) pw.Text(userStr, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))) else pw.Text('-', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.SizedBox(height: 2),
              if (timeStr.isNotEmpty) pw.Text(timeStr, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)) else pw.Text('-', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
           ]
        )
     );
  }
}
