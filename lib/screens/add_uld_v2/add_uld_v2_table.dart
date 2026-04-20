import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show appLanguage;
import 'add_uld_v2_logic.dart';
import 'add_uld_v2_dialogs.dart';

class AddUldV2TableWidget extends StatefulWidget {
  final AddUldV2Logic logic;
  final bool dark;
  final Color textP;
  final Color borderC;
  final Color bgCard;

  const AddUldV2TableWidget({
    super.key,
    required this.logic,
    required this.dark,
    required this.textP,
    required this.borderC,
    required this.bgCard,
  });

  @override
  State<AddUldV2TableWidget> createState() => _AddUldV2TableWidgetState();
}

class _AddUldV2TableWidgetState extends State<AddUldV2TableWidget> {
  final _searchUldCtrl = TextEditingController();

  @override
  void dispose() {
    _searchUldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: widget.textP, size: 20),
                  const SizedBox(width: 8),
                  Text('Added ULDs', style: TextStyle(color: widget.textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                     width: 300, height: 40,
                     decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.borderC)),
                     child: TextField(
                        controller: _searchUldCtrl, style: TextStyle(color: widget.textP, fontSize: 13), onChanged: (v) => setState(() {}),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                           TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))
                        ],
                        decoration: InputDecoration(hintText: appLanguage.value == 'es' ? 'Buscar ULD...' : 'Search ULD...', hintStyle: TextStyle(color: widget.textP.withAlpha(76), fontSize: 13), prefixIcon: Icon(Icons.search_rounded, color: widget.textP.withAlpha(76), size: 16), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                     ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(appLanguage.value == 'es' ? 'Vea y gestione todos los ULDs nuevos que serán guardados.' : 'View and manage all new ULDs that will be saved.', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Container(
              decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.borderC)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.logic.localUlds.isNotEmpty
                  ? _buildTable()
                  : Center(child: Text('No ULDs added yet', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500))),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    Map<String, List<Map<String, dynamic>>> groupedUlds = {};
    for (int i = 0; i < widget.logic.localUlds.length; i++) {
      final u = widget.logic.localUlds[i];
      if (_searchUldCtrl.text.isNotEmpty) {
        final term = _searchUldCtrl.text.toLowerCase();
        final number = (u['uldNumber'] ?? u['ULD-number'] ?? '').toString().toLowerCase();
        if (!number.contains(term)) continue;
      }
      final groupKey = u['flightLabel'] ?? 'Standalone ULDs';
      groupedUlds.putIfAbsent(groupKey, () => []);
      groupedUlds[groupKey]!.add({'index': i, 'uld': u});
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedUlds.entries.map((group) {
          final groupName = group.key;
          final groupItems = group.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: widget.borderC))),
                child: Row(
                  children: [
                    Icon(groupName == 'Standalone ULDs' ? Icons.inventory_2_outlined : Icons.flight_takeoff_rounded, color: const Color(0xFF94a3b8), size: 16),
                    const SizedBox(width: 8),
                    Text(groupName, style: TextStyle(color: widget.textP, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), borderRadius: BorderRadius.circular(4)), child: Text('${groupItems.length} items', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.w600))),
                    const Spacer(),
                    IconButton(
                      icon: Icon(widget.logic.collapsedGroups.contains(groupName) ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94a3b8), size: 20),
                      onPressed: () => widget.logic.toggleUldGroup(groupName),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    ),
                  ]
                )
              ),
              if (!widget.logic.collapsedGroups.contains(groupName))
                ...groupItems.asMap().entries.map((groupEntry) {
                  int groupIndex = groupEntry.key;
                  var item = groupEntry.value;
                  int i = item['index'];
                  var u = item['uld'];
                  List awbs = u['awbs'] ?? [];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.borderC),
                      boxShadow: [
                        BoxShadow(
                          color: widget.dark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(10),
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
                            color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.vertical(top: const Radius.circular(12), bottom: Radius.circular((awbs.isNotEmpty && (u['showAwbs'] ?? true)) ? 0 : 12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: widget.dark ? const Color(0x326366f1) : const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)), child: Text('${groupIndex + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 14))),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 125, child: Text(u['uldNumber'] ?? '', style: TextStyle(color: widget.textP, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5))),
                                    const SizedBox(width: 16),
                                    Container(width: 100, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(15) : Colors.white, border: Border.all(color: widget.borderC), borderRadius: BorderRadius.circular(8)), child: Text('Pieces: ${u['pieces'] ?? 'Auto'}', style: TextStyle(color: widget.dark ? const Color(0xFFcbd5e1) : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 12),
                                    Container(width: 100, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(15) : Colors.white, border: Border.all(color: widget.borderC), borderRadius: BorderRadius.circular(8)), child: Text('Weight: ${u['weight'] ?? 'Auto'}', style: TextStyle(color: widget.dark ? const Color(0xFFcbd5e1) : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 12),
                                    Container(width: 95, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (u['priority'] == true) ? const Color(0xFFf59e0b).withAlpha(30) : (widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(8)), child: Text('Priority: ${(u['priority'] == true) ? 'Yes' : 'No'}', style: TextStyle(color: (u['priority'] == true) ? (widget.dark ? const Color(0xFFfde68a) : const Color(0xFFD97706)) : (widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)), fontSize: 12, fontWeight: (u['priority'] == true) ? FontWeight.bold : FontWeight.w500))),
                                    const SizedBox(width: 12),
                                    Container(width: 85, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (u['break'] == true) ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30), borderRadius: BorderRadius.circular(8)), child: Text('Break: ${(u['break'] == true) ? 'Yes' : 'No'}', style: TextStyle(color: (u['break'] == true) ? (widget.dark ? const Color(0xFF6ee7b7) : const Color(0xFF059669)) : (widget.dark ? const Color(0xFFfca5a5) : const Color(0xFFDC2626)), fontSize: 12, fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 16),
                                    if (u['remarks'] != null && u['remarks'].toString().isNotEmpty) Expanded(child: Text('Rem: ${u['remarks']}', style: TextStyle(color: widget.dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 12, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.inventory_2_outlined, size: 14, color: widget.textP), const SizedBox(width: 6), Text('${awbs.length} AWBs', style: TextStyle(color: widget.textP, fontWeight: FontWeight.bold, fontSize: 12))])), const SizedBox(width: 16),
                                  ElevatedButton.icon(onPressed: () => showAddAwbDialog(context, widget.logic, i), icon: const Icon(Icons.add, size: 16), label: const Text('Add AWB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))), const SizedBox(width: 12),
                                  Container(decoration: BoxDecoration(color: const Color(0xFFef4444).withAlpha(20), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFef4444), size: 20), tooltip: 'Eliminar ULD', onPressed: () => widget.logic.removeLocalUld(i))), const SizedBox(width: 12),
                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon((u['showAwbs'] ?? true) ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: (u['showAwbs'] ?? true) ? (widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)) : (widget.dark ? const Color(0xFF64748b) : const Color(0xFF9CA3AF)), size: 24), onPressed: () => widget.logic.toggleAwbVisibility(i)),
                                ]
                              )
                            ],
                          ),
                        ),
                        if (awbs.isNotEmpty && (u['showAwbs'] ?? true))
                          Container(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: widget.borderC)),
                            ),
                            child: Table(
                              columnWidths: const {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth(), 5: FlexColumnWidth(), 6: IntrinsicColumnWidth(), 7: IntrinsicColumnWidth()},
                              children: awbs.asMap().entries.map((entry) {
                                final aInt = entry.key;
                                final a = entry.value;
                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: aInt.isEven ? Colors.transparent : (widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB)),
                                    border: aInt == awbs.length - 1 ? null : Border(bottom: BorderSide(color: widget.borderC.withAlpha(100))),
                                  ),
                                  children: [
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: widget.dark ? const Color(0x32ffffff) : const Color(0xFFE5E7EB), shape: BoxShape.circle), child: Center(child: Text('${aInt + 1}', style: TextStyle(color: widget.textP, fontSize: 11, fontWeight: FontWeight.bold))))),
                                    Padding(padding: const EdgeInsets.only(right: 32, top: 12, bottom: 12), child: Text(a['awb_number'], style: TextStyle(color: widget.textP, fontSize: 13, fontWeight: FontWeight.bold))),
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: RichText(text: TextSpan(children: [TextSpan(text: 'PIECES: ', style: TextStyle(color: widget.dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: '${a['pieces']}', style: TextStyle(color: widget.textP, fontSize: 13, fontWeight: FontWeight.w600))]))),
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: RichText(text: TextSpan(children: [TextSpan(text: 'TOTAL: ', style: TextStyle(color: widget.dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: '${a['total'] ?? 0}', style: TextStyle(color: widget.textP, fontSize: 13, fontWeight: FontWeight.w600))]))),
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: RichText(text: TextSpan(children: [TextSpan(text: 'WEIGHT: ', style: TextStyle(color: widget.dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: '${a['weight']}', style: TextStyle(color: widget.textP, fontSize: 13, fontWeight: FontWeight.w600))]))),
                                    Padding(padding: const EdgeInsets.only(right: 8, top: 12, bottom: 12), child: RichText(maxLines: 1, overflow: TextOverflow.ellipsis, text: TextSpan(children: [TextSpan(text: 'REMARKS: ', style: TextStyle(color: widget.dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 10, fontWeight: FontWeight.bold)), TextSpan(text: a['remarks']?.isNotEmpty == true ? a['remarks'] : '-', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontStyle: FontStyle.italic, fontSize: 12))]))),
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Builder(
                                      builder: (ctx) {
                                        final rawH = a['house_number'];
                                        final List<String> items = (rawH is List) ? rawH.map((e) => e.toString()).toList() : [];
                                        if (items.isEmpty) return const SizedBox.shrink();
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: InkWell(
                                            onTap: () {
                                              showDialog(context: ctx, builder: (c) => Dialog(backgroundColor: widget.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: widget.borderC)), child: Container(width: 320, padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('House Numbers (${items.length})', style: TextStyle(color: widget.textP, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Flexible(child: SingleChildScrollView(child: Column(children: items.asMap().entries.map((ent) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: widget.dark ? const Color(0xFF6366f1).withAlpha(40) : const Color(0xFFEEF2FF), shape: BoxShape.circle), child: Text('${ent.key + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Text(ent.value, style: TextStyle(color: widget.dark ? const Color(0xFFcbd5e1) : const Color(0xFF475569), fontSize: 14)))]))).toList()))), const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))))]))));
                                            },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: widget.dark ? const Color(0xFF0f172a) : const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6366f1).withAlpha(100))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.maps_home_work_outlined, size: 12, color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5)), const SizedBox(width: 4), Text('${items.length} HAWB', style: TextStyle(color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5), fontSize: 11, fontWeight: FontWeight.bold))])),
                                          ),
                                        );
                                      }
                                    )),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: () => widget.logic.removeAwb(i, aInt),
                                        child: Container(padding: const EdgeInsets.all(6.0), decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)), child: Icon(Icons.close, color: Colors.redAccent.withAlpha(220), size: 16)),
                                      ),
                                    ),
                                  ]
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          );
        }).toList(),
      )
    );
  }
}
