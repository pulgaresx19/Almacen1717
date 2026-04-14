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
      List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(response);
      // Sort dynamically: use time_delay if present, otherwise use date
      list.sort((a, b) {
        final aDelayed = a['status']?.toString().trim().toLowerCase() == 'delayed';
        final bDelayed = b['status']?.toString().trim().toLowerCase() == 'delayed';
        final aDateStr = (aDelayed && a['time_delay'] != null && a['time_delay'].toString().isNotEmpty && a['time_delay'].toString() != '-') 
            ? a['time_delay'].toString() 
            : a['date']?.toString();
        final bDateStr = (bDelayed && b['time_delay'] != null && b['time_delay'].toString().isNotEmpty && b['time_delay'].toString() != '-') 
            ? b['time_delay'].toString() 
            : b['date']?.toString();
        final aDate = DateTime.tryParse(aDateStr ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(bDateStr ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate); // descending chronological order
      });
      return list;
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
