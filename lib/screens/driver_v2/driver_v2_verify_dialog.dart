import 'package:flutter/material.dart';
import 'driver_v2_confirm_dialog.dart';

void showVerifyDriverDialog({
  required BuildContext context,
  required Map<String, dynamic> deliveryData,
  required bool dark,
  required String company,
  required String driver,
  required String time,
  required String door,
  required String type,
}) {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
  final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
  final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
  final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
  final String idPickup = deliveryData['id_pickup']?.toString() ?? '-';
  final int awbsCount = (deliveryData['awbs'] is List) ? (deliveryData['awbs'] as List).length : 1; // Fallback or logic to show count.

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: bgDialog,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF6366f1), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Verify Driver',
                          style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Card with Waiting Label
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10b981).withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.badge_rounded, color: Color(0xFF10b981), size: 24),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: borderC),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('DOOR', style: TextStyle(color: Color(0xFFfacc15), fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(door, style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: -12,
                              left: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: dark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                                ),
                                child: Text('WAITING', style: TextStyle(color: dark ? Colors.white70 : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Details Info
                        Row(
                          children: [
                            Expanded(child: _buildDialogDetailItem(Icons.local_shipping_rounded, 'Type', type, textP, textS)),
                            Container(width: 1, height: 40, color: borderC),
                            Expanded(child: Padding(padding: const EdgeInsets.only(left: 20), child: _buildDialogDetailItem(Icons.qr_code_rounded, 'ID Pickup', idPickup, textP, textS))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1, color: borderC),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildDialogDetailItem(Icons.access_time_rounded, 'Time', time, textP, textS)),
                            Container(width: 1, height: 40, color: borderC),
                            Expanded(child: Padding(padding: const EdgeInsets.only(left: 20), child: _buildDialogDetailItem(Icons.inventory_2_rounded, 'AWBs', awbsCount.toString(), textP, textS))),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),
                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // NO SHOW Logic here
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.block_rounded, size: 18),
                          label: const Text('NO SHOW', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Close current verify dialog
                            Navigator.pop(ctx);
                            // Open Confirm dialog
                            showDriverConfirmDialog(
                              context: context,
                              deliveryData: deliveryData,
                              dark: dark,
                              company: company,
                              driver: driver,
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
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

Widget _buildDialogDetailItem(IconData icon, String label, String value, Color textP, Color textS) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: textS),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: textS, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ],
  );
}
