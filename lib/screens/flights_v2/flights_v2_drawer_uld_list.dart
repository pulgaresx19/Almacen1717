import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;

class FlightsV2UldList extends StatefulWidget {
  final List<Map<String, dynamic>> ulds;
  final bool isLoading;
  final bool dark;

  const FlightsV2UldList({
    super.key,
    required this.ulds,
    required this.isLoading,
    required this.dark,
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
      child: Column(
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
                  Expanded(child: Center(child: _buildMetric('Status', uld['status']?.toString() ?? 'Ready', textP, textS))),
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
                        
                        String houseNum = '-';
                        if (combined['house_number'] != null) {
                          if (combined['house_number'] is List) {
                            houseNum = (combined['house_number'] as List).join(', ').trim();
                            if (houseNum.isEmpty) houseNum = '-';
                          } else {
                            houseNum = combined['house_number'].toString();
                          }
                        }

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
                              Expanded(child: Center(child: _buildMetric('House', houseNum, textP, textS))),
                              Expanded(child: Center(child: _buildMetric('Remarks', combined['remarks']?.toString() ?? '-', textP, textS))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.ulds.isEmpty
                  ? Center(
                      child: Text(
                        appLanguage.value == 'es' ? 'No se encontraron ULDs.' : 'No ULDs found.',
                        style: TextStyle(color: textS),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ListView.builder(
                        itemCount: widget.ulds.length,
                        itemBuilder: (context, index) {
                          return _buildUldCard(index, widget.ulds[index], textP, textS, bgCard);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
