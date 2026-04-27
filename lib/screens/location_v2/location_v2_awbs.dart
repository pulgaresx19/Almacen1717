import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'location_v2_logic.dart';
import 'location_v2_scanner_modal.dart';

class LocationV2Awbs extends StatelessWidget {
  final LocationV2Logic logic;
  final bool dark;

  const LocationV2Awbs({
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
              ],
            ),
          ),
          ...logic.uldAwbs.asMap().entries.map((entry) {
            final index = entry.key;
            final awbSplit = entry.value;
            final Map<String, dynamic> master = (awbSplit['awbs'] as Map<String, dynamic>?) ?? {};
            final Map<String, dynamic> combined = {...master, ...awbSplit};

            final awbNumber = combined['awb_number']?.toString() ?? '-';
            final pieces = awbSplit['pieces']?.toString() ?? awbSplit['pieces_split']?.toString() ?? '0';
            final weight = awbSplit['weight']?.toString() ?? awbSplit['weight_split']?.toString() ?? '0';

            final rowBg = dark ? Colors.white.withAlpha(10) : Colors.white;
            final rowBorder = dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB);



            final uldId = awbSplit['uld_id']?.toString();
            bool isCompleted = false;
            if (uldId != null) {
              final uldInfo = logic.ulds.cast<Map<String, dynamic>?>().firstWhere(
                (u) => u != null && u['id_uld']?.toString() == uldId,
                orElse: () => null,
              );
              if (uldInfo != null && uldInfo['time_saved'] != null) {
                isCompleted = true;
              }
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
                  onTap: () {
                    LocationV2ScannerModal.showLocationEditor(
                      context, 
                      awbSplit, 
                      logic, 
                      isReadOnly: isCompleted,
                    );
                  },
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
                      const SizedBox(width: 12),
                      Expanded(
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
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appLanguage.value == 'es' ? 'PCs' : 'Pcs', style: TextStyle(color: textS, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(pieces, style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appLanguage.value == 'es' ? 'Peso' : 'Weight', style: TextStyle(color: textS, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('$weight kg', style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (awbSplit['data_location'] != null)
                        Builder(
                          builder: (context) {
                            final locData = awbSplit['data_location'];
                            List<String> locs = [];
                            
                            if (locData is List) {
                              for (var item in locData) {
                                if (item is Map && item['location'] != null) {
                                  locs.add(item['location'].toString());
                                }
                              }
                            } else if (locData is Map) {
                              if (locData['locations'] != null && locData['locations'] is List) {
                                for (var item in locData['locations']) {
                                  if (item is Map && item['location'] != null) {
                                    locs.add(item['location'].toString());
                                  }
                                }
                              } else if (locData['location'] != null) {
                                locs.add(locData['location'].toString());
                              }
                            }

                            if (locs.isEmpty) return const SizedBox.shrink();

                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981).withAlpha(20),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10b981).withAlpha(50)),
                              ),
                              child: const Icon(Icons.location_on, color: Color(0xFF10b981), size: 16),
                            );
                          },
                        ),
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
