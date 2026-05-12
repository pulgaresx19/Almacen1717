import 'package:flutter/material.dart';

class DriverV2VerifyCard extends StatelessWidget {
  final Map<String, dynamic> deliveryData;
  final bool dark;
  final String company;
  final String driver;
  final String time;
  final String door;
  final String type;
  final String idPickup;
  final int awbsCount;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final VoidCallback? onNoShow;
  final VoidCallback onConfirm;
  final bool isLoadingNoShow;

  const DriverV2VerifyCard({
    super.key,
    required this.deliveryData,
    required this.dark,
    required this.company,
    required this.driver,
    required this.time,
    required this.door,
    required this.type,
    required this.idPickup,
    required this.awbsCount,
    this.showCloseButton = true,
    this.onClose,
    this.onNoShow,
    required this.onConfirm,
    this.isLoadingNoShow = false,
  });

  @override
  Widget build(BuildContext context) {
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
    final innerBg = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    
    // Status text logic just in case
    final stRaw = (deliveryData['status']?.toString() ?? 'WAITING').toUpperCase();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderC),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF6366f1), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned Driver',
                          style: TextStyle(color: textP, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please verify driver presence',
                          style: TextStyle(color: textS, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (showCloseButton && onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(Icons.close_rounded, color: textS),
                      hoverColor: Colors.white.withAlpha(10),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: borderC),
            
            // Body
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Driver Basic Info Card
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: innerBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderC),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981).withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.badge_rounded, color: Color(0xFF10b981), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(company, style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(driver, style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF0f172a) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Column(
                                children: [
                                  const Text('DOOR', style: TextStyle(color: Color(0xFFfacc15), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(door, style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
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
                          child: Text(stRaw, style: TextStyle(color: dark ? Colors.white70 : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Details Grid
                  Row(
                    children: [
                      Expanded(child: _buildDialogDetailItem(Icons.local_shipping_rounded, 'Type', type, textP, textS)),
                      Container(width: 1, height: 48, color: borderC),
                      Expanded(child: Padding(padding: const EdgeInsets.only(left: 24), child: _buildDialogDetailItem(Icons.qr_code_rounded, 'ID Pickup', idPickup, textP, textS))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(height: 1, color: borderC),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildDialogDetailItem(Icons.access_time_rounded, 'Time', time, textP, textS)),
                      Container(width: 1, height: 48, color: borderC),
                      Expanded(child: Padding(padding: const EdgeInsets.only(left: 24), child: _buildDialogDetailItem(Icons.inventory_2_rounded, 'AWBs', awbsCount.toString(), textP, textS))),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderC),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoadingNoShow ? null : onNoShow,
                      icon: isLoadingNoShow 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.block_rounded),
                      label: const Text('No Show', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogDetailItem(IconData icon, String label, String value, Color textP, Color textS) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: textS),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
