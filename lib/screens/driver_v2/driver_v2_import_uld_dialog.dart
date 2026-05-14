import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage, currentUserData;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_v2_import_awb_dialog.dart';

Future<bool?> showDriverImportUldDialog({
  required BuildContext context,
  required Map<String, dynamic> uldItem,
  required Map<String, dynamic> deliveryData,
  required String company,
  required String driver,
  required bool dark,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return DriverV2ImportUldDialogScreen(
        uldItem: uldItem,
        deliveryData: deliveryData,
        company: company,
        driver: driver,
        dark: dark,
      );
    },
  );
}

class DriverV2ImportUldDialogScreen extends StatefulWidget {
  final Map<String, dynamic> uldItem;
  final Map<String, dynamic> deliveryData;
  final String company;
  final String driver;
  final bool dark;

  const DriverV2ImportUldDialogScreen({
    super.key,
    required this.uldItem,
    required this.deliveryData,
    required this.company,
    required this.driver,
    required this.dark,
  });

  @override
  State<DriverV2ImportUldDialogScreen> createState() => _DriverV2ImportUldDialogScreenState();
}

class _DriverV2ImportUldDialogScreenState extends State<DriverV2ImportUldDialogScreen> {
  late String uldNumber;
  late String deliverPieces;
  late String weight;
  late String remarks;
  late bool isBreak;
  late List<dynamic> nestedAwbs;

  // Track checked-in AWBs if it's a Break ULD
  final Set<String> _checkedInAwbs = {};
  
  // Track master check-in for No Break ULD
  bool _noBreakCheckedIn = false;

  @override
  void initState() {
    super.initState();
    uldNumber = widget.uldItem['uld_number']?.toString() ?? 'N/A';
    deliverPieces = widget.uldItem['found']?.toString() ?? '0';
    weight = widget.uldItem['weight']?.toString() ?? '0';
    remarks = widget.uldItem['remarks']?.toString() ?? '';
    isBreak = widget.uldItem['is_break'] == true;
    nestedAwbs = widget.uldItem['nested_awbs'] as List<dynamic>? ?? [];
    
    // Check if some nested AWBs were already checked in previously (we can read 'is_delivered_now' if we implemented it, or we can just assume none are checked in when opening)
    for (var awb in nestedAwbs) {
      if (awb is Map && awb['is_delivered_now'] == true) {
        _checkedInAwbs.add(awb['awb_number']?.toString() ?? '');
      }
    }
  }

  bool _isAllCheckedIn() {
    if (isBreak) {
      if (nestedAwbs.isEmpty) return false;
      return _checkedInAwbs.length == nestedAwbs.length;
    } else {
      return _noBreakCheckedIn;
    }
  }

  Future<void> _submitUld() async {
    if (!_isAllCheckedIn()) return;
    
    if (!isBreak) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6))),
        );
        
        final payload = {
          'uld_number': uldNumber,
          'weight': double.tryParse(weight) ?? 0.0,
          'remarks': remarks,
          'user_id': Supabase.instance.client.auth.currentUser?.id,
          'user_received': currentUserData.value?['full_name'] ?? 'Unknown User',
          'pieces_total': int.tryParse(deliverPieces) ?? 0,
          'nested_awbs': nestedAwbs,
        };

        await Supabase.instance.client.rpc(
          'rpc_save_import_uld_delivery',
          params: {'payload': payload},
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Stop submission on error
      }
    }

    // Set properties to update locally
    widget.uldItem['is_delivered_now'] = true;
    for (var awb in nestedAwbs) {
      if (awb is Map) {
        awb['is_delivered_now'] = true;
      }
    }

    Navigator.pop(context, true);
  }

  Widget _buildSummaryItem(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dark = widget.dark;
    final es = appLanguage.value == 'es';
    final isAllChecked = _isAllCheckedIn();

    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
    final bgGlassy = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    // Calculate checked pieces for summary
    int checkedPieces = 0;
    if (isBreak) {
      for (var nestedItem in nestedAwbs) {
        if (nestedItem is Map) {
          final awbNum = nestedItem['awb_number']?.toString() ?? '';
          if (_checkedInAwbs.contains(awbNum) || nestedItem['is_delivered_now'] == true) {
            checkedPieces += int.tryParse(nestedItem['found']?.toString() ?? '0') ?? 0;
          }
        }
      }
    } else {
      if (_noBreakCheckedIn) {
        checkedPieces = int.tryParse(deliverPieces) ?? 0;
      }
    }

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
                        child: const Icon(Icons.pallet, color: Color(0xFF3b82f6), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(es ? 'Detalles de ULD (Importación)' : 'ULD Details (Import)', style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(uldNumber, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: Icon(Icons.close_rounded, color: textS),
                        hoverColor: Colors.white.withAlpha(10),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderC),
                
                // Summary Info (matching AWB style)
                Container(
                  padding: const EdgeInsets.all(20),
                  color: bgGlassy,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Import', '$deliverPieces Pcs', textS, textP),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Checked', style: TextStyle(color: textS, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              '$checkedPieces', 
                              style: TextStyle(
                                color: checkedPieces.toString() == deliverPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), 
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ),
                        ],
                      ),
                      _buildSummaryItem('Items', '${nestedAwbs.length} AWBs', textS, textP),
                      _buildSummaryItem('Weight', '$weight kg', textS, textP),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderC),
                
                // Sub-header for list
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(
                    isBreak ? 'NESTED AWBS (BREAK)' : 'NESTED AWBS (NO BREAK)',
                    style: const TextStyle(color: Color(0xFFef4444), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),

                // Nested AWBs List
                Expanded(
                  child: nestedAwbs.isEmpty
                      ? Center(
                          child: Text(
                            es ? 'No hay AWBs anidados en este ULD.' : 'No nested AWBs in this ULD.',
                            style: TextStyle(color: textS),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: nestedAwbs.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final nestedItem = nestedAwbs[i];
                            if (nestedItem is! Map) return const SizedBox();

                            final String awbNum = nestedItem['awb_number']?.toString() ?? 'N/A';
                            final String pcs = nestedItem['found']?.toString() ?? '0';
                            final String wgt = nestedItem['weight']?.toString() ?? '0';
                            final bool isChecked = _checkedInAwbs.contains(awbNum) || nestedItem['is_delivered_now'] == true;

                            return InkWell(
                              onTap: isBreak && !isChecked ? () async {
                                final success = await showDriverImportAwbDialog(
                                  context: context,
                                  awbItem: Map<String, dynamic>.from(nestedItem),
                                  deliveryData: widget.deliveryData,
                                  company: widget.company,
                                  driver: widget.driver,
                                  dark: dark,
                                );
                                if (success == true) {
                                  setState(() {
                                    nestedItem['is_delivered_now'] = true;
                                    _checkedInAwbs.add(awbNum);
                                  });
                                }
                              } : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: bgGlassy,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isChecked 
                                        ? const Color(0xFF10b981)
                                        : borderC,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AWB: $awbNum',
                                            style: TextStyle(
                                              color: textP,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pcs: $pcs | Wgt: $wgt kg',
                                            style: TextStyle(color: textS, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isChecked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10b981).withAlpha(30),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              es ? 'Recibido' : 'Received',
                                              style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (isBreak)
                                      Icon(Icons.chevron_right_rounded, color: textS),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                Divider(height: 1, color: borderC),
                
                // Footer Action
                Container(
                  padding: const EdgeInsets.all(20),
                  color: bgGlassy,
                  child: Row(
                    children: [
                      if (!isBreak) ...[
                        // No Break -> Checkbox
                        InkWell(
                          onTap: () => setState(() => _noBreakCheckedIn = !_noBreakCheckedIn),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Icon(
                                _noBreakCheckedIn ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: _noBreakCheckedIn ? const Color(0xFF10b981) : textS,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                es ? 'Confirmar recepción del ULD' : 'Confirm ULD receipt',
                                style: TextStyle(
                                  color: textP,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      ElevatedButton(
                        onPressed: isAllChecked ? _submitUld : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAllChecked ? const Color(0xFF3b82f6) : borderC,
                          foregroundColor: isAllChecked ? Colors.white : textS,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          es ? 'Confirmar Check-In' : 'Confirm Check-In',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
