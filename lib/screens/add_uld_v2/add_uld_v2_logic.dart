import 'package:flutter/material.dart';
import 'add_uld_v2_service.dart';


class AddUldV2Logic extends ChangeNotifier {
  final AddUldV2Service _service = AddUldV2Service();
  
  bool isSaving = false;
  List<Map<String, dynamic>> flights = [];
  final List<Map<String, dynamic>> localUlds = [];
  final Set<String> collapsedGroups = {};

  Future<void> init() async {
    flights = await _service.fetchFlights();
    notifyListeners();
  }

  void addLocalUld({
    required String uldNumber,
    required String pieces,
    required String weight,
    required String remarks,
    required bool priority,
    required bool isBreak,
    required String? flightId,
    required bool isPiecesChk,
    required bool isWeightChk,
  }) {
    String? flightLabel;
    if (flightId != null) {
      final f = flights.firstWhere((x) => x['id'].toString() == flightId, orElse: () => <String, dynamic>{});
      if (f.isNotEmpty) {
        flightLabel = '${f['carrier']} ${f['number']}';
      }
    }

    localUlds.add({
      'uldNumber': uldNumber.toUpperCase(),
      'pieces': pieces.isNotEmpty && pieces != 'Auto' ? (int.tryParse(pieces) ?? 0) : 0,
      'weight': weight.isNotEmpty && weight != 'Auto' ? (double.tryParse(weight) ?? 0.0) : 0.0,
      'remarks': remarks.trim().isEmpty ? null : remarks.trim(),
      'status': 'Waiting',
      'priority': priority,
      'break': isBreak,
      'flight_id': flightId,
      'flightLabel': flightLabel,
      'isAutoPieces': isPiecesChk,
      'isAutoWeight': isWeightChk,
      'awbs': [],
      'showAwbs': true,
    });
    notifyListeners();
  }

  void removeLocalUld(int index) {
    if (index >= 0 && index < localUlds.length) {
      localUlds.removeAt(index);
      notifyListeners();
    }
  }

  void toggleUldGroup(String groupName) {
    if (collapsedGroups.contains(groupName)) {
      collapsedGroups.remove(groupName);
    } else {
      collapsedGroups.add(groupName);
    }
    notifyListeners();
  }

  void toggleAwbVisibility(int uldIndex) {
    if (uldIndex >= 0 && uldIndex < localUlds.length) {
      localUlds[uldIndex]['showAwbs'] = !(localUlds[uldIndex]['showAwbs'] ?? true);
      notifyListeners();
    }
  }

  void removeAwb(int uldIndex, int awbIndex) {
    localUlds[uldIndex]['awbs'].removeAt(awbIndex);
    if (localUlds[uldIndex]['isAutoPieces'] == true) {
      localUlds[uldIndex]['pieces'] = (localUlds[uldIndex]['awbs'] as List).fold<int>(0, (s, a) => s + ((a['pieces'] as num).toInt()));
    }
    if (localUlds[uldIndex]['isAutoWeight'] == true) {
      localUlds[uldIndex]['weight'] = (localUlds[uldIndex]['awbs'] as List).fold<double>(0.0, (s, a) => s + ((a['weight'] as num).toDouble()));
    }
    notifyListeners();
  }

  void addAwbToUld(int uldIndex, Map<String, dynamic> awbData) {
    localUlds[uldIndex]['awbs'].add(awbData);
    if (localUlds[uldIndex]['isAutoPieces'] == true) {
      localUlds[uldIndex]['pieces'] = (localUlds[uldIndex]['awbs'] as List).fold<int>(0, (s, a) => s + ((a['pieces'] as num).toInt()));
    }
    if (localUlds[uldIndex]['isAutoWeight'] == true) {
      localUlds[uldIndex]['weight'] = (localUlds[uldIndex]['awbs'] as List).fold<double>(0.0, (s, a) => s + ((a['weight'] as num).toDouble()));
    }
    notifyListeners();
  }

  bool hasDataSync(bool hasPendingInputs) {
    if (localUlds.isNotEmpty) return true;
    return hasPendingInputs;
  }

  int getLocalUsedPieces(String awbNumber) {
    int total = 0;
    for (var u in localUlds) {
      final awbs = u['awbs'] as List? ?? [];
      for (var a in awbs) {
        if (a['awb_number'] == awbNumber) {
          total += (a['pieces'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return total;
  }

  Future<void> saveAllUlds(VoidCallback onSuccess, Function(String) onError) async {
    isSaving = true;
    notifyListeners();

    try {
      await _service.saveAllUlds(localUlds, flights);
      onSuccess();
    } catch (e) {
      onError(e.toString());
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
