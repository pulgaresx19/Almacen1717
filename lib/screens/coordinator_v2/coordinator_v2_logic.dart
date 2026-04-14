import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoordinatorV2Logic extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  DateTime? selectedDate;
  bool isLoadingFlights = false;
  List<Map<String, dynamic>> flights = [];
  String? selectedFlightId;
  
  bool isLoadingUlds = false;
  List<Map<String, dynamic>> ulds = [];

  // Search logic if needed could be stored here
  Map<String, dynamic>? globalSearchResult;
  bool isGlobalSearching = false;

  void disposeLogic() {
    // any subscriptions
  }

  @override
  void dispose() {
    disposeLogic();
    super.dispose();
  }

  Future<void> performGlobalSearch(String query) async {
    isGlobalSearching = true;
    notifyListeners();

    try {
      final resList = await supabase
          .from('ulds')
          .select()
          .ilike('uld_number', '%$query%')
          .limit(10);
      
      if (resList.isNotEmpty) {
        globalSearchResult = {'list': resList};
      } else {
        globalSearchResult = {
          'error': true,
          'message': 'Requested ULD not found.',
        };
      }
    } catch (e) {
      globalSearchResult = {'error': true, 'message': 'Error: $e'};
    }

    isGlobalSearching = false;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
    fetchFlights(date);
  }

  void selectFlight(String idFlight) {
    if (selectedFlightId == idFlight) {
      selectedFlightId = null; // deselect
      ulds = [];
    } else {
      selectedFlightId = idFlight;
      fetchUldsForFlight(idFlight);
    }
    notifyListeners();
  }

  Future<void> fetchUldsForFlight(String idFlight) async {
    isLoadingUlds = true;
    notifyListeners();
    try {
      final res = await supabase.from('ulds').select().eq('id_flight', idFlight).order('created_at', ascending: true);
      ulds = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching ULDs: $e');
      ulds = [];
    }
    isLoadingUlds = false;
    notifyListeners();
  }

  Future<void> fetchFlights(DateTime dt) async {
    isLoadingFlights = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(dt);
    final validDates = <String>[];
    for (int i = -15; i <= 15; i++) {
      validDates.add(DateFormat('yyyy-MM-dd').format(dt.add(Duration(days: i))));
    }

    try {
      final res = await supabase.from('flights').select(); // In full deployment we might limit this, but let's filter in memory for now due to date formatting.
      
      final validList = <Map<String, dynamic>>[];
      for (var f in res) {
        bool isDel = f['status']?.toString().toLowerCase() == 'delayed';
        if (isDel && f['time_delay'] != null && f['time_delay'].toString().isNotEmpty && f['time_delay'].toString() != '-') {
          try {
            final localDt = DateTime.parse(f['time_delay'].toString()).toLocal();
            if (DateFormat('yyyy-MM-dd').format(localDt) == dateStr) {
              validList.add(f);
            }
          } catch (_) {}
        } else {
          try {
            if (f['date'] != null && f['date'].toString().isNotEmpty) {
              final localDt = DateTime.parse(f['date'].toString()).toLocal();
              if (DateFormat('yyyy-MM-dd').format(localDt) == dateStr) {
                validList.add(f);
              }
            }
          } catch (_) {}
        }
      }

      flights = validList;
      if (selectedFlightId != null && !flights.any((f) => f['id_flight']?.toString() == selectedFlightId)) {
        selectedFlightId = null;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    isLoadingFlights = false;
    notifyListeners();
  }
}
