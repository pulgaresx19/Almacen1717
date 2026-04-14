import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;

void showCoordinatorV2AwbModal(BuildContext context, Map<String, dynamic> combined, Map<String, dynamic> awbSplit, bool dark) {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
  final bgCard = dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);
  final bgModal = dark ? const Color(0xFF0f172a) : Colors.white;

  final awbNumber = combined['awb_number']?.toString() ?? '-';
  final pieces = awbSplit['pieces']?.toString() ?? awbSplit['pieces_split']?.toString() ?? '0';
  final weight = awbSplit['weight']?.toString() ?? awbSplit['weight_split']?.toString() ?? '0';
  final totalPieces = combined['total_pieces']?.toString() ?? combined['pieces']?.toString() ?? '0';

  int houseCount = 0;
  if (combined['house_number'] != null) {
    if (combined['house_number'] is List) {
      houseCount = (combined['house_number'] as List).length;
    } else {
      final str = combined['house_number'].toString().trim();
      houseCount = str.isNotEmpty && str != '-' ? str.split(',').length : 0;
    }
  }
  
  final remarks = combined['remarks']?.toString() ?? '';

  showDialog(
    context: context,
    builder: (context) {
      int selectedType = 0;
      bool notFoundSelected = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgModal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLanguage.value == 'es' ? 'Detalles de AWB' : 'AWB Details',
                        style: TextStyle(color: textS, fontSize: 13),
                      ),
                      Text(
                        awbNumber,
                        style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textS),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildDetailItem(appLanguage.value == 'es' ? 'Piezas' : 'Pieces', pieces, textP, textS, bgCard),
                  _buildDetailItem('Total', totalPieces, textP, textS, bgCard),
                  _buildDetailItem(appLanguage.value == 'es' ? 'Peso' : 'Weight', '$weight kg', textP, textS, bgCard),
                  _buildHouseItem(houseCount, textP, textS, bgCard),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailItem(appLanguage.value == 'es' ? 'Comentarios' : 'Remarks', remarks.trim().isEmpty ? '-' : remarks, textP, textS, bgCard, isFullWidth: true),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Total checked', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(20), borderRadius: BorderRadius.circular(12)),
                        child: const Text('0', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        notFoundSelected = !notFoundSelected;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: notFoundSelected ? const Color(0xFFEF4444).withAlpha(20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: notFoundSelected 
                            ? const Color(0xFFEF4444).withAlpha(50) 
                            : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))
                        ),
                      ),
                      child: Text('Not found', style: TextStyle(color: notFoundSelected ? const Color(0xFFEF4444) : textS, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildTextFieldBlock('AGI skid', textP, textS, bgCard, dark),
                        const SizedBox(height: 12),
                        _buildTextFieldBlock('Pre skid', textP, textS, bgCard, dark),
                        const SizedBox(height: 12),
                        _buildTextFieldBlock('Crate', textP, textS, bgCard, dark),
                        const SizedBox(height: 12),
                        _buildTextFieldBlock('Box', textP, textS, bgCard, dark),
                        const SizedBox(height: 12),
                        _buildTextFieldBlock('Other', textP, textS, bgCard, dark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        appLanguage.value == 'es' ? 'Componente Adicional' : 'Additional Info',
                        style: TextStyle(color: textS),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _buildSelectorIcon(0, selectedType, Icons.check_circle, const Color(0xFF10B981), textS, () => setState(() => selectedType = 0)),
                        const SizedBox(height: 12),
                        _buildSelectorIcon(1, selectedType, Icons.warning_rounded, const Color(0xFFEF4444), textS, () => setState(() => selectedType = 1)),
                        const SizedBox(height: 12),
                        _buildSelectorIcon(2, selectedType, Icons.info_outline, const Color(0xFF3B82F6), textS, () => setState(() => selectedType = 2)),
                        const SizedBox(height: 12),
                        _buildSelectorIcon(3, selectedType, Icons.notes_rounded, const Color(0xFFF59E0B), textS, () => setState(() => selectedType = 3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    appLanguage.value == 'es' ? 'Guardar' : 'Save',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
       ),
      );
     },
    );
   },
  );
}

Widget _buildHouseItem(int count, Color textP, Color textS, Color bgCard) {
  return Container(
    width: 100,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('House', style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF6366f1).withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$count',
            style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailItem(String label, String value, Color textP, Color textS, Color bgCard, {bool isFullWidth = false}) {
  return Container(
    width: isFullWidth ? double.infinity : 100,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildTextFieldBlock(String label, Color textP, Color textS, Color bgCard, bool dark) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 60,
        child: Text(label, style: TextStyle(color: textS, fontSize: 11)),
      ),
      const SizedBox(width: 8),
      Container(
        width: 65,
        height: 38,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
        ),
        child: Material(
          color: Colors.transparent,
          child: TextField(
            style: TextStyle(color: textP, fontSize: 13),
            keyboardType: TextInputType.number,
            maxLength: 5,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.add_circle, color: Color(0xFF6366f1), size: 24),
          ),
        ),
      ),
    ],
  );
}

Widget _buildSelectorIcon(int index, int selectedIndex, IconData icon, Color actColor, Color textS, VoidCallback onTap) {
  final isAct = selectedIndex == index;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isAct ? actColor.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isAct ? Border.all(color: actColor.withAlpha(100)) : Border.all(color: Colors.transparent),
      ),
      child: Icon(icon, color: isAct ? actColor : textS.withAlpha(150), size: 26),
    ),
  );
}
