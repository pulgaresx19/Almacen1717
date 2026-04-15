import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'coordinator_v2_logic.dart';
import 'coordinator_v2_awb_modal.dart';

class CoordinatorV2UldAwbs extends StatelessWidget {
  final CoordinatorV2Logic logic;
  final bool dark;

  const CoordinatorV2UldAwbs({
    super.key,
    required this.logic,
    required this.dark,
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
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              appLanguage.value == 'es' ? 'Air Waybills' : 'Air Waybills',
              style: TextStyle(
                color: textS,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
            if (d is Map) {
              hasData = d.isNotEmpty;
            } else if (d is String) {
              hasData = d.trim().isNotEmpty && d != 'null' && d != '{}';
            }

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
