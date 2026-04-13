import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FlightPdfExporter {
  static Future<Uint8List> generateFlightsPdf(List<Map<String, dynamic>> flights) async {
    final pdf = pw.Document();

    for (var flightEditor in flights) {
      final flight = Map<String, dynamic>.from(flightEditor);
      
      final flightId = flight['id_flight']?.toString() ?? '';
      List uldList = [];
      if (flightId.isNotEmpty) {
        try {
          final resUlds = await Supabase.instance.client
              .from('ulds')
              .select('*, awb_splits(*, awbs(*))')
              .eq('id_flight', flightId)
              .order('is_break', ascending: false)
              .order('uld_number', ascending: true);
          uldList = List.from(resUlds);
        } catch (e) {
          // Error fetching ULDS, ignore and print empty list
        }
      }

      _addDetailedFlightPage(pdf, flight, uldList);
    }
    
    return pdf.save();
  }

  static Future<void> printFlights(List<Map<String, dynamic>> flights) async {
    final pdfBytes = await generateFlightsPdf(flights);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'flights_detailed_report.pdf',
    );
  }

  static Future<void> downloadPdf(List<Map<String, dynamic>> flights) async {
    final pdfBytes = await generateFlightsPdf(flights);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'flights_detailed_report.pdf');
  }

  static Future<Uint8List> generateDetailedFlightPdf(Map<String, dynamic> flight, List uldList) async {
    final pdf = pw.Document();
    _addDetailedFlightPage(pdf, flight, uldList);
    return pdf.save();
  }

  static void _addDetailedFlightPage(pw.Document pdf, Map<String, dynamic> flight, List uldList) {
    String formatTime(String? ts) {
       if (ts == null || ts.trim().isEmpty || ts == '-') return '--:--';
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // SUMMARY BOX (Header merged here)
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
                      pw.Text('DATE ARRIVED', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(formatDate(flight['date']?.toString()), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TIME ARRIVED', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(formatTime(flight['date']?.toString()), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL ULD', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text('${(int.tryParse(flight["cant_break"]?.toString() ?? "0") ?? 0) + (int.tryParse(flight["cant_nobreak"]?.toString() ?? "0") ?? 0)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF4F46E5))),
                    ]
                  ),
                ]
              )
            ),

            pw.SizedBox(height: 12),
            
            // TIMES BREAKDOWN
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
                      pw.Text('START BREAK', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(formatTime(flight['start_break']?.toString()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('END BREAK', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(formatTime(flight['end_break']?.toString()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('FIRST TRUCK', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(formatTime(flight['first_truck']?.toString()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                  pw.Container(width: 1, height: 20, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('LAST TRUCK', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(formatTime(flight['last_truck']?.toString()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
                    ]
                  ),
                ]
              )
            ),
            
            pw.SizedBox(height: 16),
            pw.Text('ASSOCIATED ULDs', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
            pw.SizedBox(height: 8),
            
            // ULD TABLE
            pw.TableHelper.fromTextArray(
              headers: ['#', 'ULD NUMBER', 'TYPE', 'PIECES', 'WEIGHT', 'REMARKS'],
              data: uldList.isEmpty ? [
                // Mockup data if no ULDs, acts as visual guide during testing if it fails
                ['-', '-', '-', '-', '-', '-']
              ] : uldList.asMap().entries.map((e) {
                 final idx = e.key;
                 final u = e.value as Map;
                 return [
                   '${idx + 1}',
                   u['uld_number']?.toString() ?? '-',
                   (u['is_break'] == true || u['is_break']?.toString().toLowerCase() == 'true') ? 'BREAK' : 'NO BREAK',
                   u['pieces_total']?.toString() ?? '0',
                   '${u['weight_total'] ?? 0} kg',
                   u['remarks']?.toString() ?? ''
                 ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A), fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
              cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF334155)),
              cellHeight: 28,
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FixedColumnWidth(60),
                3: const pw.FixedColumnWidth(50),
                4: const pw.FixedColumnWidth(60),
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
