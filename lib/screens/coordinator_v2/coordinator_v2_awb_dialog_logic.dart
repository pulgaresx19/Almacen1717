import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, currentUserData;

class CoordinatorV2AwbDialogLogic extends ChangeNotifier {
  final Map<String, dynamic> combined;
  final Map<String, dynamic> awbSplit;

  int selectedType = 0;
  bool notFoundSelected = false;
  String? selectedLocation;
  final locationOtherCtrl = TextEditingController();
  List<String> selectedDamages = [];
  List<XFile> localPhotos = [];
  final ImagePicker picker = ImagePicker();
  late final TextEditingController notesCtrl;
  bool isSaving = false;

  final agiSkidCtrl = TextEditingController();
  final preSkidCtrl = TextEditingController();
  final crateCtrl = TextEditingController();
  final boxCtrl = TextEditingController();
  final otherCtrl = TextEditingController();
  final piecesDamageCtrl = TextEditingController();
  final damageRemarkCtrl = TextEditingController();

  List<Map<String, dynamic>> addedItems = [];

  String? existingDamageReportId;
  List<String> networkPhotos = [];
  List<String> photosToDelete = [];
  bool isLoadingDamage = true;

  CoordinatorV2AwbDialogLogic(this.combined, this.awbSplit) {
    dynamic d = awbSplit['data_coordinator'];
    Map<String, dynamic>? data;
    if (d is Map) {
      data = Map<String, dynamic>.from(d);
    } else if (d is String && d.trim().isNotEmpty && d != 'null') {
      try {
        data = Map<String, dynamic>.from(jsonDecode(d));
      } catch (_) {}
    }

    if (data != null) {
      if (data['not_found'] == true) {
        notFoundSelected = true;
      }
      
      data.forEach((key, value) {
        if (key == 'Location requerida') {
          final locStr = value?.toString() ?? '';
          final predefined = ['2-8C*', 'CRT', 'PSV', 'DG', 'Oversize', 'Small rack', 'Animal live'];
          if (predefined.contains(locStr)) {
            selectedLocation = locStr;
          } else {
            selectedLocation = 'Other';
            locationOtherCtrl.text = locStr;
          }
        } else if (key == 'Remarks') {
          // Handled below
        } else if (!key.startsWith('discrepancy_') && key != 'processed_by' && key != 'processed_at') {
          int val = value is int ? value : (int.tryParse(value.toString()) ?? 0);
          if (val > 0) {
            String cat = key;
            if (key.contains('AGI skid')) cat = 'AGI skid';
            addedItems.add({
              'category': cat,
              'displayLabel': key,
              'value': val,
            });
          }
        }
      });
      notesCtrl = TextEditingController(text: data['Remarks']?.toString() ?? '');
    } else {
      notesCtrl = TextEditingController();
    }
    
    piecesDamageCtrl.addListener(() {
      notifyListeners();
    });
    damageRemarkCtrl.addListener(() {
      notifyListeners();
    });
    
    _fetchExistingDamage();
  }

  Future<void> _fetchExistingDamage() async {
    try {
      final supabase = Supabase.instance.client;
      final fId = combined['flight_id'] ?? awbSplit['flight_id'];
      final aId = combined['awb_id'] ?? awbSplit['awb_id'] ?? combined['id'];
      final uId = combined['uld_id'] ?? awbSplit['uld_id'];
      
      if (fId != null && aId != null) {
        var query = supabase.from('damage_reports').select().eq('flight_id', fId).eq('awb_id', aId);
        if (uId != null) {
          query = query.eq('uld_id', uId);
        } else {
          query = query.isFilter('uld_id', null);
        }
        final res = await query.maybeSingle();
        if (res != null) {
          existingDamageReportId = res['id']?.toString();
          if (res['damage_type'] is List) {
            selectedDamages = List<String>.from(res['damage_type']);
          }
          if (res['photo_urls'] is List) {
            networkPhotos = List<String>.from(res['photo_urls']);
          }
          if (res['pieces_damage'] != null) {
            piecesDamageCtrl.text = res['pieces_damage'].toString();
          }
          if (res['remarks'] != null) {
            damageRemarkCtrl.text = res['remarks'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching damage report: $e');
    } finally {
      isLoadingDamage = false;
      notifyListeners();
    }
  }

  bool get hasExistingData {
    final d = awbSplit['data_coordinator'];
    if (d == null) return false;
    if (d is Map) return d.isNotEmpty;
    if (d is String) return d.trim().isNotEmpty && d != 'null' && d != '{}';
    return true;
  }

  @override
  void dispose() {
    locationOtherCtrl.dispose();
    notesCtrl.dispose();
    agiSkidCtrl.dispose();
    preSkidCtrl.dispose();
    crateCtrl.dispose();
    boxCtrl.dispose();
    otherCtrl.dispose();
    piecesDamageCtrl.dispose();
    damageRemarkCtrl.dispose();
    super.dispose();
  }

  void setType(int type) {
    selectedType = type;
    notifyListeners();
  }

  void toggleNotFound() {
    notFoundSelected = !notFoundSelected;
    if (notFoundSelected) {
      addedItems.clear();
      selectedLocation = null;
      locationOtherCtrl.clear();
      notesCtrl.clear();
      selectedDamages.clear();
      piecesDamageCtrl.clear();
      damageRemarkCtrl.clear();
      localPhotos.clear();
    }
    notifyListeners();
  }

  void setLocation(String? loc) {
    selectedLocation = loc;
    notifyListeners();
  }

  void setDamages(List<String> damages) {
    selectedDamages = damages;
    notifyListeners();
  }

  void removePhoto(int idx) {
    localPhotos.removeAt(idx);
    notifyListeners();
  }

  void removeNetworkPhoto(int idx) {
    final url = networkPhotos[idx];
    photosToDelete.add(url);
    networkPhotos.removeAt(idx);
    notifyListeners();
  }

  int getTotalChecked() {
    int total = 0;
    for (var item in addedItems) {
      total += (item['value'] as int);
    }
    return total;
  }

  Future<void> pickImageLocally(ImageSource source, BuildContext context) async {
    final int currentTotal = localPhotos.length + networkPhotos.length;
    final int remaining = 9 - currentTotal;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLanguage.value == 'es' ? 'Límite de 9 fotos alcanzado.' : 'Limit of 9 photos reached.')),
      );
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final pickedList = await picker.pickMultiImage(imageQuality: 60, maxWidth: 800, maxHeight: 800);
        if (pickedList.isNotEmpty) {
          if (!context.mounted) return;
          if (pickedList.length > remaining) {
            localPhotos.addAll(pickedList.take(remaining));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(appLanguage.value == 'es' ? 'Solo se añadieron $remaining fotos para respetar el límite de 9.' : 'Only $remaining photos added to respect the 9 limit.')),
            );
          } else {
            localPhotos.addAll(pickedList);
          }
          notifyListeners();
        }
      } else {
        final picked = await picker.pickImage(
          source: source,
          imageQuality: 60,
          maxWidth: 800,
          maxHeight: 800,
        );
        if (picked != null) {
          localPhotos.add(picked);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void recalcDisplay() {
    int agiInd = 1;
    for (var item in addedItems) {
      if (item['category'] == 'AGI skid') {
        item['displayLabel'] = '$agiInd. AGI skid';
        agiInd++;
      } else {
        item['displayLabel'] = item['category'];
      }
    }
  }

  void addItem(String category, TextEditingController ctrl) {
    final val = int.tryParse(ctrl.text);
    if (val != null && val > 0) {
      if (category == 'AGI skid') {
        addedItems.add({
          'category': category,
          'value': val,
        });
      } else {
        int existingIdx = addedItems.indexWhere((e) => e['category'] == category);
        if (existingIdx >= 0) {
          addedItems[existingIdx]['value'] = val;
        } else {
          addedItems.add({
            'category': category,
            'value': val,
          });
        }
      }
      recalcDisplay();
      ctrl.clear();
      notifyListeners();
    }
  }

  void removeItem(Map<String, dynamic> item) {
    addedItems.remove(item);
    recalcDisplay();
    notifyListeners();
  }

  Future<void> handleSave(BuildContext context) async {
    final piecesStr = awbSplit['pieces']?.toString() ?? awbSplit['pieces_split']?.toString() ?? '0';
    final targetPieces = int.tryParse(piecesStr) ?? 0;
    final int checkedPieces = notFoundSelected ? 0 : getTotalChecked();
    
    if (checkedPieces != targetPieces) {
      if (!context.mounted) return;
      int diff = checkedPieces - targetPieces;
      String type = diff > 0 ? "OVER" : "SHORT";
      int absDiff = diff.abs();
      
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                appLanguage.value == 'es' ? 'Discrepancia de Piezas' : 'Pieces Discrepancy',
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 15, height: 1.5),
              children: [
                TextSpan(
                  text: appLanguage.value == 'es'
                    ? 'El total chequeado ($checkedPieces) no coincide con las declaradas ($targetPieces).\n\n'
                    : 'Total checked ($checkedPieces) does not match declared pieces ($targetPieces).\n\n'
                ),
                TextSpan(
                  text: appLanguage.value == 'es'
                    ? 'Hay una diferencia de '
                    : 'There is a discrepancy of ',
                ),
                TextSpan(
                  text: '[$absDiff $type]',
                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)
                ),
                TextSpan(
                  text: appLanguage.value == 'es'
                    ? ' piezas.\n¿Deseas guardar de todos modos?'
                    : ' pieces.\nDo you want to save anyway?'
                ),
              ]
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Color(0xFF94a3b8)))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx, true), 
              child: Text(appLanguage.value == 'es' ? 'Confirmar' : 'Confirm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    isSaving = true;
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      final List<String> uploadedUrls = [];

      // Borrar fotos huérfanas del Storage si se eliminaron de la nube
      if (photosToDelete.isNotEmpty) {
        try {
          final List<String> pathsToDelete = photosToDelete.map((url) {
            final uri = Uri.parse(url);
            final segments = uri.pathSegments;
            final idx = segments.indexOf('damage_reports');
            if (idx != -1 && idx + 1 < segments.length) {
              return segments.sublist(idx + 1).join('/');
            }
            return '';
          }).where((p) => p.isNotEmpty).toList();
          
          if (pathsToDelete.isNotEmpty) {
            await supabase.storage.from('damage_reports').remove(pathsToDelete);
          }
        } catch (e) {
          debugPrint('Error deleting old photos: $e');
        }
      }

      if (localPhotos.isNotEmpty) {
        for (var photo in localPhotos) {
          final bytes = await photo.readAsBytes();
          final ext = photo.name.split('.').last.toLowerCase();
          final mimeExt = ext == 'jpg' ? 'jpeg' : ext;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${supabase.auth.currentUser?.id ?? 'user'}.$ext';
          final path = 'public/$fileName';

          await supabase.storage.from('damage_reports').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$mimeExt'),
          );

          final url = supabase.storage.from('damage_reports').getPublicUrl(path);
          uploadedUrls.add(url);
        }
      }

      final dmgPieces = int.tryParse(piecesDamageCtrl.text) ?? 0;
      final List<String> finalUrls = [...networkPhotos, ...uploadedUrls];

      final String finLocation = selectedLocation == 'Other' ? locationOtherCtrl.text.trim() : (selectedLocation ?? '');
      
      final Map<String, dynamic> dataCoordinator = {};
      
      for (var item in addedItems) {
        String label = item['displayLabel'] ?? item['category'];
        dataCoordinator[label] = item['value'];
      }
      
      if (checkedPieces != targetPieces) {
        int diff = checkedPieces - targetPieces;
        dataCoordinator['discrepancy_expected'] = targetPieces;
        dataCoordinator['discrepancy_checked'] = checkedPieces;
        dataCoordinator['discrepancy_amount'] = diff.abs();
        if (notFoundSelected) {
          dataCoordinator['not_found'] = true;
        } else {
          dataCoordinator['discrepancy_type'] = diff > 0 ? 'OVER' : 'SHORT';
        }
      } else {
        if (notFoundSelected) {
          dataCoordinator['not_found'] = true;
          dataCoordinator['discrepancy_amount'] = targetPieces;
        }
      }
      
      if (finLocation.isNotEmpty) {
        dataCoordinator['Location requerida'] = finLocation;
      }
      
      final String remarksText = notesCtrl.text.trim();
      if (remarksText.isNotEmpty) {
        dataCoordinator['Remarks'] = remarksText;
      }

      String userFullName = 'Unknown User';
      try {
        if (currentUserData.value != null && currentUserData.value!['full_name'] != null) {
          userFullName = currentUserData.value!['full_name'];
        }
      } catch (_) {}
      
      dataCoordinator['processed_by'] = userFullName;
      dataCoordinator['processed_at'] = DateTime.now().toUtc().toIso8601String();
      if (awbSplit['is_new'] == true) {
        dataCoordinator['is_new'] = true;
        dataCoordinator['new_amount'] = targetPieces;
      }

      final awbSplitId = awbSplit['id'];
      
      final Map<String, dynamic> rpcParams = {
        'p_split_id': awbSplitId,
        'p_checked_pieces': checkedPieces,
        'p_not_found': notFoundSelected,
        'p_location': finLocation.isNotEmpty ? finLocation : null,
        'p_data_coordinator': dataCoordinator,
      };
      final dmgRemarks = damageRemarkCtrl.text.trim();

      rpcParams['p_existing_damage_id'] = existingDamageReportId != null ? int.tryParse(existingDamageReportId!) : null;

      if (selectedDamages.isNotEmpty || finalUrls.isNotEmpty || dmgPieces > 0 || dmgRemarks.isNotEmpty) {
        final fId = combined['flight_id'] ?? awbSplit['flight_id'];
        final uId = combined['uld_id'] ?? awbSplit['uld_id'];
        final aId = combined['awb_id'] ?? awbSplit['awb_id'] ?? combined['id'];
        final usrId = supabase.auth.currentUser?.id;

        rpcParams['p_flight_id'] = fId;
        rpcParams['p_uld_id'] = uId;
        rpcParams['p_awb_id'] = aId;
        rpcParams['p_user_id'] = usrId;
        rpcParams['p_damage_type'] = selectedDamages.isEmpty ? null : selectedDamages;
        rpcParams['p_photo_urls'] = finalUrls.isEmpty ? null : finalUrls;
        rpcParams['p_pieces_damage'] = dmgPieces;
        rpcParams['p_damage_remarks'] = dmgRemarks.isEmpty ? null : dmgRemarks;
      } else {
        rpcParams['p_flight_id'] = null;
        rpcParams['p_uld_id'] = null;
        rpcParams['p_awb_id'] = null;
        rpcParams['p_user_id'] = null;
        rpcParams['p_damage_type'] = null;
        rpcParams['p_photo_urls'] = null;
        rpcParams['p_pieces_damage'] = 0;
        rpcParams['p_damage_remarks'] = null;
      }

      await supabase.rpc('rpc_save_coordinator_data', params: rpcParams);

      if (context.mounted) {
        final nav = Navigator.of(context);
        nav.pop(true); // Close the AWB modal
        
        if (!nav.mounted) return;

        bool dialogOpen = true;
        showGeneralDialog(
          context: nav.context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (ctx, anim1, anim2) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF0f172a) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF10b981).withAlpha(40), blurRadius: 40, offset: const Offset(0, 10))], border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(20), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48)),
                      const SizedBox(height: 24),
                      Text(appLanguage.value == 'es' ? '¡AWB Chequeada!' : 'AWB Checked!', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(appLanguage.value == 'es' ? 'La guía ha sido verificada y los datos se guardaron.' : 'The airway bill has been verified and data saved.', style: TextStyle(color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(scale: Curves.easeOutBack.transform(anim1.value), child: FadeTransition(opacity: anim1, child: child)),
        ).then((_) => dialogOpen = false);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogOpen) {
            nav.pop();
          }
        });
      }
    } catch (e) {
      debugPrint('Error al guardar reporte: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage.value == 'es' ? 'Error: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
