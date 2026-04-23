import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_v2_awb_split_card.dart';

void showDriverAwbDialog({
  required BuildContext context,
  required Map<String, dynamic> awbItem,
  required bool dark,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return DriverV2AwbDialogScreen(
        awbItem: awbItem,
        dark: dark,
      );
    },
  );
}

class DriverV2AwbDialogScreen extends StatefulWidget {
  final Map<String, dynamic> awbItem;
  final bool dark;

  const DriverV2AwbDialogScreen({
    super.key,
    required this.awbItem,
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
                              Text('Found', style: TextStyle(color: textS, fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.check_box_rounded, color: Color(0xFF10b981), size: 16),
                                  const SizedBox(width: 4),
                                  Text('$foundVal', style: const TextStyle(color: Color(0xFF10b981), fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          _buildSummaryItem('Reject', '0', textS, const Color(0xFFef4444)),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
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
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3b82f6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inventory_2_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Deliver AWB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
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
  }
}
