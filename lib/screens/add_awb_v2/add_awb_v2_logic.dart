import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AddAwbV2Logic {
  static Future<List<Map<String, dynamic>>> loadFlights() async {
    try {
      final res = await Supabase.instance.client
          .from('flights')
          .select()
          .order('arrival_date', ascending: false);
      return res.map<Map<String, dynamic>>((row) => {
        'id': row['id_flight']?.toString(),
        'carrier': row['carrier'] ?? '',
        'number': row['number'] ?? '',
        'date-arrived': row['date'] != null ? row['date'].toString().substring(0, 10) : '',
      }).toList();
    } catch (e) {
      debugPrint('Error loading flights: $e');
      return [];
    }
  }

  static Future<bool?> checkUldBreakStatus(String uld, String? flightId) async {
    try {
      var query = Supabase.instance.client
          .from('ulds')
          .select('is_break')
          .eq('uld_number', uld);

      if (flightId != null) {
        query = query.eq('id_flight', flightId);
      }

      final res = await query.order('created_at', ascending: false).limit(1).maybeSingle();
      if (res != null && res['is_break'] != null) {
        return res['is_break'] as bool;
      }
    } catch (e) {
      debugPrint('Error checking ULD break status: $e');
    }
    return null;
  }
}
