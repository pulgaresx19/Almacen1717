part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2AwbDrawer on AddDeliverV2ScreenState {
  void _showAwbDrawer(BuildContext context, Map<String, dynamic> u, bool dark, int receivedPieces, int expectedPieces, String status) {
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

            List<Widget> buildCombinedAuditItems() {
              List awbList = [];
              if (u['data-AWB'] is List) {
                awbList = u['data-AWB'];
              } else if (u['data-AWB'] is Map) {
                awbList = [u['data-AWB']];
              }

              List dcList = [];
              if (u['data-coordinator'] is List) {
                dcList = u['data-coordinator'];
              } else if (u['data-coordinator'] is Map && (u['data-coordinator'] as Map).isNotEmpty) {
                dcList = [u['data-coordinator']];
              }

              List locList = [];
              if (u['data-location'] is List) {
                locList = u['data-location'];
              } else if (u['data-location'] is Map && (u['data-location'] as Map).isNotEmpty) {
                locList = [u['data-location']];
              }

              if (awbList.isEmpty) return [Text('No flight data available.', style: TextStyle(color: textS))];
              
              return awbList.asMap().entries.map((entry) {
                final int idx = entry.key;
                final e = entry.value;
                final isBreak = e['isBreak'] == true;
                final uldNum = e['refULD']?.toString() ?? '';
                final uldDcData = dcList.where((dc) => dc['refULD']?.toString() == uldNum || dcList.length == 1).toList();
                final isExpanded = expandedCards.contains(idx);

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
                              Text('ULD: ${e['refULD'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBreak ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isBreak ? const Color(0xFF10b981).withAlpha(50) : const Color(0xFFef4444).withAlpha(50)),
                                ),
                                child: Text(isBreak ? 'BREAK' : 'NO BREAK', style: TextStyle(color: isBreak ? const Color(0xFF10b981) : const Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold)),
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
                              // --- FLIGHT INFO ---
                              Row(
                                children: [
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Flight', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['refCarrier'] ?? ''} ${e['refNumber'] ?? ''}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Date', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['refDate'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                ]
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Pieces', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['pieces'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Weight', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['weight'] ?? '-'} kg', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                ]
                              ),
                              if (e['remarks'] != null && e['remarks'].toString().isNotEmpty) ...[
                                 const SizedBox(height: 12),
                                 Text('Remarks: ${e['remarks']}', style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic)),
                              ],

                              // --- NO BREAK MAPPED AWBs ---
                              if (!isBreak && uldNum.isNotEmpty)
                                FutureBuilder<List<dynamic>>(
                                  future: Supabase.instance.client.from('ULD').select('data-ULD').eq('ULD-number', uldNum).maybeSingle().then((res) => (res?['data-ULD'] as List<dynamic>?) ?? []),
                                  builder: (ctx, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                                    }
                                    final listData = snapshot.data ?? [];
                                    if (listData.isEmpty) return const SizedBox.shrink();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                        Row(children: [
                                          Icon(Icons.inventory_2_outlined, size: 16, color: textP),
                                          const SizedBox(width: 8),
                                          Text('Mapped AWBs in ULD', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ]),
                                        const SizedBox(height: 12),
                                        ...listData.map((d) {
                                           return Container(
                                             margin: const EdgeInsets.only(bottom: 6),
                                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                             decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(6)),
                                             child: Row(
                                               children: [
                                                 Expanded(flex: 2, child: Text(d['awb_number']?.toString() ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13))),
                                                 Expanded(flex: 1, child: Text('Pieces: ${d['pieces'] ?? '-'}', style: TextStyle(color: textS, fontSize: 12))),
                                                 Expanded(flex: 1, child: Text('Total: ${d['total'] ?? '-'}', style: TextStyle(color: textS, fontSize: 12))),
                                               ]
                                             )
                                           );
                                        }),
                                      ]
                                    );
                                  }
                                ),

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
                                    Map bd = (dc['breakdown'] is Map) ? dc['breakdown'] as Map : {};
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
                                                Text(dc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                const Spacer(),
                                                Icon(Icons.access_time, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(formatChicagoTime(dc['time']), style: TextStyle(color: textS, fontSize: 12)),
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
                              if (locList.isNotEmpty && awbList.last == e) ...[
                                 const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                 Row(children: [
                                    Icon(Icons.location_on_outlined, size: 16, color: textP),
                                    const SizedBox(width: 8),
                                    Text('Location Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]),
                                 const SizedBox(height: 12),
                                 ...locList.map((loc) {
                                    Map itemLocs = (loc['locations'] is Map) ? loc['locations'] as Map : ((loc['itemLocations'] is Map) ? loc['itemLocations'] as Map : {});
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
                                                Text(loc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                const Spacer(),
                                                Icon(Icons.access_time, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(formatChicagoTime(loc['time']), style: TextStyle(color: textS, fontSize: 12)),
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
                                                   child: Text('${entry.key} âž” ${entry.value}', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
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
                                 }),
                              ]
                            ]
                          )
                        )
                    ]
                  )
                );
              }).toList();
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
                                Text(u['AWB-number']?.toString() ?? 'N/A', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
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
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Root Total:', style: TextStyle(color: textS)), Text(u['total']?.toString() ?? '-', style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Expected (Manifest):', style: TextStyle(color: textS)), Text(expectedPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Received (Coordinator):', style: TextStyle(color: textS)), Text(receivedPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Calculated Status:', style: TextStyle(color: textS)), _buildStatusBadge(status)]),
                                ]
                              )
                            ),
                            const SizedBox(height: 32),
                            
                            Text('ULD Traceability Flow', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...buildCombinedAuditItems(),
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
