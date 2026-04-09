import 'dart:io';

void main() {
  final file = File('lib/screens/driver_module.dart');
  var content = file.readAsStringSync();

  // ULD Box 1 Width
  content = content.replaceFirst('''                               style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           dark,
                           width: 100,''', '''                               style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           dark,
                           width: 120,''');

  // ULD Box 2 Width
  content = content.replaceFirst('''                                                   style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                                   overflow: TextOverflow.ellipsis,
                                                 ),
                                               ),
                                               dark,
                                               width: 100,''', '''                                                   style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                                   overflow: TextOverflow.ellipsis,
                                                 ),
                                               ),
                                               dark,
                                               width: 120,''');

  // Padding
  content = content.replaceFirst('''                                             if (statusText == 'PENDING')
                                               Padding(
                                                 padding: const EdgeInsets.only(left: 12.0),
                                                 child: IconButton(''', '''                                             if (statusText == 'PENDING')
                                               Padding(
                                                 padding: const EdgeInsets.only(left: 4.0),
                                                 child: IconButton(''');

  file.writeAsStringSync(content);
}
