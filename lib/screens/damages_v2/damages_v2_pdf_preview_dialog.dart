import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../main.dart' show appLanguage;
import 'damages_v2_pdf_exporter.dart';

class DamagesV2PdfPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> damage;
  final bool dark;

  const DamagesV2PdfPreviewDialog({
    super.key,
    required this.damage,
    required this.dark,
  });

  @override
  State<DamagesV2PdfPreviewDialog> createState() => _DamagesV2PdfPreviewDialogState();
}

class _DamagesV2PdfPreviewDialogState extends State<DamagesV2PdfPreviewDialog> {
  late List<String> availablePhotos;
  List<String> selectedPhotos = [];
  final Map<String, Future<pw.ImageProvider>> imageFuturesCache = {};

  Uint8List? pdfBytes;
  bool isGeneratingPdf = false;
  String? processingUrl;
  int _generationCounter = 0;

  @override
  void initState() {
    super.initState();
    final List<dynamic>? photos = widget.damage['photo_urls'] as List?;
    availablePhotos = photos != null ? List<String>.from(photos) : [];
    
    // Opt-out by default: pre-select all photos
    selectedPhotos = List.from(availablePhotos);
    
    for (String url in availablePhotos) {
      imageFuturesCache[url] = networkImage(url);
    }
    
    _generatePdf();
  }

  Future<void> _generatePdf({String? triggeringUrl}) async {
    final currentGen = ++_generationCounter;
    setState(() {
      isGeneratingPdf = true;
      processingUrl = triggeringUrl;
    });

    final bytes = await DamageReportPdfExporter.generatePdf(
      widget.damage,
      selectedPhotos,
      imageFuturesCache: imageFuturesCache,
    );

    if (mounted && _generationCounter == currentGen) {
      setState(() {
        pdfBytes = bytes;
        isGeneratingPdf = false;
        processingUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.dark ? const Color(0xFF0f172a) : Colors.white;
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
    final awbStr = widget.damage['awbs']?['awb_number']?.toString() ?? 'Report';

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 1100,
        height: 800,
        child: Row(
          children: [
            // Sidebar for photos
            Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appLanguage.value == 'es' ? 'FOTOS A IMPRIMIR' : 'PHOTOS TO PRINT',
                        style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: isGeneratingPdf ? null : () {
                          // Select all
                          setState(() {
                            selectedPhotos = List.from(availablePhotos);
                          });
                          _generatePdf();
                        },
                        icon: const Icon(Icons.library_add_check_outlined, size: 20),
                        tooltip: appLanguage.value == 'es' ? 'Seleccionar todas' : 'Select all',
                        color: textS,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: availablePhotos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_not_supported_outlined, size: 48, color: textS.withAlpha(100)),
                                const SizedBox(height: 16),
                                Text(
                                  appLanguage.value == 'es' ? 'No hay fotos reportadas' : 'No photos reported',
                                  style: TextStyle(color: textS, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: availablePhotos.length,
                            itemBuilder: (context, index) {
                              final url = availablePhotos[index];
                              final isSelected = selectedPhotos.contains(url);
                              
                              final isProcessingThis = isGeneratingPdf && processingUrl == url;
                              
                              return InkWell(
                                onTap: isGeneratingPdf ? null : () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedPhotos.remove(url);
                                    } else {
                                      selectedPhotos.add(url);
                                    }
                                  });
                                  _generatePdf(triggeringUrl: url);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected 
                                          ? const Color(0xFF10B981) 
                                          : (widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(isSelected ? 6 : 7),
                                        child: Image.network(
                                          url,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              height: 160,
                                              color: bgCard,
                                              alignment: Alignment.center,
                                              child: const CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 160,
                                            color: bgCard,
                                            alignment: Alignment.center,
                                            child: Icon(Icons.broken_image, color: textS),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF10B981) : Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSelected ? Icons.check : Icons.add, 
                                            color: Colors.white, 
                                            size: 20
                                          ),
                                        ),
                                      ),
                                      if (isProcessingThis)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(isSelected ? 6 : 7),
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // PDF Preview area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                child: Scaffold( // Use Scaffold to provide material context for the preview
                  backgroundColor: widget.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  body: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60), // Space for custom header
                        child: PdfPreview(
                          build: (format) async => pdfBytes ?? await DamageReportPdfExporter.generatePdf(widget.damage, [], imageFuturesCache: imageFuturesCache),
                          useActions: false, // Custom actions instead
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          initialPageFormat: PdfPageFormat.a4,
                          loadingWidget: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                        ),
                      ),
                      
                      // Custom Header Toolbar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: widget.dark ? const Color(0xFF0F172A) : Colors.white,
                            border: Border(bottom: BorderSide(color: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                appLanguage.value == 'es' ? 'PREVISUALIZACIÓN DEL PDF' : 'PDF PREVIEW',
                                style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Printing.layoutPdf(
                                        onLayout: (format) => DamageReportPdfExporter.generatePdf(widget.damage, selectedPhotos, imageFuturesCache: imageFuturesCache),
                                        name: 'Damage_Report_$awbStr.pdf',
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.print_outlined, size: 18),
                                    label: Text(appLanguage.value == 'es' ? 'Imprimir' : 'Print', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final bytes = await DamageReportPdfExporter.generatePdf(widget.damage, selectedPhotos, imageFuturesCache: imageFuturesCache);
                                      await Printing.sharePdf(bytes: bytes, filename: 'Damage_Report_$awbStr.pdf');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textP,
                                      side: BorderSide(color: widget.dark ? Colors.white.withAlpha(40) : const Color(0xFFD1D5DB)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFFEF4444)),
                                    label: Text(appLanguage.value == 'es' ? 'Descargar PDF' : 'Download PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(width: 1, height: 24, color: widget.dark ? Colors.white.withAlpha(40) : const Color(0xFFD1D5DB)),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () => Navigator.of(context).pop(),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFF3F4F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.close, color: textP, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
