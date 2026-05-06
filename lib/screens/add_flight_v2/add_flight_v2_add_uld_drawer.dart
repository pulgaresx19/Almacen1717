import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'add_flight_v2_logic.dart';
import 'add_flight_v2_widgets.dart';
import 'add_flight_v2_add_awb_section.dart';

class AddFlightV2AddUldDrawer {
  static void show(BuildContext context, bool dark, AddFlightV2Logic flightLogic, {Map<String, dynamic>? initialUld}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return _AddUldDrawerBody(dark: dark, flightLogic: flightLogic, dialogContext: ctx, initialUld: initialUld);
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      }
    );
  }
}

class _AddUldDrawerBody extends StatefulWidget {
  final bool dark;
  final AddFlightV2Logic flightLogic;
  final BuildContext dialogContext;
  final Map<String, dynamic>? initialUld;

  const _AddUldDrawerBody({required this.dark, required this.flightLogic, required this.dialogContext, this.initialUld});

  @override
  State<_AddUldDrawerBody> createState() => _AddUldDrawerBodyState();
}

class _AddUldDrawerBodyState extends State<_AddUldDrawerBody> {
  // ULD Controllers
  final uldNumCtrl = TextEditingController();
  final uldPiecesCtrl = TextEditingController();
  final uldWeightCtrl = TextEditingController();
  final uldRemarkCtrl = TextEditingController();
  bool uldPriority = false;
  bool uldBreak = true;
  bool autoCalcPieces = true;
  bool autoCalcWeight = true;

  List<Map<String, dynamic>> addedAwbs = [];

  bool uldRequiredError = false;
  bool uldExistsError = false;
  bool listRequiredError = false;
  List<Map<String, dynamic>>? _initialAwbs;

  bool isReadOnly = false;

  @override
  void initState() {
    super.initState();
    isReadOnly = widget.initialUld != null;
    
    if (widget.initialUld != null) {
      final u = widget.initialUld!;
      uldNumCtrl.text = u['uldNumber'] ?? '';
      uldPiecesCtrl.text = u['pieces']?.toString() ?? 'Auto';
      uldWeightCtrl.text = u['weight']?.toString() ?? 'Auto';
      uldRemarkCtrl.text = u['remarks'] ?? '';
      uldPriority = u['priority'] == true;
      uldBreak = u['break'] == true;
      autoCalcPieces = u['isAutoPieces'] ?? true;
      autoCalcWeight = u['isAutoWeight'] ?? true;
      
      final rawAwbs = u['awbs'] as List? ?? [];
      _initialAwbs = rawAwbs.map((a) => {
        'awb': a['awb_number'] ?? '',
        'pieces': a['pieces']?.toString() ?? '0',
        'weight': a['weight']?.toString() ?? '0',
        'total': a['total']?.toString() ?? '0',
        'house': a['house_number'] ?? '',
        'remark': a['remarks'] ?? '',
      }).cast<Map<String, dynamic>>().toList();
      addedAwbs = List.from(_initialAwbs!);
    }

    uldNumCtrl.addListener(() {
      bool shouldUpdate = false;
      if (uldRequiredError && uldNumCtrl.text.trim().isNotEmpty) {
        uldRequiredError = false;
        shouldUpdate = true;
      }
      if (uldExistsError) {
        uldExistsError = false;
        shouldUpdate = true;
      }
      if (shouldUpdate) setState(() {});
    });
  }

  @override
  void dispose() {
    uldNumCtrl.dispose();
    uldPiecesCtrl.dispose();
    uldWeightCtrl.dispose();
    uldRemarkCtrl.dispose();
    super.dispose();
  }

  void _recalculateTotals(List<Map<String, dynamic>> awbs) {
    if (listRequiredError && awbs.isNotEmpty) {
      listRequiredError = false;
    }
    int totalPieces = 0;
    int totalWeight = 0;
    for (final awb in awbs) {
      totalPieces += int.tryParse(awb['pieces'].toString()) ?? 0;
      totalWeight += int.tryParse(awb['weight'].toString()) ?? 0;
    }
    setState(() {
      if (autoCalcPieces) uldPiecesCtrl.text = totalPieces.toString();
      if (autoCalcWeight) uldWeightCtrl.text = totalWeight.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final bg = dark ? const Color(0xFF0f172a) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: bg,
        elevation: 16,
        child: SizedBox(
          width: 550, // Wider to accommodate the forms comfortably
          height: double.infinity,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialUld == null 
                              ? (appLanguage.value == 'es' ? 'Añadir ULD al vuelo' : 'Add ULD to flight')
                              : (isReadOnly ? (appLanguage.value == 'es' ? 'Detalles del ULD' : 'ULD Details') : (appLanguage.value == 'es' ? 'Editar ULD' : 'Edit ULD')), 
                          style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appLanguage.value == 'es' ? 'Gestión de ULDs in-flight' : 'In-flight ULD management', 
                          style: TextStyle(color: textS, fontSize: 13)
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textP),
                      onPressed: () => Navigator.pop(widget.dialogContext),
                    ),
                  ],
                ),
              ),
              
              // Body Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top: ULD Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderC)),
                        color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2_rounded, size: 18, color: textP),
                              const SizedBox(width: 8),
                              Text('ULD Details', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              if (uldRequiredError || uldExistsError)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    uldExistsError ? (appLanguage.value == 'es' ? 'ULD ya existe' : 'ULD already exists') 
                                                   : (appLanguage.value == 'es' ? 'ULD Requerido' : 'Required ULD'), 
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              SizedBox(width: 122, child: buildTextField('ULD Number', uldNumCtrl, 'AKE12345AA', maxLen: 10, isUpperCase: true, hasError: uldRequiredError || uldExistsError, disabled: isReadOnly)),
                              SizedBox(
                                width: 75,
                                child: buildTextField(
                                  'Pieces', uldPiecesCtrl, autoCalcPieces ? 'Auto' : '0',
                                  maxLen: 5, isNum: true, digitsOnly: true, disabled: autoCalcPieces || isReadOnly,
                                  titleTrailing: SizedBox(
                                    width: 14, height: 14,
                                    child: Checkbox(
                                      value: autoCalcPieces,
                                      activeColor: const Color(0xFF6366f1),
                                      checkColor: Colors.white,
                                      side: BorderSide(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      splashRadius: 0,
                                      onChanged: isReadOnly ? null : (v) {
                                        setState(() {
                                          autoCalcPieces = v ?? true;
                                          if (autoCalcPieces) {
                                            _recalculateTotals(addedAwbs);
                                          } else {
                                            if (uldPiecesCtrl.text == '0') uldPiecesCtrl.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 75,
                                child: buildTextField(
                                  'Weight', uldWeightCtrl, autoCalcWeight ? 'Auto' : '0',
                                  maxLen: 5, isNum: true, digitsOnly: true, disabled: autoCalcWeight || isReadOnly,
                                  titleTrailing: SizedBox(
                                    width: 14, height: 14,
                                    child: Checkbox(
                                      value: autoCalcWeight,
                                      activeColor: const Color(0xFF6366f1),
                                      checkColor: Colors.white,
                                      side: BorderSide(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      splashRadius: 0,
                                      onChanged: isReadOnly ? null : (v) {
                                        setState(() {
                                          autoCalcWeight = v ?? true;
                                          if (autoCalcWeight) {
                                            _recalculateTotals(addedAwbs);
                                          } else {
                                            if (uldWeightCtrl.text == '0') uldWeightCtrl.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 95,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Priority?', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 6),
                                    Container(
                                      height: 48, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.star_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 15),
                                          Switch(value: uldPriority, onChanged: isReadOnly ? null : (v) => setState(() => uldPriority = v), activeThumbColor: Colors.white, activeTrackColor: const Color(0xFFf59e0b), inactiveThumbColor: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 95,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Break?', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 6),
                                    Container(
                                      height: 48, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.broken_image_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 15),
                                          Switch(
                                            value: uldBreak, onChanged: isReadOnly ? null : (v) => setState(() => uldBreak = v), activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF22c55e), inactiveThumbColor: dark ? const Color(0xFFbdc3c7) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                                            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                              if (states.contains(WidgetState.selected)) {
                                                return Colors.transparent;
                                              }
                                              return const Color(0xFFef4444).withAlpha(180);
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: double.infinity, child: buildTextField('Remarks', uldRemarkCtrl, 'ULD remarks...', isSentenceCase: true, disabled: isReadOnly)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Extracted AWB Section (Middle: List + Bottom: Form)
                    Expanded(
                      child: AddFlightV2AddAwbSection(
                        dark: widget.dark,
                        appLanguage: appLanguage,
                        textP: textP,
                        textS: textS,
                        borderC: borderC,
                        logic: widget.flightLogic,
                        listRequiredError: listRequiredError,
                        initialAwbs: _initialAwbs,
                        isReadOnly: isReadOnly,
                        onAwbsChanged: (awbs) {
                          setState(() {
                            addedAwbs = awbs;
                          });
                          _recalculateTotals(awbs);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Footer: Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderC)),
                  color: dark ? const Color(0xFF0f172a) : Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isReadOnly) ...[
                      ElevatedButton(
                        onPressed: () => setState(() => isReadOnly = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(appLanguage.value == 'es' ? 'Editar' : 'Edit', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () => Navigator.pop(widget.dialogContext),
                        child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: TextStyle(color: textP, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final uldNum = uldNumCtrl.text.trim();
                        bool hasError = false;
                        if (uldNum.isEmpty) {
                          uldRequiredError = true;
                          hasError = true;
                        } else {
                          // Check for duplicate ULD
                          bool isDuplicate = false;
                          if (widget.initialUld == null || widget.initialUld!['uldNumber'] != uldNum) {
                             isDuplicate = widget.flightLogic.flightLocalUlds.any((u) => u['uldNumber'] == uldNum);
                          }
                          if (isDuplicate) {
                             uldExistsError = true;
                             hasError = true;
                          }
                        }
                        
                        if (addedAwbs.isEmpty) {
                          listRequiredError = true;
                          hasError = true;
                        }
                        
                        if (hasError) {
                          setState(() {});
                          return;
                        }

                        // Build ULD object
                        final newUld = {
                          'uldNumber': uldNum,
                          'pieces': int.tryParse(uldPiecesCtrl.text.trim()) ?? 0,
                          'weight': int.tryParse(uldWeightCtrl.text.trim()) ?? 0,
                          'priority': uldPriority,
                          'break': uldBreak,
                          'remarks': uldRemarkCtrl.text.trim(),
                          'isAutoPieces': autoCalcPieces,
                          'isAutoWeight': autoCalcWeight,
                          'showAwbs': true,
                          'awbs': addedAwbs.map((a) => {
                            'awb_number': a['awb'],
                            'pieces': int.tryParse(a['pieces'].toString()) ?? 0,
                            'total': int.tryParse(a['total'].toString()) ?? 0,
                            'weight': int.tryParse(a['weight'].toString()) ?? 0,
                            'house_number': a['house'] ?? '',
                            'remarks': a['remark'] ?? '',
                            'status': 'received',
                          }).toList(),
                        };
                        
                        // Check if we are editing an existing ULD or creating a new one
                        int existIdx = -1;
                        if (widget.initialUld != null) {
                          existIdx = widget.flightLogic.flightLocalUlds.indexWhere((u) => u['uldNumber'] == widget.initialUld!['uldNumber']);
                        } else {
                          existIdx = widget.flightLogic.flightLocalUlds.indexWhere((u) => u['uldNumber'] == uldNum);
                        }

                        if (existIdx >= 0) {
                          widget.flightLogic.flightLocalUlds[existIdx] = newUld;
                        } else {
                          widget.flightLogic.flightLocalUlds.add(newUld);
                        }
                        
                        // Sort the list: BULK first, then alphabetically by uldNumber
                        widget.flightLogic.flightLocalUlds.sort((a, b) {
                          final aNum = (a['uldNumber'] ?? '').toString().toUpperCase();
                          final bNum = (b['uldNumber'] ?? '').toString().toUpperCase();
                          if (aNum == 'BULK' && bNum != 'BULK') return -1;
                          if (bNum == 'BULK' && aNum != 'BULK') return 1;
                          return aNum.compareTo(bNum);
                        });
                        
                        widget.flightLogic.recalculateAutoCounts();
                        widget.flightLogic.rebuild();
                        Navigator.pop(widget.dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.initialUld != null ? (appLanguage.value == 'es' ? 'Guardar Cambios' : 'Save Changes') : (appLanguage.value == 'es' ? 'Guardar ULD' : 'Save ULD'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
