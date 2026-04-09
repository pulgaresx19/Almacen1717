const fs = require('fs');
let code = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');
code = code.replace("currentUserData.value?.['full-name']", "currentUserData.value?['full-name']");
fs.writeFileSync('lib/screens/driver_module.dart', code);
