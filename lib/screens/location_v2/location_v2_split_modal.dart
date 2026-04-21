import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'location_v2_logic.dart';
import 'location_v2_scanner_modal.dart';

class LocationV2SplitModal {
  static Future<void> show(
    BuildContext context,
    String query,
    List<Map<String, dynamic>> matches,
    LocationV2Logic logic,
  ) async {
    final dark = isDarkMode.value;
    final bgCol = dark ? const Color(0xFF1e293b) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final borderCard = dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(
          children: [
            const Icon(Icons.call_split_rounded, color: Color(0xFF6366f1), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                appLanguage.value == 'es' ? 'Seleccionar AWB (Split)' : 'Select AWB (Split)',
                style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLanguage.value == 'es'
                    ? 'Múltiples coincidencias para "$query". Selecciona el ULD correspondiente:'
                    : 'Multiple matches for "$query". Select the corresponding ULD:',
                style: TextStyle(color: textS, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: matches.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (c, i) {
                    final split = matches[i];
                    final pieces = split['pieces']?.toString() ?? split['pieces_split']?.toString() ?? '0';
                    final weight = split['weight']?.toString() ?? split['weight_split']?.toString() ?? '0';
                    
                    final rawUldId = split['uld_id']?.toString() ?? '';
                    final matchedUld = logic.ulds.where((u) => u['id_uld']?.toString() == rawUldId).firstOrNull;
                    final uldId = matchedUld != null ? (matchedUld['uld_number']?.toString() ?? rawUldId) : rawUldId;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        LocationV2ScannerModal.showLocationEditor(context, split, logic);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderCard),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: Color(0xFF6366f1), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ULD: $uldId',
                                    style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PCs: $pieces  |  Weight: $weight kg',
                                    style: TextStyle(color: textS, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6366f1)),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
              style: const TextStyle(color: Color(0xFF94a3b8)),
            ),
          ),
        ],
      ),
    );
  }
}
