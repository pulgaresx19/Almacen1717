import 'dart:io';

void main() {
  final file = File('lib/screens/driver_module.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(RegExp(r'spacing:\s*16,\s*\n\s*runSpacing:\s*8,'), 'spacing: 4, runSpacing: 4,');

  file.writeAsStringSync(content);
}
