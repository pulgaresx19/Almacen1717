import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart' show appLanguage;
import 'coordinator_v2_awb_modal_widgets.dart';
import 'coordinator_v2_awb_dialog_logic.dart';

class CoordinatorV2AwbDialog extends StatefulWidget {
  final Map<String, dynamic> combined;
  final Map<String, dynamic> awbSplit;
  final bool dark;
  final bool isReadOnly;

  const CoordinatorV2AwbDialog({
    super.key,
    required this.combined,
    required this.awbSplit,
    required this.dark,
    this.isReadOnly = false,
  });

  @override
  State<CoordinatorV2AwbDialog> createState() => _CoordinatorV2AwbDialogState();
}

class _CoordinatorV2AwbDialogState extends State<CoordinatorV2AwbDialog> {
  late final CoordinatorV2AwbDialogLogic logic;

  @override
  void initState() {
    super.initState();
    logic = CoordinatorV2AwbDialogLogic(widget.combined, widget.awbSplit);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);
    final bgModal = widget.dark ? const Color(0xFF0f172a) : Colors.white;

    final awbNumber = widget.combined['awb_number']?.toString() ?? '-';
    final pieces = widget.awbSplit['pieces']?.toString() ?? widget.awbSplit['pieces_split']?.toString() ?? '0';
    final weight = widget.awbSplit['weight']?.toString() ?? widget.awbSplit['weight_split']?.toString() ?? '0';
    final totalPieces = widget.combined['total_pieces']?.toString() ?? widget.combined['pieces']?.toString() ?? '0';

    int houseCount = 0;
    if (widget.combined['house_number'] != null) {
      if (widget.combined['house_number'] is List) {
        houseCount = (widget.combined['house_number'] as List).length;
      } else {
        final str = widget.combined['house_number'].toString().trim();
        houseCount = str.isNotEmpty && str != '-' ? str.split(',').length : 0;
      }
    }
    
    final remarks = widget.combined['remarks']?.toString() ?? '';

    final dynamic d = widget.awbSplit['data_coordinator'];
    bool hasDiscrepancy = false;
    String? discAmount;
    String? discType;
    bool isNotFound = false;
    
    if (d is Map) {
      if (d['not_found'] == true) isNotFound = true;
      if (d['discrepancy_amount'] != null) {
        hasDiscrepancy = true;
        discAmount = d['discrepancy_amount'].toString();
        discType = d['discrepancy_type']?.toString();
      }
    } else if (d is String && d.trim().isNotEmpty && d != 'null') {
      try {
        final parsed = jsonDecode(d);
        if (parsed['not_found'] == true) isNotFound = true;
        if (parsed['discrepancy_amount'] != null) {
          hasDiscrepancy = true;
          discAmount = parsed['discrepancy_amount'].toString();
          discType = parsed['discrepancy_type']?.toString();
        }
      } catch (_) {}
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: logic,
        builder: (context, child) {
          return Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgModal,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appLanguage.value == 'es' ? 'Detalles de AWB' : 'AWB Details',
                          style: TextStyle(color: textS, fontSize: 13),
                        ),
                        Text(
                          awbNumber,
                          style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (isNotFound)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444).withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  appLanguage.value == 'es' ? 'NO ENCONTRADO' : 'NOT FOUND',
                                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        else if (hasDiscrepancy && discAmount != null && discType != null)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444).withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$discAmount $discType',
                                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: textS),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    buildDetailItem(appLanguage.value == 'es' ? 'Piezas' : 'Pieces', pieces, textP, textS, bgCard),
                    buildDetailItem('Total', totalPieces, textP, textS, bgCard),
                    buildDetailItem(appLanguage.value == 'es' ? 'Peso' : 'Weight', '$weight kg', textP, textS, bgCard),
                    buildHouseItem(houseCount, textP, textS, bgCard),
                  ],
                ),
                const SizedBox(height: 16),
                buildDetailItem(appLanguage.value == 'es' ? 'Comentarios' : 'Remarks', remarks.trim().isEmpty ? '-' : remarks, textP, textS, bgCard, isFullWidth: true),
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Total checked', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(20), borderRadius: BorderRadius.circular(12)),
                          child: Text('${logic.getTotalChecked()}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: widget.isReadOnly ? null : () => logic.toggleNotFound(),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: logic.notFoundSelected ? const Color(0xFFEF4444).withAlpha(20) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: logic.notFoundSelected 
                              ? const Color(0xFFEF4444).withAlpha(50) 
                              : (widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))
                          ),
                        ),
                        child: Text('Not found', style: TextStyle(color: logic.notFoundSelected ? const Color(0xFFEF4444) : textS, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (logic.selectedType == 2)
                      buildLocationSection(widget.dark, bgCard, bgModal, textP, textS, logic.selectedLocation, logic.locationOtherCtrl, (loc) {
                        logic.setLocation(loc);
                      }, widget.isReadOnly || logic.notFoundSelected)
                    else if (logic.selectedType == 1)
                      buildDamageSection(widget.dark, bgCard, bgModal, textP, textS, logic.selectedDamages, (damages) {
                        logic.setDamages(damages);
                      }, logic.localPhotos, () => logic.pickImageLocally(ImageSource.gallery), () => logic.pickImageLocally(ImageSource.camera), (idx) {
                        logic.removePhoto(idx);
                      }, widget.isReadOnly || logic.notFoundSelected, logic.piecesDamageCtrl)
                    else if (logic.selectedType == 3)
                      buildNotesSection(widget.dark, bgCard, textP, textS, logic.notesCtrl, widget.isReadOnly || logic.notFoundSelected)
                    else ...[
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            buildTextFieldBlock('AGI skid', textP, textS, bgCard, widget.dark, logic.agiSkidCtrl, () => logic.addItem('AGI skid', logic.agiSkidCtrl), widget.isReadOnly || logic.notFoundSelected),
                            const SizedBox(height: 12),
                            buildTextFieldBlock('Pre skid', textP, textS, bgCard, widget.dark, logic.preSkidCtrl, () => logic.addItem('Pre skid', logic.preSkidCtrl), widget.isReadOnly || logic.notFoundSelected),
                            const SizedBox(height: 12),
                            buildTextFieldBlock('Crate', textP, textS, bgCard, widget.dark, logic.crateCtrl, () => logic.addItem('Crate', logic.crateCtrl), widget.isReadOnly || logic.notFoundSelected),
                            const SizedBox(height: 12),
                            buildTextFieldBlock('Box', textP, textS, bgCard, widget.dark, logic.boxCtrl, () => logic.addItem('Box', logic.boxCtrl), widget.isReadOnly || logic.notFoundSelected),
                            const SizedBox(height: 12),
                            buildTextFieldBlock('Other', textP, textS, bgCard, widget.dark, logic.otherCtrl, () => logic.addItem('Other', logic.otherCtrl), widget.isReadOnly || logic.notFoundSelected),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: logic.addedItems.isEmpty 
                            ? Center(
                                child: Text(
                                  appLanguage.value == 'es' ? 'Lista de ítems' : 'Item List',
                                  style: TextStyle(color: textS),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(8),
                                children: () {
                                  final List<Widget> listWidgets = [];
                                  final agiSkids = logic.addedItems.where((e) => e['category'] == 'AGI skid').toList();
                                  
                                  Widget buildItemRow(Map<String, dynamic> item) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: widget.dark ? Colors.white.withAlpha(10) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(item['displayLabel'] ?? item['category'], style: TextStyle(color: textS, fontSize: 11)),
                                              const SizedBox(width: 8),
                                              Text(item['value'].toString(), style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          if (!widget.isReadOnly && !logic.notFoundSelected)
                                            InkWell(
                                              onTap: () => logic.removeItem(item),
                                              child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
                                            )
                                        ],
                                      ),
                                    );
                                  }

                                  if (agiSkids.isNotEmpty) {
                                    listWidgets.add(
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: widget.dark ? const Color(0xFF6366f1).withAlpha(15) : const Color(0xFFe0e7ff),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF6366f1).withAlpha(50)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                                              child: Text('AGI SKIDS', style: TextStyle(color: const Color(0xFF6366f1), fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                            ...agiSkids.map((item) => buildItemRow(item)),
                                          ],
                                        )
                                      )
                                    );
                                  }

                                  for (String cat in ['Pre skid', 'Crate', 'Box', 'Other']) {
                                    final itemsCat = logic.addedItems.where((e) => e['category'] == cat).toList();
                                    if (itemsCat.isNotEmpty) {
                                      listWidgets.add(buildItemRow(itemsCat.first));
                                    }
                                  }

                                  return listWidgets;
                                }(),
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          buildSelectorIcon(0, logic.selectedType, Icons.check_circle, const Color(0xFF10B981), textS, () => logic.setType(0)),
                          const SizedBox(height: 12),
                          buildSelectorIcon(2, logic.selectedType, Icons.location_on_outlined, const Color(0xFF3B82F6), textS, () => logic.setType(2)),
                          const SizedBox(height: 12),
                          buildSelectorIcon(1, logic.selectedType, Icons.warning_rounded, const Color(0xFFEF4444), textS, () => logic.setType(1)),
                          const SizedBox(height: 12),
                          buildSelectorIcon(3, logic.selectedType, Icons.notes_rounded, const Color(0xFFF59E0B), textS, () => logic.setType(3)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Builder(
                  builder: (context) {
                    String checkedText = appLanguage.value == 'es' ? 'Chequeado' : 'Checked';
                    if (widget.isReadOnly && widget.awbSplit['data_coordinator'] is Map) {
                      final data = widget.awbSplit['data_coordinator'] as Map;
                      final pb = data['processed_by'];
                      final pa = data['processed_at'];
                      if (pb != null && pa != null) {
                        try {
                          final dt = DateTime.parse(pa.toString()).toLocal();
                          int hr = dt.hour;
                          String ampm = hr >= 12 ? 'PM' : 'AM';
                          if (hr > 12) hr -= 12;
                          if (hr == 0) hr = 12;
                          final timeStr = "${hr.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm";
                          if (appLanguage.value == 'es') {
                            checkedText = 'Chequeado por $pb a las $timeStr';
                          } else {
                            checkedText = 'Checked by $pb at $timeStr';
                          }
                        } catch (_) {}
                      }
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (logic.isSaving || widget.isReadOnly) ? null : () => logic.handleSave(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isReadOnly ? const Color(0xFF10b981).withAlpha(20) : (logic.hasExistingData ? const Color(0xFF3B82F6) : const Color(0xFF6366f1)),
                          foregroundColor: widget.isReadOnly ? const Color(0xFF059669) : Colors.white,
                          disabledBackgroundColor: widget.isReadOnly ? const Color(0xFF10b981).withAlpha(20) : null,
                          disabledForegroundColor: widget.isReadOnly ? const Color(0xFF059669) : null,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: logic.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              widget.isReadOnly 
                                ? checkedText
                                : (logic.hasExistingData
                                    ? (appLanguage.value == 'es' ? 'Editar' : 'Edit')
                                    : (appLanguage.value == 'es' ? 'Guardar' : 'Save')),
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold,
                                color: widget.isReadOnly ? const Color(0xFF059669) : Colors.white,
                              ),
                            ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}
