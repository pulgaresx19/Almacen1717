import 'dart:io';

void main() {
  final file = File('lib/screens/driver_module.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll('''                               overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                                 text: TextSpan(
                                   children: [
                                     TextSpan(text: flightStr, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                     if (dateStr.isNotEmpty)
                                       TextSpan(text: ' / \$dateStr', style: TextStyle(color: textS.withAlpha(150), fontSize: 12, fontWeight: FontWeight.normal)),
                                   ],
                                 ),
                               ),
                             ),
                             dark,
                             width: 130,''', '''                               overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                                 text: TextSpan(
                                   children: [
                                     TextSpan(text: flightStr, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                     if (dateStr.isNotEmpty)
                                       TextSpan(text: ' / \$dateStr', style: TextStyle(color: textS.withAlpha(150), fontSize: 12, fontWeight: FontWeight.normal)),
                                   ],
                                 ),
                               ),
                             ),
                             dark,
                             width: 140,''');

  file.writeAsStringSync(content);
}
