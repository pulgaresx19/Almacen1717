import 'package:flutter/material.dart';
import '../../main.dart' show isDarkMode;

class AwbsV2AddAwbForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AwbsV2AddAwbForm({super.key, required this.onAdd});

  @override
  State<AwbsV2AddAwbForm> createState() => _AwbsV2AddAwbFormState();
}

class _AwbsV2AddAwbFormState extends State<AwbsV2AddAwbForm> {
  final _awbNumberCtrl = TextEditingController();
  final _awbPiecesCtrl = TextEditingController();
  final _awbTotalCtrl = TextEditingController();
  final _awbWeightCtrl = TextEditingController();
  final _awbRemarkCtrl = TextEditingController();
  final _awbHouseCtrl = TextEditingController();

  @override
  void dispose() {
    _awbNumberCtrl.dispose();
    _awbPiecesCtrl.dispose();
    _awbTotalCtrl.dispose();
    _awbWeightCtrl.dispose();
    _awbRemarkCtrl.dispose();
    _awbHouseCtrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_awbNumberCtrl.text.trim().isEmpty) return;
    widget.onAdd({
      'awb_number': _awbNumberCtrl.text.trim(),
      'pieces': _awbPiecesCtrl.text.trim(),
      'total_pieces': _awbTotalCtrl.text.trim(),
      'weight': _awbWeightCtrl.text.trim(),
      'remarks': _awbRemarkCtrl.text.trim(),
      'house_number': _awbHouseCtrl.text.trim(),
    });
    _awbNumberCtrl.clear();
    _awbPiecesCtrl.clear();
    _awbTotalCtrl.clear();
    _awbWeightCtrl.clear();
    _awbRemarkCtrl.clear();
    _awbHouseCtrl.clear();
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDarkMode.value ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: ctrl,
              keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              maxLines: maxLines,
              style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode.value ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Air Waybill (AWB)', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 160, child: _buildTextField('AWB Number', _awbNumberCtrl)),
                  SizedBox(width: 80, child: _buildTextField('Pieces', _awbPiecesCtrl, isNumber: true)),
                  SizedBox(width: 80, child: _buildTextField('Total', _awbTotalCtrl, isNumber: true)),
                  SizedBox(width: 100, child: _buildTextField('Weight', _awbWeightCtrl, isNumber: true)),
                  SizedBox(width: 200, child: _buildTextField('Remarks', _awbRemarkCtrl)),
                  SizedBox(width: 140, child: _buildTextField('House No.', _awbHouseCtrl)),
                  Container(
                    margin: const EdgeInsets.only(top: 24, left: 8),
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(color: const Color(0xFF6366f1), borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      onPressed: _handleAdd,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
