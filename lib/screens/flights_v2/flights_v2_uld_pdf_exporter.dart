import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class FlightsV2UldPdfExporter {
  static Future<Uint8List> generateUldPdf(Map<String, dynamic> flight, List<Map<String, dynamic>> ulds) async {
    final pdf = pw.Document();

    for (var uld in ulds) {
      final uldId = uld['id_uld']?.toString() ?? '';
      List awbsList = [];
      
      if (uldId.isNotEmpty) {
        try {
          final res = await Supabase.instance.client
              .from('awb_splits')
              .select('*, awbs(*)')
              .eq('id_uld', uldId)
              .order('created_at', ascending: true);
          awbsList = List.from(res);
        } catch (e) {
          // Error fetching AWBs
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
                 
                 final splitPieces = a['pieces']?.toString() ?? '0';
                 final masterPieces = a['awbs']?['pieces']?.toString() ?? '0';
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
                   a['awb_number']?.toString() ?? '-',
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
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        }
      )
    );
  }
}
