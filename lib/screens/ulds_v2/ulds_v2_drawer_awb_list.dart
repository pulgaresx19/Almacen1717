import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;

class UldsV2AwbList extends StatefulWidget {
  final List<Map<String, dynamic>> awbs;
  final bool isLoading;
  final bool dark;

  const UldsV2AwbList({
    super.key,
    required this.awbs,
    required this.isLoading,
    required this.dark,
  });

  @override
  State<UldsV2AwbList> createState() => _UldsV2AwbListState();
}

class _UldsV2AwbListState extends State<UldsV2AwbList> {
  String? _selectedAwbId;

  Widget _buildMetric(String label, String value, Color textP, Color textS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 10)),
        Text(value, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAwbCard(int index, Map<String, dynamic> awbSplit, Color textP, Color textS, Color bgCard) {
    final awbId = awbSplit['id_split']?.toString() ?? awbSplit['id_awb']?.toString() ?? '$index';
    final isSelected = _selectedAwbId == awbId;
    final master = awbSplit['awbs'] ?? {};
    final combined = {...master, ...awbSplit};

    final awbNumber = combined['awb_number']?.toString() ?? '-';
    final pieces = awbSplit['pieces']?.toString() ?? awbSplit['pieces_split']?.toString() ?? '0';
    final weight = awbSplit['weight']?.toString() ?? awbSplit['weight_split']?.toString() ?? '0';
    
    String houseNum = '-';
    if (combined['house_number'] != null) {
      if (combined['house_number'] is List) {
        houseNum = (combined['house_number'] as List).join(', ').trim();
        if (houseNum.isEmpty) houseNum = '-';
      } else {
        houseNum = combined['house_number'].toString();
      }
    }
    final remarks = combined['remarks']?.toString() ?? '-';
    final masterPieces = master['total_pieces']?.toString() ?? master['pieces']?.toString() ?? '0';
    
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
                _selectedAwbId = isSelected ? null : awbId;
              });
            },
            borderRadius: isSelected ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Pcs' : 'Pieces', pieces, textP, textS))),
                  Expanded(child: Center(child: _buildMetric('Total', masterPieces, textP, textS))),
                  Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Wgt' : 'Weight', weight, textP, textS))),
                  Center(
                    child: IconButton(
                      icon: Icon(
                        isSelected ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                        size: 20, 
                        color: isSelected ? const Color(0xFF6366f1) : textS
                      ),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        setState(() {
                          _selectedAwbId = isSelected ? null : awbId;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSelected) ...[
            Divider(height: 1, color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('House Number', style: TextStyle(color: textS, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(houseNum, style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Remarks', style: TextStyle(color: textS, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(remarks, style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
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
    final textHeader = widget.dark ? Colors.white : const Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Text(
                appLanguage.value == 'es' ? 'Air Waybills' : 'Air Waybills',
                style: TextStyle(color: textHeader, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.awbs.length}',
                  style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
        if (widget.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (widget.awbs.isEmpty)
           Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 48, color: textS.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(appLanguage.value == 'es' ? 'No hay AWBs' : 'No AWBs found.', style: TextStyle(color: textS, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: widget.awbs.length,
              itemBuilder: (context, index) {
                final bgCard = widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);
                return _buildAwbCard(index, widget.awbs[index], textP, textS, bgCard);
              },
            ),
          ),
      ],
    );
  }
}
