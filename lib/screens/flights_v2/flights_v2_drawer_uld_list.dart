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
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 10)),
        Text(value, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Pcs' : 'Pieces', uld['pieces_total']?.toString() ?? '0', textP, textS))),
                  Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Wgt' : 'Weight', uld['weight_total']?.toString() ?? '0', textP, textS))),
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.info_outline_rounded, size: 18, color: isSelected ? const Color(0xFF6366f1) : textS),
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => _showUldDetails(context, uld),
                        ),
                      ],
                    ),
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
                        final awbMaster = split['awbs'] ?? {};
                        final awbNumber = awbMaster['awb_number']?.toString() ?? 'Desconocida';
                        final splitPieces = split['pieces'] ?? split['pieces_split'] ?? 0;
                        final splitWeight = split['weight'] ?? split['weight_split'] ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
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
                              Expanded(child: Center(child: _buildMetric('Pcs', '$splitPieces', textP, textS))),
                              Expanded(child: Center(child: _buildMetric('Wgt', '$splitWeight', textP, textS))),
                              SizedBox(
                                width: 50,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(Icons.info_outline_rounded, size: 18, color: textS),
                                    splashRadius: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () => _showAwbDetails(context, split, awbMaster),
                                  ),
                                ),
                              ),
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

  void _showUldDetails(BuildContext context, Map<String, dynamic> uld) {
    final titleInfo = {
      'label': 'ULD Number',
      'value': uld['uld_number']?.toString() ?? 'Desconocido',
      'icon': Icons.inventory_2,
      'color': widget.dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
    };
    
    final gridItems = [
      {'label': 'Pieces', 'value': uld['pieces_total']?.toString() ?? uld['pieces']?.toString() ?? '0', 'icon': Icons.extension, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'Weight', 'value': '${uld['weight_total']?.toString() ?? uld['weight']?.toString() ?? '0'} kg', 'icon': Icons.scale, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'Priority', 'value': uld['is_priority'] == true ? 'Yes' : 'No', 'icon': Icons.star, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'Break', 'value': uld['is_break'] == true ? 'Yes' : 'No', 'icon': Icons.broken_image, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'Status', 'value': uld['status']?.toString() ?? 'Ready', 'icon': Icons.info_outline, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
    ];

    _showGridDialog(context, 'ULD Information', titleInfo, gridItems.sublist(0, 2), gridItems.sublist(2, 5));
  }

  void _showAwbDetails(BuildContext context, Map<String, dynamic> split, Map<String, dynamic> master) {
    final combined = {...master, ...split};
    final titleInfo = {
      'label': 'AWB Number',
      'value': combined['awb_number']?.toString() ?? 'Desconocida',
      'icon': Icons.description,
      'color': widget.dark ? const Color(0xFFf472b6) : const Color(0xFFdb2777),
    };
    
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

    final gridItems = [
      {'label': 'Pieces', 'value': splitPieces, 'icon': Icons.extension, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'Total', 'value': masterPieces, 'icon': Icons.layers, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'Weight', 'value': '$splitWeight kg', 'icon': Icons.scale, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'House Num', 'value': houseNum, 'icon': Icons.home_work, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
      {'label': 'Remarks', 'value': combined['remarks']?.toString() ?? '-', 'icon': Icons.notes, 'color': widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)},
    ];

    _showGridDialog(context, 'AWB Information', titleInfo, gridItems.sublist(0, 3), gridItems.sublist(3, 5));
  }

  void _showGridDialog(BuildContext context, String title, Map<String, dynamic> titleInfo, List<Map<String, dynamic>> row1, List<Map<String, dynamic>> row2) {
    final bgCard = widget.dark ? const Color(0xFF1E293B) : Colors.white;
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(title, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildGridCard(titleInfo['label'], titleInfo['value'], titleInfo['icon'], titleInfo['color'], true),
                  ),
                  const SizedBox(height: 12),
                  if (row1.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: row1.asMap().entries.map((e) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12.0),
                                child: _buildGridCard(e.value['label'], e.value['value'], e.value['icon'], e.value['color']),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  if (row2.isNotEmpty)
                    const SizedBox(height: 12),
                  if (row2.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: row2.asMap().entries.map((e) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12.0),
                                child: _buildGridCard(e.value['label'], e.value['value'], e.value['icon'], e.value['color']),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close', style: TextStyle(color: widget.dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCard(String label, String value, IconData icon, Color iconColor, [bool isFull = false]) {
    final bgCard = widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
    final borderColor = widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB);
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    
    return Container(
      padding: EdgeInsets.all(isFull ? 16 : 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isFull ? 0 : 2),
            child: Icon(icon, size: isFull ? 24 : 18, color: iconColor),
          ),
          SizedBox(width: isFull ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isFull ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textS, fontSize: isFull ? 12 : 11)),
                SizedBox(height: isFull ? 4 : 2),
                Text(value, style: TextStyle(color: textP, fontSize: isFull ? 18 : 14, fontWeight: FontWeight.bold)),
              ],
            ),
          )
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              appLanguage.value == 'es' ? 'ULDs del Vuelo' : 'ULDs in Flight',
              style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
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
