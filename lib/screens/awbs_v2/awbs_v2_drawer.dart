import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'awbs_v2_print_preview.dart';

class AwbsV2Drawer {
  static void show(BuildContext context, Map<String, dynamic> u, bool dark, int receivedPieces, int expectedPieces, String status) {
    final Future<List<Map<String, dynamic>>> splitsFuture = Supabase.instance.client
        .from('awb_splits')
        .select('*, ulds(uld_number, is_break), flights(carrier, number, date)')
        .eq('awb_id', u['id'])
        .order('created_at', ascending: false)
        .then((res) => List<Map<String, dynamic>>.from(res));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        final Set<int> expandedCards = {};

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBuilder) {
            String formatChicagoTime(String? timeStr) {
               if (timeStr == null) return '-';
               final dt = DateTime.tryParse(timeStr);
               if (dt == null) return '-';
               final utc = dt.isUtc ? dt : dt.toUtc();
               final chicago = utc.subtract(const Duration(hours: 5));
               int h = chicago.hour;
               String amPm = h >= 12 ? 'PM' : 'AM';
               if (h == 0) { h = 12; }
               else if (h > 12) { h -= 12; }
               String hh = h.toString().padLeft(2, '0');
               String mm = chicago.minute.toString().padLeft(2, '0');
               String mth = chicago.month.toString().padLeft(2, '0');
               String dd = chicago.day.toString().padLeft(2, '0');
               String yy = chicago.year.toString();
               return '$hh:$mm $amPm $mth/$dd/$yy';
            }

            Widget buildTraceability() {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: splitsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))));
                  }
                  if (snapshot.hasError) {
                    return Padding(padding: const EdgeInsets.all(16), child: Text('Error loading traceability: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  
                  final splits = snapshot.data ?? [];
                  if (splits.isEmpty) {
                    return Padding(padding: const EdgeInsets.all(16), child: Text('No traceability data available for this AWB.', style: TextStyle(color: textS)));
                  }

                  return Column(
                    children: splits.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final s = entry.value;
                      final isExpanded = expandedCards.contains(idx);
                      
                      List uldDcData = [];
                      if (s['data_coordinator'] is List) {
                        uldDcData = s['data_coordinator'] as List;
                      } else if (s['data_coordinator'] is Map && (s['data_coordinator'] as Map).isNotEmpty) {
                        uldDcData = [s['data_coordinator']];
                      }

                      List locList = [];
                      if (s['data_location'] is List) {
                        locList = s['data_location'] as List;
                      } else if (s['data_location'] is Map && (s['data_location'] as Map).isNotEmpty) {
                        locList = [s['data_location']];
                      }

                      final uldData = s['ulds'] ?? {};
                      final flightData = s['flights'] ?? {};
                      
                      final String? uldIdRaw = s['uld_id']?.toString();
                      final bool hasUld = uldData.isNotEmpty || (uldIdRaw != null && uldIdRaw.isNotEmpty && uldIdRaw != 'null');
                      final String uldNum = hasUld ? (uldData['uld_number']?.toString() ?? uldIdRaw ?? 'Unknown ULD') : 'Manual';

                      final String? flightIdRaw = s['flight_id']?.toString();
                      final bool hasFlight = flightData.isNotEmpty || (flightIdRaw != null && flightIdRaw.isNotEmpty && flightIdRaw != 'null');
                      
                      final String flightDate = flightData['date']?.toString() ?? '-';
                      String flightNum;
                      if (!hasFlight) {
                        flightNum = 'Manual';
                      } else {
                        final String carrier = flightData['carrier']?.toString() ?? '';
                        final String fNumber = flightData['number']?.toString() ?? flightIdRaw ?? 'Unknown Flight';
                        String shortDate = '';
                        if (flightDate != '-') {
                          try {
                            final dt = DateTime.parse(flightDate).toLocal();
                            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            shortDate = ' (${months[dt.month - 1]} ${dt.day})';
                          } catch (_) {}
                        }
                        flightNum = '$carrier $fNumber'.trim() + shortDate;
                      }

                      Color badgeColor;
                      Color badgeBgColor;
                      Color badgeBorderColor;
                      String badgeText;

                      if (!hasUld) {
                        badgeText = 'MANUAL';
                        badgeColor = const Color(0xFFf59e0b);
                        badgeBgColor = badgeColor.withAlpha(30);
                        badgeBorderColor = badgeColor.withAlpha(50);
                      } else {
                        final bool isBreak = uldData['is_break'] == true;
                        badgeText = isBreak ? 'BREAK' : 'NO BREAK';
                        badgeColor = isBreak ? const Color(0xFF10b981) : const Color(0xFFef4444);
                        badgeBgColor = badgeColor.withAlpha(30);
                        badgeBorderColor = badgeColor.withAlpha(50);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                 setStateBuilder(() {
                                    if (isExpanded) {
                                      expandedCards.remove(idx);
                                    } else {
                                      expandedCards.add(idx);
                                    }
                                 });
                              },
                              borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.flight_land, size: 16, color: Color(0xFF6366f1)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(uldNum, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Text('$flightNum • ${s['pieces'] ?? 0} pcs', style: TextStyle(color: textS, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeBgColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: badgeBorderColor),
                                      ),
                                      child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: textS),
                                  ]
                                )
                              )
                            ),
                            
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(padding: EdgeInsets.only(bottom: 12), child: Divider(height: 1)),
                                    
                                    Row(
                                      children: [
                                         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('Flight Date', style: TextStyle(color: textS, fontSize: 12)),
                                            Text(formatChicagoTime(flightDate), style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                         ])),
                                         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('Received At', style: TextStyle(color: textS, fontSize: 12)),
                                            Text(formatChicagoTime(s['created_at']), style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                         ])),
                                      ]
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('Weight', style: TextStyle(color: textS, fontSize: 12)),
                                            Text('${s['weight'] ?? '-'} kg', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                         ])),
                                         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('Status', style: TextStyle(color: textS, fontSize: 12)),
                                            Text('${s['status'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                         ])),
                                      ]
                                    ),
                                    if (uldDcData.isNotEmpty || (locList.isNotEmpty && idx == splits.length - 1)) ...[
                                      const SizedBox(height: 12),
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
                                                      Icon(Icons.assignment_turned_in_outlined, size: 14, color: textP),
                                                      const SizedBox(width: 6),
                                                      Text('Coordinator Audit', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (uldDcData.isEmpty)
                                                    Text('No data', style: TextStyle(color: textS, fontSize: 12))
                                                  else
                                                    ...uldDcData.map((dc) {
                                                      Map bd = {};
                                                      if (dc['breakdown'] is Map) {
                                                        bd = dc['breakdown'] as Map;
                                                      } else {
                                                        bd = Map.from(dc);
                                                      }
                                                      
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
                                                      
                                                      bd.removeWhere((k, v) => const ['processed_by', 'processed_at', 'user', 'time', 'refULD', 'manual_entry'].contains(k));
                                                      
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
                                                      
                                                      final timeDisp = formatChicagoTime(dc['processed_at']?.toString() ?? dc['time']?.toString());
                                                      final byDisp = dc['processed_by']?.toString() ?? dc['user']?.toString() ?? 'Unknown';

                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 8),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('By: $byDisp [$timeDisp]', style: TextStyle(color: textP, fontSize: 11, fontWeight: FontWeight.w600)),
                                                            const SizedBox(height: 4),
                                                            if (chips.isNotEmpty)
                                                              Wrap(spacing: 4, runSpacing: 4, children: chips)
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
                                          if (locList.isNotEmpty && idx == splits.length - 1)
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
                                                        Icon(Icons.location_on_outlined, size: 14, color: textP),
                                                        const SizedBox(width: 6),
                                                        Text('Location Audit', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ...locList.map((loc) {
                                                      Map itemLocs = {};
                                                      if (loc['locations'] is Map) {
                                                        itemLocs = loc['locations'] as Map;
                                                      } else if (loc['itemLocations'] is Map) {
                                                        itemLocs = loc['itemLocations'] as Map;
                                                      } else {
                                                        itemLocs = Map.from(loc);
                                                        itemLocs.removeWhere((k, v) => const ['processed_by', 'processed_at', 'user', 'time', 'refULD', 'manual_entry'].contains(k));
                                                      }
                                                      
                                                      List<Widget> locChips = [];
                                                      itemLocs.forEach((key, value) {
                                                        if (value == null || value.toString().isEmpty || value.toString() == '0') return;
                                                        locChips.add(Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                                          child: Text(value.toString(), style: const TextStyle(color: Color(0xFF10b981), fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ));
                                                      });

                                                      if (locChips.isEmpty) return const SizedBox.shrink();

                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 6),
                                                        child: Wrap(spacing: 4, runSpacing: 4, children: locChips),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            Expanded(child: const SizedBox.shrink()),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
              );
            }

            List deliveryHistory = [];
            final dynamic delData = u['deliveries_history'] ?? u['data-deliver'];
            if (delData != null) {
              if (delData is List) {
                deliveryHistory = delData;
              } else if (delData is Map && delData.isNotEmpty) {
                deliveryHistory = [delData];
              }
            }

            Widget buildDeliveryHistory() {
              if (deliveryHistory.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                  child: Text('No deliveries have been recorded yet.', style: TextStyle(color: textS, fontStyle: FontStyle.italic)),
                );
              }

              return Column(
                children: deliveryHistory.map((del) {
                  if (del is! Map) return const SizedBox.shrink();
                  
                  bool isRejected = (del.containsKey('rejection_details') && del['rejection_details'] != null) || (del.containsKey('rejection') && del['rejection'] != null);
                  Map rej = isRejected ? ((del['rejection_details'] ?? del['rejection']) as Map) : {};
                  
                  final String company = del['company']?.toString().toUpperCase() ?? '-';
                  final String driver = del['driver_name']?.toString().toUpperCase() ?? del['driver']?.toString().toUpperCase() ?? '-';
                  final String pickupId = del['id_pickup']?.toString() ?? del['pickup_id']?.toString() ?? '-';
                  final int pieces = int.tryParse(del['pieces']?.toString() ?? del['delivery']?.toString() ?? del['total']?.toString() ?? '0') ?? 0;
                  final int total = int.tryParse(del['total']?.toString() ?? '0') ?? 0;
                  final String timeStr = formatChicagoTime(del['time']?.toString());
                  final String deliveredBy = del['delivered_by']?.toString() ?? del['received_by']?.toString() ?? 'Unknown User';
                  final String door = del['door']?.toString() ?? '-';
                  final String typeDel = del['type_delivery']?.toString() ?? '-';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isRejected ? const Color(0xFFef4444).withAlpha(100) : const Color(0xFF10b981).withAlpha(100), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isRejected ? const Color(0xFFef4444).withAlpha(20) : const Color(0xFF10b981).withAlpha(20),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            border: Border(bottom: BorderSide(color: isRejected ? const Color(0xFFef4444).withAlpha(50) : const Color(0xFF10b981).withAlpha(50))),
                          ),
                          child: Row(
                            children: [
                              Icon(isRejected ? Icons.warning_amber_rounded : Icons.check_circle, color: isRejected ? const Color(0xFFef4444) : const Color(0xFF10b981), size: 18),
                              const SizedBox(width: 8),
                              Text(isRejected ? 'DELIVERY WITH REJECTION' : 'SUCCESSFUL DELIVERY', style: TextStyle(color: isRejected ? const Color(0xFFef4444) : const Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(timeStr, style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Delivered to', style: TextStyle(color: textS, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(driver, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Company: $company', style: TextStyle(color: textS, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text('Pickup ID: $pickupId', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pieces Delivered', style: TextStyle(color: textS, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(total > 0 ? '$pieces / $total' : '$pieces pcs', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text('Delivered by: $deliveredBy', style: TextStyle(color: textS, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text('Door: $door  •  $typeDel', style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isRejected)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFef4444).withAlpha(10),
                              border: Border(top: BorderSide(color: const Color(0xFFef4444).withAlpha(50))),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Rejected', style: TextStyle(color: const Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text('${rej['qty'] ?? 0} pcs', style: const TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Location', style: TextStyle(color: const Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text(rej['location']?.toString() ?? '-', style: const TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Reason', style: TextStyle(color: const Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text(rej['reason']?.toString() ?? '-', style: const TextStyle(color: Color(0xFFef4444), fontSize: 12, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }

            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: bg,
                elevation: 16,
                child: SizedBox(
                  width: 520, // slightly wider to fit everything beautifully
                  height: double.infinity,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AWB Traceability', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(u['awb_number']?.toString() ?? u['AWB-number']?.toString() ?? 'N/A', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print_rounded, color: Color(0xFF6366f1)),
                                  tooltip: 'Print / Download PDF',
                                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15)),
                                  onPressed: () => showPrintPreviewDialog(context, u),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: textP),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text('ULD Traceability Flow', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            buildTraceability(),
                            const SizedBox(height: 24),
                            Text('Delivery History', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            buildDeliveryHistory(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            );
          }
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      }
    );
  }
}
