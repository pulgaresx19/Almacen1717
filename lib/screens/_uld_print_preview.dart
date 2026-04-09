import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '_uld_pdf_exporter.dart';

void showUldPrintPreviewDialog(BuildContext context, Map<String, dynamic> uld) {
  showDialog(
    context: context,
    builder: (context) {
      final double width = MediaQuery.of(context).size.width * 0.8;
      final double maxHeight = MediaQuery.of(context).size.height * 0.9;

      List awbList = [];
      if (uld['data-ULD'] is List) {
         awbList = uld['data-ULD'] as List;
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: width > 900 ? 900 : width,
          height: maxHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                   border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      const Text('PDF PREVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                         children: [
                            IconButton(
                               onPressed: () async {
                                  final bytes = await UldPdfExporter.generateDetailedUldPdf(uld, awbList);
                                  await Printing.layoutPdf(
                                     onLayout: (format) async => bytes,
                                     name: 'uld_detailed_${uld["ULD-number"] ?? "report"}.pdf',
                                  );
                               },
                               icon: const Icon(Icons.print_rounded, color: Color(0xFF6366f1)),
                               tooltip: 'Print',
                               style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                               onPressed: () async {
                                  final bytes = await UldPdfExporter.generateDetailedUldPdf(uld, awbList);
                                  await Printing.sharePdf(
                                     bytes: bytes,
                                     filename: 'uld_detailed_${uld["ULD-number"] ?? "report"}.pdf',
                                  );
                               },
                               icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF6366f1)),
                               tooltip: 'Download PDF',
                               style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15)),
                            ),
                            const SizedBox(width: 16),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                         ]
                      )
                   ]
                 )
               ),
               Expanded(
                 child: Container(
                   color: const Color(0xFF64748B), // slate-500 backend
                   child: PdfPreview(
                     build: (format) => UldPdfExporter.generateDetailedUldPdf(uld, awbList),
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
