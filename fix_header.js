const fs = require('fs');

let content = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');

// 1. Remove the old header Text and replace with the Profile Row
const headerSearch = `                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Actividad del Conductor', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: textS),
                                  onPressed: () => setState(() {
                                    _selectedDriver = null;
                                    _selectedAwbDetails = null;
                                  }),
                                )
                              ]
                            )`;

const headerReplace = `                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 28, backgroundColor: dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB), child: Icon(Icons.person_rounded, size: 32, color: textS)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedDriver!['truck-company']?.toString().isNotEmpty == true ? _selectedDriver!['truck-company'].toString() : 'Unknown Company', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                                      Text(_selectedDriver!['driver']?.toString() ?? 'Unknown Driver', style: TextStyle(color: textS, fontSize: 16)),
                                    ],
                                  ),
                                ),
                                Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                   decoration: BoxDecoration(color: dark ? Colors.amberAccent.withAlpha(20) : Colors.amber.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.amberAccent.withAlpha(50) : Colors.amber.shade300)),
                                   child: Column(
                                     children: [
                                       Text('DOOR', style: TextStyle(color: dark ? Colors.amberAccent : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                       Text(_selectedDriver!['door']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 28, fontWeight: FontWeight.bold)),
                                     ],
                                   ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: textS),
                                  onPressed: () => setState(() {
                                    _selectedDriver = null;
                                    _selectedAwbDetails = null;
                                  }),
                                )
                              ]
                            )`;

let contentCRLF = content.replace(/\r\n/g, '\n');
if (contentCRLF.includes(headerSearch)) {
  content = contentCRLF.replace(headerSearch, headerReplace);
}

// 2. Remove the Row from _buildDriverActivityPanel
const profileSearchStart = `                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB), child: Icon(Icons.person_rounded, size: 32, color: textS)),`;
const profileSearchEnd = `                   ],
                ),
                const SizedBox(height: 32),`;

let pStart = content.indexOf(profileSearchStart);
let pEndStr = `                   ],\n                ),\n                const SizedBox(height: 32),\n`;
let pEnd = content.indexOf(pEndStr, pStart);

if (pStart !== -1 && pEnd !== -1) {
  content = content.substring(0, pStart) + content.substring(pEnd + pEndStr.length);
}

fs.writeFileSync('lib/screens/driver_module.dart', content);
