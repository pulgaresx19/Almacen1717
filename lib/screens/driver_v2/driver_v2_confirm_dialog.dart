import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show currentUserData;
import 'driver_v2_awb_dialog.dart';

void showDriverConfirmDialog({
  required BuildContext context,
  required Map<String, dynamic> deliveryData,
  required bool dark,
  required String company,
  required String driver,
}) {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
  final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
  final bgGlassy = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
  final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
  
  // The list of deliveries (AWBs) could be under 'awbs' or 'list_deliveries' based on previous context.
  final List<dynamic> awbsList = (deliveryData['awbs'] is List) ? deliveryData['awbs'] as List 
                               : (deliveryData['list_deliver'] is List) ? deliveryData['list_deliver'] as List : [];
  
  final String door = deliveryData['door']?.toString() ?? '-';
  final String type = deliveryData['type']?.toString() ?? '-';
  final String idPickup = deliveryData['id_pickup']?.toString() ?? '-';
  final bool isPriority = deliveryData['is_priority'] == true;
  final String remarks = deliveryData['remarks']?.toString() ?? deliveryData['remar']?.toString() ?? '';
  
  // Initialize is_delivered_now from memory FIRST before building the dialog
  List<dynamic> deliveredItemsMem = (deliveryData['delivered_items'] is List) ? deliveryData['delivered_items'] as List : [];
  for (var item in awbsList) {
    if (item['is_delivered_now'] == null) {
      final String currentId = item['awb_id']?.toString() ?? item['uld_id']?.toString() ?? item['id']?.toString() ?? '';
      bool isDelivered = false;
      for (var d in deliveredItemsMem) {
        if (d is Map && d['item_id']?.toString() == currentId) {
          isDelivered = true;
          break;
        } else if (d.toString() == currentId) {
          isDelivered = true; // Fallback for plain strings
          break;
        }
      }
      item['is_delivered_now'] = isDelivered;
    }
  }
  
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final size = MediaQuery.of(context).size;
          final allDelivered = awbsList.isNotEmpty && awbsList.every((i) => i['is_delivered_now'] == true);
          
          return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600, // Tablet-like width
            maxHeight: size.height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: bgDialog,
              child: Column(
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
                          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF6366f1), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(company, style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(driver, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            // If the delivery is already marked as Completed in the database, just let them out.
                            // Otherwise, they MUST provide a pending reason to exit, even if all items are checked.
                            if (deliveryData['status'] == 'Completed') {
                              Navigator.pop(ctx);
                              return;
                            }
                            
                            final reasonController = TextEditingController();
                            final formKey = GlobalKey<FormState>();
                            
                            final shouldExit = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext warningCtx) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    width: 400,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0xFF1e293b) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
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
                                                  color: Colors.orange.withAlpha(30),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Pending Delivery', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 4),
                                                    Text('If you exit, this delivery will be marked as "Pending".', style: TextStyle(color: textS, fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          Text('Reason for pending:', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: reasonController,
                                            style: TextStyle(color: textP),
                                            maxLines: 3,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'This field is required';
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'Enter a valid reason...',
                                              hintStyle: TextStyle(color: textS.withAlpha(150)),
                                              filled: true,
                                              fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orange)),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () => Navigator.pop(warningCtx, false),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    side: BorderSide(color: borderC),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  child: Text('Cancel', style: TextStyle(color: textS, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (formKey.currentState!.validate()) {
                                                      Navigator.pop(warningCtx, true);
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    elevation: 0,
                                                  ),
                                                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            
                            if (shouldExit == true) {
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                              );
                              
                              try {
                                final pendingReport = {
                                  'reason': reasonController.text.trim(),
                                  'time': DateTime.now().toIso8601String(),
                                  'user': currentUserData.value?['full-name'] ?? 'Unknown',
                                };
                                
                                final idStr = deliveryData['id_delivery']?.toString() ?? deliveryData['id_pickup']?.toString() ?? deliveryData['id']?.toString();
                                
                                if (idStr != null) {
                                  final response = await Supabase.instance.client
                                      .from('deliveries')
                                      .select('report_pending')
                                      .eq('id_delivery', idStr)
                                      .maybeSingle();
                                      
                                  List<dynamic> currentPending = [];
                                  if (response != null && response['report_pending'] != null) {
                                    if (response['report_pending'] is List) {
                                      currentPending = List<dynamic>.from(response['report_pending']);
                                    }
                                  }
                                  
                                  currentPending.add(pendingReport);
                                  
                                  await Supabase.instance.client
                                      .from('deliveries')
                                      .update({
                                        'status': 'Pending',
                                        'report_pending': currentPending,
                                      })
                                      .eq('id_delivery', idStr);
                                }
                                
                                if (!context.mounted) return;
                                Navigator.pop(context); // Close loading
                                Navigator.pop(ctx);     // Close main dialog
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Delivery marked as Pending', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                Navigator.pop(context); // Close loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.close_rounded, color: textS),
                          hoverColor: Colors.white.withAlpha(10),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),
                  
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // General Info Section
                          Text('GENERAL INFORMATION', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgGlassy,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderC),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoItem('ID Pickup', idPickup, textS, textP)),
                                    Expanded(child: _buildInfoItem('Door', door, textS, textP)),
                                    Expanded(child: _buildInfoItem('Type', type, textS, textP)),
                                    if (isPriority)
                                      const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 28),
                                  ],
                                ),
                                if (remarks.isNotEmpty && remarks != '-') ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.notes_rounded, size: 16, color: textS),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            remarks,
                                            style: TextStyle(color: textS, fontSize: 13, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // List of Deliveries Section
                          Text('DELIVERIES LIST', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          
                          if (awbsList.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text('No deliveries found for this driver.', style: TextStyle(color: textS)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: awbsList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = awbsList[index];
                                  
                                final String rawNumber = item['awb_number']?.toString() ?? item['uld_number']?.toString() ?? item['awb']?.toString() ?? 'N/A';
                                final String typeLabel = item.containsKey('uld_id') ? 'ULD: ' : 'AWB: ';
                                final awbNumber = '$typeLabel$rawNumber';
                                  
                                final pieces = item['found']?.toString() ?? '0';
                                final weight = item['weight']?.toString() ?? '0';
                                final remar = item['remarks']?.toString() ?? '';
                                  
                                return InkWell(
                                  onTap: () async {
                                    if (item['is_delivered_now'] == true) return;
                                    
                                    final success = await showDriverAwbDialog(
                                      context: context,
                                      awbItem: item,
                                      deliveryData: deliveryData,
                                      company: company,
                                      driver: driver,
                                      dark: dark,
                                    );
                                    
                                    if (success == true) {
                                      setState(() {
                                        item['is_delivered_now'] = true;
                                      });
                                      
                                      if (!context.mounted) return;
                                      // Show a quick fading success icon
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        barrierColor: Colors.transparent,
                                        builder: (c) => Center(
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween<double>(begin: 0.0, end: 1.0),
                                            duration: const Duration(milliseconds: 300),
                                            builder: (context, value, child) {
                                              return Transform.scale(
                                                scale: value,
                                                child: Opacity(
                                                  opacity: value,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(24),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withAlpha(180),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 60),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                      // Auto close after 800ms
                                      Future.delayed(const Duration(milliseconds: 800), () {
                                        if (context.mounted) {
                                          Navigator.of(context, rootNavigator: true).pop();
                                        }
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: bgGlassy,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderC),
                                    ),
                                    child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: item['is_delivered_now'] == true 
                                                  ? const Color(0xFF10b981) 
                                                  : const Color(0xFF10b981).withAlpha(20),
                                              shape: BoxShape.circle,
                                            ),
                                            child: item['is_delivered_now'] == true
                                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                                : Text('${index + 1}', style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              awbNumber, 
                                              style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Pieces', style: TextStyle(color: textS, fontSize: 10)),
                                                Text(pieces, style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Weight', style: TextStyle(color: textS, fontSize: 10)),
                                                Text('$weight kg', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (remar != '-' && remar.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.notes_rounded, size: 14, color: textS),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  remar,
                                                  style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Fixed Bottom Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgDialog,
                      border: Border(top: BorderSide(color: borderC)),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: allDelivered ? () async {
                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFF10b981))),
                          );
                          
                          final idStr = deliveryData['id_delivery']?.toString() ?? deliveryData['id_pickup']?.toString() ?? deliveryData['id']?.toString();
                          
                          if (idStr != null && idStr != '-') {
                            // First attempt with 'deliveries' table using id_pickup
                            try {
                              await Supabase.instance.client
                                  .from('deliveries')
                                  .update({'status': 'Completed'})
                                  .eq('id_pickup', idStr);
                            } catch (_) {
                              // Fallback if the primary key is 'id_delivery', handled gracefully.
                              await Supabase.instance.client
                                  .from('deliveries')
                                  .update({'status': 'Completed'})
                                  .eq('id_delivery', idStr);
                            }
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading
                          Navigator.pop(ctx);     // Close the main dialog
                          
                          // Show nice animated/curious success dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext successCtx) {
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  width: 320,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: dark ? const Color(0xFF1e293b) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10b981).withAlpha(30),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 50),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Delivery Completed',
                                        style: TextStyle(
                                          color: dark ? Colors.white : Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'All items have been successfully delivered and processed.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: dark ? Colors.white70 : Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(successCtx),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10b981),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0,
                                          ),
                                          child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}', style: const TextStyle(color: Colors.white)),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } : null,
                      icon: const Icon(Icons.task_alt_rounded, size: 20),
                      label: const Text('Mark Delivery Finished', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF10b981).withAlpha(80), // Faded green background
                        disabledForegroundColor: Colors.white.withAlpha(180), // Slightly muted white text
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
        },
      );
    },
  );
}

Widget _buildInfoItem(String label, String value, Color textS, Color textP) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: textS, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}
