part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2UldDrawerExt on AddDeliverV2ScreenState {
  void _showUldDrawer(BuildContext context, Map<String, dynamic> u, bool dark) {
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

        List dataUld = [];
        if (u['data-ULD'] is List) dataUld = u['data-ULD'];

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

        return StatefulBuilder(
          builder: (ctxModal, setModalState) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: bg,
                elevation: 16,
                child: SizedBox(
                  width: 450,
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
                                     Text('${u['ULD-number'] ?? '-'}', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
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
                                         Expanded(child: buildInfoBox('Pieces', '${u['pieces'] ?? '0'}', Icons.extension_outlined)),
                                         Expanded(child: buildInfoBox('Weight', '${u['weight'] ?? '0'} kg', Icons.scale_outlined)),
                                       ]),
                                       const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                       Row(children: [
                                         Expanded(child: buildInfoBox('Type', u['isBreak'] == true ? 'BREAK' : 'NO BREAK', Icons.broken_image_rounded, u['isBreak'] == true ? const Color(0xFF10b981) : const Color(0xFFef4444))),
                                         Expanded(child: buildInfoBox('Priority', u['isPriority'] == true ? 'Priority' : 'Normal', Icons.star_outline_rounded, u['isPriority'] == true ? Colors.redAccent : textP)),
                                       ]),
                                       const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                       Row(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Expanded(flex: 2, child: buildInfoBox('Status', u['status']?.toString() ?? 'Waiting', Icons.info_outline)),
                                           Expanded(flex: 3, child: buildInfoBox('Remarks', u['remarks']?.toString() ?? '-', Icons.notes_rounded)),
                                       ])
                                    ]
                                  )
                                ),
                                if (dataUld.isNotEmpty) ...[
                                   const SizedBox(height: 24),
                                   Text('Assigned AWBs', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                                   const SizedBox(height: 12),
                                   ...dataUld.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final awb = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
                                        child: Row(
                                          children: [
                                             Container(
                                               width: 20, height: 20,
                                               alignment: Alignment.center,
                                               decoration: const BoxDecoration(color: Color(0x326366f1), shape: BoxShape.circle),
                                               child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                                             ),
                                             const SizedBox(width: 8),
                                             Expanded(
                                               child: Row(
                                                  children: [
                                                     SizedBox(width: 120, child: Text(awb['awb_number']?.toString() ?? '', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w500))),
                                                     const SizedBox(width: 8),
                                                     Expanded(child: Text('Pieces: ${awb['pieces'] ?? 0}', style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                     Expanded(child: Text('Weight: ${awb['weight'] ?? 0} kg', style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                  ],
                                               )
                                             ),
                                          ],
                                        ),
                                      );
                                   }),
                                ]
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
