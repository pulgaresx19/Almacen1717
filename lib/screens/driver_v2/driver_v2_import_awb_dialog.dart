import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show currentUserData;
import 'import_components/data_coordinator_panel.dart';
import 'import_components/data_location_panel.dart';
import 'import_components/damage_information_panel.dart';
import 'package:image_picker/image_picker.dart';

Future<bool?> showDriverImportAwbDialog({
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
      return DriverV2ImportAwbDialogScreen(
        awbItem: awbItem,
        deliveryData: deliveryData,
        company: company,
        driver: driver,
        dark: dark,
      );
    },
  );
}

class DriverV2ImportAwbDialogScreen extends StatefulWidget {
  final Map<String, dynamic> awbItem;
  final Map<String, dynamic> deliveryData;
  final String company;
  final String driver;
  final bool dark;

  const DriverV2ImportAwbDialogScreen({
    super.key,
    required this.awbItem,
    required this.deliveryData,
    required this.company,
    required this.driver,
    required this.dark,
  });

  @override
  State<DriverV2ImportAwbDialogScreen> createState() => _DriverV2ImportAwbDialogScreenState();
}

class _DriverV2ImportAwbDialogScreenState extends State<DriverV2ImportAwbDialogScreen> {
  late String? awbId;
  late String? uldId;
  late String awbNumber;
  late String deliverPieces;
  late String totalPieces;

  final Set<int> collapsedSplits = {};
  final Set<String> selectedLocations = {};
  
  late ValueNotifier<int> foundNotifier;
  late ValueNotifier<Map<String, dynamic>?> rejectNotifier;
  final ValueNotifier<List<Map<String, dynamic>>> itemsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final TextEditingController remarksCtrl = TextEditingController();
  final GlobalKey<DamageInformationPanelState> _damagePanelKey = GlobalKey<DamageInformationPanelState>();

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
  }


  @override
  void dispose() {
    foundNotifier.dispose();
    rejectNotifier.dispose();
    itemsNotifier.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  void _updateFoundCount() {
    int total = 0;
    for (var item in itemsNotifier.value) {
      total += int.tryParse(item['value'].toString()) ?? 0;
    }
    foundNotifier.value = total;
  }

  void _onAddItem(String category, String value) {
    if (value.trim().isEmpty) return;
    
    final currentList = List<Map<String, dynamic>>.from(itemsNotifier.value);
    
    if (category != 'AGI Skid') {
      final existingIndex = currentList.indexWhere((item) => item['category'] == category);
      if (existingIndex != -1) {
        currentList[existingIndex] = {
          ...currentList[existingIndex],
          'value': value.trim(),
        };
      } else {
        currentList.add({
          'id': category, 
          'category': category,
          'value': value.trim(),
          'location': '',
        });
      }
    } else {
      currentList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'category': category,
        'value': value.trim(),
        'location': '',
      });
    }
    
    itemsNotifier.value = currentList;
    _updateFoundCount();
  }

  void _onUpdateLocation(String id, String location) {
    final currentList = List<Map<String, dynamic>>.from(itemsNotifier.value);
    final index = currentList.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      currentList[index]['location'] = location;
      itemsNotifier.value = currentList;
    }
  }

  void _onRemoveItem(String id) {
    final currentList = List<Map<String, dynamic>>.from(itemsNotifier.value);
    currentList.removeWhere((item) => item['id'] == id);
    itemsNotifier.value = currentList;
    _updateFoundCount();
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
                    'time': DateTime.now().toUtc().toIso8601String(),
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

  void _showRemarksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          title: Text('Add Remarks', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: remarksCtrl,
            style: TextStyle(color: widget.dark ? Colors.white : Colors.black),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter any extra information or remarks...',
              hintStyle: TextStyle(color: widget.dark ? Colors.white54 : Colors.black54),
              filled: true,
              fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
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

      final dmgState = _damagePanelKey.currentState;
      int piecesDamage = dmgState?.pieces ?? 0;
      List<String> selectedDamages = dmgState?.selectedDamages ?? [];
      String damageRemarks = dmgState?.remarks ?? '';
      List<String> photos = dmgState?.photos ?? [];

      List<String> uploadedUrls = [];
      if (photos.isNotEmpty) {
        for (var photoPath in photos) {
          if (photoPath.startsWith('http')) {
            uploadedUrls.add(photoPath);
          } else {
            final xfile = XFile(photoPath);
            final bytes = await xfile.readAsBytes();
            
            String ext = 'png';
            if (photoPath.contains('.')) {
              ext = photoPath.split('.').last.toLowerCase();
            }
            // En web, las URLs blob no tienen extensión válida. 
            // Esto evita que 'ext' sea igual a la URL completa (ej. blob:http://...)
            if (ext.length > 4 || ext.contains(RegExp(r'[^a-z0-9]'))) {
              ext = 'jpeg'; // JPEG es el default al usar compresión en image_picker
            }
            
            final mimeExt = ext == 'jpg' ? 'jpeg' : ext;
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${Supabase.instance.client.auth.currentUser?.id ?? 'user'}.$ext';
            final path = 'public/$fileName';

            await Supabase.instance.client.storage.from('damage_reports').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$mimeExt'),
            );

            final url = Supabase.instance.client.storage.from('damage_reports').getPublicUrl(path);
            uploadedUrls.add(url);
          }
        }
      }

      int checkedPieces = foundNotifier.value;
      Map<String, dynamic> dataCoordinator = {};
      
      for (var item in itemsNotifier.value) {
         String category = item['category'];
         int val = int.tryParse(item['value'].toString()) ?? 0;
         dataCoordinator[category] = (dataCoordinator[category] as int? ?? 0) + val;
      }
      dataCoordinator['processed_by'] = currentUserData.value?['full_name'] ?? 'Unknown';
      dataCoordinator['processed_at'] = DateTime.now().toUtc().toIso8601String();
      if (rejectNotifier.value != null) {
        dataCoordinator['discrepancy'] = rejectNotifier.value;
      }

      List<String> allLocations = [];
      for (var item in itemsNotifier.value) {
        String locStr = item['location']?.toString() ?? '';
        if (locStr.trim().isNotEmpty) {
          var locs = locStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
          allLocations.addAll(locs);
        }
      }
      
      Map<String, dynamic> dataLocation = {
        'locations': allLocations,
        'processed_by': currentUserData.value?['full_name'] ?? 'Unknown',
        'processed_at': DateTime.now().toUtc().toIso8601String(),
      };

      await Supabase.instance.client.rpc(
        'rpc_confirm_import_delivery',
        params: {
          'payload': {
            'awb_number': awbNumber,
            'total_pieces': int.tryParse(totalPieces) ?? 0,
            'total_weight': double.tryParse(widget.awbItem['weight']?.toString() ?? '0') ?? 0.0,
            'pieces_checked': checkedPieces,
            'data_coordinator': dataCoordinator,
            'data_location': dataLocation,
            'remarks': remarksCtrl.text.trim(),
            'user_id': Supabase.instance.client.auth.currentUser?.id,
            
            'damage_type': selectedDamages.isNotEmpty ? selectedDamages.join(', ') : null,
            'photo_urls': uploadedUrls.isNotEmpty ? uploadedUrls : null,
            'damage_remarks': damageRemarks.isNotEmpty ? damageRemarks : null,
            'pieces_damage': piecesDamage > 0 ? piecesDamage : null,
          }
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
                            Text(uldId != null ? 'ULD Details (Import)' : 'AWB Details (Import)', style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(awbNumber, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: remarksCtrl,
                        builder: (context, value, child) {
                          final hasRemark = value.text.trim().isNotEmpty;
                          return IconButton(
                            onPressed: () => _showRemarksDialog(context),
                            icon: Icon(
                              hasRemark ? Icons.note_alt_rounded : Icons.note_alt_outlined, 
                              color: hasRemark ? const Color(0xFF3b82f6) : textS
                            ),
                            tooltip: hasRemark ? 'Edit Remarks' : 'Add Remarks',
                            hoverColor: Colors.white.withAlpha(10),
                          );
                        },
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
                                  '$foundVal', 
                                  style: TextStyle(
                                    color: foundVal.toString() == deliverPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), 
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold
                                  )
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

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Top Section: Data Coordinator & Data Location
                        SizedBox(
                          height: 310,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Data Coordinator Form
                              Expanded(
                                flex: 1,
                                child: DataCoordinatorPanel(
                                  dark: widget.dark,
                                  textP: textP,
                                  textS: textS,
                                  borderC: borderC,
                                  bgGlassy: bgGlassy,
                                  onAdd: _onAddItem,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Data Location Placeholder
                              Expanded(
                                flex: 1,
                                child: DataLocationPanel(
                                  dark: widget.dark,
                                  textP: textP,
                                  textS: textS,
                                  borderC: borderC,
                                  bgGlassy: bgGlassy,
                                  itemsNotifier: itemsNotifier,
                                  onUpdateLocation: _onUpdateLocation,
                                  onRemoveItem: _onRemoveItem,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Bottom Section: Damage Placeholder
                        Expanded(
                          child: DamageInformationPanel(
                            key: _damagePanelKey,
                            dark: widget.dark,
                            textP: textP,
                            textS: textS,
                            borderC: borderC,
                            bgGlassy: bgGlassy,
                          ),
                        ),
                      ],
                    ),
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
                                      Icon(Icons.inventory_2_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Check In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
