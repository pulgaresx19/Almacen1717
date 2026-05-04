import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'flights_v2_uld_pdf_exporter.dart';

void showUldPrintPreviewDialog(BuildContext context, Map<String, dynamic> flight, List<Map<String, dynamic>> ulds, bool dark) {
  showDialog(
    context: context,
    builder: (context) {
      final double width = MediaQuery.of(context).size.width * 0.8;
      final double maxHeight = MediaQuery.of(context).size.height * 0.9;
      
      final bg = dark ? const Color(0xFF1e293b) : Colors.white;
      final headerBg = dark ? const Color(0xFF0f172a) : Colors.grey.shade100;
      final textC = dark ? Colors.white : Colors.black;
      final borderC = dark ? Colors.white.withAlpha(20) : Colors.grey.shade300;

      final title = ulds.length == 1 
          ? 'ULD PDF PREVIEW - ${ulds.first['uld_number'] ?? 'UNKNOWN'}' 
          : 'ULD PDF PREVIEW - ${ulds.length} ULDs';
      final fileName = ulds.length == 1 
          ? 'uld_${ulds.first['uld_number'] ?? 'report'}.pdf' 
          : 'ulds_batch_report.pdf';

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: width > 900 ? 900 : width,
          height: maxHeight,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                 decoration: BoxDecoration(
                   color: headerBg,
                   borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                   border: Border(bottom: BorderSide(color: borderC)),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textC)),
                      Row(
                         children: [
                            IconButton(
                               onPressed: () async {
                                  final bytes = await FlightsV2UldPdfExporter.generateUldPdf(flight, ulds);
                                  await Printing.layoutPdf(
                                     onLayout: (format) async => bytes,
                                     name: fileName,
                                  );
                               },
                               icon: const Icon(Icons.print_rounded, color: Color(0xFF6366f1)),
                               tooltip: 'Print',
                               style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                               onPressed: () async {
                                  final bytes = await FlightsV2UldPdfExporter.generateUldPdf(flight, ulds);
                                  await Printing.sharePdf(
                                     bytes: bytes,
                                     filename: fileName,
                                  );
                               },
                               icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF6366f1)),
                               tooltip: 'Download PDF',
                               style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15)),
                            ),
                            const SizedBox(width: 16),
                            IconButton(icon: Icon(Icons.close, color: textC), onPressed: () => Navigator.pop(context)),
                         ]
                      )
                   ]
                 )
               ),
               Expanded(
                 child: Container(
                   color: dark ? const Color(0xFF334155) : const Color(0xFF94a3b8), 
                   child: PdfPreview(
                     build: (format) => FlightsV2UldPdfExporter.generateUldPdf(flight, ulds),
                     useActions: false,
                     allowPrinting: false,
                     allowSharing: false,
                     canChangePageFormat: false,
                   ),
                 ),
               ),
            ],
          ),
        ),
      );
    },
  );
}
