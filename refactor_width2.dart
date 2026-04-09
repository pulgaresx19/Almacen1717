import 'dart:io';

void main() {
  final file = File('lib/screens/driver_module.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll('''                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           dark,
                           width: 120,''', '''                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           dark,
                           width: 140,''');

  file.writeAsStringSync(content);
}
