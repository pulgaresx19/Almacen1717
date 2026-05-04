import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'awbs_v2_dialogs.dart';
import 'awbs_v2_add_awb_form.dart';
import 'awbs_v2_add_uld_form.dart';
import 'awbs_v2_uld_list_item.dart';

class AwbsV2AddItemsScreen extends StatefulWidget {
  final VoidCallback onPop;

  const AwbsV2AddItemsScreen({super.key, required this.onPop});

  @override
  State<AwbsV2AddItemsScreen> createState() => _AwbsV2AddItemsScreenState();
}

class _AwbsV2AddItemsScreenState extends State<AwbsV2AddItemsScreen> {
  final List<Map<String, dynamic>> _addedAwbs = [];
  final List<Map<String, dynamic>> _addedUlds = [];
  bool _isSavingAll = false;
  bool _showEmptyError = false;

  Future<void> _saveAllItems() async {
    if (_addedAwbs.isEmpty && _addedUlds.isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }

    for (var u in _addedUlds) {
      final nested = u['awbs'] as List? ?? [];
      if (nested.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) {
            final dark = isDarkMode.value;
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1e293b) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dark ? Colors.white12 : Colors.black12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      appLanguage.value == 'es' ? 'Acción Requerida' : 'Action Required',
                      style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appLanguage.value == 'es' 
                        ? 'Faltan AWBs para el ULD ${u['uld_number']}. Añade al menos uno.' 
                        : 'AWBs are missing for ULD ${u['uld_number']}. Add at least one.',
                      style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          appLanguage.value == 'es' ? 'ENTENDIDO' : 'UNDERSTOOD',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        return;
      }
    }

    setState(() => _isSavingAll = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      String userName = session?.user.email ?? 'Unknown';
      if (session != null) {
        if (session.user.userMetadata?['full_name'] != null) {
          userName = session.user.userMetadata!['full_name'].toString();
        }
        try {
          final profile = await Supabase.instance.client.from('users').select('full_name').eq('id', session.user.id).maybeSingle();
          if (profile != null && profile['full_name'] != null && profile['full_name'].toString().trim().isNotEmpty) {
            userName = profile['full_name'].toString().trim();
          }
        } catch (_) {}
      }

      Map<String, dynamic> formatCoordinator(Map<dynamic, dynamic>? counts, int expectedPieces) {
        if (counts == null || counts.isEmpty) return {};
        final coordRecord = <String, dynamic>{};
        int totalChecked = 0;
        void addValues(String key, String label) {
          if (counts[key] != null) {
            final list = counts[key].toString().split(RegExp(r'[,\s-]+')).where((e) => int.tryParse(e) != null && int.parse(e) > 0).toList();
            for (int i = 0; i < list.length; i++) {
              final val = int.parse(list[i]);
              coordRecord['${i + 1}. $label'] = val;
              totalChecked += val;
            }
          }
        }
        addValues('AGI Skid', 'AGI skid');
        addValues('Pre Skid', 'Pre skid');
        addValues('Crate', 'Crate');
        addValues('Box', 'Box');
        addValues('Other', 'Other');
        if (coordRecord.isNotEmpty) {
          coordRecord['processed_at'] = DateTime.now().toUtc().toIso8601String();
          coordRecord['processed_by'] = userName;
          if (expectedPieces > 0 && totalChecked != expectedPieces) {
            coordRecord['discrepancy_type'] = totalChecked > expectedPieces ? 'OVER' : 'SHORT';
            coordRecord['discrepancy_amount'] = (totalChecked - expectedPieces).abs();
            coordRecord['discrepancy_checked'] = totalChecked;
            coordRecord['discrepancy_expected'] = expectedPieces;
          }
        }
        return coordRecord;
      }

      List<Map<String, dynamic>> formatLocations(Map<dynamic, dynamic>? locs) {
        if (locs == null || locs.isEmpty) return [];
        final items = <Map<String, dynamic>>[];
        locs.forEach((k, v) {
          if (v.toString().trim().isNotEmpty) {
            items.add({
              'location': v.toString().trim(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
              'updated_by': userName,
            });
          }
        });
        return items;
      }

      final payload = <String, dynamic>{};

      if (_addedAwbs.isNotEmpty) {
        payload['awbs'] = _addedAwbs.map((a) {
          final expected = int.tryParse(a['pieces'].toString()) ?? 1;
          return {
            'awb_number': a['awb_number'],
            'pieces': expected,
            'total_pieces': int.tryParse(a['total_pieces'].toString()) ?? 1,
            'weight': double.tryParse(a['weight'].toString()) ?? 0.0,
            'remarks': a['remarks'].toString().isEmpty ? null : a['remarks'],
            'data_coordinator': formatCoordinator(a['data_coordinator'] as Map?, expected),
            'data_location': formatLocations(a['data_location'] as Map?),
          };
        }).toList();
      }

      if (_addedUlds.isNotEmpty) {
        payload['ulds'] = _addedUlds.map((u) {
          final nestedAwbs = (u['awbs'] as List? ?? []).map((a) {
            final expected = int.tryParse(a['pieces'].toString()) ?? 1;
            return {
              'awb_number': a['awb_number'],
              'pieces': expected,
              'total_pieces': int.tryParse(a['total_pieces'].toString()) ?? 1,
              'weight': double.tryParse(a['weight'].toString()) ?? 0.0,
              'remarks': a['remarks'].toString().isEmpty ? null : a['remarks'],
              'data_coordinator': formatCoordinator(a['data_coordinator'] as Map?, expected),
              'data_location': formatLocations(a['data_location'] as Map?),
            };
          }).toList();

          return {
            'uld_number': u['uld_number'],
            'pieces': int.tryParse(u['pieces'].toString()) ?? 0,
            'weight': double.tryParse(u['weight'].toString()) ?? 0.0,
            'remarks': u['remarks'].toString().isEmpty ? null : u['remarks'],
            'awbs': nestedAwbs,
          };
        }).toList();
      }

      if (payload.isNotEmpty) {
        await Supabase.instance.client.rpc('save_manual_inventory_items', params: {'payload': payload});
      }

      if (mounted) {
         setState(() {
            _addedAwbs.clear();
            _addedUlds.clear();
         });

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
                   width: 320, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                   decoration: BoxDecoration(color: dark ? const Color(0xFF1e293b) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF10b981).withAlpha(40), blurRadius: 40, offset: const Offset(0, 10))], border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5)),
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(20), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48)),
                       const SizedBox(height: 24),
                       Text(appLanguage.value == 'es' ? '¡Registros Guardados!' : 'Records Saved!', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                       const SizedBox(height: 8),
                       Text(appLanguage.value == 'es' ? 'El inventario se ha guardado exitosamente.' : 'The inventory was saved successfully.', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                     ],
                   ),
                 ),
               ),
             );
           },
           transitionBuilder: (context, anim1, anim2, child) => Transform.scale(scale: Curves.easeOutBack.transform(anim1.value), child: FadeTransition(opacity: anim1, child: child)),
         ).then((_) => dialogOpen = false);

         await Future.delayed(const Duration(milliseconds: 2000));
         if (mounted) {
           if (dialogOpen) Navigator.of(context).pop();
           widget.onPop();
         }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Error: $e'), 
           backgroundColor: Colors.redAccent
         ));
      }
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderCard)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: textP),
                      onPressed: widget.onPop,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      appLanguage.value == 'es' ? 'Añadir Nuevo Ítem' : 'Add New Item',
                      style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              // Split Content
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // AWB Section
                    Expanded(
                      child: AwbsV2AddAwbForm(
                        globalAwbs: _addedAwbs,
                        globalUlds: _addedUlds,
                        onAdd: (item) {
                          setState(() {
                            _addedAwbs.add(item);
                            _showEmptyError = false;
                          });
                        },
                      ),
                    ),
                    
                    // Divider
                    Container(width: 1, color: borderCard),
                    
                    // ULD Section
                    Expanded(
                      child: AwbsV2AddUldForm(
                        globalUlds: _addedUlds,
                        onAdd: (item) {
                          setState(() {
                            _addedUlds.add(item);
                            _showEmptyError = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
            
            const SizedBox(height: 24),
            
            // Bottom Lists Section
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AWB List Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (_showEmptyError && _addedAwbs.isEmpty) ? Colors.redAccent : borderCard),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              appLanguage.value == 'es' ? 'Lista de AWBs' : 'AWB List',
                              style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_addedAwbs.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  appLanguage.value == 'es' ? 'No hay AWBs agregados aún.' : 'No AWBs added yet.',
                                  style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _addedAwbs.length,
                                itemBuilder: (context, index) {
                                  final item = _addedAwbs[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: borderCard),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28, height: 28, alignment: Alignment.center,
                                          decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                                          child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text('AWB Number', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text(item['awb_number'], style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ])),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text('Pieces', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text('${item['pieces'].toString().isEmpty ? '0' : item['pieces']}', style: TextStyle(color: textP, fontSize: 13)),
                                        ])),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text('Total', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text('${item['total_pieces'].toString().isEmpty ? '0' : item['total_pieces']}', style: TextStyle(color: textP, fontSize: 13)),
                                        ])),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text('Weight', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text('${item['weight'].toString().isEmpty ? '0' : item['weight']}', style: TextStyle(color: textP, fontSize: 13)),
                                        ])),
                                        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text('Remark', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text(item['remarks'].toString().isEmpty ? '-' : item['remarks'], style: TextStyle(color: textP, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ])),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.other_houses_outlined, color: item['house_number'] != null && item['house_number'].toString().trim().isNotEmpty ? const Color(0xFFf59e0b) : (dark ? Colors.white24 : Colors.black26), size: 18),
                                              onPressed: () {
                                                if (item['house_number'] != null && item['house_number'].toString().trim().isNotEmpty) {
                                                   List<String> houses = item['house_number'].toString().split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                                   showCustomListDialog(context, 'House Numbers', houses);
                                                }
                                              },
                                              tooltip: 'House Numbers',
                                              splashRadius: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 12),
                                            IconButton(
                                              icon: Icon(Icons.assignment_rounded, color: item['data_coordinator'] != null && (item['data_coordinator'] as Map).isNotEmpty ? const Color(0xFF6366f1) : (dark ? Colors.white24 : Colors.black26), size: 18),
                                              onPressed: () {
                                                if (item['data_coordinator'] != null && (item['data_coordinator'] as Map).isNotEmpty) {
                                                   showCoordinatorDataPreviewDialog(context, {
                                                      'pieces': item['pieces'], 
                                                      'coordinatorCounts': item['data_coordinator'],
                                                   });
                                                }
                                              },
                                              tooltip: 'Data Coordinator',
                                              splashRadius: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 12),
                                            IconButton(
                                              icon: Icon(Icons.location_on_rounded, color: item['data_location'] != null && (item['data_location'] as Map).isNotEmpty ? const Color(0xFF10b981) : (dark ? Colors.white24 : Colors.black26), size: 18),
                                              onPressed: () {
                                                if (item['data_location'] != null && (item['data_location'] as Map).isNotEmpty) {
                                                   showItemLocationPreviewDialog(context, {
                                                      'pieces': item['pieces'],
                                                      'coordinatorCounts': item['data_coordinator'],
                                                      'itemLocations': item['data_location'],
                                                   });
                                                }
                                              },
                                              tooltip: 'Data Location',
                                              splashRadius: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(width: 1, height: 24, color: borderCard),
                                            const SizedBox(width: 12),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                              onPressed: () => setState(() => _addedAwbs.removeAt(index)),
                                              splashRadius: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // ULD List Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (_showEmptyError && _addedUlds.isEmpty) ? Colors.redAccent : borderCard),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              appLanguage.value == 'es' ? 'Lista de ULDs' : 'ULD List',
                              style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_addedUlds.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  appLanguage.value == 'es' ? 'No hay ULDs agregados aún.' : 'No ULDs added yet.',
                                  style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _addedUlds.length,
                                itemBuilder: (context, index) {
                                  final item = _addedUlds[index];
                                  return AwbsV2UldListItem(
                                    item: item,
                                    index: index,
                                    dark: dark,
                                    textP: textP,
                                    borderCard: borderCard,
                                    globalAwbs: _addedAwbs,
                                    globalUlds: _addedUlds,
                                    onDelete: () {
                                      setState(() {
                                        _addedUlds.removeAt(index);
                                      });
                                    },
                                    onUpdate: () {
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSavingAll ? null : _saveAllItems,
                  icon: _isSavingAll 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    appLanguage.value == 'es' ? 'Guardar Registros' : 'Save Records',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
