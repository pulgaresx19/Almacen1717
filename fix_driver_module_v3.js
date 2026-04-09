const fs = require('fs');

function refactorDriverModule() {
  const filePath = 'lib/screens/driver_module.dart';
  let content = fs.readFileSync(filePath, 'utf8');
  console.log('Original length:', content.length);

  // 1. Wrap main Column in Stack
  const search1 = `        return Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [`;
  const search1CRLF = search1.replace(/\n/g, '\r\n');
  const replace1 = `        return Stack(\n          children: [\n            Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [`;
  
  if (content.includes(search1)) content = content.replace(search1, replace1);
  else if (content.includes(search1CRLF)) content = content.replace(search1CRLF, replace1);
  else throw new Error("search1 not found");
  console.log('Step 1 applied. Length:', content.length);

  // 2. Add overlays to the end of the `build` method
  const search2a = `            ),\n          ),\n        ),\n      ],\n    );\n     }\n    );\n  }`;
  const search2aCRLF = search2a.replace(/\n/g, '\r\n');
  const search2b = `            ),\n          ),\n        ),\n      ],\n    );\n  }`;
  const search2bCRLF = search2b.replace(/\n/g, '\r\n');

  const replace2 = `            ),\n          ),\n        ),\n\n        // --- FIRST OVERLAY: Driver details and AWB List ---\n        if (_selectedDriver != null && _selectedAwbDetails == null)\n          Positioned.fill(\n            child: GestureDetector(\n              onTap: () => setState(() {\n                  _selectedDriver = null;\n                  _selectedAwbDetails = null;\n              }),\n              child: Container(\n                color: const Color(0xFF0f172a).withOpacity(0.9), // Solid, opaque background\n                alignment: Alignment.center,\n                child: GestureDetector(\n                  onTap: () {}, // Prevent closing when tapping inside the panel\n                  child: Material(\n                    color: Colors.transparent,\n                    child: Container(\n                      width: 600,\n                      height: MediaQuery.of(context).size.height * 0.85,\n                      padding: const EdgeInsets.all(0),\n                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCard)),\n                      child: Column(\n                        children: [\n                          Container(\n                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),\n                            decoration: BoxDecoration(\n                              border: Border(bottom: BorderSide(color: borderCard)),\n                            ),\n                            child: Row(\n                              mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                              children: [\n                                Text('Actividad del Conductor', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),\n                                IconButton(\n                                  icon: Icon(Icons.close_rounded, color: textS),\n                                  onPressed: () => setState(() {\n                                    _selectedDriver = null;\n                                    _selectedAwbDetails = null;\n                                  }),\n                                )\n                              ]\n                            )\n                          ),\n                          Expanded(\n                            child: Padding(\n                               padding: const EdgeInsets.all(24),\n                               child: _buildDriverActivityPanel(_selectedDriver!, dark, textP, textS, bgCard, borderCard, iconColor)\n                            )\n                          )\n                        ]\n                      )\n                    )\n                  )\n                )\n              )\n            )\n          ),\n\n        // --- SECOND OVERLAY: AWB Details ---\n        if (_selectedAwbDetails != null)\n          Positioned.fill(\n            child: GestureDetector(\n              onTap: () => setState(() => _selectedAwbDetails = null),\n              child: Container(\n                color: const Color(0xFF0f172a).withOpacity(0.9), // Solid colored background\n                alignment: Alignment.center,\n                child: GestureDetector(\n                  onTap: () {}, // Prevent closing when tapping inside\n                  child: Material(\n                    color: Colors.transparent,\n                    child: Container(\n                      width: 700,\n                      height: MediaQuery.of(context).size.height * 0.85,\n                      padding: const EdgeInsets.all(0),\n                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCard)),\n                      child: Column(\n                        children: [\n                          Container(\n                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),\n                            decoration: BoxDecoration(\n                              border: Border(bottom: BorderSide(color: borderCard)),\n                            ),\n                            child: Row(\n                              mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                              children: [\n                                Row(\n                                   children: [\n                                     IconButton(\n                                       icon: Icon(Icons.arrow_back_rounded, color: textP),\n                                       onPressed: () => setState(() => _selectedAwbDetails = null),\n                                     ),\n                                     const EdgeInsets.only(left: 8),\n                                     Text('Detalle Operativo', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),\n                                   ]\n                                ),\n                                IconButton(\n                                  icon: Icon(Icons.close_rounded, color: textS),\n                                  onPressed: () => setState(() {\n                                     _selectedAwbDetails = null;\n                                  }),\n                                )\n                              ]\n                            )\n                          ),\n                          Expanded(\n                            child: Padding(\n                               padding: const EdgeInsets.all(0),\n                               child: _buildAwbDetailPanel(_selectedAwbDetails!, dark, textP, textS, bgCard, borderCard)\n                            )\n                          )\n                        ]\n                      )\n                    )\n                  )\n                )\n              )\n            )\n          ),\n      ],\n    ); // Close Stack\n     } // Close Builder\n    ); // Close ValueListenableBuilder\n  }`;

  if (content.includes(search2a)) content = content.replace(search2a, replace2);
  else if (content.includes(search2aCRLF)) content = content.replace(search2aCRLF, replace2);
  else if (content.includes(search2b)) content = content.replace(search2b, replace2);
  else if (content.includes(search2bCRLF)) content = content.replace(search2bCRLF, replace2);
  else throw new Error("search2 not found");
  console.log('Step 2 applied. Length:', content.length);

  
  // 3. Rename `_buildDriverDetailView` to `_buildDriverActivityPanel` AND remove `Row` layout and right column
  // Find start of _buildDriverDetailView
  let methodStartIdx = content.indexOf('Widget _buildDriverDetailView(');
  if (methodStartIdx === -1) throw new Error("Could not find _buildDriverDetailView");
  
  // Find the exact line "return Row("
  let returnRowIdx = content.indexOf('return Row(', methodStartIdx);
  let afterLeftColumnWrapperIdx = content.indexOf('child: Column(', returnRowIdx);
  if (afterLeftColumnWrapperIdx === -1) throw new Error("Could not find child: Column(");
  // find the "children: [" right after
  let childrenListIdx = content.indexOf('children: [', afterLeftColumnWrapperIdx);
  
  // Find the end of Left column (ElevatedButton)
  let elevatedButtonEndStr = 'elevation: allDelivered ? 2 : 0,\n                     ),\n                   ),\n                 ),\n               ],\n            ),\n          ),\n        ),';
  let elevatedButtonEndStrCRLF = elevatedButtonEndStr.replace(/\n/g, '\r\n');
  
  let endLeftColIdx = content.indexOf(elevatedButtonEndStr, childrenListIdx);
  let endLen = elevatedButtonEndStr.length;
  if (endLeftColIdx === -1) {
     endLeftColIdx = content.indexOf(elevatedButtonEndStrCRLF, childrenListIdx);
     endLen = elevatedButtonEndStrCRLF.length;
  }
  if (endLeftColIdx === -1) throw new Error("Could not find end of left column");
  
  // Find the end of the method body (the "Espacio Reservado" chunk end)
  let methodEndStr = '_buildAwbDetailPanel(_selectedAwbDetails!, dark, textP, textS, bgCard, borderCard),\n        ),\n      ],\n    );\n  }';
  let methodEndStrCRLF = methodEndStr.replace(/\n/g, '\r\n');
  let methodEndIdx = content.indexOf(methodEndStr, endLeftColIdx);
  let methodEndLen = methodEndStr.length;
  if (methodEndIdx === -1) {
     methodEndIdx = content.indexOf(methodEndStrCRLF, endLeftColIdx);
     methodEndLen = methodEndStrCRLF.length;
  }
  if (methodEndIdx === -1) throw new Error("Could not find end of method _buildDriverDetailView logic");

  let newMethodHeader = content.substring(methodStartIdx, returnRowIdx).replace('_buildDriverDetailView', '_buildDriverActivityPanel');
  
  let newMethodBodyStart = `    return Column(\n      crossAxisAlignment: CrossAxisAlignment.start,\n      `;
  
  // Slice everything from children: [ to end of Elevated button block
  let methodInnerContent = content.substring(childrenListIdx, endLeftColIdx);
  
  // Clean up the ElevatedButton end block to just close the Column gracefully
  let newMethodBodyEnd = `elevation: allDelivered ? 2 : 0,
                     ),
                   ),
                 ),
               ],
            );
  }`;

  let newCompleteMethod = newMethodHeader + newMethodBodyStart + methodInnerContent + `elevation: allDelivered ? 2 : 0,\n                     ),\n                   ),\n                 ),\n               ],\n            );\n  }`;

  // Let's replace the whole old method block with the new one
  content = content.substring(0, methodStartIdx) + newCompleteMethod + content.substring(methodEndIdx + methodEndLen);
  console.log('Step 3 applied. Length:', content.length);

  // Note: we should replace all remaining instances of `_buildDriverDetailView(` if any
  content = content.replace(/_buildDriverDetailView\(/g, '_buildDriverActivityPanel(');

  fs.writeFileSync(filePath, content);
  console.log('Fix applied successfully!');
}

try {
  refactorDriverModule();
} catch (e) {
  console.error("ERROR:", e.message);
  process.exit(1);
}
