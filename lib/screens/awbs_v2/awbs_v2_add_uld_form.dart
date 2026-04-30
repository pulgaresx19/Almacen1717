import 'package:flutter/material.dart';
import '../../main.dart' show isDarkMode;

class AwbsV2AddUldForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AwbsV2AddUldForm({super.key, required this.onAdd});

  @override
  State<AwbsV2AddUldForm> createState() => _AwbsV2AddUldFormState();
}

class _AwbsV2AddUldFormState extends State<AwbsV2AddUldForm> {
  final _uldNumberCtrl = TextEditingController();
  final _uldPiecesCtrl = TextEditingController();
  final _uldTotalCtrl = TextEditingController();
  final _uldWeightCtrl = TextEditingController();
  final _uldRemarkCtrl = TextEditingController();

  @override
  void dispose() {
    _uldNumberCtrl.dispose();
    _uldPiecesCtrl.dispose();
    _uldTotalCtrl.dispose();
    _uldWeightCtrl.dispose();
    _uldRemarkCtrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_uldNumberCtrl.text.trim().isEmpty) return;
    widget.onAdd({
      'uld_number': _uldNumberCtrl.text.trim(),
      'pieces': _uldPiecesCtrl.text.trim(),
      'total_pieces': _uldTotalCtrl.text.trim(),
      'weight': _uldWeightCtrl.text.trim(),
      'remarks': _uldRemarkCtrl.text.trim(),
    });
    setState(() {
      _uldNumberCtrl.clear();
      _uldPiecesCtrl.clear();
      _uldTotalCtrl.clear();
      _uldWeightCtrl.clear();
      _uldRemarkCtrl.clear();
    });
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
              Text('ULD No Break', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 160, child: _buildTextField('ULD Number', _uldNumberCtrl)),
                  SizedBox(width: 80, child: _buildTextField('Pieces', _uldPiecesCtrl, isNumber: true)),
                  SizedBox(width: 80, child: _buildTextField('Total', _uldTotalCtrl, isNumber: true)),
                  SizedBox(width: 100, child: _buildTextField('Weight', _uldWeightCtrl, isNumber: true)),
                  SizedBox(width: 340, child: _buildTextField('Remarks', _uldRemarkCtrl)),
                  
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
