import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_uld_v2_logic.dart';

Widget buildUldTextField(String label, TextEditingController ctrl, String hint, {bool isNum = false, bool digitsOnly = false, bool allowDecimal = false, int? maxLen, bool disabled = false, Widget? suffixIcon, VoidCallback? onTap, bool readOnly = false, bool isUpperCase = false, Widget? titleTrailing, bool isAwb = false, int? maxLines = 1, int? minLines, bool expands = false, List<TextInputFormatter>? customFormatters, bool hasError = false, String? errorText}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)), titleTrailing ?? const SizedBox.shrink()]),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, enabled: !disabled, readOnly: readOnly, onTap: onTap,
        keyboardType: (maxLines == null || maxLines > 1) ? TextInputType.multiline : (isNum ? (allowDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number) : TextInputType.text),
        textCapitalization: isUpperCase ? TextCapitalization.characters : TextCapitalization.none,
        inputFormatters: [
          if (isAwb) AwbTextInputFormatter(),
          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (allowDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          if (isUpperCase) TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection)),
          ...?customFormatters,
        ],
        maxLength: maxLen, maxLines: maxLines, minLines: minLines, expands: expands, textAlignVertical: expands ? TextAlignVertical.top : null,
        style: TextStyle(color: disabled ? Colors.white.withAlpha(120) : Colors.white, fontSize: 12),
        decoration: InputDecoration(
           hintText: hint, 
           hintStyle: TextStyle(color: Colors.white.withAlpha(76), fontSize: 12), 
           filled: true, 
           fillColor: disabled ? Colors.white.withAlpha(5) : (hasError ? const Color(0xFFef4444).withAlpha(10) : Colors.white.withAlpha(13)), 
           counterText: '', 
           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? const Color(0xFFef4444) : Colors.white.withAlpha(25))), 
           focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? const Color(0xFFef4444) : const Color(0xFF8b5cf6), width: 1.5)), 
           disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(10))), 
           suffixIcon: suffixIcon
        ),
      ),
      if (hasError && errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(errorText, style: const TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.bold)),
        )
    ],
  );
}

Widget buildUldFlightDropdown(AddUldV2Logic logic, String? selectedFlight, ValueChanged<String?> onChanged, {Widget? titleTrailing}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Expanded(child: Text('Reference Flight', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)), titleTrailing ?? const SizedBox.shrink()]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedFlight,
            hint: const Text('Standalone ULD', style: TextStyle(color: Colors.white, fontSize: 12)),
            dropdownColor: const Color(0xFF1e293b), isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: 12), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFcbd5e1), size: 20),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Standalone ULD')),
              ...logic.flights.map((f) => DropdownMenuItem<String?>(value: f['id'].toString(), child: Text('${f['carrier']} ${f['number']} (${f['date-arrived']})')))
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

class AwbTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.length > 11) raw = raw.substring(0, 11);
    String formatted = '';
    for (int i = 0; i < raw.length; i++) {
        if (i == 3) formatted += '-';
        if (i == 7) formatted += ' ';
        formatted += raw[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
