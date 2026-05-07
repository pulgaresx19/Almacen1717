import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void showNoBreakDeliverDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> selectedUlds,
  required bool dark,
  VoidCallback? onSuccess,
}) {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
  final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
  final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
  final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

  final companyCtrl = TextEditingController();
  final driverCtrl = TextEditingController();
  final doorCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final idPickupCtrl = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool showErrorCompany = false;
      bool showErrorDriver = false;
      bool showErrorDoor = false;
      bool showErrorIdPickup = false;

      return StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: bgDialog,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF6366f1), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Deliver ULDs',
                          style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: textS),
                          hoverColor: Colors.white.withAlpha(10),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),
                  
                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Form
                          Text('Delivery Details', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(controller: companyCtrl, hint: 'Company', icon: Icons.business_outlined, dark: dark, textP: textP, borderC: borderC, textCapitalization: TextCapitalization.characters, inputFormatters: [UpperCaseTextFormatter()], showError: showErrorCompany, onChanged: (v) { if (showErrorCompany && v.trim().isNotEmpty) setState(() => showErrorCompany = false); })),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(controller: driverCtrl, hint: 'Driver Name', icon: Icons.person_outline, dark: dark, textP: textP, borderC: borderC, textCapitalization: TextCapitalization.words, inputFormatters: [TitleCaseTextFormatter()], showError: showErrorDriver, onChanged: (v) { if (showErrorDriver && v.trim().isNotEmpty) setState(() => showErrorDriver = false); })),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(width: 120, child: _buildTextField(controller: doorCtrl, hint: 'Door', icon: Icons.door_front_door_outlined, dark: dark, textP: textP, borderC: borderC, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly], showError: showErrorDoor, onChanged: (v) { if (showErrorDoor && v.trim().isNotEmpty) setState(() => showErrorDoor = false); })),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(
                                controller: idPickupCtrl, 
                                hint: 'ID Pickup', 
                                icon: Icons.badge_outlined, 
                                dark: dark, textP: textP, borderC: borderC, 
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [UpperCaseTextFormatter()],
                                showError: showErrorIdPickup, 
                                onChanged: (v) { if (showErrorIdPickup && v.trim().isNotEmpty) setState(() => showErrorIdPickup = false); },
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.autorenew_rounded, color: dark ? Colors.white54 : Colors.black54),
                                  onPressed: () {
                                    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
                                    final rnd = Random();
                                    idPickupCtrl.text = String.fromCharCodes(Iterable.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
                                    if (showErrorIdPickup) setState(() => showErrorIdPickup = false);
                                  },
                                ),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(controller: remarksCtrl, hint: 'Remarks', icon: Icons.comment_outlined, dark: dark, textP: textP, borderC: borderC, textCapitalization: TextCapitalization.sentences, inputFormatters: [SentenceCaseTextFormatter()]),
                          
                          const SizedBox(height: 24),
                          Divider(height: 1, color: borderC),
                          const SizedBox(height: 24),
                          
                          // Selected ULDs List
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 18, color: textS),
                              const SizedBox(width: 8),
                              Text('Selected ULDs (${selectedUlds.length})', style: TextStyle(color: textS, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderC),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: selectedUlds.length,
                              separatorBuilder: (c, i) => Divider(height: 1, color: borderC),
                              itemBuilder: (c, i) {
                                final u = selectedUlds[i];
                                final uldNumber = u['uld_number']?.toString() ?? '-';
                                final pieces = u['pieces_total']?.toString() ?? u['pieces']?.toString() ?? '-';
                                final weight = u['weight_total']?.toString() ?? u['weight']?.toString() ?? '-';
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366f1).withAlpha(30),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          (i + 1).toString(),
                                          style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          uldNumber,
                                          style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text('$pieces pcs', style: TextStyle(color: textS, fontSize: 13), textAlign: TextAlign.center),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text('$weight kg', style: TextStyle(color: textS, fontSize: 13), textAlign: TextAlign.right),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Footer
                  Divider(height: 1, color: borderC),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel', style: TextStyle(color: textS, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            setState(() {
                              showErrorCompany = companyCtrl.text.trim().isEmpty;
                              showErrorDriver = driverCtrl.text.trim().isEmpty;
                              showErrorDoor = doorCtrl.text.trim().isEmpty;
                              showErrorIdPickup = idPickupCtrl.text.trim().isEmpty;
                            });

                            if (showErrorCompany || showErrorDriver || showErrorDoor || showErrorIdPickup) return;

                            int totalPieces = 0;
                            double totalWeight = 0.0;
                            List<Map<String, dynamic>> listDeliver = [];

                            for (var uld in selectedUlds) {
                              final uldNum = uld['uld_number']?.toString() ?? uld['ULD-number']?.toString() ?? '';
                              final pcsStr = uld['pieces_total']?.toString() ?? uld['pieces']?.toString() ?? uld['total_pieces']?.toString() ?? '0';
                              final wgtStr = uld['weight_total']?.toString() ?? uld['weight']?.toString() ?? '0.00';
                              
                              final pcs = int.tryParse(pcsStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                              final wgt = double.tryParse(wgtStr) ?? 0.0;

                              totalPieces += pcs;
                              totalWeight += wgt;

                              listDeliver.add({
                                'type': 'ULD',
                                'uld_id': uld['id_uld'],
                                'uld_number': uldNum,
                                'found': pcs.toString(),
                                'weight': wgt.toStringAsFixed(2),
                                'remarks': remarksCtrl.text.trim(),
                                'total_pieces': pcs.toString(),
                                'is_break': uld['is_break'] == true,
                              });
                            }

                            final payload = {
                              'company': companyCtrl.text.trim(),
                              'driver_name': driverCtrl.text.trim(),
                              'door': doorCtrl.text.trim(),
                              'id_pickup': idPickupCtrl.text.trim(),
                              'type': 'Send-ULD',
                              'time': DateTime.now().toUtc().toIso8601String(),
                              'remarks': remarksCtrl.text.trim(),
                              'is_priority': false,
                              'list_deliver': listDeliver,
                              'total_pieces': totalPieces,
                              'total_weight': totalWeight,
                              'all_uld': true,
                              'id_user': Supabase.instance.client.auth.currentUser?.id,
                            };

                            try {
                              await Supabase.instance.client.rpc('rpc_save_delivery', params: {'payload': payload});
                              if (context.mounted) {
                                Navigator.pop(ctx, true);
                                if (onSuccess != null) onSuccess();
                                showDialog(
                                  context: context,
                                  builder: (c) {
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (c.mounted) Navigator.pop(c);
                                    });
                                    return AlertDialog(
                                      backgroundColor: dark ? const Color(0xFF1F2937) : Colors.white,
                                      elevation: 24,
                                      shadowColor: const Color(0xFF10b981).withAlpha(100),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(color: const Color(0xFF10b981).withAlpha(80), width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.all(32),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10b981).withAlpha(20),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 48),
                                          ),
                                          const SizedBox(height: 24),
                                          Text('Delivery Prepared!', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text('Delivery items processed successfully.', textAlign: TextAlign.center, style: TextStyle(color: dark ? Colors.white54 : Colors.black54, fontSize: 14)),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          label: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  },
);
}

Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  required bool dark,
  required Color textP,
  required Color borderC,
  TextCapitalization textCapitalization = TextCapitalization.none,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  bool showError = false,
  ValueChanged<String>? onChanged,
  Widget? suffixIcon,
}) {
  final bgColor = showError ? Colors.red.withAlpha(20) : (dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB));
  final borderColor = showError ? Colors.red : borderC;
  final hintColor = showError ? Colors.red.withAlpha(200) : (dark ? Colors.white54 : Colors.black54);
  final iconColor = showError ? Colors.red.withAlpha(200) : (dark ? Colors.white54 : Colors.black54);

  return TextField(
    controller: controller,
    textCapitalization: textCapitalization,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    style: TextStyle(color: textP, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: showError ? Colors.red : const Color(0xFF6366f1), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class TitleCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (text.isEmpty) return newValue;
    
    StringBuffer buffer = StringBuffer();
    bool capitalizeNext = true;
    for (int i = 0; i < text.length; i++) {
      if (text[i].trim().isEmpty) {
        capitalizeNext = true;
        buffer.write(text[i]);
      } else if (capitalizeNext) {
        buffer.write(text[i].toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(text[i].toLowerCase());
      }
    }
    
    return newValue.copyWith(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

class SentenceCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (text.isEmpty) return newValue;
    
    return newValue.copyWith(
      text: text[0].toUpperCase() + text.substring(1).toLowerCase(),
      selection: newValue.selection,
    );
  }
}
