import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;
import '../add_flight_v2/add_flight_v2_widgets.dart';
import '../add_flight_v2/add_flight_v2_add_awb_section.dart';

class FlightsV2DrawerUldAdd {
  static void show(BuildContext context, bool dark, String flightId, VoidCallback onSaveSuccess) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return _FlightsV2DrawerUldAddBody(
          dark: dark, 
          flightId: flightId, 
          dialogContext: ctx, 
          onSaveSuccess: onSaveSuccess
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)
          ),
          child: child,
        );
      }
    );
  }
}

class _FlightsV2DrawerUldAddBody extends StatefulWidget {
  final bool dark;
  final String flightId;
  final BuildContext dialogContext;
  final VoidCallback onSaveSuccess;

  const _FlightsV2DrawerUldAddBody({
    required this.dark, 
    required this.flightId, 
    required this.dialogContext, 
    required this.onSaveSuccess
  });

  @override
  State<_FlightsV2DrawerUldAddBody> createState() => _FlightsV2DrawerUldAddBodyState();
}

class _FlightsV2DrawerUldAddBodyState extends State<_FlightsV2DrawerUldAddBody> {
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

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

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

  Future<void> _handleSave() async {
    final uldNum = uldNumCtrl.text.trim().toUpperCase();
    bool hasError = false;
    
    if (uldNum.isEmpty) {
      uldRequiredError = true;
      hasError = true;
    } else {
      try {
        final existing = await Supabase.instance.client
            .from('ulds')
            .select('id_uld')
            .eq('uld_number', uldNum)
            .maybeSingle();
        if (existing != null) {
          uldExistsError = true;
          hasError = true;
        }
      } catch (_) {}
    }
    
    if (addedAwbs.isEmpty) {
      listRequiredError = true;
      hasError = true;
    }
    
    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'uldNumber': uldNum,
        'pieces': int.tryParse(uldPiecesCtrl.text.trim()) ?? 0,
        'weight': int.tryParse(uldWeightCtrl.text.trim()) ?? 0,
        'priority': uldPriority,
        'break': uldBreak,
        'remarks': uldRemarkCtrl.text.trim(),
        'isAutoPieces': autoCalcPieces,
        'isAutoWeight': autoCalcWeight,
        'awbs': addedAwbs.map((a) => {
          'awb_number': a['awb'],
          'pieces': int.tryParse(a['pieces'].toString()) ?? 0,
          'total': int.tryParse(a['total'].toString()) ?? 0,
          'weight': int.tryParse(a['weight'].toString()) ?? 0,
          'house_number': a['house'] ?? '',
          'remarks': a['remark'] ?? '',
        }).toList(),
      };

      await Supabase.instance.client.rpc('rpc_add_uld_to_flight', params: {
        'p_flight_id': widget.flightId,
        'p_payload': payload,
      });

      if (mounted) {
        widget.onSaveSuccess();
        if (widget.dialogContext.mounted) {
          Navigator.pop(widget.dialogContext);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.redAccent
          )
        );
      }
    }
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
          width: 550,
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
                          appLanguage.value == 'es' ? 'Añadir nuevo ULD al vuelo' : 'Add new ULD to flight', 
                          style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appLanguage.value == 'es' ? 'Se creará en la base de datos de inmediato' : 'It will be created in the database immediately', 
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
                              SizedBox(width: 122, child: buildTextField('ULD Number', uldNumCtrl, 'AKE12345AA', maxLen: 10, isUpperCase: true, hasError: uldRequiredError || uldExistsError, disabled: _isSubmitting)),
                              SizedBox(
                                width: 75,
                                child: buildTextField(
                                  'Pieces', uldPiecesCtrl, autoCalcPieces ? 'Auto' : '0',
                                  maxLen: 5, isNum: true, digitsOnly: true, disabled: autoCalcPieces || _isSubmitting,
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
                                      onChanged: _isSubmitting ? null : (v) {
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
                                  maxLen: 5, isNum: true, digitsOnly: true, disabled: autoCalcWeight || _isSubmitting,
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
                                      onChanged: _isSubmitting ? null : (v) {
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
                                          Switch(value: uldPriority, onChanged: _isSubmitting ? null : (v) => setState(() => uldPriority = v), activeThumbColor: Colors.white, activeTrackColor: const Color(0xFFf59e0b), inactiveThumbColor: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
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
                                            value: uldBreak, onChanged: _isSubmitting ? null : (v) => setState(() => uldBreak = v), activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF22c55e), inactiveThumbColor: dark ? const Color(0xFFbdc3c7) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
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
                              SizedBox(width: double.infinity, child: buildTextField('Remarks', uldRemarkCtrl, 'ULD remarks...', isSentenceCase: true, disabled: _isSubmitting)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Middle: List + Bottom: Form
                    Expanded(
                      child: AddFlightV2AddAwbSection(
                        dark: widget.dark,
                        appLanguage: appLanguage,
                        textP: textP,
                        textS: textS,
                        borderC: borderC,
                        getLocalUsedPieces: (awb) => 0, // No local unsaved state to worry about
                        listRequiredError: listRequiredError,
                        isReadOnly: _isSubmitting,
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
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(widget.dialogContext),
                      child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: TextStyle(color: textP, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(appLanguage.value == 'es' ? 'Guardar Nuevo ULD' : 'Save New ULD', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
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
