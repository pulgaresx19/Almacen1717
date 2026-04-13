import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FlightsV2Service {
  Future<List<Map<String, dynamic>>> fetchFlights() async {
    try {
      final response = await Supabase.instance.client
          .from('flights')
          .select()
          .neq('status', 'Closed')
          .order('date', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching flights: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFlightDetails(String flightId) async {
    try {
      final response = await Supabase.instance.client
          .from('ulds')
          .select('*, awb_splits(*, awbs(*))')
          .eq('id_flight', flightId)
          .order('is_break', ascending: false)
          .order('uld_number', ascending: true);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching flight details (ULDs & AWBs): $e');
      return [];
    }
  }

  Future<void> deleteFlights(List<String> flightIds) async {
    if (flightIds.isEmpty) return;
    try {
      // Soft Delete strategy: Mark them as Closed.
      // We do not detach ULDs, preserving full history.
      await Supabase.instance.client
          .from('flights')
          .update({'status': 'Closed'})
          .inFilter('id_flight', flightIds);
    } catch (e) {
      debugPrint('Error archiving flights: $e');
      rethrow;
    }
  }
}
