import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> showAssignDoorDialog({
  required BuildContext context,
  required bool dark,
  required Map<String, dynamic> deliveryData,
}) async {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
  final bgDialog = dark ? const Color(0xFF1e293b) : Colors.white;
  final borderC = dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  final inputBg = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
  
  final doorCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool isSaving = false;
      return StatefulBuilder(
        builder: (stContext, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgDialog,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderC),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFACC15).withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.meeting_room_rounded, color: Color(0xFFFACC15), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assign Door', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Please specify the door number.', style: TextStyle(color: textS, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: doorCtrl,
                      style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        return null;
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '05',
                        hintStyle: TextStyle(color: textS.withAlpha(100)),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(ctx, null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: borderC),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: TextStyle(color: textS, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => isSaving = true);
                              
                              String doorVal = doorCtrl.text.trim();
                              if (doorVal == '0' || doorVal == '00') {
                                doorVal = 'RAMP';
                              }
                              
                              final idDelivery = deliveryData['id_delivery']?.toString();
                              final idPickup = deliveryData['id_pickup']?.toString() ?? deliveryData['id']?.toString();
                              
                              try {
                                if (idDelivery != null && idDelivery.isNotEmpty && idDelivery != '-') {
                                  await Supabase.instance.client
                                      .from('deliveries')
                                      .update({'door': doorVal})
                                      .eq('id_delivery', idDelivery);
                                } else if (idPickup != null && idPickup.isNotEmpty && idPickup != '-') {
                                  await Supabase.instance.client
                                      .from('deliveries')
                                      .update({'door': doorVal})
                                      .eq('id_pickup', idPickup);
                                }
                                
                                if (ctx.mounted) Navigator.pop(ctx, doorVal);
                              } catch (e) {
                                debugPrint('Error updating door: $e');
                                if (ctx.mounted) {
                                  setState(() => isSaving = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Assign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      );
    }
  );
}
