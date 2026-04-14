import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'flights_v2_service.dart';

class FlightsV2Logic extends ChangeNotifier {
  final FlightsV2Service _service = FlightsV2Service();
  bool isLoading = false;
  List<Map<String, dynamic>> flightsList = [];
  RealtimeChannel? _realtimeChannel;

  FlightsV2Logic() {
    _initRealtime();
  }

  void _initRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('public:flights_v2_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'flights',
          callback: (payload) {
            fetchFlights(silent: true);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

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
