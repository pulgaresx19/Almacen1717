import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show currentUserData;
import 'driver_v2_awb_split_card.dart';

Future<bool?> showDriverAwbDialog({
  required BuildContext context,
  required Map<String, dynamic> awbItem,
  required Map<String, dynamic> deliveryData,
  required String company,
  required String driver,
  required bool dark,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return DriverV2AwbDialogScreen(
        awbItem: awbItem,
        deliveryData: deliveryData,
        company: company,
        driver: driver,
        dark: dark,
      );
    },
  );
}

class DriverV2AwbDialogScreen extends StatefulWidget {
  final Map<String, dynamic> awbItem;
  final Map<String, dynamic> deliveryData;
  final String company;
  final String driver;
  final bool dark;

  const DriverV2AwbDialogScreen({
    super.key,
    required this.awbItem,
    required this.deliveryData,
    required this.company,
    required this.driver,
    required this.dark,
  });

  @override
  State<DriverV2AwbDialogScreen> createState() => _DriverV2AwbDialogScreenState();
}

class _DriverV2AwbDialogScreenState extends State<DriverV2AwbDialogScreen> {
  late String? awbId;
  late String? uldId;
  late String awbNumber;
  late String deliverPieces;
  late String totalPieces;

  final Set<int> collapsedSplits = {};
  final Set<String> selectedLocations = {};
  
  late ValueNotifier<int> foundNotifier;
  late ValueNotifier<Map<String, dynamic>?> rejectNotifier;
  final Set<String> checkedItems = {};
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    awbId = widget.awbItem['awb_id']?.toString();
    uldId = widget.awbItem['uld_id']?.toString();
    awbNumber = widget.awbItem['awb_number']?.toString() ?? widget.awbItem['uld_number']?.toString() ?? widget.awbItem['awb']?.toString() ?? 'N/A';
    deliverPieces = widget.awbItem['found']?.toString() ?? '0';
    totalPieces = widget.awbItem['total_pieces']?.toString() ?? widget.awbItem['pieces']?.toString() ?? '0';
    
    foundNotifier = ValueNotifier<int>(0);
    rejectNotifier = ValueNotifier<Map<String, dynamic>?>(null);
    _dataFuture = _fetchDetails();
  }

  Future<List<dynamic>> _fetchDetails() async {
    try {
      if (uldId != null && uldId!.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('ulds')
            .select('*, flights:id_flight(*)')
            .eq('id_uld', uldId!)
            .maybeSingle();
        if (res != null) return [res];
        return [];
      } else if (awbId != null && awbId!.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('awb_splits')
            .select('*, ulds(*), flights(*)')
            .eq('awb_id', awbId!);
        return List<dynamic>.from(res);
      } else {
        final res = await Supabase.instance.client
            .from('awbs')
            .select('id, awb_number, awb_splits(*, ulds(*), flights(*))')
            .eq('awb_number', awbNumber.replaceAll('AWB: ', '').replaceAll('ULD: ', ''))
            .maybeSingle();
        return List<dynamic>.from(res?['awb_splits'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching details: $e');
      return [];
    }
  }

  @override
  void dispose() {
    foundNotifier.dispose();
    rejectNotifier.dispose();
    super.dispose();
  }

  Widget _buildSummaryItem(String label, String value, Color textS, Color textP) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showEditFoundDialog(BuildContext context, int currentVal) {
    final TextEditingController ctrl = TextEditingController(text: currentVal.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          title: Text('Edit Found Pieces', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: widget.dark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Pieces',
              hintStyle: TextStyle(color: widget.dark ? Colors.white54 : Colors.black54),
              filled: true,
              fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(ctrl.text);
                if (val != null) {
                  foundNotifier.value = val;
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      }
    );
  }

  void _showRejectDialog(BuildContext context) {
    final Map<String, dynamic>? currentRej = rejectNotifier.value;
    final TextEditingController qtyCtrl = TextEditingController(text: currentRej?['qty']?.toString() ?? '');
    final TextEditingController reasonCtrl = TextEditingController(text: currentRej?['reason']?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          title: Text('Reject Pieces', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: widget.dark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Rejected Quantity',
                  labelStyle: TextStyle(color: widget.dark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: TextStyle(color: widget.dark ? Colors.white : Colors.black),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: TextStyle(color: widget.dark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            if (currentRej != null)
              TextButton(
                onPressed: () {
                  rejectNotifier.value = null;
                  Navigator.pop(ctx);
                },
                child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
              ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty > 0 && reasonCtrl.text.trim().isNotEmpty) {
                  rejectNotifier.value = {
                    'qty': qty,
                    'reason': reasonCtrl.text.trim(),
                    'user': currentUserData.value?['full_name'] ?? 'Unknown',
                    'time': DateTime.now().toIso8601String(),
                  };
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      }
    );
  }

  void _showRejectDetailsDialog(BuildContext context, Map<String, dynamic> rejectData) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Rejection Details', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold))),
              IconButton(
                onPressed: () {
                  rejectNotifier.value = null;
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Pieces Rejected:', rejectData['qty']?.toString() ?? '0'),
              const SizedBox(height: 8),
              _detailRow('Reason:', rejectData['reason']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _detailRow('User:', rejectData['user']?.toString() ?? 'Unknown'),
              const SizedBox(height: 8),
              _detailRow('Time:', _formatTime(rejectData['time']?.toString() ?? '')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      }
    );
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $ampm';
    } catch (e) {
      return isoString;
    }
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: widget.dark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 13))),
      ],
    );
  }

  Future<void> _executeDelivery() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6))),
      );

      final isUld = uldId != null && uldId!.isNotEmpty;
      final itemId = isUld ? uldId : awbId;

      await Supabase.instance.client.rpc(
        'execute_driver_delivery',
        params: {
          'p_item_id': itemId,
          'p_item_number': awbNumber,
          'p_is_uld': isUld,
          'p_pieces': foundNotifier.value,
          'p_reject_data': rejectNotifier.value,
          'p_company': widget.company,
          'p_door': widget.deliveryData['door']?.toString() ?? '-',
          'p_type': widget.deliveryData['type']?.toString() ?? '-',
          'p_id_pickup': widget.deliveryData['id_pickup']?.toString() ?? '-',
          'p_id_delivery': widget.deliveryData['id_delivery'], // <-- NUEVO PARÁMETRO
          'p_user_name': currentUserData.value?['full_name'] ?? 'Unknown',
          'p_time': DateTime.now().toIso8601String(),
          'p_driver_name': widget.driver,
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context, true); // Close details dialog with success
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final bgDialog = widget.dark ? const Color(0xFF0f172a) : Colors.white;
    final bgGlassy = widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
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
                          color: const Color(0xFF3b82f6).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF3b82f6), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(uldId != null ? 'ULD Details' : 'AWB Details', style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(awbNumber, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: textS),
                        hoverColor: Colors.white.withAlpha(10),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderC),
                
                // Summary Info
                Container(
                  padding: const EdgeInsets.all(20),
                  color: bgGlassy,
                  child: ValueListenableBuilder<int>(
                    valueListenable: foundNotifier,
                    builder: (ctx, foundVal, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Deliver', '$deliverPieces Pcs', textS, textP),
                          Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Found', style: TextStyle(color: textS, fontSize: 11)),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _showEditFoundDialog(context, foundVal),
                                    child: Icon(Icons.edit_rounded, color: textS.withAlpha(150), size: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _showEditFoundDialog(context, foundVal),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    '$foundVal', 
                                    style: TextStyle(
                                      color: foundVal.toString() == deliverPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), 
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ValueListenableBuilder<Map<String, dynamic>?>(
                            valueListenable: rejectNotifier,
                            builder: (ctx, rejectData, _) {
                              return Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Reject', style: TextStyle(color: textS, fontSize: 11)),
                                      if (rejectData != null) ...[
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _showRejectDetailsDialog(context, rejectData),
                                          child: Icon(Icons.warning_amber_rounded, color: const Color(0xFFef4444).withAlpha(200), size: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${rejectData?['qty'] ?? 0}', 
                                    style: const TextStyle(color: Color(0xFFef4444), fontSize: 16, fontWeight: FontWeight.bold)
                                  ),
                                ],
                              );
                            }
                          ),
                          _buildSummaryItem('Total', totalPieces, textS, textP),
                        ],
                      );
                    }
                  ),
                ),
                Divider(height: 1, color: borderC),

                // FutureBuilder for awb_splits or ulds
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6)));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading details.', style: TextStyle(color: textS)));
                      }
                      
                      final List<dynamic> splits = snapshot.data ?? [];
                      
                      if (splits.isEmpty) {
                        return Center(child: Text('No information found.', style: TextStyle(color: textS)));
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: splits.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final split = splits[index];
                          
                          return DriverV2AwbSplitCard(
                            split: split,
                            awbNumber: awbNumber,
                            dark: widget.dark,
                            index: index,
                            isCollapsed: collapsedSplits.contains(index),
                            onToggleCollapse: () {
                              setState(() {
                                if (collapsedSplits.contains(index)) {
                                  collapsedSplits.remove(index);
                                } else {
                                  collapsedSplits.add(index);
                                }
                              });
                            },
                            checkedItems: checkedItems,
                            selectedLocations: selectedLocations,
                            foundNotifier: foundNotifier,
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgDialog,
                    border: Border(top: BorderSide(color: borderC)),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: foundNotifier,
                    builder: (context, foundVal, _) {
                      return ValueListenableBuilder<Map<String, dynamic>?>(
                        valueListenable: rejectNotifier,
                        builder: (context, rejectData, _) {
                          int rejectQty = rejectData != null ? (int.tryParse(rejectData['qty'].toString()) ?? 0) : 0;
                          int targetPieces = int.tryParse(deliverPieces) ?? 0;
                          bool canDeliver = (foundVal + rejectQty) == targetPieces;
                          
                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showRejectDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.dark ? Colors.white.withAlpha(5) : Colors.grey.shade100,
                                    foregroundColor: Colors.redAccent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: canDeliver ? _executeDelivery : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3b82f6),
                                    disabledBackgroundColor: widget.dark ? Colors.white.withAlpha(5) : Colors.grey.shade200,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: textS.withAlpha(100),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.local_shipping_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Deliver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
