import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget buildAwbTextField(
  String label,
  TextEditingController ctrl,
  String hint, {
  bool isNum = false,
  required bool dark,
  required Color textP,
  int? maxLen,
  List<TextInputFormatter>? inputFormatters,
  TextCapitalization textCapitalization = TextCapitalization.none,
  bool readOnly = false,
  int? maxLines = 1,
  int? minLines = 1,
  Widget? titleTrailing,
  ValueChanged<String>? onChanged,
}) {
  Widget field = TextField(
    controller: ctrl,
    keyboardType: maxLines == null || maxLines > 1 ? TextInputType.multiline : (isNum ? TextInputType.number : TextInputType.text),
    textCapitalization: textCapitalization,
    maxLength: maxLen,
    readOnly: readOnly,
    maxLines: maxLines,
    minLines: minLines,
    inputFormatters: inputFormatters,
    style: TextStyle(
      color: readOnly ? (dark ? const Color(0xFFcbd5e1) : const Color(0xFF6B7280)) : textP,
      fontSize: 13,
    ),
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: textP.withAlpha(76),
        fontSize: 13,
      ),
      filled: true,
      fillColor: readOnly ? (dark ? const Color(0xFF0f172a).withAlpha(150) : const Color(0xFFF3F4F6)) : (dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF6366f1),
          width: 1.5,
        ),
      ),
    ),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (titleTrailing != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            titleTrailing,
          ],
        )
      else
        Text(
          label,
          style: TextStyle(
            color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      const SizedBox(height: 8),
      field,
    ],
  );
}

Widget buildFlightDropdownWidget(
  bool dark, 
  Color textP, 
  Color borderC, 
  {
     Widget? titleTrailing,
     required String? selectedFlight,
     required List<dynamic> flights,
     required ValueChanged<String?> onChanged,
  }
) {
  String formatFlightDate(String? d) {
     if (d == null || d.trim().isEmpty) return '';
     final parts = d.split('-');
     if (parts.length >= 3) return '${parts[1]}/${parts[2]}';
     return d;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (titleTrailing != null)
         Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text(
                 'Reference Flight',
                 style: TextStyle(
                   color: Color(0xFFcbd5e1),
                   fontSize: 13,
                   fontWeight: FontWeight.w500,
                 ),
               ),
               titleTrailing,
            ],
         )
      else
         const Text(
           'Reference Flight',
           style: TextStyle(
             color: Color(0xFFcbd5e1),
             fontSize: 13,
             fontWeight: FontWeight.w500,
           ),
         ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 48,
        decoration: BoxDecoration(
          color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderC),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedFlight,
            hint: Text(
              'No Flight (Standalone)',
              style: TextStyle(color: textP.withAlpha(150)),
            ),
            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: textP, fontSize: 13),
            menuMaxHeight: 300,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No Flight (Standalone)'),
              ),
              ...flights.map(
                (f) => DropdownMenuItem<String?>(
                  value: f['id'].toString(),
                  child: Text(
                    '${f['carrier']} ${f['number']} (${formatFlightDate(f['date-arrived']?.toString())})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}
