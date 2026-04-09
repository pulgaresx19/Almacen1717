const fs = require('fs');
let code = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');
const search = "var delivers = List<Map<String, dynamic>>.from(snapshot.data ?? [])\r\n                      .where((d) => d['status']?.toString().toLowerCase() == 'waiting')\r\n                      .toList();";
const search2 = "var delivers = List<Map<String, dynamic>>.from(snapshot.data ?? [])\n                      .where((d) => d['status']?.toString().toLowerCase() == 'waiting')\n                      .toList();";
const repl = "var delivers = List<Map<String, dynamic>>.from(snapshot.data ?? [])\n                      .where((d) {\n                        if (d['status']?.toString().toLowerCase() != 'waiting') return false;\n                        final currentNoShow = d['no-show'];\n                        if (currentNoShow != null && currentNoShow is List) {\n                          final currentUserFullName = currentUserData.value?.['full-name'] ?? 'Unknown';\n                          bool hasNoShowed = currentNoShow.any((ns) => ns is Map && ns['user'] == currentUserFullName);\n                          if (hasNoShowed) return false;\n                        }\n                        return true;\n                      })\n                      .toList();";

if (code.includes(search)) {
    code = code.replace(search, repl);
    fs.writeFileSync('lib/screens/driver_module.dart', code);
    console.log('Replaced using CRLF');
} else if (code.includes(search2)) {
    code = code.replace(search2, repl);
    fs.writeFileSync('lib/screens/driver_module.dart', code);
    console.log('Replaced using LF');
} else {
    console.log('Not found');
}
