const fs = require('fs');
let code = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');
const searchStr = '  late Stream<List<Map<String, dynamic>>> _deliversStream;';
code = code.replace(searchStr, searchStr + '\n\n' + fs.readFileSync('replacement.txt', 'utf8'));
fs.writeFileSync('lib/screens/driver_module.dart', code);
console.log('Class variables restored');
