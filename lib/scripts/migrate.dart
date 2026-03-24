import 'dart:io';

void main() {
  final file = File(r'c:\App New\lib\screens\other_modules.dart');
  final lines = file.readAsLinesSync();

  int startIndex = lines.indexWhere((l) => l.startsWith('class SystemModule extends StatefulWidget'));
  int endIndex = lines.indexWhere((l) => l.startsWith('class CoordinatorModule '));
  int locIndex = lines.indexWhere((l) => l.startsWith('class LocationModule '));

  if (startIndex == -1 || endIndex == -1) {
    stdout.writeln('Indices not found');
    exit(1);
  }

  // Get lines of SystemModule
  final systemModuleLines = lines.sublist(startIndex, endIndex);

  // Generate CoordinatorModule code
  String copiedCode = systemModuleLines.join('\n');
  copiedCode = copiedCode.replaceAll('SystemModule', 'CoordinatorModule');
  copiedCode = copiedCode.replaceAll('_SystemModuleState', '_CoordinatorModuleState');

  // Hardcode logic for single panel internally for CoordinatorModule
  copiedCode = copiedCode.replaceAll('widget.singlePanelMode', 'true');
  copiedCode = copiedCode.replaceAll('widget.titleOverride ?? (appLanguage.value == \'es\' ? \'Panel Único\' : \'Single Panel\')', '(appLanguage.value == \'es\' ? \'Coordinador\' : \'Coordinator\')');

  // Generate original SystemModule code removing single panel logic
  String cleanSystemCode = systemModuleLines.join('\n');
  cleanSystemCode = cleanSystemCode.replaceAll('widget.singlePanelMode', 'false');

  final newLines = [
    ...lines.sublist(0, startIndex),
    cleanSystemCode,
    copiedCode,
    ...lines.sublist(locIndex)
  ];

  file.writeAsStringSync(newLines.join('\n'));
  stdout.writeln('Successfully duplicated SystemModule into CoordinatorModule and securely decoupled both modules');
}
