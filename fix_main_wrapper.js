const fs = require('fs');

let content = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');

// Replace the toggled header
let search1 = /if \(_selectedDriver != null\) \.\.\.\[[\s\S]*?\] else \.\.\.\[\s*Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[\s*Text\([\s\S]*?appLanguage\.value == 'es' \? 'Coordinador de Chofer' : 'Driver Coordinator'[\s\S]*?\),[\s\S]*?const SizedBox\(height: 4\),[\s\S]*?Text\([\s\S]*?appLanguage\.value == 'es'[\s\S]*?\? 'Módulo de asignación para la entrega de mercancías\.'[\s\S]*?: 'Module for assigning the delivery of goods\.',[\s\S]*?style: TextStyle\(color: textS, fontSize: 13\),[\s\S]*?\),[\s\S]*?\],\s*\),\s*\],/g;

let replace1 = `                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLanguage.value == 'es' ? 'Coordinador de Chofer' : 'Driver Coordinator',
                        style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appLanguage.value == 'es'
                            ? 'Módulo de asignación para la entrega de mercancías.'
                            : 'Module for assigning the delivery of goods.',
                        style: TextStyle(color: textS, fontSize: 13),
                      ),
                    ],
                  ),`;

content = content.replace(search1, replace1);

// Replace the conditional stream builder for the table
let search2 = /if \(_selectedDriver != null\)\s*Expanded\(\s*child: StreamBuilder<List<Map<String, dynamic>>>\([\s\S]*?return _buildDriverActivityPanel\(updatedDriver, dark, textP, textS, bgCard, borderCard, iconColor\);\s*}\s*\)\s*\)\s*else\s*Expanded\(\s*child: Container\(/g;

let replace2 = `          Expanded(
            child: Container(`;

content = content.replace(search2, replace2);


fs.writeFileSync('lib/screens/driver_module.dart', content);
