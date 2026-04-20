import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showCoordinatorDataDialog({
  required BuildContext context,
  required bool dark,
  required Color textP,
  required Color textS,
  required int expectedPieces,
  required Map<String, String> coordinatorCounts,
  required VoidCallback onSave,
}) async {
  final ctrls = {
    'AGI Skid': TextEditingController(text: coordinatorCounts['AGI Skid'] ?? ''),
    'Pre Skid': TextEditingController(text: coordinatorCounts['Pre Skid'] ?? ''),
    'Crate': TextEditingController(text: coordinatorCounts['Crate'] ?? ''),
    'Box': TextEditingController(text: coordinatorCounts['Box'] ?? ''),
    'Other': TextEditingController(text: coordinatorCounts['Other'] ?? ''),
  };

  int enteredPieces = 0;
  ctrls.forEach((key, ctrl) {
    if (key == 'AGI Skid') {
      final parts = ctrl.text.split(RegExp(r'[,\s-]+'));
      for (var p in parts) { enteredPieces += int.tryParse(p) ?? 0; }
    } else {
      enteredPieces += int.tryParse(ctrl.text) ?? 0;
    }
  });

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          void updateCount() {
            int sum = 0;
            ctrls.forEach((key, ctrl) {
              if (key == 'AGI Skid') {
                final parts = ctrl.text.split(RegExp(r'[,\s-]+'));
                for (var p in parts) {
                  sum += int.tryParse(p) ?? 0;
                }
              } else {
                sum += int.tryParse(ctrl.text) ?? 0;
              }
            });
            if (sum != enteredPieces) setDialogState(() => enteredPieces = sum);
          }

          int agiLastLen = 0;

          Widget buildField(String label) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: ctrls[label],
                keyboardType: label == 'AGI Skid' ? TextInputType.text : TextInputType.number,
                inputFormatters: [
                  if (label == 'AGI Skid')
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\s+]'))
                  else
                    FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(color: textP),
                onChanged: (val) {
                  if (label == 'AGI Skid') {
                    if (val.endsWith(' ') && val.length > agiLastLen) {
                      final newText = '${val.substring(0, val.length - 1)} + ';
                      ctrls[label]!.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(offset: newText.length),
                      );
                    }
                    agiLastLen = ctrls[label]!.text.length;
                  }
                  updateCount();
                },
                decoration: InputDecoration(
                  labelText: label == 'AGI Skid' ? 'AGI Skid (space separated)' : label,
                  labelStyle: TextStyle(color: textS, fontSize: label == 'AGI Skid' ? 13 : 15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
            title: Column(
              children: [
                Text('Insert Coordinator Data', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text('EXPECTED', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$expectedPieces', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(width: 1, height: 35, color: dark ? Colors.white24 : Colors.grey.shade300),
                    Column(
                      children: [
                        Text('COUNTED', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$enteredPieces', style: TextStyle(color: enteredPieces == expectedPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildField('AGI Skid'),
                    buildField('Pre Skid'),
                    buildField('Crate'),
                    buildField('Box'),
                    buildField('Other'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: textS)),
              ),
              ElevatedButton(
                onPressed: () {
                  coordinatorCounts.clear();
                  ctrls.forEach((k, v) {
                    if (v.text.trim().isNotEmpty) {
                      coordinatorCounts[k] = v.text.trim();
                    } else {
                      coordinatorCounts[k] = '0';
                    }
                  });
                  onSave();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        }
      );
    }
  );
}

Future<void> showCoordinatorDataPreviewDialog(BuildContext context, Map<String, dynamic> awb) async {
  Map<String, String> counts = {};
  if (awb['coordinatorCounts'] != null && awb['coordinatorCounts'] is Map) {
    counts = Map<String, String>.from(awb['coordinatorCounts']);
  }

  Map<String, List<String>> breakdownParts = {};

  int totalChecked = 0;
  counts.forEach((k, v) {
    final parts = v.split(RegExp(r'[,\s\+]+')).where((e) => int.tryParse(e) != null && int.parse(e) > 0).toList();
    if (parts.isNotEmpty) {
      breakdownParts[k] = parts;
      totalChecked += parts.map((e) => int.tryParse(e) ?? 0).fold(0, (x, y) => x + y);
    }
  });

  String getDisplayName(String key, int count) {
    if (count <= 1) return key.toUpperCase();
    if (key == 'Box') return 'BOXES';
    return '${key.toUpperCase()}S';
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withAlpha(10))),
        title: Column(
          children: [
            const Text('Coordinator Data Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('EXPECTED', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${awb['pieces'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 35, color: Colors.white24),
                Column(
                  children: [
                    const Text('COUNTED', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$totalChecked', style: TextStyle(color: totalChecked == (int.tryParse(awb['pieces']?.toString() ?? '0') ?? 0) ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.white.withAlpha(10)), borderRadius: BorderRadius.circular(8)),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: breakdownParts.entries.map((entry) {
                       int groupTotal = entry.value.map((e) => int.tryParse(e) ?? 0).fold(0, (x, y) => x + y);
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withAlpha(10))),
                         child: Row(
                           children: [
                             Container(
                               width: 24, height: 24, alignment: Alignment.center,
                               decoration: BoxDecoration(color: Colors.white.withAlpha(25), shape: BoxShape.circle),
                               child: Text('${entry.value.length}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.bold)),
                             ),
                             const SizedBox(width: 8),
                             Text(getDisplayName(entry.key, entry.value.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                             const Spacer(),
                             Text('$groupTotal pcs', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
                           ]
                         )
                       );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ]
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF94a3b8))),
          ),
        ],
      );
    }
  );
}

Future<void> showItemLocationPreviewDialog(BuildContext context, Map<String, dynamic> a) async {
  Map<String, dynamic> coordCounts = a['coordinatorCounts'] ?? {};
  Map<String, dynamic> itemLocs = a['itemLocations'] ?? {};
  int totalChecked = 0;
  Map<String, List<String>> breakdownParts = {};

  coordCounts.forEach((k, v) {
    final parts = v.toString().split(RegExp(r'[,\s\+]+')).where((e) => int.tryParse(e) != null && int.parse(e) > 0).toList();
    if (parts.isNotEmpty) {
      breakdownParts[k] = parts;
      totalChecked += parts.map((e) => int.tryParse(e) ?? 0).fold(0, (x, y) => x + y);
    }
  });

  String getDisplayName(String key, int count) {
    if (count <= 1) return key.toUpperCase();
    if (key == 'Box') return 'BOXES';
    return '${key.toUpperCase()}S';
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withAlpha(10))),
        title: Column(
          children: [
            const Text('Location Data Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('EXPECTED', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${a['pieces'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 35, color: Colors.white24),
                Column(
                  children: [
                    const Text('COUNTED', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$totalChecked', style: TextStyle(color: totalChecked == (int.tryParse(a['pieces']?.toString() ?? '0') ?? 0) ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.white.withAlpha(10)), borderRadius: BorderRadius.circular(8)),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: breakdownParts.entries.map((entry) {
                       int groupTotal = entry.value.map((e) => int.tryParse(e) ?? 0).fold(0, (x, y) => x + y);
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withAlpha(10))),
                         child: Column(
                           children: [
                             Row(
                               children: [
                                 Container(
                                   width: 24, height: 24, alignment: Alignment.center,
                                   decoration: BoxDecoration(color: Colors.white.withAlpha(25), shape: BoxShape.circle),
                                   child: Text('${entry.value.length}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.bold)),
                                 ),
                                 const SizedBox(width: 8),
                                 Text(getDisplayName(entry.key, entry.value.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                 const Spacer(),
                                 Text('$groupTotal pcs', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
                               ]
                             ),
                             const SizedBox(height: 12),
                             ...entry.value.asMap().entries.map((item) {
                                int idx = item.key;
                                String pc = item.value;
                                String locKey = '${entry.key}__$idx';
                                String locVal = itemLocs[locKey]?.toString() ?? '-';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 24, child: Text('#${idx+1}', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13, fontWeight: FontWeight.bold))),
                                      const SizedBox(width: 8),
                                      SizedBox(width: 45, child: Text(pc, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            locVal,
                                            style: TextStyle(color: locVal == '-' ? Colors.white30 : const Color(0xFF60a5fa), fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                             })
                           ],
                         )
                       );
                     }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ]
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF94a3b8))),
          ),
        ],
      );
    }
  );
}

Future<void> showItemLocationEntryDialog({
  required BuildContext context,
  required int expectedPieces,
  required Map<String, String> coordinatorCounts,
  required Map<String, String> itemLocations,
  required VoidCallback onSave,
}) async {
  Map<String, TextEditingController> ctrls = {};
  int totalChecked = 0;
  Map<String, List<String>> breakdownParts = {};

  coordinatorCounts.forEach((k, v) {
    final parts = v.split(RegExp(r'[,\s\+]+')).where((e) => int.tryParse(e) != null && int.parse(e) > 0).toList();
    if (parts.isNotEmpty) {
      breakdownParts[k] = parts;
      totalChecked += parts.map((e) => int.tryParse(e) ?? 0).fold(0, (a, b) => a + b);

      for (int i = 0; i < parts.length; i++) {
        String key = '${k}__$i';
        ctrls[key] = TextEditingController(text: itemLocations[key] ?? '');
      }
    }
  });

  String getDisplayName(String key, int count) {
    if (count <= 1) return key.toUpperCase();
    if (key == 'Box') return 'BOXES';
    return '${key.toUpperCase()}S';
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withAlpha(10))),
        title: Column(
          children: [
            const Text('Insert Location Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('EXPECTED', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$expectedPieces', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 35, color: Colors.white24),
                Column(
                  children: [
                    const Text('COUNTED', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$totalChecked', style: TextStyle(color: totalChecked == expectedPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.white.withAlpha(10)), borderRadius: BorderRadius.circular(8)),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: breakdownParts.entries.map((entry) {
                       int groupTotal = entry.value.map((e) => int.tryParse(e) ?? 0).fold(0, (a, b) => a + b);
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withAlpha(10))),
                         child: Column(
                           children: [
                             Row(
                               children: [
                                 Container(
                                   width: 24, height: 24, alignment: Alignment.center,
                                   decoration: BoxDecoration(color: Colors.white.withAlpha(25), shape: BoxShape.circle),
                                   child: Text('${entry.value.length}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.bold)),
                                 ),
                                 const SizedBox(width: 8),
                                 Text(getDisplayName(entry.key, entry.value.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                 const Spacer(),
                                 Text('$groupTotal pcs', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
                               ]
                             ),
                             const SizedBox(height: 12),
                             ...entry.value.asMap().entries.map((item) {
                                int idx = item.key;
                                String pc = item.value;
                                String locKey = '${entry.key}__$idx';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 24, child: Text('#${idx+1}', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13, fontWeight: FontWeight.bold))),
                                      const SizedBox(width: 8),
                                      SizedBox(width: 45, child: Text(pc, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: ctrls[locKey],
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                          textCapitalization: TextCapitalization.characters,
                                          inputFormatters: [
                                            TextInputFormatter.withFunction((oldValue, newValue) {
                                              return newValue.copyWith(text: newValue.text.toUpperCase());
                                            }),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: 'Location...',
                                            hintStyle: TextStyle(color: Colors.white.withAlpha(50), fontSize: 12),
                                            filled: true,
                                            fillColor: Colors.white.withAlpha(5),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            isDense: true,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                             })
                           ],
                         )
                       );
                     }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ]
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8))),
          ),
          ElevatedButton(
            onPressed: () {
              itemLocations.clear();
              ctrls.forEach((k, v) {
                if (v.text.trim().isNotEmpty) {
                  itemLocations[k] = v.text.trim();
                }
              });
              onSave();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      );
    }
  );
}
