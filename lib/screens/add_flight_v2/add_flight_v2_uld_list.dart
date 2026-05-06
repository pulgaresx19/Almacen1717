import 'package:flutter/material.dart';
import 'add_flight_v2_logic.dart';
import 'add_flight_v2_add_uld_drawer.dart';
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
      padding: const EdgeInsets.all(16),
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
                InkWell(
                  onTap: () {
                    AddFlightV2AddUldDrawer.show(context, dark, logic, initialUld: u);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: dark ? const Color(0x326366f1) : const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)), child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 14))), const SizedBox(width: 16),
                              SizedBox(width: 125, child: Text(u['uldNumber'] ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5))), const SizedBox(width: 16),
                              SizedBox(width: 70, child: Text('${u['pieces'] ?? 'Auto'} pcs', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)), const SizedBox(width: 12),
                              SizedBox(width: 75, child: Text('${u['weight'] ?? 'Auto'} kg', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)), const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (u['remarks'] != null && u['remarks'].toString().trim().isNotEmpty) ? 'Remarks: ${u['remarks']}' : 'Remarks: ...', 
                                  style: TextStyle(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 12, fontStyle: FontStyle.italic), 
                                  overflow: TextOverflow.ellipsis
                                )
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.inventory_2_outlined, size: 14, color: textP), const SizedBox(width: 6), Text('${awbs.length} AWBs', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 12))])), const SizedBox(width: 16),
                            Icon(
                              u['priority'] == true ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: u['priority'] == true ? const Color(0xFFf59e0b) : (dark ? Colors.white.withAlpha(60) : Colors.black.withAlpha(50)),
                              size: 20
                            ),
                            const SizedBox(width: 12),
                            Container(width: 85, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (u['break'] == true) ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30), borderRadius: BorderRadius.circular(8)), child: Text((u['break'] == true) ? 'BREAK' : 'NO BREAK', style: TextStyle(color: (u['break'] == true) ? (dark ? const Color(0xFF6ee7b7) : const Color(0xFF059669)) : (dark ? const Color(0xFFfca5a5) : const Color(0xFFdc2626)), fontSize: 11, fontWeight: FontWeight.bold))), const SizedBox(width: 16),
                            Container(decoration: BoxDecoration(color: const Color(0xFFef4444).withAlpha(20), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFef4444), size: 20), tooltip: 'Eliminar ULD', onPressed: () => logic.removeLocalUld(i))),
                          ],
                        )
                      ],
                    ),
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
