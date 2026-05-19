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
    final bgCard = dark ? const Color(0xFF0f172a) : Colors.white;
    final innerBg = dark ? const Color(0xFF1e293b) : const Color(0xFFF8FAFC);
    final borderC = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    
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
                color: dark ? const Color(0xFF6366F1).withAlpha(15) : const Color(0xFFEEF2FF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF6366F1).withAlpha(30) : const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF6366F1), size: 24),
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
                      hoverColor: dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
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
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withAlpha(80),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
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
                                border: Border.all(color: dark ? const Color(0xFFFACC15).withAlpha(60) : const Color(0xFFFACC15).withAlpha(150), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFACC15).withAlpha(15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text('DOOR', style: TextStyle(color: Color(0xFFfacc15), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  if (door == 'PENDING')
                                    const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFfacc15), size: 28)
                                  else
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
                        child: Builder(
                          builder: (context) {
                            final isPending = stRaw == 'PENDING';
                            final statusBgColor = isPending
                                ? (dark ? Colors.orange.withAlpha(40) : Colors.orange.shade50)
                                : (dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB));
                            final statusBorderColor = isPending
                                ? (dark ? Colors.orange.withAlpha(80) : Colors.orange.shade200)
                                : (dark ? const Color(0xFF475569) : const Color(0xFFD1D5DB));
                            final statusTextColor = isPending
                                ? (dark ? Colors.orange.shade300 : Colors.orange.shade800)
                                : (dark ? Colors.white70 : Colors.black87);
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusBorderColor),
                              ),
                              child: Text(
                                stRaw, 
                                style: TextStyle(
                                  color: statusTextColor, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }
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
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                        shadowColor: const Color(0xFF4F46E5).withAlpha(150),
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
