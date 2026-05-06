import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddFlightV2Service {
  Future<Map<String, dynamic>?> fetchAwbTotal(String awbNumber) async {
    try {
      final res = await Supabase.instance.client
          .from('awbs')
          .select('total_pieces, total_espected')
          .eq('awb_number', awbNumber)
          .maybeSingle();
      if (res != null) {
        return {
          'total': res['total_pieces'],
          'total_expected': res['total_espected'] ?? 0,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFlight({
    required String carrier,
    required String number,
    required int breakCount,
    required int noBreakCount,
    required String dateArrived,
    required String timeArrived,
    required String delayedDate,
    required String delayedTime,
    required String remarks,
    required String status,
    required List<Map<String, dynamic>> flightLocalUlds,
  }) async {
    final supabase = Supabase.instance.client;

    DateTime? flightDate;
    if (dateArrived.isNotEmpty) {
      try {
        final parsedDate = DateFormat('MM/dd/yyyy').parse(dateArrived);
        if (timeArrived.isNotEmpty) {
          final parsedTime = DateFormat('hh:mm a').parse(timeArrived);
          flightDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day,
              parsedTime.hour, parsedTime.minute);
        } else {
          flightDate = parsedDate;
        }
      } catch (_) {}
    }

    DateTime? delayDate;
    if (delayedDate.isNotEmpty) {
      try {
        final parsedDate = DateFormat('MM/dd/yyyy').parse(delayedDate);
        if (delayedTime.isNotEmpty) {
          final parsedTime = DateFormat('hh:mm a').parse(delayedTime);
          delayDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day,
              parsedTime.hour, parsedTime.minute);
        } else {
          delayDate = parsedDate;
        }
      } catch (_) {}
    }

    final flightPayload = {
      'carrier': carrier,
      'number': number,
      if (flightDate != null) 'date': flightDate.toUtc().toIso8601String(),
      if (delayDate != null) 'time_delay': delayDate.toUtc().toIso8601String(),
      'cant_break': breakCount,
      'cant_nobreak': noBreakCount,
      'remarks': remarks,
      'status': status,
      'flightLocalUlds': flightLocalUlds,
    };

    await supabase.rpc('rpc_save_flight_manifest', params: {'payload': flightPayload});
  }
}
