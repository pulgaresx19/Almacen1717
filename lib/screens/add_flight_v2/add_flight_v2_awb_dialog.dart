import 'package:flutter/material.dart';
import 'add_flight_v2_logic.dart';
import 'add_flight_v2_widgets.dart';

Future<void> showAddAwbDialog(BuildContext context, AddFlightV2Logic logic, int uldIndex) async {
  final awbNumCtrl = TextEditingController();
  final piecesCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final totalCtrl = TextEditingController();
  final houseCtrl = TextEditingController();
  final remCtrl = TextEditingController();
  final totalLocked = ValueNotifier<bool>(false);
  final dbExpected = ValueNotifier<int>(0);
  final awbErrors = ValueNotifier<Map<String, String>>({});

  awbNumCtrl.addListener(() {
    final text = awbNumCtrl.text.toUpperCase();
    if (text.length == 13) {
      bool foundLocally = false;
      String foundTotal = '';
      for (var u in logic.flightLocalUlds) {
        for (var a in (u['awbs'] as List)) {
          if (a['awb_number'] == text) {
            foundLocally = true;
            foundTotal = a['total'].toString();
            break;
          }
        }
        if (foundLocally) break;
      }

      logic.fetchAwbTotalAsync(text, totalLocked, totalCtrl, dbExpected);

      if (foundLocally) {
        totalLocked.value = true;
        if (totalCtrl.text != foundTotal) {
          totalCtrl.text = foundTotal;
        }
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
        title: Text('Add AWB to ${logic.flightLocalUlds[uldIndex]['uldNumber']}', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 380,
          child: ValueListenableBuilder<Map<String, String>>(
            valueListenable: awbErrors,
            builder: (ctx, err, _) {
              return SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: buildTextField('AWB Number', awbNumCtrl, '123-1234 5678', isAwb: true, hasError: err.containsKey('AWB Number'), errorText: err['AWB Number'])),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: buildTextField('Pieces', piecesCtrl, '0', isNum: true, digitsOnly: true, hasError: err.containsKey('Pieces'), errorText: err['Pieces'])),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3, 
                        child: ValueListenableBuilder<bool>(
                          valueListenable: totalLocked,
                          builder: (ctx, locked, _) => buildTextField('Total', totalCtrl, '0', isNum: true, digitsOnly: true, disabled: locked, hasError: err.containsKey('Total'), errorText: err['Total']),
                        )
                      ),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: buildTextField('Weight', weightCtrl, '0.0', isNum: true, allowDecimal: true)),
                    ]
                  ),
                  const SizedBox(height: 12),
                  buildTextField('Remarks', remCtrl, 'Additional remarks...'),
                  const SizedBox(height: 12),
                  buildTextField('House Number', houseCtrl, 'HAWB', maxLines: 3, minLines: 1, isUpperCase: true),
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
              if (currentErrors.isNotEmpty) { awbErrors.value = currentErrors; return; }
              
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
              
              final existingAwbs = logic.flightLocalUlds[uldIndex]['awbs'] as List;
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

              logic.onAwbAddedToUld(uldIndex, {
                'awb_number': newAwb,
                'pieces': int.tryParse(piecesCtrl.text) ?? 0,
                'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                'total': int.tryParse(totalCtrl.text) ?? 1,
                'house_number': houseCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                'remarks': remCtrl.text,
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
