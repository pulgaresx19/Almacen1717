import 'package:flutter/material.dart';
import 'driver_v2_awb_dialog.dart';

void showDriverConfirmDialog({
  required BuildContext context,
  required Map<String, dynamic> deliveryData,
  required bool dark,
  required String company,
  required String driver,
}) {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
  final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
  final bgGlassy = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
  final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
  
  // The list of deliveries (AWBs) could be under 'awbs' or 'list_deliveries' based on previous context.
  final List<dynamic> awbsList = (deliveryData['awbs'] is List) ? deliveryData['awbs'] as List 
                               : (deliveryData['list_deliver'] is List) ? deliveryData['list_deliver'] as List : [];
  
  final String door = deliveryData['door']?.toString() ?? '-';
  final String type = deliveryData['type']?.toString() ?? '-';
  final String idPickup = deliveryData['id_pickup']?.toString() ?? '-';
  final bool isPriority = deliveryData['is_priority'] == true;
  final String remarks = deliveryData['remarks']?.toString() ?? deliveryData['remar']?.toString() ?? '';
  
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (ctx) {
      final size = MediaQuery.of(context).size;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600, // Tablet-like width
            maxHeight: size.height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: bgDialog,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF6366f1), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(company, style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(driver, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: textS),
                          hoverColor: Colors.white.withAlpha(10),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),
                  
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // General Info Section
                          Text('GENERAL INFORMATION', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgGlassy,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderC),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoItem('ID Pickup', idPickup, textS, textP)),
                                    Expanded(child: _buildInfoItem('Door', door, textS, textP)),
                                    Expanded(child: _buildInfoItem('Type', type, textS, textP)),
                                    if (isPriority)
                                      const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 28),
                                  ],
                                ),
                                if (remarks.isNotEmpty && remarks != '-') ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.notes_rounded, size: 16, color: textS),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            remarks,
                                            style: TextStyle(color: textS, fontSize: 13, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // List of Deliveries Section
                          Text('DELIVERIES LIST', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          
                          if (awbsList.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text('No deliveries found for this driver.', style: TextStyle(color: textS)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: awbsList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = awbsList[index];
                                  
                                final String rawNumber = item['awb_number']?.toString() ?? item['uld_number']?.toString() ?? item['awb']?.toString() ?? 'N/A';
                                final String typeLabel = item.containsKey('uld_id') ? 'ULD: ' : 'AWB: ';
                                final awbNumber = '$typeLabel$rawNumber';
                                  
                                final pieces = item['found']?.toString() ?? '0';
                                final weight = item['weight']?.toString() ?? '0';
                                final remar = item['remarks']?.toString() ?? '';
                                  
                                return InkWell(
                                  onTap: () {
                                    showDriverAwbDialog(
                                      context: context,
                                      awbItem: item,
                                      dark: dark,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: bgGlassy,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderC),
                                    ),
                                    child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10b981).withAlpha(20),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              awbNumber, 
                                              style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Pieces', style: TextStyle(color: textS, fontSize: 10)),
                                                Text(pieces, style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Weight', style: TextStyle(color: textS, fontSize: 10)),
                                                Text('$weight kg', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (remar != '-' && remar.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.notes_rounded, size: 14, color: textS),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  remar,
                                                  style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Fixed Bottom Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgDialog,
                      border: Border(top: BorderSide(color: borderC)),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: null, // Initially disabled
                      icon: const Icon(Icons.task_alt_rounded, size: 20),
                      label: const Text('Mark Delivery Finished', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF10b981).withAlpha(80), // Faded green background
                        disabledForegroundColor: Colors.white.withAlpha(180), // Slightly muted white text
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildInfoItem(String label, String value, Color textS, Color textP) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: textS, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}
