import 'dart:io';

void main() {
  final file = File(r'c:\App New\lib\screens\other_modules.dart');
  final lines = file.readAsLinesSync();

  int startIndex = lines.indexWhere((l) => l.startsWith('class CoordinatorModule extends StatefulWidget'));
  int endIndex = lines.indexWhere((l) => l.startsWith('class LocationModule '));
  int customPaintIndex = lines.indexWhere((l) => l.startsWith('class _SharedResizePainter '));

  if (startIndex == -1 || endIndex == -1 || customPaintIndex == -1) {
    stdout.writeln('Indices not found: start=$startIndex, end=$endIndex, paint=$customPaintIndex');
    exit(1);
  }

  // Get lines of CoordinatorModule
  final coordinatorLines = lines.sublist(startIndex, endIndex);

  // Generate LocationModule code
  String copiedCode = coordinatorLines.join('\n');
  copiedCode = copiedCode.replaceAll('CoordinatorModule', 'LocationModule');
  copiedCode = copiedCode.replaceAll('_CoordinatorModuleState', '_LocationModuleState');
  copiedCode = copiedCode.replaceAll("'Coordinador' : 'Coordinator'", "'Locación' : 'Location'");
  copiedCode = copiedCode.replaceAll("'Módulo para verificación y check-in de vuelos y AWBs' : 'Module for verification and check-in of flights and AWBs'", "'Módulo para asignar los artículos (AWB) en locación' : 'Module to assign items (AWBs) to location'");

  final newLines = [
    ...lines.sublist(0, endIndex),
    copiedCode,
    ...lines.sublist(customPaintIndex)
  ];

  file.writeAsStringSync(newLines.join('\n'));
  stdout.writeln('Successfully duplicated CoordinatorModule into LocationModule');
}
