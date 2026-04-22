import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;

void showDriverAwbDialog({
  required BuildContext context,
  required Map<String, dynamic> awbItem,
  required bool dark,
}) {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
  final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
  final bgGlassy = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
  final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
  
  final String? awbId = awbItem['awb_id']?.toString();
  final String? uldId = awbItem['uld_id']?.toString();
  final String awbNumber = awbItem['awb_number']?.toString() ?? awbItem['uld_number']?.toString() ?? awbItem['awb']?.toString() ?? 'N/A';
  final String pieces = awbItem['found']?.toString() ?? '0';
  final String weight = awbItem['weight']?.toString() ?? '0';
  Set<int> collapsedSplits = {};

  showDialog(
    context: context,
    barrierDismissible: false, // Must tap the X to close
    builder: (ctx) {
      final size = MediaQuery.of(context).size;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: size.height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: bgDialog,
              child: Column(
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
                            color: const Color(0xFF3b82f6).withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF3b82f6), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(uldId != null ? 'ULD Details' : 'AWB Details', style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(awbNumber, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: textS),
                          hoverColor: Colors.white.withAlpha(10),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),
                  
                  // Summary Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: bgGlassy,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Total Pieces', pieces, textS, textP),
                        _buildSummaryItem('Total Weight', '$weight kg', textS, textP),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),

                  // FutureBuilder for awb_splits or ulds
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: () async {
                        try {
                          if (uldId != null && uldId.isNotEmpty) {
                            // Es un ULD (tabla principal ulds)
                            final res = await Supabase.instance.client
                                .from('ulds')
                                .select('*, flights:id_flight(*)')
                                .eq('id_uld', uldId)
                                .maybeSingle();
                            if (res != null) return [res];
                            return [];
                          } else if (awbId != null && awbId.isNotEmpty) {
                            // Es un AWB (tabla intermedia awb_splits)
                            final res = await Supabase.instance.client
                                .from('awb_splits')
                                .select('*, ulds(*), flights(*)')
                                .eq('awb_id', awbId);
                            return List<dynamic>.from(res);
                          } else {
                            // Fallback para entregas viejas
                            final res = await Supabase.instance.client
                                .from('awbs')
                                .select('id, awb_number, awb_splits(*, ulds(*), flights(*))')
                                .eq('awb_number', awbNumber.replaceAll('AWB: ', '').replaceAll('ULD: ', ''))
                                .maybeSingle();
                            return List<dynamic>.from(res?['awb_splits'] ?? []);
                          }
                        } catch (e) {
                          debugPrint('Error fetching details: $e');
                          return [];
                        }
                      }(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6)));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading details.', style: TextStyle(color: textS)));
                        }
                        
                        final List<dynamic> splits = snapshot.data ?? [];
                        
                        if (splits.isEmpty) {
                          return Center(child: Text('No information found.', style: TextStyle(color: textS)));
                        }
                        
                        return ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: splits.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final split = splits[index];
                            
                            String uldName = 'N/A';
                            String flightName = 'N/A';
                            String itemPieces = split['pieces']?.toString() ?? split['pieces_total']?.toString() ?? '0';
                            
                            List locList = [];
                            if (split['data_location'] is List) {
                              locList = split['data_location'] as List;
                            } else if (split['data_location'] is Map && (split['data_location'] as Map).isNotEmpty) {
                              locList = [split['data_location']];
                            }

                            List coordList = [];
                            if (split['data_coordinator'] is List) {
                              coordList = split['data_coordinator'] as List;
                            } else if (split['data_coordinator'] is Map && (split['data_coordinator'] as Map).isNotEmpty) {
                              coordList = [split['data_coordinator']];
                            }
                            
                            // Check si la fila es de la tabla ulds directamente
                            if (split.containsKey('id_uld') && !split.containsKey('awb_id')) {
                               uldName = split['uld_number']?.toString() ?? 'N/A';
                               if (split['flights'] is Map) {
                                  flightName = split['flights']['number']?.toString() ?? 'N/A';
                               }
                            } else {
                               // La fila viene de awb_splits
                               if (split['ulds'] is Map) {
                                  uldName = split['ulds']['uld_number']?.toString() ?? 'N/A';
                               }
                               if (split['flights'] is Map) {
                                  flightName = split['flights']['number']?.toString() ?? 'N/A';
                               }
                            }
                            
                            return StatefulBuilder(
                              builder: (context, setItemState) {
                                final bool isCollapsed = collapsedSplits.contains(index);
                                
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: dark ? Colors.white.withAlpha(5) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderC),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory_2_rounded, color: Color(0xFF10b981), size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'ULD: $uldName', 
                                              style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3b82f6).withAlpha(30),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$itemPieces pcs', 
                                              style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          if (locList.isNotEmpty || coordList.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                setItemState(() {
                                                  if (isCollapsed) {
                                                    collapsedSplits.remove(index);
                                                  } else {
                                                    collapsedSplits.add(index);
                                                  }
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(20),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Icon(
                                                  isCollapsed ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                                                  color: isCollapsed ? textS : const Color(0xFF3b82f6), 
                                                  size: 20
                                                ),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.flight_land_rounded, color: textS, size: 14),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Flight Ref: $flightName', 
                                              style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (split.containsKey('awb_id')) ...[
                                        if ((locList.isNotEmpty || coordList.isNotEmpty) && !isCollapsed) ...[
                                          const SizedBox(height: 12),
                                          const Divider(height: 1),
                                          const SizedBox(height: 8),
                                          Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: borderC),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.person_rounded, color: textS, size: 14),
                                                      const SizedBox(width: 6),
                                                      Text('Coordinator Info', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (coordList.isEmpty)
                                                    Text('No data', style: TextStyle(color: textS, fontSize: 12))
                                                  else
                                                    ...coordList.map((item) {
                                                      final map = Map.from(item as Map);
                                                      final by = map.remove('processed_by') ?? map.remove('user') ?? 'Unknown';
                                                      final timeRaw = map.remove('processed_at') ?? map.remove('time');
                                                      
                                                      String timeStr = '';
                                                      if (timeRaw != null) {
                                                        final time = DateTime.tryParse(timeRaw.toString())?.toLocal();
                                                        if (time != null) {
                                                          final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
                                                          final ampm = time.hour >= 12 ? 'PM' : 'AM';
                                                          final minute = time.minute.toString().padLeft(2, '0');
                                                          final esMonths = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                                                          final enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                                          final monthStr = appLanguage.value == 'es' ? esMonths[time.month - 1] : enMonths[time.month - 1];
                                                          final dayStr = time.day.toString().padLeft(2, '0');
                                                          timeStr = ' [$dayStr $monthStr, $hour:$minute $ampm]';
                                                        }
                                                      }
                                                      
                                                      Map bd = {};
                                                      if (map['breakdown'] is Map) {
                                                        bd = Map.from(map['breakdown'] as Map);
                                                      } else {
                                                        bd = Map.from(map);
                                                      }
                                                      
                                                      // Remove unwanted keys from the unified breakdown map
                                                      bd.remove('remark');
                                                      bd.remove('remarks');
                                                      bd.remove('Remarks');
                                                      bd.remove('discrepancy_check');
                                                      bd.remove('discrepancy check');
                                                      bd.remove('discrepancy_checked');
                                                      bd.remove('discrepancy checked');
                                                      bd.remove('discrepancy_expected');
                                                      bd.remove('discrepancy expected');
                                                      
                                                      final discAmount = bd.remove('discrepancy_amount') ?? bd.remove('discrepancy amount');
                                                      final discType = bd.remove('discrepancy_type') ?? bd.remove('discrepancy type');
                                                      String discrepancyStr = '';
                                                      if (discAmount != null && discAmount.toString().isNotEmpty && discAmount.toString() != '0') {
                                                        discrepancyStr = '${discAmount.toString()} ${discType?.toString() ?? ''}'.trim().toUpperCase();
                                                      }
                                                      
                                                      final locReq1 = bd.remove('location_required');
                                                      final locReq2 = bd.remove('required_location');
                                                      final locReq3 = bd.remove('location required');
                                                      final locReq4 = bd.remove('Location requerida');
                                                      final locReq5 = bd.remove('location requerida');
                                                      String locReqStr = (locReq1 ?? locReq2 ?? locReq3 ?? locReq4 ?? locReq5 ?? '').toString();
                                                      if (locReqStr.toLowerCase() == 'null') locReqStr = '';
                                                      
                                                      bd.removeWhere((k, v) => const ['processed_by', 'processed_at', 'user', 'time', 'refULD', 'manual_entry', 'breakdown'].contains(k));
                                                      
                                                      List<Widget> chips = [];
                                                      bd.forEach((key, value) {
                                                        if (value is List && value.isEmpty) return;
                                                        if (value == null || value.toString().isEmpty || value.toString() == '0') return;
                                                        chips.add(Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                          decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                                          child: Text('$key: ${value is List ? value.join(', ') : value}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ));
                                                      });

                                                      Widget? discWidget;
                                                      if (discrepancyStr.isNotEmpty) {
                                                        discWidget = Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                          decoration: BoxDecoration(color: Colors.redAccent.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                                                              const SizedBox(width: 4),
                                                              Flexible(child: Text(discrepancyStr, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                      
                                                      Widget? locWidget;
                                                      if (locReqStr.isNotEmpty && locReqStr.toLowerCase() != 'false' && locReqStr != '0') {
                                                        locWidget = Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                          decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Icon(Icons.location_on, size: 12, color: Colors.blue),
                                                              const SizedBox(width: 4),
                                                              Flexible(child: Text(locReqStr, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                      
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 6),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('By: $by$timeStr', style: TextStyle(color: textP, fontSize: 11, fontWeight: FontWeight.w600)),
                                                            const SizedBox(height: 4),
                                                            if (chips.isNotEmpty)
                                                              Wrap(
                                                                spacing: 4,
                                                                runSpacing: 4,
                                                                children: chips,
                                                              )
                                                            else if (discWidget == null && locWidget == null)
                                                              Text('No details', style: TextStyle(color: textS, fontSize: 10)),
                                                            if (discWidget != null || locWidget != null) ...[
                                                              if (chips.isNotEmpty)
                                                                Padding(
                                                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                                                  child: Divider(height: 1, color: borderC),
                                                                ),
                                                              Row(
                                                                children: [
                                                                  if (locWidget != null) Expanded(child: locWidget),
                                                                  if (discWidget != null && locWidget != null) ...[
                                                                    const SizedBox(width: 8),
                                                                    Container(width: 1, height: 20, color: borderC),
                                                                    const SizedBox(width: 8),
                                                                  ],
                                                                  if (discWidget != null) Expanded(child: discWidget),
                                                                ],
                                                              ),
                                                            ]
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: borderC),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.place_rounded, color: textS, size: 14),
                                                      const SizedBox(width: 6),
                                                      Text('Locations', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (locList.isEmpty)
                                                    Text('No locations', style: TextStyle(color: textS, fontSize: 12))
                                                  else
                                                    ...locList.map((item) {
                                                      final map = Map.from(item as Map);
                                                      final List<Widget> locChips = [];
                                                      
                                                      void extractLocs(Map m) {
                                                        m.forEach((key, value) {
                                                          if (['updated_by', 'processed_by', 'user', 'updated_at', 'processed_at', 'time'].contains(key)) return;
                                                          if (value == null || value.toString().isEmpty || value.toString() == '0') return;
                                                          locChips.add(
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                                              child: Text(value.toString(), style: const TextStyle(color: Color(0xFF10b981), fontSize: 10, fontWeight: FontWeight.bold)),
                                                            )
                                                          );
                                                        });
                                                      }

                                                      if (map.containsKey('locations') && map['locations'] is List) {
                                                        for (var locItem in map['locations']) {
                                                          if (locItem is Map) extractLocs(locItem);
                                                        }
                                                      } else {
                                                        extractLocs(map);
                                                      }
                                                      
                                                      if (locChips.isEmpty) return const SizedBox.shrink();
                                                      
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 6),
                                                        child: Wrap(
                                                          spacing: 4,
                                                          runSpacing: 4,
                                                          children: locChips,
                                                        ),
                                                      );
                                                    }),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ); // closes Container
                          }, // closes builder of StatefulBuilder
                        ); // closes StatefulBuilder
                      }, // closes itemBuilder
                    ); // closes ListView.separated
                  }, // closes builder of FutureBuilder
                ), // closes FutureBuilder
              ), // closes Expanded
              
              // Bottom Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgDialog,
                  border: Border(top: BorderSide(color: borderC)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dark ? Colors.white.withAlpha(5) : Colors.grey.shade100,
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3b82f6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ], // closes Column children
          ), // closes Column
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildSummaryItem(String label, String value, Color textS, Color textP) {
  return Column(
    children: [
      Text(label, style: TextStyle(color: textS, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );
}
