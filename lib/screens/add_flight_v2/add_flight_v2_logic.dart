import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_flight_v2_service.dart';

class AddFlightV2Logic extends ChangeNotifier {
  final AddFlightV2Service _service = AddFlightV2Service();

  AddFlightV2Logic() {
    carrierCtrl.addListener(() {
      if (fieldErrors.containsKey('Carrier') && carrierCtrl.text.trim().isNotEmpty) {
        fieldErrors.remove('Carrier');
        notifyListeners();
      }
    });
    numberCtrl.addListener(() {
      if (fieldErrors.containsKey('Number') && numberCtrl.text.trim().isNotEmpty) {
        fieldErrors.remove('Number');
        notifyListeners();
      }
    });
    dateCtrl.addListener(() {
      if (fieldErrors.containsKey('Date Arrived') && dateCtrl.text.trim().isNotEmpty) {
        fieldErrors.remove('Date Arrived');
        notifyListeners();
      }
    });
  }

  // Flight Controllers
  final carrierCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final delayedDateCtrl = TextEditingController();
  final delayedTimeCtrl = TextEditingController();
  
  // Break Counters
  int cBreak = 0;
  int cNoBreak = 0;
  bool isBreakAuto = true;
  bool isNoBreakAuto = true;
  final breakCtrl = TextEditingController(text: 'Auto');
  final noBreakCtrl = TextEditingController(text: 'Auto');

  String status = 'Waiting';
  bool isSaving = false;
  Map<String, String> fieldErrors = {};

  void clearErrors() {
    if (fieldErrors.isNotEmpty) {
      fieldErrors.clear();
      notifyListeners();
    }
  }

  void setError(String field, String msg) {
    fieldErrors[field] = msg;
    notifyListeners();
  }

  // ULD Controllers
  final searchUldCtrl = TextEditingController();


  // Nested Data
  final List<Map<String, dynamic>> flightLocalUlds = [];

  void disposeAll() {
    carrierCtrl.dispose();
    numberCtrl.dispose();
    dateCtrl.dispose();
    timeCtrl.dispose();
    remarksCtrl.dispose();
    delayedDateCtrl.dispose();
    delayedTimeCtrl.dispose();
    breakCtrl.dispose();
    noBreakCtrl.dispose();
    searchUldCtrl.dispose();
    super.dispose();
  }

  void rebuild() {
    notifyListeners();
  }

  bool get hasDataSync {
    return carrierCtrl.text.isNotEmpty || 
           numberCtrl.text.isNotEmpty || 
           dateCtrl.text.isNotEmpty || 
           flightLocalUlds.isNotEmpty;
  }

  void setBreakAuto(bool value) {
    isBreakAuto = value;
    breakCtrl.text = isBreakAuto ? '$cBreak' : '';
    notifyListeners();
  }

  void setNoBreakAuto(bool value) {
    isNoBreakAuto = value;
    noBreakCtrl.text = isNoBreakAuto ? '$cNoBreak' : '';
    notifyListeners();
  }

  void setStatus(String newStatus) {
    status = newStatus;
    notifyListeners();
  }



  Future<void> selectDate(BuildContext context) async {
    DateTime initD = DateTime.now();
    if (dateCtrl.text.isNotEmpty) {
      try { initD = DateFormat('MM/dd/yyyy').parse(dateCtrl.text); } catch (_) {}
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initD,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), onPrimary: Colors.white, surface: Color(0xFF1e293b), onSurface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      dateCtrl.text = DateFormat('MM/dd/yyyy').format(picked);
      notifyListeners();
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b))),
        child: child!,
      ),
    );
    if (picked != null) {
      final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
      timeCtrl.text = DateFormat('hh:mm a').format(dt).toUpperCase();
      notifyListeners();
    }
  }

  Future<void> selectDelayedDate(BuildContext context) async {
    DateTime initD = DateTime.now();
    if (delayedDateCtrl.text.isNotEmpty) {
      try { initD = DateFormat('MM/dd/yyyy').parse(delayedDateCtrl.text); } catch (_) {}
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initD,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b))), child: child!),
    );
    if (picked != null) {
      delayedDateCtrl.text = DateFormat('MM/dd/yyyy').format(picked);
      notifyListeners();
    }
  }

  Future<void> selectDelayedTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b))), child: child!),
    );
    if (picked != null) {
      final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
      delayedTimeCtrl.text = DateFormat('hh:mm a').format(dt).toUpperCase();
      notifyListeners();
    }
  }



  void recalculateAutoCounts() {
    cBreak = flightLocalUlds.where((u) => u['break'] == true).length;
    cNoBreak = flightLocalUlds.where((u) => u['break'] == false).length;
    
    if (isBreakAuto) breakCtrl.text = '$cBreak';
    if (isNoBreakAuto) noBreakCtrl.text = '$cNoBreak';
    notifyListeners();
  }

  void removeLocalUld(int index) {
    flightLocalUlds.removeAt(index);
    recalculateAutoCounts();
  }





  int getLocalUsedPieces(String awbNumber) {
    int total = 0;
    for (var uld in flightLocalUlds) {
      List awbs = uld['awbs'] ?? [];
      for (var awb in awbs) {
        if (awb['awb_number'] == awbNumber) {
          total += (awb['pieces'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return total;
  }

  Future<void> fetchAwbTotalAsync(String text, ValueNotifier<bool> totalLocked, TextEditingController totalCtrl, ValueNotifier<int> dbExpectedPieces) async {
    final res = await _service.fetchAwbTotal(text);
    if (res != null && res['total'] != null) {
      totalLocked.value = true;
      totalCtrl.text = res['total'].toString();
      dbExpectedPieces.value = (res['total_expected'] as num?)?.toInt() ?? 0;
    } else {
       dbExpectedPieces.value = 0;
    }
  }

  Future<void> saveEverything(
    BuildContext context, 
    {required Function(String) showValidationError,
     required Function() onSuccess,
     required Function(String) onError}
  ) async {
    clearErrors();
    bool hasError = false;
    if (carrierCtrl.text.isEmpty) { fieldErrors['Carrier'] = 'Required'; hasError = true; }
    if (numberCtrl.text.isEmpty) { fieldErrors['Number'] = 'Required'; hasError = true; }
    if (dateCtrl.text.isEmpty) { fieldErrors['Date Arrived'] = 'Required'; hasError = true; }

    if (hasError) {
      notifyListeners();
      return;
    }

    final emptyUld = flightLocalUlds.firstWhere((u) => (u['awbs'] as List).isEmpty, orElse: () => {});
    if (emptyUld.isNotEmpty) {
      showValidationError('AWBs are missing for ULD ${emptyUld['uldNumber']}. Add at least one.'); return;
    }

    if (!isBreakAuto) {
      final manualBreak = int.tryParse(breakCtrl.text) ?? 0;
      final actualBreakCount = flightLocalUlds.where((u) => u['break'] == true).length;
      if (manualBreak != actualBreakCount) {
        showValidationError('If manual Break is set to $manualBreak, you must add exactly $manualBreak ULD(s) marked as Break. Currently you have $actualBreakCount.');
        return;
      }
    }

    if (!isNoBreakAuto) {
      final manualNoBreak = int.tryParse(noBreakCtrl.text) ?? 0;
      final actualNoBreakCount = flightLocalUlds.where((u) => u['break'] == false).length;
      if (manualNoBreak != actualNoBreakCount) {
        showValidationError('If manual No Break is set to $manualNoBreak, you must add exactly $manualNoBreak ULD(s) marked as No Break. Currently you have $actualNoBreakCount.');
        return;
      }
    }

    isSaving = true;
    notifyListeners();

    try {
      await _service.saveFlight(
        carrier: carrierCtrl.text.toUpperCase(),
        number: numberCtrl.text,
        breakCount: isBreakAuto ? cBreak : (int.tryParse(breakCtrl.text) ?? 0),
        noBreakCount: isNoBreakAuto ? cNoBreak : (int.tryParse(noBreakCtrl.text) ?? 0),
        dateArrived: dateCtrl.text,
        timeArrived: timeCtrl.text,
        delayedDate: delayedDateCtrl.text,
        delayedTime: delayedTimeCtrl.text,
        remarks: remarksCtrl.text,
        status: status,
        flightLocalUlds: flightLocalUlds,
      );
      onSuccess();
    } catch (e) {
      onError(e.toString());
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
