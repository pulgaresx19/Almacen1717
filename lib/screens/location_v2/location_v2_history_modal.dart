import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'location_v2_logic.dart';

class LocationV2HistoryModal {
  static Future<void> show(
    BuildContext context,
    List<Map<String, dynamic>> parsedLocations,
    Map<String, dynamic> split,
    LocationV2Logic logic,
    VoidCallback onUpdated,
  ) async {
    final dark = isDarkMode.value;
    final bgCol = dark ? const Color(0xFF1e293b) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          Future<void> handleDelete(Map<String, dynamic> locObj) async {
            try {
              final supabase = Supabase.instance.client;
              parsedLocations.remove(locObj);

              bool isConfirmed = false;
              final reqLoc = split['required_location']?.toString().trim();
              if (reqLoc != null && reqLoc.isNotEmpty) {
                isConfirmed = parsedLocations.any((l) => l['location'].toString().toUpperCase() == reqLoc.toUpperCase());
              }

              await supabase.from('awb_splits').update({
                'data_location': {'locations': parsedLocations},
                'is_location_confirmed': isConfirmed,
              }).eq('id', split['id']);

              if (logic.selectedUldId == split['uld_id']?.toString()) {
                logic.fetchAwbsForUld(split['uld_id'].toString());
              }

              onUpdated();
              setDialogState(() {});

              if (parsedLocations.isEmpty) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          }

          return AlertDialog(
            backgroundColor: bgCol,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            title: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF6366f1), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appLanguage.value == 'es' ? 'Historial' : 'History',
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
                  ...parsedLocations.map((locObj) {
                    final locText = locObj['location'].toString();
                    final time = locObj['updated_at'] != null 
                        ? DateTime.tryParse(locObj['updated_at'].toString())?.toLocal() 
                        : null;
                    String timeStr = '';
                    if (time != null) {
                      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
                      final ampm = time.hour >= 12 ? 'PM' : 'AM';
                      final minute = time.minute.toString().padLeft(2, '0');
                      
                      final esMonths = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                      final enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final monthStr = appLanguage.value == 'es' ? esMonths[time.month - 1] : enMonths[time.month - 1];
                      final dayStr = time.day.toString().padLeft(2, '0');

                      timeStr = '[$dayStr $monthStr, $hour:$minute $ampm]';
                    }
                        
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF6366f1), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    locText, 
                                    style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(timeStr, style: TextStyle(color: textS, fontSize: 11)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => handleDelete(locObj),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(appLanguage.value == 'es' ? 'Cerrar' : 'Close', style: const TextStyle(color: Color(0xFF6366f1))),
              ),
            ],
          );
        },
      ),
    );
  }
}
