import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class DeliverPdfExporter {
  static Future<Uint8List> generateDeliversPdf(List<Map<String, dynamic>> delivers) async {
    final pdf = pw.Document();

    final headers = [
      'No.',
      'Company',
      'Driver',
      'ID Pickup',
      'Time',
      'Door',
      'Type',
      'AWBs',
      'Status',
    ];

    final data = delivers.asMap().entries.map((entry) {
      final idx = entry.key;
      final u = entry.value;

      String company = u['truck-company']?.toString() ?? '-';
      String driver = u['driver']?.toString() ?? '-';
      String idPickup = u['id-pickup']?.toString() ?? '-';
      
      String timeStr = '-';
      if (u['time-deliver'] != null) {
        final tdt = DateTime.tryParse(u['time-deliver'].toString())?.toLocal();
        if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
      }

      String door = u['door']?.toString() ?? '-';
      String type = u['type']?.toString() ?? '-';

      String awbsStr = '0';
      if (u['list-pickup'] != null) {
        if (u['list-pickup'] is List) {
          awbsStr = (u['list-pickup'] as List).length.toString();
        } else {
          awbsStr = '1';
        }
      }

      String status = u['status']?.toString() ?? 'Waiting';

      return [
        '${idx + 1}',
        company,
        driver,
        idPickup,
        timeStr,
        door,
        type,
        awbsStr,
        status.toUpperCase(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Delivers Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF3F51B5)),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.center,
                8: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printDelivers(List<Map<String, dynamic>> delivers) async {
    final pdfBytes = await generateDeliversPdf(delivers);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'delivers_report.pdf',
    );
  }

  static Future<void> downloadPdf(List<Map<String, dynamic>> delivers) async {
    final pdfBytes = await generateDeliversPdf(delivers);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'delivers_report.pdf');
  }
}
