import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show isDarkMode;
import 'awbs_v2_formatters.dart';

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
  bool _autoPieces = true;
  bool _autoWeight = true;

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
      _uldPiecesError = !_autoPieces && _uldPiecesCtrl.text.trim().isEmpty;
    });

    if (_uldNumberError || _uldPiecesError) return;

    widget.onAdd({
      'type': 'uld',
      'uld_number': _uldNumberCtrl.text.trim(),
      'pieces': _autoPieces ? 'Auto' : _uldPiecesCtrl.text.trim(),
      'total_pieces': '',
      'weight': _autoWeight ? 'Auto' : _uldWeightCtrl.text.trim(),
      'remarks': _uldRemarkCtrl.text.trim(),
      'auto_pieces': _autoPieces,
      'auto_weight': _autoWeight,
      'awbs': <Map<String, dynamic>>[],
    });
    _uldNumberCtrl.clear();
    if (!_autoPieces) _uldPiecesCtrl.clear();
    if (!_autoWeight) _uldWeightCtrl.clear();
    _uldRemarkCtrl.clear();
    setState(() {
      _uldNumberError = false;
      _uldPiecesError = false;
    });
  }

  Widget _buildAutoCheckbox(bool value, Function(bool) onChanged) {
    return SizedBox(
      height: 16,
      width: 16,
      child: Checkbox(
        value: value,
        activeColor: const Color(0xFF6366f1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: isDarkMode.value ? Colors.white54 : Colors.black54, width: 1.5),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1, List<TextInputFormatter>? inputFormatters, int? maxLength, bool hasError = false, bool readOnly = false, Widget? trailingLabel, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: hasError ? const Color(0xFFef4444) : (isDarkMode.value ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)), fontSize: 12, fontWeight: FontWeight.w600)),
              trailingLabel ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: ctrl,
              readOnly: readOnly,
              keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              maxLines: maxLines,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              style: TextStyle(color: isDarkMode.value ? (readOnly ? Colors.white54 : Colors.white) : (readOnly ? Colors.black54 : Colors.black), fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                counterText: '',
                hintText: readOnly ? 'Auto' : null,
                hintStyle: TextStyle(color: isDarkMode.value ? Colors.white54 : Colors.black54, fontSize: 13),
                fillColor: hasError ? const Color(0xFFef4444).withAlpha(10) : (!readOnly ? (isDarkMode.value ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6)) : (isDarkMode.value ? Colors.white.withAlpha(5) : const Color(0xFFE5E7EB))),
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
                  SizedBox(width: 95, child: _buildTextField('Pieces', _uldPiecesCtrl, isNumber: true, readOnly: _autoPieces, 
                    trailingLabel: _buildAutoCheckbox(_autoPieces, (val) {
                      setState(() {
                        _autoPieces = val;
                        if (_autoPieces) {
                          _uldPiecesError = false;
                          _uldPiecesCtrl.clear();
                        }
                      });
                    }),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], hasError: _uldPiecesError, onChanged: (_) { if (_uldPiecesError) setState(() => _uldPiecesError = false); })),
                  SizedBox(width: 95, child: _buildTextField('Weight', _uldWeightCtrl, isNumber: true, readOnly: _autoWeight, 
                    trailingLabel: _buildAutoCheckbox(_autoWeight, (val) {
                      setState(() {
                        _autoWeight = val;
                        if (_autoWeight) _uldWeightCtrl.clear();
                      });
                    }),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
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
