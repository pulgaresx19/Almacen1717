import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class DamageReportPdfExporter {
  static Future<Uint8List> generatePdf(
    Map<String, dynamic> damage,
    List<String> selectedPhotos, {
    Map<String, Future<pw.ImageProvider>>? imageFuturesCache,
  }) async {
    final pdf = pw.Document();

    // 1. Download images concurrently with timeout
    List<pw.ImageProvider> downloadedImages = [];
    if (selectedPhotos.isNotEmpty) {
      final futures = selectedPhotos.map((url) async {
        try {
          if (imageFuturesCache != null && imageFuturesCache.containsKey(url)) {
            // Await the preloading future
            return await imageFuturesCache[url]!.timeout(const Duration(seconds: 25));
          }
          final future = networkImage(url);
          if (imageFuturesCache != null) {
            imageFuturesCache[url] = future;
          }
          return await future.timeout(const Duration(seconds: 15));
        } catch (e) {
          return null; // Return null if it fails or times out
        }
      });
      
      final results = await Future.wait(futures);
      for (var img in results) {
        if (img != null) {
          downloadedImages.add(img);
        }
      }
    }

    String damageType = 'N/A';
    if (damage['damage_type'] != null) {
      if (damage['damage_type'] is List) {
        damageType = (damage['damage_type'] as List).join(', ');
      } else {
        damageType = damage['damage_type'].toString();
      }
    }

    final dateStr = damage['created_at'] != null 
        ? DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.parse(damage['created_at']).toLocal()) 
        : 'N/A';

    final flightData = damage['flights'] ?? {};
    final flightStr = (flightData['carrier'] != null && flightData['number'] != null)
        ? '${flightData['carrier']} ${flightData['number']}'
        : 'N/A';

    final awbStr = damage['awbs']?['awb_number']?.toString() ?? 'N/A';
    final uldStr = damage['ulds']?['uld_number']?.toString() ?? 'LOOSE';
    
    // Attempt to extract reported by
    String reportedBy = 'Unknown';
    if (damage['users'] != null) {
      if (damage['users'] is List && (damage['users'] as List).isNotEmpty) {
        reportedBy = (damage['users'] as List)[0]['full_name']?.toString() ?? 'Unknown';
      } else if (damage['users'] is Map) {
        reportedBy = damage['users']['full_name']?.toString() ?? 'Unknown';
      }
    }

    final pieces = damage['pieces_damage']?.toString() ?? '0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DAMAGE REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFEF4444))),
                    pw.SizedBox(height: 4),
                    pw.Text('WAREHOUSE OPERATIONS', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(dateStr, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 24),

            // INFO BOX
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('FLIGHT', flightStr),
                  _buildInfoColumn('ULD', uldStr),
                  _buildInfoColumn('AWB', awbStr),
                  _buildInfoColumn('REPORTED BY', reportedBy),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // DAMAGE DETAILS BOX
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
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
                      pw.Text('DAMAGE TYPE', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(damageType, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFEF4444))),
                    ]
                  ),
                  pw.Container(width: 1, height: 30, color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('PIECES DAMAGED', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(pieces, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                    ]
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),
            pw.Text('PHOTOGRAPHIC EVIDENCE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF334155))),
            pw.SizedBox(height: 12),

            if (downloadedImages.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text('No photographic evidence provided.', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.grey600)),
              )
            else
              pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: downloadedImages.map((img) {
                  return pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Container(
                      width: 150,
                      height: 150,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
                      ),
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    ),
                  );
                }).toList(),
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

    return pdf.save();
  }

  static pw.Widget _buildInfoColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
      ]
    );
  }
}
