part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2UldDrawerExt on AddDeliverV2ScreenState {
  void _showUldDrawer(BuildContext context, Map<String, dynamic> u, bool dark) {
    final uldId = u['id_uld'] ?? u['id'];
    
    final Future<List<Map<String, dynamic>>> splitsFuture = Supabase.instance.client
        .from('awb_splits')
        .select('*, awbs(awb_number, total_pieces, total_espected)')
        .eq('uld_id', uldId)
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

        Widget buildInfoBox(String label, String value, IconData icon, [Color? valColor]) {
           return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(
                       children: [
                          Icon(icon, color: textS, size: 14),
                          const SizedBox(width: 4),
                          Expanded(child: Text(label, style: TextStyle(color: textS, fontSize: 11), overflow: TextOverflow.ellipsis)),
                       ],
                    ),
                    const SizedBox(height: 6),
                    Text(value, style: TextStyle(color: valColor ?? textP, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                 ]
              )
           );
        }

        Widget buildAwbList() {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: splitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))));
              }
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(16), child: Text('Error loading AWBs: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              
              final splits = snapshot.data ?? [];
              if (splits.isEmpty) {
                return Padding(padding: const EdgeInsets.all(16), child: Text('No AWBs found inside this ULD.', style: TextStyle(color: textS)));
              }

              return Column(
                children: splits.map((s) {
                  final awbData = s['awbs'] ?? {};
                  final String awbNumber = awbData['awb_number']?.toString() ?? 'Unknown AWB';
                  final int totalExpected = int.tryParse(awbData['total_pieces']?.toString() ?? awbData['total_espected']?.toString() ?? '0') ?? 0;
                  final int pieces = int.tryParse(s['pieces']?.toString() ?? '0') ?? 0;
                  final double weight = double.tryParse(s['weight']?.toString() ?? '0') ?? 0.0;
                  
                  final String itemRemarks = s['remarks']?.toString() ?? '';
                  List<String> houses = [];
                  final hRaw = s['house_number'];
                  if (hRaw is List) {
                    houses = hRaw.map((e) => e.toString()).toList();
                  } else if (hRaw is String && hRaw.isNotEmpty) {
                    houses = hRaw.split(RegExp(r'[,\n]')).map((str) => str.trim()).where((str) => str.isNotEmpty).toList();
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderC),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF6366f1)),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 85,
                          child: Text('$pieces / $totalExpected pcs', style: TextStyle(color: textS, fontSize: 13)),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 65,
                          child: Text('$weight kg', style: TextStyle(color: textS, fontSize: 13)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: itemRemarks.isNotEmpty
                            ? Row(
                                children: [
                                  Icon(Icons.notes_rounded, size: 14, color: textS.withAlpha(150)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      itemRemarks,
                                      style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                        ),
                        if (houses.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                  title: Text('House Numbers', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                  content: SizedBox(
                                    width: 300,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: houses.asMap().entries.map((eh) {
                                        final hi = eh.key;
                                        final h = eh.value;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3b82f6).withAlpha(30),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${hi + 1}',
                                                  style: const TextStyle(color: Color(0xFF60a5fa), fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(h, style: TextStyle(color: textS, fontSize: 14)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3b82f6).withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.house_siding_rounded, size: 12, color: Color(0xFF60a5fa)),
                                  const SizedBox(width: 4),
                                  Text('${houses.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF60a5fa), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                }).toList(),
              );
            }
          );
        }

        return StatefulBuilder(
          builder: (ctxModal, setModalState) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: bg,
                elevation: 16,
                child: SizedBox(
                  width: 520,
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
                                 Text('ULD Details', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                                 const SizedBox(height: 4),
                                 Row(
                                   children: [
                                     Icon(Icons.inventory_2_rounded, color: textP, size: 24),
                                     const SizedBox(width: 8),
                                     Text('${u['ULD-number'] ?? u['uld_number'] ?? '-'}', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                                   ]
                                 )
                               ],
                             ),
                             IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: textP)),
                           ],
                         ),
                       ),
                       Expanded(
                         child: SingleChildScrollView(
                           padding: const EdgeInsets.all(24),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       Row(
                                         children: [
                                            Icon(Icons.description_rounded, size: 16, color: textP),
                                            const SizedBox(width: 8),
                                            Text('General Information', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                         ]
                                       ),
                                       const SizedBox(height: 12),
                                       Row(children: [
                                         Expanded(child: buildInfoBox('Pieces', '${u['pieces'] ?? u['pieces_total'] ?? '0'}', Icons.extension_outlined)),
                                         Expanded(child: buildInfoBox('Weight', '${u['weight'] ?? u['weight_total'] ?? '0'} kg', Icons.scale_outlined)),
                                       ]),
                                       const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                       Row(children: [
                                         Expanded(child: buildInfoBox('Type', (u['isBreak'] == true || u['is_break'] == true) ? 'BREAK' : 'NO BREAK', Icons.broken_image_rounded, (u['isBreak'] == true || u['is_break'] == true) ? const Color(0xFF10b981) : const Color(0xFFef4444))),
                                         Expanded(child: buildInfoBox('Priority', (u['isPriority'] == true || u['is_priority'] == true) ? 'Priority' : 'Normal', Icons.star_outline_rounded, (u['isPriority'] == true || u['is_priority'] == true) ? Colors.redAccent : textP)),
                                       ]),
                                       const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                       Row(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Expanded(flex: 2, child: buildInfoBox('Status', FlightsV2StatusLogic.getUldStatus(u), Icons.info_outline)),
                                           Expanded(flex: 3, child: buildInfoBox('Remarks', u['remarks']?.toString() ?? '-', Icons.notes_rounded)),
                                       ])
                                    ]
                                  )
                                ),
                                const SizedBox(height: 24),
                                Text('Assigned AWBs', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                buildAwbList(),
                             ],
                           )
                         )
                       )
                    ]
                  )
                )
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
