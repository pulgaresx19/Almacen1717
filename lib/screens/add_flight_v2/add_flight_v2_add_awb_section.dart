import 'package:flutter/material.dart';
import 'add_flight_v2_widgets.dart';
import 'add_flight_v2_logic.dart';

class AddFlightV2AddAwbSection extends StatefulWidget {
  final bool dark;
  final ValueNotifier<String> appLanguage;
  final Color textP;
  final Color textS;
  final Color borderC;
  final void Function(List<Map<String, dynamic>>) onAwbsChanged;
  final AddFlightV2Logic logic;
  final bool listRequiredError;
  final List<Map<String, dynamic>>? initialAwbs;
  final bool isReadOnly;

  const AddFlightV2AddAwbSection({
    super.key,
    required this.dark,
    required this.appLanguage,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.onAwbsChanged,
    required this.logic,
    this.listRequiredError = false,
    this.initialAwbs,
    this.isReadOnly = false,
  });

  @override
  State<AddFlightV2AddAwbSection> createState() => _AddFlightV2AddAwbSectionState();
}

class _AddFlightV2AddAwbSectionState extends State<AddFlightV2AddAwbSection> {
  // AWB Controllers
  final awbNumCtrl = TextEditingController();
  final awbPiecesCtrl = TextEditingController();
  final awbTotalCtrl = TextEditingController();
  final awbWeightCtrl = TextEditingController();
  final awbRemarkCtrl = TextEditingController();
  final awbHouseCtrl = TextEditingController();

  final totalLocked = ValueNotifier<bool>(false);
  final dbExpected = ValueNotifier<int>(0);

  String? piecesError;
  String? awbExistsError;

  bool awbRequiredError = false;
  bool piecesRequiredError = false;
  bool totalRequiredError = false;

  late final List<Map<String, dynamic>> addedAwbs;

  @override
  void initState() {
    super.initState();
    addedAwbs = widget.initialAwbs != null ? List<Map<String, dynamic>>.from(widget.initialAwbs!) : [];
    awbNumCtrl.addListener(_onAwbNumChanged);
    awbPiecesCtrl.addListener(_validatePieces);
    awbTotalCtrl.addListener(_validatePieces);
    totalLocked.addListener(_validatePieces);
    dbExpected.addListener(_validatePieces);
  }

  @override
  void dispose() {
    awbNumCtrl.removeListener(_onAwbNumChanged);
    awbPiecesCtrl.removeListener(_validatePieces);
    awbTotalCtrl.removeListener(_validatePieces);
    totalLocked.removeListener(_validatePieces);
    dbExpected.removeListener(_validatePieces);
    
    awbNumCtrl.dispose();
    awbPiecesCtrl.dispose();
    awbTotalCtrl.dispose();
    awbWeightCtrl.dispose();
    awbHouseCtrl.dispose();
    awbRemarkCtrl.dispose();
    totalLocked.dispose();
    dbExpected.dispose();
    super.dispose();
  }

  int _getLocalUsedPiecesInCurrentUld(String awbNumber) {
    int total = 0;
    for (var awb in addedAwbs) {
      if (awb['awb'] == awbNumber) {
        total += int.tryParse(awb['pieces'].toString()) ?? 0;
      }
    }
    return total;
  }

  void _validatePieces() {
    if (!mounted) return;
    setState(() {
      if (piecesRequiredError && awbPiecesCtrl.text.isNotEmpty && awbPiecesCtrl.text != '0') {
        piecesRequiredError = false;
      }
      if (totalRequiredError && awbTotalCtrl.text.isNotEmpty && awbTotalCtrl.text != '0') {
        totalRequiredError = false;
      }

      final text = awbNumCtrl.text.toUpperCase();
      if (text.length < 13) {
        piecesError = null;
        return;
      }

      final p = int.tryParse(awbPiecesCtrl.text) ?? 0;
      final t = int.tryParse(awbTotalCtrl.text) ?? 0;
      
      if (t == 0) {
        piecesError = null;
        return;
      }

      final dbExp = dbExpected.value;
      final localUsedOtherUlds = widget.logic.getLocalUsedPieces(text);
      final localUsedThisUld = _getLocalUsedPiecesInCurrentUld(text);
      final totalAllowed = t - dbExp - localUsedOtherUlds - localUsedThisUld;

      if (p > totalAllowed) {
        if (totalAllowed <= 0) {
          piecesError = widget.appLanguage.value == 'es' ? 'AWB Completado' : 'AWB Completed';
        } else {
          piecesError = 'Máx: $totalAllowed';
        }
      } else {
        piecesError = null;
      }
    });
  }

  Future<void> _onAwbNumChanged() async {
    final text = awbNumCtrl.text.toUpperCase();
    
    if (awbRequiredError && text.length == 13 && mounted) {
      setState(() => awbRequiredError = false);
    }
    
    // Validate duplicate in current ULD
    final exists = addedAwbs.any((a) => a['awb'] == text);
    
    if (exists && text.isNotEmpty) {
      if (mounted && awbExistsError == null) {
        setState(() {
          awbExistsError = widget.appLanguage.value == 'es' ? 'Duplicado' : 'Duplicate';
        });
      }
    } else {
      if (mounted && awbExistsError != null) {
        setState(() {
          awbExistsError = null;
        });
      }
    }

    if (text.length == 13) {
      bool foundLocally = false;
      String foundTotal = '';
      for (var u in widget.logic.flightLocalUlds) {
        for (var a in (u['awbs'] as List)) {
          if (a['awb_number'] == text) {
            foundLocally = true;
            foundTotal = a['total'].toString();
            break;
          }
        }
        if (foundLocally) break;
      }

      await widget.logic.fetchAwbTotalAsync(text, totalLocked, awbTotalCtrl, dbExpected);

      if (foundLocally && mounted) {
        totalLocked.value = true;
        if (awbTotalCtrl.text != foundTotal) {
          awbTotalCtrl.text = foundTotal;
        }
      }
      _validatePieces();
    } else {
      if (totalLocked.value && mounted) {
        totalLocked.value = false;
        awbTotalCtrl.clear();
        dbExpected.value = 0;
        setState(() {
          piecesError = null;
        });
      }
    }
  }

  void _addAwb() {
    final text = awbNumCtrl.text.trim();
    final piecesStr = awbPiecesCtrl.text.trim();
    final totalStr = awbTotalCtrl.text.trim();

    bool hasValidation = false;
    setState(() {
      awbRequiredError = text.length < 13;
      piecesRequiredError = piecesStr.isEmpty || piecesStr == '0';
      totalRequiredError = totalStr.isEmpty || totalStr == '0';

      hasValidation = awbRequiredError || piecesRequiredError || totalRequiredError;
      
      if (text.isNotEmpty && text.length < 13) {
        awbExistsError = widget.appLanguage.value == 'es' ? 'Incompleto' : 'Incomplete';
      }
    });

    if (hasValidation) return;
    if (piecesError != null || awbExistsError != null) return;
    setState(() {
      addedAwbs.add({
        'awb': awbNumCtrl.text.trim(),
        'pieces': awbPiecesCtrl.text.trim().isEmpty ? '0' : awbPiecesCtrl.text.trim(),
        'total': awbTotalCtrl.text.trim().isEmpty ? '0' : awbTotalCtrl.text.trim(),
        'weight': awbWeightCtrl.text.trim().isEmpty ? '0' : awbWeightCtrl.text.trim(),
        'house': awbHouseCtrl.text.trim(),
        'remark': awbRemarkCtrl.text.trim(),
        'isExpanded': false,
      });
      awbNumCtrl.clear();
      awbPiecesCtrl.clear();
      awbTotalCtrl.clear();
      awbWeightCtrl.clear();
      awbHouseCtrl.clear();
      awbRemarkCtrl.clear();
    });
    widget.onAwbsChanged(addedAwbs);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Middle: List
        Expanded(
          child: Container(
            color: widget.dark ? const Color(0xFF0f172a) : Colors.white,
            child: addedAwbs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 48, color: widget.listRequiredError ? Colors.redAccent : widget.textS.withAlpha(100)),
                        const SizedBox(height: 16),
                        Text(
                          widget.appLanguage.value == 'es' ? 'Lista de AWBs se mostrará aquí' : 'AWB List will be shown here',
                          style: TextStyle(color: widget.listRequiredError ? Colors.redAccent : widget.textS, fontSize: 14, fontWeight: widget.listRequiredError ? FontWeight.bold : FontWeight.normal),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20),
                          itemCount: addedAwbs.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final awb = addedAwbs[i];
                            final isExpanded = awb['isExpanded'] as bool? ?? false;
                            return GestureDetector(
                              onTap: () {
                                if (awb['house'].toString().isNotEmpty || awb['remark'].toString().isNotEmpty) {
                                  setState(() {
                                    awb['isExpanded'] = !isExpanded;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: widget.dark ? Colors.white.withAlpha(8) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Index circle
                                        Container(
                                          width: 28, height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(color: const Color(0xFF3b82f6).withAlpha(30), shape: BoxShape.circle),
                                          child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF60a5fa), fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 16),
                                        // AWB number
                                        Expanded(
                                          flex: 3,
                                          child: Text(awb['awb'], style: TextStyle(color: widget.textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ),
                                        // Pieces
                                        Expanded(
                                          flex: 2,
                                          child: Text('${awb['pieces']}/${awb['total']} pcs', style: TextStyle(color: widget.textS, fontSize: 13)),
                                        ),
                                        // Weight
                                        Expanded(
                                          flex: 2,
                                          child: Text('${awb['weight']} kg', style: TextStyle(color: widget.textS, fontSize: 13)),
                                        ),
                                        // Remove button
                                        if (!widget.isReadOnly)
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addedAwbs.removeAt(i);
                                              });
                                              widget.onAwbsChanged(addedAwbs);
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Icon(Icons.close_rounded, color: const Color(0xFFef4444).withAlpha(200), size: 20),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (isExpanded && (awb['house'].toString().isNotEmpty || awb['remark'].toString().isNotEmpty)) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                                        child: Divider(color: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB), height: 1),
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (awb['house'].toString().isNotEmpty)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.home_work_outlined, size: 14, color: widget.textP),
                                                      const SizedBox(width: 6),
                                                      Text('House Num:', style: TextStyle(color: widget.textP, fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ]
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ...awb['house'].toString().split('\n').where((e) => e.trim().isNotEmpty).map((h) => 
                                                    Padding(
                                                      padding: const EdgeInsets.only(bottom: 4, left: 6),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Container(
                                                            margin: const EdgeInsets.only(top: 5, right: 6),
                                                            width: 4, height: 4,
                                                            decoration: BoxDecoration(color: widget.textS, shape: BoxShape.circle),
                                                          ),
                                                          Expanded(child: Text(h.trim(), style: TextStyle(color: widget.textS, fontSize: 12))),
                                                        ],
                                                      ),
                                                    )
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (awb['house'].toString().isNotEmpty && awb['remark'].toString().isNotEmpty)
                                            const SizedBox(width: 16),
                                          if (awb['remark'].toString().isNotEmpty)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.notes_rounded, size: 14, color: widget.textP),
                                                      const SizedBox(width: 6),
                                                      Text('Remarks:', style: TextStyle(color: widget.textP, fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ]
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 6),
                                                    child: Text(awb['remark'].toString(), style: TextStyle(color: widget.textS, fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        if (!widget.isReadOnly)
          // Bottom: AWB Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: widget.borderC)),
              color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_rounded, size: 18, color: widget.textP),
                    const SizedBox(width: 8),
                    Text('AWB Details', style: TextStyle(color: widget.textP, fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (awbExistsError != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                        child: Text(awbExistsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    if (piecesError != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                        child: Text(piecesError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    if (piecesError == null && totalLocked.value)
                      ValueListenableBuilder<int>(
                        valueListenable: dbExpected,
                        builder: (ctx, dbExp, _) {
                          final t = int.tryParse(awbTotalCtrl.text) ?? 0;
                          final localUsedOtherUlds = widget.logic.getLocalUsedPieces(awbNumCtrl.text.toUpperCase());
                          final localUsedThisUld = _getLocalUsedPiecesInCurrentUld(awbNumCtrl.text.toUpperCase());
                          final remaining = t - dbExp - localUsedOtherUlds - localUsedThisUld;
                          if (remaining > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF22c55e).withAlpha(20), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                widget.appLanguage.value == 'es' ? 'Máx: $remaining piezas' : 'Max $remaining pcs',
                                style: const TextStyle(color: Color(0xFF22c55e), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            );
                          } else {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                widget.appLanguage.value == 'es' ? 'AWB Completado' : 'AWB Completed',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                        }
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: 125, 
                      child: buildTextField(
                        'AWB Number', awbNumCtrl, '000-0000 0000', 
                        maxLen: 13, isNum: true, isAwb: true,
                        hasError: awbExistsError != null || awbRequiredError,
                      )
                    ),
                    SizedBox(
                      width: 75, 
                      child: buildTextField(
                        'Pieces', awbPiecesCtrl, '0', 
                        maxLen: 5, isNum: true, digitsOnly: true,
                        hasError: piecesError != null || piecesRequiredError,
                      )
                    ),
                    SizedBox(
                      width: 75, 
                      child: ValueListenableBuilder<bool>(
                        valueListenable: totalLocked,
                        builder: (ctx, locked, _) {
                          return buildTextField('Total', awbTotalCtrl, '0', maxLen: 5, isNum: true, digitsOnly: true, disabled: locked, hasError: totalRequiredError);
                        }
                      )
                    ),
                    SizedBox(width: 75, child: buildTextField('Weight', awbWeightCtrl, '0', maxLen: 5, isNum: true, digitsOnly: true)),
                    SizedBox(
                      width: 112, 
                      child: buildTextField(
                        'House Num', 
                        awbHouseCtrl, 
                        'Optional...',
                        isUpperCase: true,
                        maxLines: null,
                        fieldHeight: 48,
                        titleTrailing: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: awbHouseCtrl,
                          builder: (ctx, val, child) {
                            int count = val.text.split('\n').where((e) => e.trim().isNotEmpty).length;
                            if (count == 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFF6366f1), shape: BoxShape.circle),
                              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1)),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 358, child: buildTextField('Remarks', awbRemarkCtrl, 'AWB remarks...', isSentenceCase: true)),
                    SizedBox(
                      width: 140, height: 48,
                      child: ElevatedButton(
                        onPressed: _addAwb,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15), 
                          foregroundColor: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), 
                          elevation: 0, 
                          padding: const EdgeInsets.symmetric(horizontal: 16), 
                          side: BorderSide(color: widget.dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: Text(widget.appLanguage.value == 'es' ? '+ Añadir AWB' : '+ Add AWB', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
