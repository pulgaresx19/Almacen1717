const fs = require('fs');
let code = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');
const startStr = '  void _showDriverConfirmationOverlay(Map<String, dynamic> u) {';
const endStr = '  Widget _confirmDetailRow(IconData icon, String label, String value, bool dark) {';
const startIndex = code.indexOf(startStr);
const endIndex = code.indexOf(endStr);
if (startIndex !== -1 && endIndex !== -1) {
  const original = code.substring(startIndex, endIndex);
  let newCode = code.replace(original, fs.readFileSync('replacement.txt', 'utf8') + '\n');
  fs.writeFileSync('lib/screens/driver_module.dart', newCode);
  console.log('Done!');
} else {
  console.log('Not found');
}
