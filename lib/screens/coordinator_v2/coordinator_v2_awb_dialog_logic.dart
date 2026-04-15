import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;

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

  List<Map<String, dynamic>> addedItems = [];

  CoordinatorV2AwbDialogLogic(this.combined, this.awbSplit) {
    if (awbSplit['data_coordinator'] != null && awbSplit['data_coordinator'] is Map) {
      final Map<String, dynamic> data = awbSplit['data_coordinator'];
      
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
        } else {
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
      notesCtrl = TextEditingController(text: data['Remarks']?.toString() ?? combined['remarks']?.toString() ?? '');
    } else {
      notesCtrl = TextEditingController(text: combined['remarks']?.toString() ?? '');
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
    super.dispose();
  }

  void setType(int type) {
    selectedType = type;
    notifyListeners();
  }

  void toggleNotFound() {
    notFoundSelected = !notFoundSelected;
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

  int getTotalChecked() {
    int total = 0;
    for (var item in addedItems) {
      total += (item['value'] as int);
    }
    return total;
  }

  Future<void> pickImageLocally(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final pickedList = await picker.pickMultiImage(imageQuality: 70);
        if (pickedList.isNotEmpty) {
          localPhotos.addAll(pickedList);
          notifyListeners();
        }
      } else {
        final picked = await picker.pickImage(source: source, imageQuality: 70);
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
    isSaving = true;
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      final List<String> uploadedUrls = [];

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

      if (selectedDamages.isNotEmpty || uploadedUrls.isNotEmpty) {
         final Map<String, dynamic> reportData = {
           'damage_type': selectedDamages,
           'photo_urls': uploadedUrls,
         };
         
         final fId = combined['flight_id'] ?? awbSplit['flight_id'];
         if (fId != null) reportData['flight_id'] = fId;
         
         final uId = combined['uld_id'] ?? awbSplit['uld_id'];
         if (uId != null) reportData['uld_id'] = uId;
         
         final aId = combined['awb_id'] ?? awbSplit['awb_id'] ?? combined['id'];
         if (aId != null) reportData['awb_id'] = aId;
         
         final usrId = supabase.auth.currentUser?.id;
         if (usrId != null) reportData['user_id'] = usrId;

         await supabase.from('damage_reports').insert(reportData);
      }

      final String finLocation = selectedLocation == 'Other' ? locationOtherCtrl.text.trim() : (selectedLocation ?? '');
      
      final Map<String, dynamic> dataCoordinator = {};
      
      for (var item in addedItems) {
        String label = item['displayLabel'] ?? item['category'];
        dataCoordinator[label] = item['value'];
      }
      
      if (finLocation.isNotEmpty) {
        dataCoordinator['Location requerida'] = finLocation;
      }
      
      final String remarksText = notesCtrl.text.trim();
      if (remarksText.isNotEmpty) {
        dataCoordinator['Remarks'] = remarksText;
      }

      final awbSplitId = awbSplit['id'];
      if (awbSplitId != null) {
        await supabase.from('awb_splits').update({
          'data_coordinator': dataCoordinator,
        }).eq('id', awbSplitId);
      }

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage.value == 'es' ? 'Reporte guardado con éxito' : 'Report saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
