const fs = require('fs');
let code = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');

const targetStr = \                  var delivers = List<Map<String, dynamic>>.from(snapshot.data ?? [])
                      .where((d) => d['status']?.toString().toLowerCase() == 'waiting')
                      .toList();\;

const replacement = \                  var delivers = List<Map<String, dynamic>>.from(snapshot.data ?? [])
                      .where((d) {
                        if (d['status']?.toString().toLowerCase() != 'waiting') return false;
                        
                        final currentNoShow = d['no-show'];
                        if (currentNoShow != null && currentNoShow is List) {
                          final currentUserFullName = currentUserData.value?['full-name'] ?? 'Unknown';
                          bool hasNoShowed = currentNoShow.any((ns) => ns is Map && ns['user'] == currentUserFullName);
                          if (hasNoShowed) return false;
                        }
                        return true;
                      })
                      .toList();\;

code = code.replace(targetStr, replacement);
fs.writeFileSync('lib/screens/driver_module.dart', code);
console.log('Successfully filtered NO SHOW rows inside Stream builder!');
