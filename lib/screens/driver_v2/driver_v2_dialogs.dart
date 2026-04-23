import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show currentUserData;

class DriverV2Dialogs {
  static void showNoBreakInfoDialog({
    required BuildContext context,
    required Map uldData,
    required String uldName,
    required bool dark,
  }) {
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
    final bgGlassy = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    String timeReceived = uldData['time_received']?.toString() ?? 'N/A';
    if (timeReceived != 'N/A') {
      try {
        DateTime dt = DateTime.parse(timeReceived).toLocal();
        timeReceived = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (e) {
        // Keep original if it fails
      }
    }
    String userReceived = uldData['user_received']?.toString() ?? 'N/A';
    String weight = uldData['weight_total']?.toString() ?? uldData['weight']?.toString() ?? 'N/A';
    String pieces = uldData['pieces_total']?.toString() ?? uldData['pieces']?.toString() ?? 'N/A';
    String uldId = uldData['id']?.toString() ?? uldData['id_uld']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 475,
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
                              color: const Color(0xFF94a3b8).withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline_rounded, color: Color(0xFF94a3b8), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('NO BREAK DETAILS', style: TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('ULD: $uldName', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(Icons.close_rounded, color: textS),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: borderC),
                    // ULD Summary Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: bgGlassy,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Pieces', style: TextStyle(color: textS, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('$pieces pcs', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                Text('Received By', style: TextStyle(color: textS, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(userReceived, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 60, color: borderC),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weight', style: TextStyle(color: textS, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('$weight kg', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                Text('Time Received', style: TextStyle(color: textS, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(timeReceived, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: borderC),
                    // AWBs List Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text('AWBs in this ULD', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    // FutureBuilder for AWBs
                    Flexible(
                      child: uldId.isEmpty
                          ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No ULD ID found.', style: TextStyle(color: textS))))
                          : FutureBuilder<List<dynamic>>(
                              future: Supabase.instance.client
                                  .from('awb_splits')
                                  .select('id, awb_id, pieces, weight, awbs(awb_number)')
                                  .eq('uld_id', uldId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(30),
                                    child: Center(child: CircularProgressIndicator(color: Color(0xFF94a3b8))),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: textS))),
                                  );
                                }
                                final splits = snapshot.data ?? [];
                                if (splits.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(child: Text('No AWBs found.', style: TextStyle(color: textS))),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  itemCount: splits.length,
                                  separatorBuilder: (ctx, i) => Divider(height: 1, color: borderC),
                                  itemBuilder: (ctx, i) {
                                    final sp = splits[i];
                                    final awbMap = sp['awbs'];
                                    final awbNum = (awbMap is Map && awbMap['awb_number'] != null) ? awbMap['awb_number'] : 'Unknown AWB';
                                    final itemPieces = sp['pieces'] ?? (awbMap is Map ? awbMap['pieces'] : null) ?? 0;
                                    final itemWeight = sp['weight'] ?? (awbMap is Map ? awbMap['weight'] : null) ?? 0;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 16, color: textS),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: Text(awbNum.toString(), style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w500)),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text('$itemPieces pcs', textAlign: TextAlign.center, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text('$itemWeight kg', textAlign: TextAlign.right, style: TextStyle(color: textS, fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void showCheckItemDialog({
    required BuildContext context,
    required Map split,
    required String awbNumber,
    required bool dark,
    VoidCallback? onUpdate,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _CheckItemDialogContent(
        split: split,
        awbNumber: awbNumber,
        dark: dark,
        onUpdate: onUpdate,
      ),
    );
  }
}

class _CheckItemDialogContent extends StatefulWidget {
  final Map split;
  final String awbNumber;
  final bool dark;
  final VoidCallback? onUpdate;

  const _CheckItemDialogContent({
    required this.split,
    required this.awbNumber,
    required this.dark,
    this.onUpdate,
  });

  @override
  State<_CheckItemDialogContent> createState() => _CheckItemDialogContentState();
}

class _CheckItemDialogContentState extends State<_CheckItemDialogContent> {
  final TextEditingController _agiSkidController = TextEditingController();
  final TextEditingController _preSkidController = TextEditingController();
  final TextEditingController _crateController = TextEditingController();
  final TextEditingController _boxesController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();

  List<int> agiSkids = [];
  int? preSkid;
  int? crate;
  int? boxes;
  int? other;

  bool _showDiscrepancy = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _agiSkidController.dispose();
    _preSkidController.dispose();
    _crateController.dispose();
    _boxesController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _addValue(TextEditingController ctrl, Function(int) onAdd) {
    if (ctrl.text.isNotEmpty) {
      setState(() {
        onAdd(int.parse(ctrl.text));
        ctrl.clear();
      });
    }
  }

  Future<void> _saveData({bool isDiscrepancy = false}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      String expectedPiecesStr = widget.split['pieces']?.toString() ?? widget.split['pieces_total']?.toString() ?? '0';
      int expected = int.tryParse(expectedPiecesStr) ?? 0;
      int totalEntered = agiSkids.fold(0, (sum, val) => sum + val) + (preSkid ?? 0) + (crate ?? 0) + (boxes ?? 0) + (other ?? 0);

      Map<String, dynamic> report = {};
      
      // Breakdown data (excluding nulls)
      for (int i = 0; i < agiSkids.length; i++) {
        report['${i + 1}. AGI skid'] = agiSkids[i];
      }
      if (preSkid != null) report['Pre skid'] = preSkid;
      if (crate != null) report['Crate'] = crate;
      if (boxes != null) report['Box'] = boxes;
      if (other != null) report['Other'] = other;

      // Audit data
      final now = DateTime.now().toUtc().toIso8601String();
      final user = Supabase.instance.client.auth.currentUser;
      final userName = currentUserData.value?['full-name'] ?? user?.email ?? 'Unknown Driver';

      report['processed_at'] = now;
      report['processed_by'] = userName;
      report['check_source'] = 'Driver Pick Up';

      // Discrepancy details
      if (isDiscrepancy) {
        String diffType = totalEntered > expected ? 'OVER' : 'SHORT';
        int diffAmount = (totalEntered - expected).abs();
        
        report['discrepancy_type'] = diffType;
        report['discrepancy_amount'] = diffAmount;
        report['discrepancy_checked'] = totalEntered;
        report['discrepancy_expected'] = expected;

        // Update ulds table discrepancies_summary
        String uldId = widget.split['uld_id']?.toString() ?? widget.split['id_uld']?.toString() ?? '';
        if (uldId.isNotEmpty) {
           final uldRes = await Supabase.instance.client
               .from('ulds')
               .select('discrepancies_summary')
               .eq('id_uld', uldId)
               .maybeSingle();
               
           if (uldRes != null) {
               List<dynamic> discSum = [];
               if (uldRes['discrepancies_summary'] is List) {
                   discSum = List.from(uldRes['discrepancies_summary']);
               } else if (uldRes['discrepancies_summary'] != null) {
                   discSum = [uldRes['discrepancies_summary']];
               }
               
               discSum.add({
                   'awb': widget.awbNumber,
                   'type': diffType,
                   'amount': diffAmount,
               });
               
               await Supabase.instance.client
                   .from('ulds')
                   .update({'discrepancies_summary': discSum})
                   .eq('id_uld', uldId);
           }
        }
      }

      // Merge with existing data_coordinator
      var existingData = widget.split['data_coordinator'];
      List<dynamic> updatedCoordinatorList = [];
      if (existingData is List) {
        updatedCoordinatorList = List.from(existingData);
      } else if (existingData is Map && existingData.isNotEmpty) {
        updatedCoordinatorList = [existingData];
      }
      updatedCoordinatorList.add(report);

      // Handle total_checked
      int currentTotalChecked = 0;
      if (widget.split['total_checked'] != null) {
        currentTotalChecked = int.tryParse(widget.split['total_checked'].toString()) ?? 0;
      }
      int newTotalChecked = currentTotalChecked + totalEntered;

      // Update Supabase
      final splitId = widget.split['id'] ?? widget.split['awb_id']; // Usually id is the split id
      
      await Supabase.instance.client
          .from('awb_splits')
          .update({
            'data_coordinator': updatedCoordinatorList,
            'total_checked': newTotalChecked,
          })
          .eq('id', splitId);

      // Update local state
      widget.split['data_coordinator'] = updatedCoordinatorList;
      widget.split['total_checked'] = newTotalChecked;
      
      if (widget.onUpdate != null) {
        widget.onUpdate!();
      }

      if (mounted) {
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildRow(String label, TextEditingController ctrl, Color inputBg, Color borderC, Color textP, Color textS, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderC),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: textP, fontSize: 14),
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF4f46e5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgiSkidsBox(Color inputBg, Color borderC, Color textP, Color textS) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.dark ? const Color(0xFF1e293b).withAlpha(100) : const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4f46e5).withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AGI SKIDS', style: TextStyle(color: Color(0xFF4f46e5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...agiSkids.asMap().entries.map((e) {
            int idx = e.key;
            int val = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderC),
              ),
              child: Row(
                children: [
                  Text('${idx + 1}. Skid', style: TextStyle(color: textS, fontSize: 11)),
                  const Spacer(),
                  Text(val.toString(), style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => agiSkids.removeAt(idx)),
                    child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSingleItemBox(String label, int val, Color inputBg, Color borderC, Color textP, Color textS, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderC),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: textS, fontSize: 11), overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(val.toString(), style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final bgDialog = widget.dark ? const Color(0xFF0f172a) : Colors.white;
    final bgGlassy = widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final inputBg = widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6);

    String expectedPieces = widget.split['pieces']?.toString() ?? widget.split['pieces_total']?.toString() ?? '0';
    int expected = int.tryParse(expectedPieces) ?? 0;
    
    int totalEntered = agiSkids.fold(0, (sum, val) => sum + val) + (preSkid ?? 0) + (crate ?? 0) + (boxes ?? 0) + (other ?? 0);
    Color counterColor = totalEntered == expected ? const Color(0xFF10b981) : const Color(0xFFf59e0b);

    int diffAmount = (totalEntered - expected).abs();
    String diffType = totalEntered > expected ? 'OVER' : 'SHORT';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 475,
            color: bgDialog,
            child: Stack(
              children: [
                Column(
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
                        child: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF3b82f6), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CHECK ITEM', style: TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('AWB: ${widget.awbNumber}', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: textS),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderC),
                // Item Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: bgGlassy,
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: textS),
                      const SizedBox(width: 8),
                      Text('Expected Pieces:', style: TextStyle(color: textS, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(expectedPieces, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('Count: ', style: TextStyle(color: textS, fontSize: 13)),
                      Text(totalEntered.toString(), style: TextStyle(color: counterColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderC),
                // Form Fields & Results (Two Columns squeezed to 400px)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Inputs
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRow('AGI skid', _agiSkidController, inputBg, borderC, textP, textS, () => _addValue(_agiSkidController, (val) => agiSkids.add(val))),
                              _buildRow('Pre skid', _preSkidController, inputBg, borderC, textP, textS, () => _addValue(_preSkidController, (val) => preSkid = val)),
                              _buildRow('Crate', _crateController, inputBg, borderC, textP, textS, () => _addValue(_crateController, (val) => crate = val)),
                              _buildRow('Box', _boxesController, inputBg, borderC, textP, textS, () => _addValue(_boxesController, (val) => boxes = val)),
                              _buildRow('Other', _otherController, inputBg, borderC, textP, textS, () => _addValue(_otherController, (val) => other = val)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      // Right Column: Results
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (agiSkids.isNotEmpty) _buildAgiSkidsBox(inputBg, borderC, textP, textS),
                              if (preSkid != null) _buildSingleItemBox('Pre skid', preSkid!, inputBg, borderC, textP, textS, () => setState(() => preSkid = null)),
                              if (crate != null) _buildSingleItemBox('Crate', crate!, inputBg, borderC, textP, textS, () => setState(() => crate = null)),
                              if (boxes != null) _buildSingleItemBox('Box', boxes!, inputBg, borderC, textP, textS, () => setState(() => boxes = null)),
                              if (other != null) _buildSingleItemBox('Other', other!, inputBg, borderC, textP, textS, () => setState(() => other = null)),
                              
                              if (agiSkids.isEmpty && preSkid == null && crate == null && boxes == null && other == null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.center,
                                  child: Text('No items yet', style: TextStyle(color: textS.withAlpha(100), fontStyle: FontStyle.italic, fontSize: 11)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                Divider(height: 1, color: borderC),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: textS, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSaving ? null : () {
                          if (totalEntered != expected) {
                            setState(() => _showDiscrepancy = true);
                          } else {
                            _saveData(isDiscrepancy: false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3b82f6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save & Check', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Discrepancy Overlay
            if (_showDiscrepancy)
              Container(
                color: bgDialog.withAlpha(240),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withAlpha(100)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        const Text('PIECE COUNT DISCREPANCY', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$diffAmount pieces $diffType', 
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text('Expected', style: TextStyle(color: textS, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('$expected', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: borderC,
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            Column(
                              children: [
                                Text('Entered', style: TextStyle(color: textS, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('$totalEntered', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _isSaving ? null : () => setState(() => _showDiscrepancy = false),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('Cancel', style: TextStyle(color: textS, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : () {
                                  _saveData(isDiscrepancy: true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isSaving 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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

