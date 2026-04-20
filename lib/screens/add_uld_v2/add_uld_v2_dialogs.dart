import 'package:flutter/material.dart';

import '../../main.dart' show isDarkMode, appLanguage;
import 'add_uld_v2_logic.dart';
import 'add_uld_v2_service.dart';
import 'add_uld_v2_widgets.dart';

void showRequiredFieldError(BuildContext context, String fieldName) {
  showDialog(
    context: context,
    builder: (alertCtx) => AlertDialog(
      backgroundColor: const Color(0xFF1e293b),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.redAccent.withAlpha(50)),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text('Action Required', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('The field "$fieldName" is missing.\nPlease provide this information to proceed.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(alertCtx),
              child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 14)),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showAddAwbDialog(BuildContext context, AddUldV2Logic logic, int uldIndex) async {
  final awbNumCtrl = TextEditingController();
  final piecesCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final totalCtrl = TextEditingController();
  final houseCtrl = TextEditingController();
  final remCtrl = TextEditingController();

  final totalLocked = ValueNotifier<bool>(false);
  final dbExpected = ValueNotifier<int>(0);
  final awbErrors = ValueNotifier<Map<String, String>>({});

  awbNumCtrl.addListener(() async {
    final text = awbNumCtrl.text.toUpperCase();
    if (text.length == 13) {
      bool foundLocally = false;
      String foundTotal = '';
      for (var u in logic.localUlds) {
        for (var a in (u['awbs'] as List)) {
          if (a['awb_number'] == text) {
            foundLocally = true;
            foundTotal = a['total'].toString();
            break;
          }
        }
        if (foundLocally) break;
      }

      if (foundLocally) {
        totalLocked.value = true;
        if (totalCtrl.text != foundTotal) {
          totalCtrl.text = foundTotal;
        }
      }

      final res = await AddUldV2Service().checkAwbTotal(text);
      if (res != null && awbNumCtrl.text.toUpperCase() == text) {
        totalLocked.value = true;
        if (!foundLocally) {
          totalCtrl.text = res['total'].toString();
        }
        dbExpected.value = res['total_expected'] as int;
      } else {
        dbExpected.value = 0;
      }
    } else {
      if (totalLocked.value) {
        totalLocked.value = false;
        totalCtrl.text = '0';
        dbExpected.value = 0;
      }
    }
  });


  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: Text('Add AWB to ${logic.localUlds[uldIndex]['uldNumber']}', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 380,
          child: ValueListenableBuilder<Map<String, String>>(
            valueListenable: awbErrors,
            builder: (c, err, _) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: buildUldTextField('AWB Number', awbNumCtrl, '123-1234 5678', isAwb: true, hasError: err.containsKey('AWB Number'), errorText: err['AWB Number'])),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: buildUldTextField('Pieces', piecesCtrl, '0', isNum: true, digitsOnly: true, hasError: err.containsKey('Pieces'), errorText: err['Pieces'])),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3, 
                          child: ValueListenableBuilder<bool>(
                            valueListenable: totalLocked,
                            builder: (c, locked, _) => buildUldTextField('Total', totalCtrl, '0', isNum: true, digitsOnly: true, disabled: locked, hasError: err.containsKey('Total'), errorText: err['Total']),
                          )
                        ),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: buildUldTextField('Weight', weightCtrl, '0.0', isNum: true, allowDecimal: true)),
                      ]
                    ),
                    const SizedBox(height: 12),
                    buildUldTextField('Remarks', remCtrl, 'Additional remarks...'),
                    const SizedBox(height: 12),
                    
                    // Multiline House Number Field
                    buildUldTextField(
                      'House Number (One per line)',
                      houseCtrl,
                      'HAWB...\nHAWB...',
                      isUpperCase: true,
                      maxLines: 3,
                      minLines: 1,
                      titleTrailing: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: houseCtrl,
                        builder: (context, value, child) {
                          final count = value.text.split('\n').where((e) => e.trim().isNotEmpty).length;
                          if (count == 0) return const SizedBox.shrink();
                          return Container(
                            width: 22, height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3b82f6),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
            onPressed: () {
              awbErrors.value = {};
              final newAwb = awbNumCtrl.text.trim().toUpperCase();
              Map<String, String> currentErrors = {};

              if (newAwb.isEmpty) currentErrors['AWB Number'] = 'Required';
              if (piecesCtrl.text.trim().isEmpty || piecesCtrl.text.trim() == '0') currentErrors['Pieces'] = 'Required';
              if (totalCtrl.text.trim().isEmpty || totalCtrl.text.trim() == '0') currentErrors['Total'] = 'Required';

              if (currentErrors.isNotEmpty) {
                 awbErrors.value = currentErrors;
                 return;
              }
              
              final p = int.tryParse(piecesCtrl.text) ?? 0;
              final t = int.tryParse(totalCtrl.text) ?? 0;
              
              final dbExp = dbExpected.value;
              final localUsed = logic.getLocalUsedPieces(newAwb);
              final totalAllowed = t - dbExp - localUsed;

              if (p > totalAllowed) {
                 if (totalAllowed <= 0) {
                   currentErrors['Pieces'] = 'No pieces remaining';
                 } else {
                   currentErrors['Pieces'] = 'Max $totalAllowed pieces';
                 }
                 awbErrors.value = currentErrors;
                 return;
              }
              
              final existingAwbs = logic.localUlds[uldIndex]['awbs'] as List;
              if (existingAwbs.any((a) => a['awb_number'] == newAwb)) {
                  showDialog(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      backgroundColor: const Color(0xFF1e293b),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Column(children: [Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 48), SizedBox(height: 16), Text('Duplicate AWB', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
                      content: SizedBox(
                        width: 260,
                        height: 70,
                        child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                              Text('The AWB "$newAwb" is already registered under this ULD. Please verify or modify.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFcbd5e1)))
                           ]
                        )
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK', style: TextStyle(color: Color(0xFF6366f1), fontSize: 16, fontWeight: FontWeight.bold)))]
                    )
                  );
                  return;
                }

                List<String> parsedHouseNumbers = [];
                if (houseCtrl.text.trim().isNotEmpty) {
                   parsedHouseNumbers = houseCtrl.text.split('\n').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toSet().toList();
                }

                logic.addAwbToUld(uldIndex, {
                  'awb_number': newAwb,
                  'pieces': int.tryParse(piecesCtrl.text) ?? 0,
                  'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                  'total': int.tryParse(totalCtrl.text) ?? 1,
                  'house_number': parsedHouseNumbers,
                  'remarks': remCtrl.text.trim().isEmpty ? null : remCtrl.text.trim(),
                });
                Navigator.pop(ctx);
            },
            child: const Text('Add AWB', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }
  );
}

Future<bool> showDiscardDialog(BuildContext context) async {
  final bool? shouldPop = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1e293b),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFFf59e0b).withAlpha(100), width: 2)),
      title: const Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 60),
          SizedBox(height: 16),
          Text('Discard Data?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Any unsaved data entered for the ULD will be permanently lost.\n\nDo you want to discard your changes and continue?', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 16, height: 1.4)),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('STAY', style: TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFef4444),
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ],
    ),
  );

  return shouldPop == true;
}

Future<void> showSaveSuccessDialog(BuildContext context) async {
  bool dialogOpen = true;
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) {
      final dark = isDarkMode.value;
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1e293b) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF10b981).withAlpha(40), blurRadius: 40, offset: const Offset(0, 10))],
              border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(20), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48)),
                const SizedBox(height: 24),
                Text(appLanguage.value == 'es' ? '¡ULD Guardado!' : 'ULD Saved!', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(appLanguage.value == 'es' ? 'Los ULDs se guardaron exitosamente.' : 'ULDs saved successfully.', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (c, a1, a2, child) => Transform.scale(scale: Curves.easeOutBack.transform(a1.value), child: FadeTransition(opacity: a1, child: child)),
  ).then((_) => dialogOpen = false);

  await Future.delayed(const Duration(milliseconds: 2000));
  
  if (context.mounted && dialogOpen) {
    Navigator.of(context).pop();
  }
}
