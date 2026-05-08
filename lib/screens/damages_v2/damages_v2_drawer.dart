import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class DamagesV2Drawer {
  static void show(BuildContext context, Map<String, dynamic> damage, bool dark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        final dateStr = damage['created_at'] != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(damage['created_at']).toLocal()) : 'N/A';
        String damageType = 'N/A';
        if (damage['damage_type'] != null) {
          if (damage['damage_type'] is List) {
            damageType = (damage['damage_type'] as List).join(', ');
          } else {
            damageType = damage['damage_type'].toString();
          }
        }
        final pieces = damage['pieces_damage']?.toString() ?? '0';
        dynamic userData = damage['users'];
        if (userData is List && userData.isNotEmpty) userData = userData[0];
        final reportedBy = userData != null ? userData['full_name']?.toString() ?? 'Unknown User' : 'Unknown User';

        dynamic awbData = damage['awbs'];
        if (awbData is List && awbData.isNotEmpty) awbData = awbData[0];
        
        dynamic uldData = damage['ulds'];
        if (uldData is List && uldData.isNotEmpty) uldData = uldData[0];
        
        dynamic flightData = damage['flights'];
        if (flightData is List && flightData.isNotEmpty) flightData = flightData[0];

        List<Widget> refWidgets = [];
        if (awbData != null && awbData['awb_number'] != null) {
          refWidgets.add(Text('AWB: ${awbData['awb_number']}', style: TextStyle(color: refWidgets.isEmpty ? textP : textS, fontSize: refWidgets.isEmpty ? 24 : 14, fontWeight: refWidgets.isEmpty ? FontWeight.bold : FontWeight.w500)));
        }
        if (uldData != null && uldData['uld_number'] != null) {
          refWidgets.add(Text('ULD: ${uldData['uld_number']}', style: TextStyle(color: refWidgets.isEmpty ? textP : textS, fontSize: refWidgets.isEmpty ? 24 : 14, fontWeight: refWidgets.isEmpty ? FontWeight.bold : FontWeight.w500)));
        }
        if (flightData != null && flightData['number'] != null) {
          refWidgets.add(Text('Flight: ${flightData['carrier'] ?? ''} ${flightData['number']}', style: TextStyle(color: refWidgets.isEmpty ? textP : textS, fontSize: refWidgets.isEmpty ? 24 : 14, fontWeight: refWidgets.isEmpty ? FontWeight.bold : FontWeight.w500)));
        }
        if (refWidgets.isEmpty) {
          refWidgets.add(Text('N/A', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)));
        }

        List<String> photos = [];
        if (damage['photo_urls'] != null) {
          if (damage['photo_urls'] is List) {
            photos = List<String>.from(damage['photo_urls']);
          } else if (damage['photo_urls'] is String) {
            photos = [damage['photo_urls']];
          }
        }

        Widget buildDetailRow(String label, String value, Color valueColor, Color labelColor, {bool isBold = false}) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: valueColor, fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
            ],
          );
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: bg,
            elevation: 16,
            child: SizedBox(
              width: 520, // matching awb drawer width
              height: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appLanguage.value == 'es' ? 'Detalles de Daño' : 'Damage Details', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            ...refWidgets,
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.print_outlined, color: textP),
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                        const SizedBox(width: 16),
                                        Text(appLanguage.value == 'es' ? 'Generando documento oficial...' : 'Generating official document...'),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                
                                final List<dynamic>? photos = damage['photo_urls'] as List?;
                                final availablePhotos = photos != null ? List<String>.from(photos) : <String>[];
                                
                                try {
                                  final FunctionResponse response = await Supabase.instance.client.functions.invoke(
                                    'generate_damage_pdf',
                                    body: {
                                      'damage_id': damage['id'],
                                      'selected_photos': availablePhotos,
                                    },
                                  );

                                  if (response.status == 200 && response.data is Uint8List) {
                                    final bytes = response.data as Uint8List;
                                    await Printing.layoutPdf(
                                      onLayout: (format) async => bytes,
                                      name: 'Damage_Report_${damage['awbs']?['awb_number'] ?? 'Unknown'}.pdf',
                                    );
                                  } else {
                                    throw Exception('Failed to generate PDF. Status: ${response.status}');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error generating PDF: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              tooltip: appLanguage.value == 'es' ? 'Imprimir Reporte' : 'Print Report',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: textP),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderC),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildDetailRow('Reported At', dateStr, textP, textS),
                              const SizedBox(height: 16),
                              buildDetailRow('Reported By', reportedBy, textP, textS),
                              const SizedBox(height: 16),
                              buildDetailRow('Damage Type', damageType, const Color(0xFFef4444), textS, isBold: true),
                              const SizedBox(height: 16),
                              buildDetailRow('Pieces Damaged', pieces, textP, textS),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          appLanguage.value == 'es' ? 'Evidencia Fotográfica' : 'Photographic Evidence',
                          style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (photos.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderC),
                            ),
                            child: Text(
                              appLanguage.value == 'es' ? 'No se subieron fotos.' : 'No photos attached.',
                              style: TextStyle(color: textS, fontSize: 13),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: photos.map((url) => GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: ctx,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(24),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        InteractiveViewer(
                                          panEnabled: true,
                                          boundaryMargin: const EdgeInsets.all(20),
                                          minScale: 0.5,
                                          maxScale: 4,
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: bgCard,
                                              child: Icon(Icons.broken_image_rounded, color: textS, size: 48),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  width: 220,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 220,
                                    height: 220,
                                    color: bgCard,
                                    child: Icon(Icons.broken_image_rounded, color: textS),
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      }
    );
  }
}
