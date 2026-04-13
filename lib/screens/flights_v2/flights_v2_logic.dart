import 'package:flutter/material.dart';
import 'flights_v2_service.dart';

class FlightsV2Logic extends ChangeNotifier {
  final FlightsV2Service _service = FlightsV2Service();
  bool isLoading = false;
  List<Map<String, dynamic>> flightsList = [];

  Future<void> fetchFlights({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    flightsList = await _service.fetchFlights();
    if (!silent) {
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> deleteFlights(List<String> flightIds) async {
    if (flightIds.isEmpty) return;
    
    // Instantly remove from local list for smooth visual delete
    flightsList.removeWhere((flight) => flightIds.contains(flight['id_flight']?.toString()));
    notifyListeners();
    
    try {
      await _service.deleteFlights(flightIds);
    } catch (e) {
      // Ignored for UI
    }
    
    // Re-sync silently in background
    await fetchFlights(silent: true);
  }
}
