import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'coordinator_v2_logic.dart';
import 'coordinator_v2_add_awb_dialog.dart';
import 'coordinator_v2_awb_modal.dart';

class CoordinatorV2UldAwbs extends StatelessWidget {
  final CoordinatorV2Logic logic;
  final bool dark;
  final String flightId;
  final String uldId;

  const CoordinatorV2UldAwbs({
    super.key,
    required this.logic,
    required this.dark,
    required this.flightId,
    required this.uldId,
  });

  @override
  Widget build(BuildContext context) {
    if (logic.isLoadingUldAwbs) {
      return const Padding(
        padding: EdgeInsets.only(top: 16, bottom: 8),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))),
      );
    }

    if (logic.uldAwbs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Center(
          child: Text(
            appLanguage.value == 'es' ? 'No se encontraron AWBs para este ULD.' : 'No AWBs found for this ULD.',
            style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 13),
          ),
        ),
      );
    }

    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appLanguage.value == 'es' ? 'Air Waybills' : 'Air Waybills',
                  style: TextStyle(
                    color: textS,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => CoordinatorV2AddAwbDialog(
                        logic: logic,
                        flightId: flightId,
                        uldId: uldId,
                        dark: dark,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Color(0xFF6366f1), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          appLanguage.value == 'es' ? 'Añadir' : 'Add',
                          style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...logic.uldAwbs.asMap().entries.map((entry) {
            final index = entry.key;
            final awbSplit = entry.value;
            final Map<String, dynamic> master = (awbSplit['awbs'] as Map<String, dynamic>?) ?? {};
            final Map<String, dynamic> combined = {...master, ...awbSplit};

            final thisUld = logic.ulds.firstWhere((u) => u['id_uld'].toString() == logic.selectedUldId, orElse: () => <String, dynamic>{});
            final bool isUldReady = thisUld['time_checked'] != null;

            final awbNumber = combined['awb_number']?.toString() ?? '-';
            final pieces = awbSplit['pieces']?.toString() ?? awbSplit['pieces_split']?.toString() ?? '0';
            final weight = awbSplit['weight']?.toString() ?? awbSplit['weight_split']?.toString() ?? '0';
            final totalPieces = master['total_pieces']?.toString() ?? master['pieces']?.toString() ?? '0';

            final rowBg = dark ? Colors.white.withAlpha(10) : Colors.white;
            final rowBorder = dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB);

            final dynamic d = awbSplit['data_coordinator'];
            bool hasData = false;
            bool hasDiscrepancy = false;
            bool isNotFound = false;
            String? discAmount;
            String? discType;
            String? newAmount;
            String? notFoundAmount;
            
            if (d is Map) {
              hasData = d.isNotEmpty;
              if (d['discrepancy_amount'] != null && d['discrepancy_type'] != null && d['not_found'] != true) {
                hasDiscrepancy = true;
                discAmount = d['discrepancy_amount'].toString();
                discType = d['discrepancy_type']?.toString();
              }
              if (d['not_found'] == true) {
                isNotFound = true;
                notFoundAmount = d['discrepancy_amount']?.toString() ?? master['total_pieces']?.toString() ?? '0';
              }
              if (d['is_new'] == true) {
                newAmount = d['new_amount']?.toString() ?? awbSplit['pieces']?.toString() ?? '0';
              }
            } else if (d is String) {
              hasData = d.trim().isNotEmpty && d != 'null' && d != '{}';
            }

            final bool isNew = awbSplit['is_new'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: rowBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rowBorder),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showCoordinatorV2AwbModal(context, combined, awbSplit, dark, isUldReady),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF6366f1),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    child: Text(
                      awbNumber,
                      style: TextStyle(
                        color: textP,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appLanguage.value == 'es' ? 'PCs' : 'Pcs', style: TextStyle(color: textS, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(pieces, style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: TextStyle(color: textS, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(totalPieces, style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appLanguage.value == 'es' ? 'Peso' : 'Weight', style: TextStyle(color: textS, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('$weight kg', style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (hasDiscrepancy && discAmount != null && discType != null) ...[
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$discAmount $discType',
                            style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isNotFound && notFoundAmount != null) ...[
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF97316).withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, color: Color(0xFFF97316), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$notFoundAmount NOT FOUND',
                            style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isNew) ...[
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6).withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fiber_new_rounded, color: Color(0xFF3B82F6), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${newAmount ?? "0"} NEW',
                            style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (hasData) ...[
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 20),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }),
        ],
      ),
    );
  }
}
