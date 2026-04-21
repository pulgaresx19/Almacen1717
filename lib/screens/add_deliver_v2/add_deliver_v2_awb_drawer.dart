part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2AwbDrawer on AddDeliverV2ScreenState {
  void _showAwbDrawer(BuildContext context, Map<String, dynamic> u, bool dark, int receivedPieces, int expectedPieces, int deliveredPieces, int inProcessPieces, int remainingPieces, int totalPieces, String status) {
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
                      // Some splits might not have a direct user relation depending on schema
                      final String uldNum = uldData['uld_number']?.toString() ?? s['uld_id']?.toString() ?? 'Loose/Unknown';
                      final String carrier = flightData['carrier']?.toString() ?? '';
                      final String fNumber = flightData['number']?.toString() ?? s['flight_id']?.toString() ?? 'Unknown Flight';
                      final String flightDate = flightData['date']?.toString() ?? '-';
                      String shortDate = '';
                      if (flightDate != '-') {
                        try {
                          final dt = DateTime.parse(flightDate).toLocal();
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          shortDate = ' (${months[dt.month - 1]} ${dt.day})';
                        } catch (_) {}
                      }
                      final String flightNum = '$carrier $fNumber'.trim() + shortDate;
                      final bool isBreak = uldData['is_break'] == true;
                      final String remarks = s['remarks']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Collapsible Header Area
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
                                        color: isBreak ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isBreak ? const Color(0xFF10b981).withAlpha(50) : const Color(0xFFef4444).withAlpha(50)),
                                      ),
                                      child: Text(isBreak ? 'BREAK' : 'NO BREAK', style: TextStyle(color: isBreak ? const Color(0xFF10b981) : const Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: textS),
                                  ]
                                )
                              )
                            ),
                            
                            // Expanded Content Area
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(padding: EdgeInsets.only(bottom: 12), child: Divider(height: 1)),
                                    
                                    // --- SPLIT INFO ---
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
                                    
                                    if (remarks.isNotEmpty) ...[
                                       const SizedBox(height: 12),
                                       Container(
                                         width: double.infinity,
                                         padding: const EdgeInsets.all(10),
                                         decoration: BoxDecoration(color: const Color(0xFFf59e0b).withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFf59e0b).withAlpha(50))),
                                         child: Text('Remarks: $remarks', style: const TextStyle(color: Color(0xFFd97706), fontSize: 12, fontStyle: FontStyle.italic)),
                                       )
                                    ],

                                    // --- COORDINATOR AUDIT ---
                                    if (uldDcData.isNotEmpty) ...[
                                       const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                       Row(children: [
                                          Icon(Icons.assignment_turned_in_outlined, size: 16, color: textP),
                                          const SizedBox(width: 8),
                                          Text('Coordinator Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                       ]),
                                       const SizedBox(height: 12),
                                       ...uldDcData.map((dc) {
                                          Map bd = {};
                                          if (dc['breakdown'] is Map) {
                                            bd = dc['breakdown'] as Map;
                                          } else {
                                            bd = Map.from(dc);
                                            bd.removeWhere((k, v) => const ['processed_by', 'processed_at', 'user', 'time', 'refULD', 'manual_entry'].contains(k));
                                          }
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8)),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                   children: [
                                                      Icon(Icons.person_outline, size: 14, color: textS),
                                                      const SizedBox(width: 6),
                                                      Text(dc['processed_by']?.toString() ?? dc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                      const Spacer(),
                                                      Icon(Icons.access_time, size: 14, color: textS),
                                                      const SizedBox(width: 6),
                                                      Text(formatChicagoTime(dc['processed_at']?.toString() ?? dc['time']?.toString()), style: TextStyle(color: textS, fontSize: 12)),
                                                   ]
                                                ),
                                                if (bd.isNotEmpty) ...[
                                                   const SizedBox(height: 10),
                                                   Wrap(
                                                     spacing: 6,
                                                     runSpacing: 6,
                                                     children: bd.entries.map((entry) {
                                                       if (entry.value is List && (entry.value as List).isEmpty) return const SizedBox.shrink();
                                                       if (entry.value is num && entry.value == 0) return const SizedBox.shrink();
                                                       if (entry.value.toString() == '0') return const SizedBox.shrink();
                                                       return Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                         decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF6366f1).withAlpha(50))),
                                                         child: Text('${entry.key}: ${entry.value is List ? entry.value.join(', ') : entry.value}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                                       );
                                                     }).toList(),
                                                   ),
                                                ],
                                                if (dc['manual_entry'] != null) ...[
                                                   const SizedBox(height: 10),
                                                   Wrap(
                                                     spacing: 6,
                                                     runSpacing: 6,
                                                     crossAxisAlignment: WrapCrossAlignment.center,
                                                     children: [
                                                       Text('Manual Entry:', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                       ...(dc['manual_entry'] is List ? dc['manual_entry'] as List : [dc['manual_entry']]).map((entry) {
                                                         return Container(
                                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                           decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF6366f1).withAlpha(50))),
                                                           child: Text(entry.toString(), style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                                         );
                                                       }),
                                                     ],
                                                   ),
                                                ]
                                              ]
                                            )
                                          );
                                       }),
                                    ],

                                    // --- LOCATION AUDIT ---
                                    if (locList.isNotEmpty && idx == splits.length - 1) ...[
                                       const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                       Row(children: [
                                          Icon(Icons.location_on_outlined, size: 16, color: textP),
                                          const SizedBox(width: 8),
                                          Text('Location Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                       ]),
                                       const SizedBox(height: 12),
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
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8)),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                   children: [
                                                      Icon(Icons.person_outline, size: 14, color: textS),
                                                      const SizedBox(width: 6),
                                                      Text(loc['processed_by']?.toString() ?? loc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                      const Spacer(),
                                                      Icon(Icons.access_time, size: 14, color: textS),
                                                      const SizedBox(width: 6),
                                                      Text(formatChicagoTime(loc['processed_at']?.toString() ?? loc['time']?.toString()), style: TextStyle(color: textS, fontSize: 12)),
                                                   ]
                                                ),
                                                if (itemLocs.isNotEmpty) ...[
                                                   const SizedBox(height: 10),
                                                   Wrap(
                                                     spacing: 6,
                                                     runSpacing: 6,
                                                     children: itemLocs.entries.map((entry) {
                                                       if (entry.value == null || entry.value.toString().isEmpty) return const SizedBox.shrink();
                                                       return Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                         decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(50))),
                                                         child: Text('${entry.key} ➔ ${entry.value}', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
                                                       );
                                                     }).toList(),
                                                   ),
                                                ],
                                                if (loc['manual_entry'] != null) ...[
                                                   const SizedBox(height: 10),
                                                   Wrap(
                                                     spacing: 6,
                                                     runSpacing: 6,
                                                     crossAxisAlignment: WrapCrossAlignment.center,
                                                     children: [
                                                       Text('Manual Entry:', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                       ...(loc['manual_entry'] is List ? loc['manual_entry'] as List : [loc['manual_entry']]).map((entry) {
                                                         return Container(
                                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                           decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(50))),
                                                           child: Text(entry.toString(), style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
                                                         );
                                                       }),
                                                     ],
                                                   ),
                                                ]
                                              ]
                                            )
                                          );
                                       })
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
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: textP),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            // Totals Summary
                            Text('Pieces Summary', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                              child: Column(
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total:', style: TextStyle(color: textS)), Text(totalPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Expected:', style: TextStyle(color: textS)), Text(expectedPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Received:', style: TextStyle(color: textS)), Text(receivedPieces.toString(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivered:', style: TextStyle(color: textS)), Text(deliveredPieces.toString(), style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('In Process:', style: TextStyle(color: textS)), Text(inProcessPieces.toString(), style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Remaining:', style: TextStyle(color: textP, fontWeight: FontWeight.bold)), Text(remainingPieces.toString(), style: const TextStyle(color: Color(0xFF6366f1), fontSize: 18, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 2)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Calculated Status:', style: TextStyle(color: textS)), _buildStatusBadge(status)]),
                                ]
                              )
                            ),
                            const SizedBox(height: 32),
                            
                            Text('ULD Traceability Flow', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            buildTraceability(),
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
