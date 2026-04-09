import 'dart:io';

void main() {
  final file = File('lib/screens/driver_module.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(
    '''    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,''',
    '''    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,'''
  );

  // We also need to remove the closing brackets of the Container if it exists.
  // Wait, I can just leave standard replacement if I can match the end.
  // Let me just replace the prefix.
  
  file.writeAsStringSync(content);
}
