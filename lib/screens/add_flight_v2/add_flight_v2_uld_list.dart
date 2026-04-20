import 'package:flutter/material.dart';
import 'add_flight_v2_logic.dart';
import 'add_flight_v2_awb_dialog.dart';

class AddFlightV2UldList extends StatelessWidget {
  final AddFlightV2Logic logic;
  final bool dark;
  final Color textP;
  final Color borderC;

  const AddFlightV2UldList({
    super.key,
    required this.logic,
    required this.dark,
    required this.textP,
    required this.borderC,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: logic.flightLocalUlds.asMap().entries.where((e) {
          if (logic.searchUldCtrl.text.isEmpty) return true;
          final term = logic.searchUldCtrl.text.toLowerCase();
          return (e.value['uldNumber'] ?? '').toString().toLowerCase().contains(term);
        }).map((entry) {
          int i = entry.key;
          var u = entry.value;
          List awbs = u['awbs'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1e293b) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderC),
              boxShadow: [
                BoxShadow(
                  color: dark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.vertical(top: const Radius.circular(12), bottom: Radius.circular((awbs.isNotEmpty && (u['showAwbs'] ?? true)) ? 0 : 12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: dark ? const Color(0x326366f1) : const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)), child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 14))), const SizedBox(width: 16),
                            SizedBox(width: 125, child: Text(u['uldNumber'] ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5))), const SizedBox(width: 16),
                            Container(width: 100, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(15) : Colors.white, border: Border.all(color: borderC), borderRadius: BorderRadius.circular(8)), child: Text('Pieces: ${u['pieces'] ?? 'Auto'}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w600))), const SizedBox(width: 12),
                            Container(width: 100, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(15) : Colors.white, border: Border.all(color: borderC), borderRadius: BorderRadius.circular(8)), child: Text('Weight: ${u['weight'] ?? 'Auto'}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w600))), const SizedBox(width: 12),
                            Container(width: 95, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (u['priority'] == true) ? const Color(0xFFf59e0b).withAlpha(30) : (dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(8)), child: Text('Priority: ${(u['priority'] == true) ? 'Yes' : 'No'}', style: TextStyle(color: (u['priority'] == true) ? (dark ? const Color(0xFFfde68a) : const Color(0xFFd97706)) : (dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)), fontSize: 12, fontWeight: (u['priority'] == true) ? FontWeight.bold : FontWeight.w500))), const SizedBox(width: 12),
                            Container(width: 85, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (u['break'] == true) ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30), borderRadius: BorderRadius.circular(8)), child: Text('Break: ${(u['break'] == true) ? 'Yes' : 'No'}', style: TextStyle(color: (u['break'] == true) ? (dark ? const Color(0xFF6ee7b7) : const Color(0xFF059669)) : (dark ? const Color(0xFFfca5a5) : const Color(0xFFdc2626)), fontSize: 12, fontWeight: FontWeight.bold))), const SizedBox(width: 16),
                            if (u['remarks'] != null && u['remarks'].toString().isNotEmpty)
                              Expanded(child: Text('Rem: ${u['remarks']}', style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 12, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.inventory_2_outlined, size: 14, color: textP), const SizedBox(width: 6), Text('${awbs.length} AWBs', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 12))])), const SizedBox(width: 16),
                          ElevatedButton.icon(onPressed: () => showAddAwbDialog(context, logic, i), icon: const Icon(Icons.add, size: 16), label: const Text('Add AWB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))), const SizedBox(width: 12),
                          Container(decoration: BoxDecoration(color: const Color(0xFFef4444).withAlpha(20), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFef4444), size: 20), tooltip: 'Eliminar ULD', onPressed: () => logic.removeLocalUld(i))), const SizedBox(width: 12),
                          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon((u['showAwbs'] ?? true) ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: (u['showAwbs'] ?? true) ? (dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)) : (dark ? const Color(0xFF64748b) : const Color(0xFF9CA3AF)), size: 24), onPressed: () => logic.toggleUldAwbsVisibility(i)),
                        ],
                      )
                    ],
                  ),
                ),
                if (awbs.isNotEmpty && (u['showAwbs'] ?? true))
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderC)),
                    ),
                    child: Table(
                      columnWidths: const { 0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth(), 5: FlexColumnWidth(), 6: IntrinsicColumnWidth(), 7: IntrinsicColumnWidth() },
                      children: awbs.asMap().entries.map((entry) {
                        final aInt = entry.key; final a = entry.value;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: aInt.isEven ? Colors.transparent : (dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB)),
                            border: aInt == awbs.length - 1 ? null : Border(bottom: BorderSide(color: borderC.withAlpha(100))),
                          ),
                          children: [
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: dark ? const Color(0x32ffffff) : const Color(0xFFE5E7EB), shape: BoxShape.circle), child: Center(child: Text('${aInt + 1}', style: TextStyle(color: textP, fontSize: 11, fontWeight: FontWeight.bold))))),
                            Padding(padding: const EdgeInsets.only(right: 32, top: 12, bottom: 12), child: Text(a['awb_number'], style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: RichText(text: TextSpan(children: [TextSpan(text: 'PIECES: ', style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: '${a['pieces']}', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600))]))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: RichText(text: TextSpan(children: [TextSpan(text: 'TOTAL: ', style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: '${a['total'] ?? 0}', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600))]))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: RichText(text: TextSpan(children: [TextSpan(text: 'WEIGHT: ', style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: '${a['weight']}', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600))]))),
                            Padding(padding: const EdgeInsets.only(right: 8, top: 12, bottom: 12), child: RichText(maxLines: 1, overflow: TextOverflow.ellipsis, text: TextSpan(children: [TextSpan(text: 'REMARKS: ', style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: a['remarks']?.isNotEmpty == true ? a['remarks'] : '-', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontStyle: FontStyle.italic, fontSize: 12))]))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Builder(
                              builder: (ctx) {
                                final rawH = a['house_number']; final List<String> items = (rawH is List) ? rawH.map((e) => e.toString()).toList() : [];
                                if (items.isEmpty) return const SizedBox.shrink();
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: ctx,
                                        builder: (c) => Dialog(
                                          backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderC)),
                                          child: Container(
                                            width: 320, padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('House Numbers (${items.length})', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
                                                Flexible(child: SingleChildScrollView(child: Column(children: items.asMap().entries.map((ent) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle), child: Text('${ent.key + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Text(ent.value, style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 14)))]))).toList()))),
                                                const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))))
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: dark ? const Color(0xFF0f172a) : const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6366f1).withAlpha(100))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.maps_home_work_outlined, size: 12, color: dark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5)), const SizedBox(width: 4), Text('${items.length} HAWB', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5), fontSize: 11, fontWeight: FontWeight.bold))])),
                                  ),
                                );
                              }
                            )),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: InkWell(borderRadius: BorderRadius.circular(6), onTap: () => logic.removeAwbFromUld(i, aInt), child: Container(padding: const EdgeInsets.all(6.0), decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)), child: Icon(Icons.close, color: Colors.redAccent.withAlpha(220), size: 16)))),
                          ]
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
