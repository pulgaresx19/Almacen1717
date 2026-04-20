import 'package:flutter/services.dart';

class AwbNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 3) {
        buffer.write('-');
      } else if (i == 7) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class SentenceCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    List<String> lines = newValue.text.split('\n');
    for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) {
            String leftPad = '';
            String rightPad = '';
            String core = lines[i];

            while (core.isNotEmpty && core.startsWith(' ')) {
              leftPad += ' ';
              core = core.substring(1);
            }
            while (core.isNotEmpty && core.endsWith(' ')) {
              rightPad += ' ';
              core = core.substring(0, core.length - 1);
            }

            if (core.isNotEmpty) {
               String first = core[0].toUpperCase();
               String rest = core.substring(1).toLowerCase();
               lines[i] = leftPad + first + rest + rightPad;
            }
        }
    }

    return TextEditingValue(
      text: lines.join('\n'),
      selection: newValue.selection,
    );
  }
}
