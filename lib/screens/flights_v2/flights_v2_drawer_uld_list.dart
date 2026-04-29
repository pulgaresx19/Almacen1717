import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import '../flight_details_v2/flight_details_v2_add_uld.dart';
import 'flights_v2_status_logic.dart';

class FlightsV2UldList extends StatefulWidget {
  final List<Map<String, dynamic>> ulds;
  final Map<String, dynamic> flight;
  final bool isLoading;
  final bool dark;
  final VoidCallback? onRefresh;

  const FlightsV2UldList({
    super.key,
    required this.ulds,
    required this.flight,
    required this.isLoading,
    required this.dark,
    this.onRefresh,
  });

  @override
  State<FlightsV2UldList> createState() => _FlightsV2UldListState();
}

class _FlightsV2UldListState extends State<FlightsV2UldList> {
  String? _selectedUldId;

  Widget _buildMetric(String label, String value, Color textP, Color textS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildStatusMetric(String label, String value, Color textS) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = value.toLowerCase();
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('process') || s.contains('progress')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('checked') || s.contains('received')) {
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
    } else if (s.contains('ready') || s.contains('saved') || s.contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('pending')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 10)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUldCard(int index, Map<String, dynamic> uld, Color textP, Color textS, Color bgCard) {
    final uldId = uld['id_uld']?.toString() ?? '';
    final isSelected = _selectedUldId == uldId;
    final awbSplits = List<Map<String, dynamic>>.from(uld['awb_splits'] ?? []);
    final borderColor = isSelected 
        ? const Color(0xFF6366f1) 
        : (widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB));
    final bgColor = isSelected ? const Color(0xFF6366f1).withAlpha(20) : bgCard;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              InkWell(
                onTap: () {
              setState(() {
                _selectedUldId = isSelected ? null : uldId;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 155,
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (widget.dark ? const Color(0xFF6366f1).withAlpha(40) : const Color(0xFF4F46E5).withAlpha(20))
                                : (widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected 
                                    ? (widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5))
                                    : (widget.dark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(15))),
                          ),
                          alignment: Alignment.center,
                          child: Text('${index + 1}', style: TextStyle(
                              color: isSelected ? (widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5)) : textS, 
                              fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(uld['uld_number']?.toString() ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Pcs' : 'Pieces', uld['pieces_total']?.toString() ?? uld['pieces']?.toString() ?? '0', textP, textS))),
                  Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Wgt' : 'Weight', '${uld['weight_total']?.toString() ?? uld['weight']?.toString() ?? '0'} kg', textP, textS))),
                  Expanded(child: Center(child: _buildMetric('Priority', uld['is_priority'] == true ? 'Yes' : 'No', uld['is_priority'] == true ? const Color(0xFFeab308) : textP, textS))),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Break', style: TextStyle(color: textS, fontSize: 10)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (uld['is_break'] == true) ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: (uld['is_break'] == true) ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50)),
                            ),
                            child: Text(
                              (uld['is_break'] == true) ? 'BREAK' : 'NO BRK',
                              style: TextStyle(
                                color: (uld['is_break'] == true) ? Colors.green : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: Center(child: _buildMetric('Remarks', (uld['remarks']?.toString().trim().isNotEmpty == true && uld['remarks']?.toString().trim().toLowerCase() != 'null') ? uld['remarks'].toString() : '-', textP, textS))),
                  Expanded(child: Center(child: _buildStatusMetric('Status', FlightsV2StatusLogic.getUldStatus(uld), textS))),
                  const SizedBox(width: 16),
                  Icon(
                    isSelected ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: textS,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected) ...[
            Divider(height: 1, color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
            Container(
              padding: const EdgeInsets.all(16),
              child: awbSplits.isEmpty
                  ? Text(appLanguage.value == 'es' ? 'Sin guías.' : 'No AWBs.', style: TextStyle(color: textS))
                  : Column(
                      children: awbSplits.asMap().entries.map((entry) {
                        final awbIndex = entry.key + 1;
                        final split = entry.value;
                        final master = split['awbs'] ?? {};
                        final combined = {...master, ...split};
                        
                        final awbNumber = master['awb_number']?.toString() ?? 'Desconocida';
                        final splitPieces = split['pieces']?.toString() ?? split['pieces_split']?.toString() ?? '0';
                        final masterPieces = master['total_pieces']?.toString() ?? master['pieces']?.toString() ?? '0';
                        final splitWeight = split['weight']?.toString() ?? split['weight_split']?.toString() ?? '0';
                        
                        List<String> houseList = [];
                        if (combined['house_number'] != null) {
                          if (combined['house_number'] is List) {
                            houseList = List<String>.from(combined['house_number']).where((e) => e.trim().isNotEmpty).toList();
                          } else if (combined['house_number'].toString().trim().isNotEmpty) {
                            houseList = [combined['house_number'].toString().trim()];
                          }
                        }
                        int houseCount = houseList.length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 155,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: widget.dark ? const Color(0xFFf472b6).withAlpha(30) : const Color(0xFFdb2777).withAlpha(20),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: widget.dark ? const Color(0xFFf472b6).withAlpha(80) : const Color(0xFFdb2777).withAlpha(60)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('$awbIndex', style: TextStyle(color: widget.dark ? const Color(0xFFf472b6) : const Color(0xFFdb2777), fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              Expanded(child: Center(child: _buildMetric('Pcs', splitPieces, textP, textS))),
                              Expanded(child: Center(child: _buildMetric('Total Pcs', masterPieces, textP, textS))),
                              Expanded(child: Center(child: _buildMetric('Weight', '$splitWeight kg', textP, textS))),
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('House', style: TextStyle(color: textS, fontSize: 10)),
                                      const SizedBox(height: 2),
                                      if (houseList.isEmpty)
                                        Text('-', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold))
                                      else
                                        InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: widget.dark ? const Color(0xFF1E293B) : Colors.white,
                                                title: Text('House Numbers', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                                                content: SizedBox(
                                                  width: 300,
                                                  child: ListView.separated(
                                                    shrinkWrap: true,
                                                    itemCount: houseList.length,
                                                    separatorBuilder: (context, index) => Divider(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                                    itemBuilder: (ctx, i) => Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 24,
                                                            height: 24,
                                                            decoration: BoxDecoration(
                                                              color: widget.dark ? const Color(0xFF6366f1).withAlpha(40) : const Color(0xFF4F46E5).withAlpha(20),
                                                              shape: BoxShape.circle,
                                                              border: Border.all(color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5)),
                                                            ),
                                                            alignment: Alignment.center,
                                                            child: Text('${i + 1}', style: TextStyle(color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(child: Text(houseList[i], style: TextStyle(color: textP, fontSize: 14))),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx),
                                                    child: Text(appLanguage.value == 'es' ? 'Cerrar' : 'Close', style: const TextStyle(color: Color(0xFF6366f1))),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: widget.dark ? const Color(0xFF6366f1).withAlpha(40) : const Color(0xFF4F46E5).withAlpha(20),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5)),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text('$houseCount', style: TextStyle(color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(child: Center(child: _buildMetric('Remarks', (combined['remarks']?.toString().trim().isNotEmpty == true && combined['remarks']?.toString().trim().toLowerCase() != 'null') ? combined['remarks'].toString() : '-', textP, textS))),
                              Expanded(child: Center(child: _buildStatusMetric('Status', FlightsV2StatusLogic.getAwbStatus(split), textS))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            )
          ]
        ],
      ),
      Positioned(
        top: 0,
        right: 0,
        child: InkWell(
          onTap: () async {
            final bool? result = await showAddUldComponent(context, widget.flight, widget.dark, widget.ulds, uld);
            if (result == true && widget.onRefresh != null) {
              widget.onRefresh!();
            }
          },
          borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.dark ? const Color(0xFF6366f1).withAlpha(40) : const Color(0xFF4F46E5).withAlpha(20),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.edit_outlined, color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), size: 13),
          ),
        ),
      ),
    ],
  ),
);
}

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);

    final sortedUlds = List<Map<String, dynamic>>.from(widget.ulds);
    sortedUlds.sort((a, b) {
      final aBreak = a['is_break'] == true;
      final bBreak = b['is_break'] == true;
      if (aBreak && !bBreak) return -1;
      if (!aBreak && bBreak) return 1;

      final aUldNum = (a['uld_number']?.toString() ?? '').toLowerCase();
      final bUldNum = (b['uld_number']?.toString() ?? '').toLowerCase();
      
      final aIsBulk = aUldNum == 'bulk';
      final bIsBulk = bUldNum == 'bulk';
      if (aIsBulk && !bIsBulk) return -1;
      if (!aIsBulk && bIsBulk) return 1;

      return aUldNum.compareTo(bUldNum);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : sortedUlds.isEmpty
                  ? Center(
                      child: Text(
                        appLanguage.value == 'es' ? 'No se encontraron ULDs.' : 'No ULDs found.',
                        style: TextStyle(color: textS),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ListView.builder(
                        itemCount: sortedUlds.length,
                        itemBuilder: (context, index) {
                          return _buildUldCard(index, sortedUlds[index], textP, textS, bgCard);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
