import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'location_v2_logic.dart';
import 'location_v2_not_found_modal.dart';
import 'location_v2_split_modal.dart';
import 'location_v2_history_modal.dart';

class LocationV2ScannerModal {
  static Future<void> show(
    BuildContext context, {
    required String query,
    required List<Map<String, dynamic>> matches,
    required LocationV2Logic logic,
  }) async {
    if (matches.isEmpty) {
      await LocationV2NotFoundModal.show(context, query);
    } else if (matches.length == 1) {
      await showLocationEditor(context, matches.first, logic);
    } else {
      await LocationV2SplitModal.show(context, query, matches, logic);
    }
  }


  static Future<void> showLocationEditor(
    BuildContext context,
    Map<String, dynamic> split,
    LocationV2Logic logic, {
    bool isReadOnly = false,
  }) async {
    final dark = isDarkMode.value;
    final bgCol = dark ? const Color(0xFF1e293b) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

    final master = split['awbs'];
    Map<String, dynamic> masterMap = {};
    if (master is Map<String, dynamic>) {
      masterMap = master;
    } else if (master is List && master.isNotEmpty) {
      masterMap = master.first as Map<String, dynamic>;
    }

    final awbNumber = (masterMap['awb_number'] ?? split['awb_number'] ?? '').toString();
    final pieces = split['pieces']?.toString() ?? split['pieces_split']?.toString() ?? '0';
    final weight = split['weight']?.toString() ?? split['weight_split']?.toString() ?? '0.0';

    final reqLoc = split['required_location']?.toString().trim();
    final hasReqLoc = reqLoc != null && reqLoc.isNotEmpty;

    final TextEditingController locationCtrl = TextEditingController();
    
    // Parse existing locations
    List<Map<String, dynamic>> parsedLocations = [];
    if (split['data_location'] != null && split['data_location'] is Map) {
      final locData = split['data_location'] as Map;
      if (locData['locations'] != null && locData['locations'] is List) {
        for (var item in locData['locations']) {
          if (item is Map) parsedLocations.add(Map<String, dynamic>.from(item));
        }
      } else if (locData['location'] != null) {
        // Migration from old format
        parsedLocations.add({
          'location': locData['location'].toString(),
          'updated_by': locData['updated_by'],
          'updated_at': locData['updated_at'],
        });
      }
    }

    bool isSaving = false;
    String? locationError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          Future<void> handleSave() async {
            if (isSaving) return;

            final locText = locationCtrl.text.trim().toUpperCase();
            if (locText.isEmpty) {
              setDialogState(() {
                locationError = appLanguage.value == 'es' ? 'Requerido' : 'Required';
              });
              return;
            }

            setDialogState(() => isSaving = true);

            try {
              final supabase = Supabase.instance.client;
              final splitId = split['id'];

              // Append new location to parsedLocations
              parsedLocations.add({
                'location': locText,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
                'updated_by': supabase.auth.currentUser?.id,
              });

              Map<String, dynamic> newLocData = {
                'locations': parsedLocations,
              };

              bool isConfirmed = split['is_location_confirmed'] == true;
              if (hasReqLoc && locText.toUpperCase() == reqLoc.toUpperCase()) {
                isConfirmed = true;
              }

              await supabase.from('awb_splits').update({
                'data_location': newLocData,
                'is_location_confirmed': isConfirmed,
              }).eq('id', splitId);

              if (logic.selectedUldId == split['uld_id']?.toString()) {
                logic.fetchAwbsForUld(split['uld_id'].toString());
              }
              if (logic.selectedFlightId != null) {
                logic.fetchUldsForFlight(logic.selectedFlightId!, isSilent: true);
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                
                bool dialogOpen = true;
                showGeneralDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black54,
                  transitionDuration: const Duration(milliseconds: 350),
                  pageBuilder: (context, anim1, anim2) {
                    final dark = isDarkMode.value;
                    return Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF1e293b) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10b981).withAlpha(40),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10b981).withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                appLanguage.value == 'es' ? '¡Locación Guardada!' : 'Location Saved!',
                                style: TextStyle(
                                  color: dark ? Colors.white : const Color(0xFF111827),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return Transform.scale(
                      scale: Curves.easeOutBack.transform(anim1.value),
                      child: FadeTransition(
                        opacity: anim1,
                        child: child,
                      ),
                    );
                  },
                ).then((_) => dialogOpen = false);

                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (dialogOpen && context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              if (ctx.mounted) {
                setDialogState(() => isSaving = false);
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
                const Icon(Icons.location_on_outlined, color: Color(0xFF10b981), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appLanguage.value == 'es' ? 'Asignar Locación' : 'Assign Location',
                    style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (!isReadOnly && parsedLocations.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.history, color: Color(0xFF6366f1), size: 22),
                    onPressed: () {
                      LocationV2HistoryModal.show(
                        context, 
                        parsedLocations, 
                        split, 
                        logic,
                        () {
                          setDialogState(() {});
                        }
                      );
                    },
                  ),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AWB', style: TextStyle(color: textS, fontSize: 11)),
                              Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pieces', style: TextStyle(color: textS, fontSize: 11)),
                              Text(pieces, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weight', style: TextStyle(color: textS, fontSize: 11)),
                              Text('$weight kg', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasReqLoc) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf59e0b).withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFf59e0b).withAlpha(30)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFf59e0b), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appLanguage.value == 'es' ? 'Locación Requerida:' : 'Required Location:',
                                  style: TextStyle(color: textS, fontSize: 11),
                                ),
                                Text(
                                  reqLoc.toString(),
                                  style: const TextStyle(color: Color(0xFFf59e0b), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFf59e0b),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                locationCtrl.text = reqLoc;
                              });
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(appLanguage.value == 'es' ? 'Confirmar' : 'Confirm'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Chips moved to history dialog
                  if (!isReadOnly) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appLanguage.value == 'es' ? 'Ubicación / Rack / Zona' : 'Location / Rack / Zone',
                          style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              locationCtrl.text = 'OVERSIZE';
                              locationError = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Tooltip(
                            message: 'Oversize',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_full_rounded, color: textS.withAlpha(150), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'OVERSIZE', 
                                    style: TextStyle(color: textS.withAlpha(150), fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationCtrl,
                      style: TextStyle(color: textP, fontSize: 14),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      autofocus: true,
                      onChanged: (val) {
                        if (locationError != null) {
                          setDialogState(() => locationError = null);
                        }
                      },
                      onSubmitted: (_) => handleSave(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: dark ? Colors.white.withAlpha(10) : Colors.white,
                        hintText: 'Ej. RACK-A1, FLOOR-2',
                        hintStyle: TextStyle(color: textS.withAlpha(150), fontSize: 14),
                        errorText: locationError,
                        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: dark ? Colors.white.withAlpha(30) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: dark ? Colors.white.withAlpha(30) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF10b981)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                  if (isReadOnly && parsedLocations.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      appLanguage.value == 'es' ? 'Locaciones Registradas' : 'Registered Locations',
                      style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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
                          ],
                        ),
                      );
                    }),
                  ] else if (isReadOnly && parsedLocations.isEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      appLanguage.value == 'es' ? 'No hay locaciones registradas.' : 'No locations registered.',
                      style: TextStyle(color: textS, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (isReadOnly)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    appLanguage.value == 'es' ? 'Cerrar' : 'Close',
                    style: const TextStyle(color: Color(0xFF6366f1)),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(
                    appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                    style: const TextStyle(color: Color(0xFF94a3b8)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving ? null : () => handleSave(),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(appLanguage.value == 'es' ? 'Guardar' : 'Save'),
                ),
              ]
            ],
          );
        },
      ),
    );
  }


}
