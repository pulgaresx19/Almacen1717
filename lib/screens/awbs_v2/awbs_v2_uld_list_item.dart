import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import '../flight_details_v2/flight_details_v2_add_awb_dialog.dart';
import 'awbs_v2_dialogs.dart';

class AwbsV2UldListItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool dark;
  final Color textP;
  final Color borderCard;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const AwbsV2UldListItem({
    super.key,
    required this.item,
    required this.index,
    required this.dark,
    required this.textP,
    required this.borderCard,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<AwbsV2UldListItem> createState() => _AwbsV2UldListItemState();
}

class _AwbsV2UldListItemState extends State<AwbsV2UldListItem> {
  bool _isExpanded = false;

  void _recalcAuto() {
    final awbsList = widget.item['awbs'] as List? ?? [];
    int sumP = 0;
    double sumW = 0.0;
    for (var a in awbsList) {
      sumP += int.tryParse(a['pieces'].toString()) ?? 0;
      sumW += double.tryParse(a['weight'].toString()) ?? 0.0;
    }

    bool updated = false;
    if (widget.item['auto_pieces'] == true) {
      widget.item['pieces'] = sumP > 0 ? sumP.toString() : 'Auto';
      updated = true;
    }
    if (widget.item['auto_weight'] == true) {
      widget.item['weight'] = sumW > 0 ? sumW.toString() : 'Auto';
      updated = true;
    }

    if (updated) {
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final awbsList = widget.item['awbs'] as List? ?? [];
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.borderCard),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28, alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                      child: Text('${widget.index + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ULD Number', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(widget.item['uld_number'], style: TextStyle(color: widget.textP, fontWeight: FontWeight.bold, fontSize: 14)),
                    ])),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pieces', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${widget.item['pieces'].toString().isEmpty ? '0' : widget.item['pieces']}', style: TextStyle(color: widget.item['auto_pieces'] == true ? const Color(0xFF10b981) : widget.textP, fontSize: 13, fontWeight: widget.item['auto_pieces'] == true ? FontWeight.bold : FontWeight.normal)),
                    ])),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Weight', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${widget.item['weight'].toString().isEmpty ? '0' : widget.item['weight']}', style: TextStyle(color: widget.item['auto_weight'] == true ? const Color(0xFF10b981) : widget.textP, fontSize: 13, fontWeight: widget.item['auto_weight'] == true ? FontWeight.bold : FontWeight.normal)),
                    ])),
                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Remark', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(widget.item['remarks'].toString().isEmpty ? '-' : widget.item['remarks'], style: TextStyle(color: widget.textP, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                      child: Text('${awbsList.length} AWBs', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: widget.textP),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 24, color: widget.borderCard),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: widget.onDelete,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Nested AWBs List
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(bottom: 12, left: 24, right: 8),
            decoration: BoxDecoration(
              color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.borderCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (awbsList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        appLanguage.value == 'es' ? 'No hay AWBs anidados en este ULD.' : 'No nested AWBs in this ULD.',
                        style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 13),
                      ),
                    ),
                  ),
                if (awbsList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: List.generate(awbsList.length, (i) {
                        final awb = awbsList[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: widget.borderCard),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20, height: 20, alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0xFF3b82f6).withAlpha(40), shape: BoxShape.circle),
                                child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF60a5fa), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('AWB', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 9, fontWeight: FontWeight.bold)),
                                Text(awb['awb_number'], style: TextStyle(color: widget.textP, fontWeight: FontWeight.bold, fontSize: 13)),
                              ])),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Pieces', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 9, fontWeight: FontWeight.bold)),
                                Text('${awb['pieces']} / ${awb['total_pieces'].toString().isEmpty ? '0' : awb['total_pieces']}', style: TextStyle(color: widget.textP, fontSize: 12)),
                              ])),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Weight', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 9, fontWeight: FontWeight.bold)),
                                Text('${awb['weight'].toString().isEmpty ? '0' : awb['weight']}', style: TextStyle(color: widget.textP, fontSize: 12)),
                              ])),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Remark', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 9, fontWeight: FontWeight.bold)),
                                Text(awb['remarks'].toString().isEmpty ? '-' : awb['remarks'], style: TextStyle(color: widget.textP, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              const SizedBox(width: 8),
                              if (awb['house_number'] != null && awb['house_number'].toString().trim().isNotEmpty)
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                     List<String> houses = awb['house_number'].toString().split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                     showCustomListDialog(context, 'House Numbers', houses);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFf59e0b).withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.other_houses_outlined, color: Color(0xFFf59e0b), size: 14),
                                        const SizedBox(width: 4),
                                        Text('${awb['house_number'].toString().split('\n').where((e) => e.trim().isNotEmpty).length}', style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Icon(Icons.other_houses_outlined, color: widget.dark ? Colors.white24 : Colors.black26, size: 16),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                                onPressed: () {
                                  setState(() {
                                    awbsList.removeAt(i);
                                    _recalcAuto();
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 16,
                              )
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                
                // Add AWB Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: widget.borderCard))),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1).withAlpha(30),
                        foregroundColor: const Color(0xFF818cf8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        appLanguage.value == 'es' ? 'Añadir AWB a ULD' : 'Add AWB to ULD',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () async {
                        final existingAwbs = awbsList.map((e) => Map<String, dynamic>.from(e)).toList();
                        final res = await showAddAwbDialog(context, widget.dark, existingAwbs, widget.item['uld_number']);
                        if (res != null) {
                          setState(() {
                            awbsList.add({
                              'awb_number': res['awb_number'],
                              'pieces': res['pieces'],
                              'total_pieces': res['total'],
                              'weight': res['weight'],
                              'remarks': res['remarks'],
                              'house_number': res['house'],
                            });
                            _recalcAuto();
                          });
                        }
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
      ],
    );
  }
}
