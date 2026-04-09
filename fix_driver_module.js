const fs = require('fs');
let content = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');

// 1. Modify the `build` method layout wrapper
let search1 = `        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [`;
let replace1 = `        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [`;
content = content.replace(search1, replace1);

let searchCRLF1 = search1.replace(/\n/g, '\r\n');
content = content.replace(searchCRLF1, replace1);


// 2. Add overlays to the end of the `build` method
let search2 = `            ),
          ),
        ),
      ],
    );
     }
    );
  }`;
let replace2 = `            ),
          ),
        ),

        // --- FIRST OVERLAY: Driver details and AWB List ---
        if (_selectedDriver != null && _selectedAwbDetails == null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                  _selectedDriver = null;
                  _selectedAwbDetails = null;
              }),
              child: Container(
                color: Colors.black87, // Solid color as requested
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping inside the panel
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 600,
                      height: MediaQuery.of(context).size.height * 0.85,
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCard)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderCard)),
                            ),
                            child: Row(
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
                            )
                          ),
                          Expanded(
                            child: Padding(
                               padding: const EdgeInsets.all(24),
                               child: _buildDriverActivityPanel(_selectedDriver!, dark, textP, textS, bgCard, borderCard, iconColor)
                            )
                          )
                        ]
                      )
                    )
                  )
                )
              )
            )
          ),

        // --- SECOND OVERLAY: AWB Details ---
        if (_selectedAwbDetails != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _selectedAwbDetails = null),
              child: Container(
                color: Colors.black87, // Solid color
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping inside
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 700,
                      height: MediaQuery.of(context).size.height * 0.85,
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCard)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderCard)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                   children: [
                                     IconButton(
                                       icon: Icon(Icons.arrow_back_rounded, color: textP),
                                       onPressed: () => setState(() => _selectedAwbDetails = null),
                                     ),
                                     const SizedBox(width: 8),
                                     Text('Detalle Operativo', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                                   ]
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: textS),
                                  onPressed: () => setState(() {
                                     _selectedAwbDetails = null;
                                     _selectedDriver = null;
                                  }),
                                )
                              ]
                            )
                          ),
                          Expanded(
                            child: Padding(
                               padding: const EdgeInsets.all(0),
                               child: _buildAwbDetailPanel(_selectedAwbDetails!, dark, textP, textS, bgCard, borderCard)
                            )
                          )
                        ]
                      )
                    )
                  )
                )
              )
            )
          ),
      ],
    ); // Close Stack
     } // Close Builder
    ); // Close ValueListenableBuilder
  }`;
content = content.replace(search2, replace2);
let searchCRLF2 = search2.replace(/\n/g, '\r\n');
content = content.replace(searchCRLF2, replace2);


// 3. Rename `_buildDriverDetailView` to `_buildDriverActivityPanel` AND remove Right column space.
content = content.replace(/Widget _buildDriverDetailView([\s\S]*?)return Row\([\s\S]*?crossAxisAlignment: CrossAxisAlignment\.start,[\s\S]*?children: \[[\s\S]*?\/\/ Left Column: General Information \+ AWBs List[\s\S]*?Expanded\([\s\S]*?flex: 4,[\s\S]*?child: Container\([\s\S]*?padding: const EdgeInsets\.all\(24\),[\s\S]*?decoration: BoxDecoration\(color: bgCard, borderRadius: BorderRadius\.circular\(16\), border: Border\.all\(color: borderCard\)\),[\s\S]*?child: Column\([\s\S]*?crossAxisAlignment: CrossAxisAlignment\.start,[\s\S]*?children: \[/g, 
`Widget _buildDriverActivityPanel$1return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [`);


// Now remove the Right Column ("Espacio Reservado" & "_buildAwbDetailPanel") until the end of the method
// We will search backwards from `_buildAwbDetailPanel(_selectedAwbDetails!, dark, textP, textS, bgCard, borderCard),`
// but safely stopping by being very specific about the Button block!
let pattern4 = /([\s\S]*?),\s*label: Text\('DELIVERY COMPLETED'[\s\S]*?elevation: allDelivered \? 2 : 0,\s*\),\s*\),\s*\),\s*\],\s*\),\s*\),\s*\),\s*const SizedBox\(width: 24\),\s*\/\/ Right Column[\s\S]*?\]\s*,\s*\)\s*:\s*_buildAwbDetailPanel\(_selectedAwbDetails!, dark, textP, textS, bgCard, borderCard\),\s*\),\s*\],\s*\);/;

let match4 = content.match(pattern4);
if (match4) {
  let replace4 = match4[1] + `,
                     label: Text('DELIVERY COMPLETED', 
                       style: TextStyle(
                         fontWeight: FontWeight.bold, 
                         fontSize: 14,
                         color: allDelivered ? Colors.white : (dark ? Colors.white54 : Colors.black38)
                       )
                     ),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       backgroundColor: allDelivered ? const Color(0xFF10b981) : (dark ? Colors.white12 : Colors.black12),
                       elevation: allDelivered ? 2 : 0,
                     ),
                   ),
                 ),
               ],
            );`;
  content = content.replace(pattern4, replace4);
}

fs.writeFileSync('lib/screens/driver_module.dart', content);
