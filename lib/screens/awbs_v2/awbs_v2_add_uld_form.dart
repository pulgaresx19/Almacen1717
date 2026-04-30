import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show isDarkMode;
import '../add_awb_v2/add_awb_v2_formatters.dart';

class AwbsV2AddUldForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AwbsV2AddUldForm({super.key, required this.onAdd});

  @override
  State<AwbsV2AddUldForm> createState() => _AwbsV2AddUldFormState();
}

class _AwbsV2AddUldFormState extends State<AwbsV2AddUldForm> {
  final _uldNumberCtrl = TextEditingController();
  final _uldPiecesCtrl = TextEditingController();
  final _uldWeightCtrl = TextEditingController();
  final _uldRemarkCtrl = TextEditingController();

  bool _uldNumberError = false;
  bool _uldPiecesError = false;

  @override
  void dispose() {
    _uldNumberCtrl.dispose();
    _uldPiecesCtrl.dispose();
    _uldWeightCtrl.dispose();
    _uldRemarkCtrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    setState(() {
      _uldNumberError = _uldNumberCtrl.text.trim().isEmpty;
      _uldPiecesError = _uldPiecesCtrl.text.trim().isEmpty;
    });

    if (_uldNumberError || _uldPiecesError) return;

    widget.onAdd({
      'type': 'uld',
      'uld_number': _uldNumberCtrl.text.trim(),
      'pieces': _uldPiecesCtrl.text.trim(),
      'total_pieces': '',
      'weight': _uldWeightCtrl.text.trim(),
      'remarks': _uldRemarkCtrl.text.trim(),
    });
    _uldNumberCtrl.clear();
    _uldPiecesCtrl.clear();
    _uldWeightCtrl.clear();
    _uldRemarkCtrl.clear();
    setState(() {
      _uldNumberError = false;
      _uldPiecesError = false;
    });
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1, List<TextInputFormatter>? inputFormatters, int? maxLength, bool hasError = false, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
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
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                counterText: '',
                fillColor: isDarkMode.value ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: hasError ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: hasError ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: hasError ? const BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) {
                if (onChanged != null) onChanged(val);
                setState(() {});
              },
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
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ULD No Break', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 140, child: _buildTextField('ULD Number', _uldNumberCtrl, maxLength: 10, inputFormatters: [UpperCaseTextFormatter()], hasError: _uldNumberError, onChanged: (_) { if (_uldNumberError) setState(() => _uldNumberError = false); })),
                  SizedBox(width: 95, child: _buildTextField('Pieces', _uldPiecesCtrl, isNumber: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly], hasError: _uldPiecesError, onChanged: (_) { if (_uldPiecesError) setState(() => _uldPiecesError = false); })),
                  SizedBox(width: 95, child: _buildTextField('Weight', _uldWeightCtrl, isNumber: true, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                  Expanded(child: _buildTextField('Remarks', _uldRemarkCtrl)),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _uldNumberCtrl.text.isNotEmpty ? const Color(0xFF6366f1) : (dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)), 
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add_rounded, color: _uldNumberCtrl.text.isNotEmpty ? Colors.white : (dark ? Colors.white54 : Colors.black38), size: 20),
                      onPressed: _uldNumberCtrl.text.isNotEmpty ? _handleAdd : null,
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
