import 'dart:io';

void main() {
  final file = File('lib/screens/driver_module.dart');
  var content = file.readAsStringSync();

  // Replace ULD block 1
  content = content.replaceFirst('''                         _buildCustomChip(
                           Row(
                             children: [
                               Text('ULD:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                               const SizedBox(width: 4),
                               Expanded(
                                 child: Text(
                                   uldNumber,
                                   style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                             ],
                           ),
                           dark,
                           width: 160,
                         ),''', '''                         _buildCustomChip(
                           Center(
                             child: Text(
                               uldNumber,
                               style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           dark,
                           width: 100,
                         ),''');

  // Replace Flight block 1
  content = content.replaceFirst('''                           _buildCustomChip(
                             Row(
                               children: [
                                 Text('Flight:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                                 const SizedBox(width: 4),
                                 Expanded(
                                   child: RichText(
                                     overflow: TextOverflow.ellipsis,
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
                               ],
                             ),
                             dark,
                             width: 170,
                           ),''', '''                           _buildCustomChip(
                             Center(
                               child: RichText(
                                 overflow: TextOverflow.ellipsis,
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
                             width: 130,
                           ),''');

  // Replace ULD block 2
  content = content.replaceFirst('''                                             _buildCustomChip(
                                               Row(
                                                 mainAxisAlignment: MainAxisAlignment.center,
                                                 children: [
                                                   Text('ULD:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                                                   const SizedBox(width: 4),
                                                   Flexible(
                                                     child: Text(
                                                       awbItem['refULD']?.toString().isNotEmpty == true ? awbItem['refULD'].toString() : '-',
                                                       style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                                       overflow: TextOverflow.ellipsis,
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               dark,
                                               width: 160,
                                             ),''', '''                                             _buildCustomChip(
                                               Center(
                                                 child: Text(
                                                   awbItem['refULD']?.toString().isNotEmpty == true ? awbItem['refULD'].toString() : '-',
                                                   style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                                   overflow: TextOverflow.ellipsis,
                                                 ),
                                               ),
                                               dark,
                                               width: 100,
                                             ),''');

  // Replace Flight block 2
  content = content.replaceFirst('''                                               _buildCustomChip(
                                                 Row(
                                                   mainAxisAlignment: MainAxisAlignment.center,
                                                   children: [
                                                     Text('Flight:', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                                                     const SizedBox(width: 4),
                                                     Flexible(
                                                       child: RichText(
                                                         overflow: TextOverflow.ellipsis,
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
                                                   ],
                                                 ),
                                                 dark,
                                                 width: 170,
                                               ),''', '''                                               _buildCustomChip(
                                                 Center(
                                                   child: RichText(
                                                     overflow: TextOverflow.ellipsis,
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
                                                 width: 130,
                                               ),''');

  file.writeAsStringSync(content);
}
