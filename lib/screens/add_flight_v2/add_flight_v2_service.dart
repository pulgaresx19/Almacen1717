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

    final flightPayload = {
      'carrier': carrier,
      'number': number,
      if (flightDate != null) 'date': flightDate.toIso8601String(),
      'cant_break': breakCount,
      'cant_nobreak': noBreakCount,
      'remarks': remarks,
      'status': status,
    };

    final insertedFlight = await supabase.from('flights').insert(flightPayload).select().single();
    // ignore: unused_local_variable
    final flightId = insertedFlight['id_flight'];

    if (flightLocalUlds.isNotEmpty) {
      // 1. Gather all unique AWB numbers from the form payload
      Set<String> uniqueAwbNumbers = {};
      for (var uld in flightLocalUlds) {
        List awbs = uld['awbs'] ?? [];
        for (var a in awbs) {
          if (a['awb_number'] != null && a['awb_number'].toString().isNotEmpty) {
            uniqueAwbNumbers.add(a['awb_number'].toString());
          }
        }
      }

      // 2. Look up existing records in the master "awbs" table
      Map<String, Map<String, dynamic>> dbAwbsData = {};
      if (uniqueAwbNumbers.isNotEmpty) {
        final existingAwbs = await supabase
            .from('awbs')
            .select('id, awb_number, total_espected, total_weight')
            .inFilter('awb_number', uniqueAwbNumbers.toList());
        for (var row in existingAwbs) {
          dbAwbsData[row['awb_number'].toString()] = {
            'id': row['id'].toString(),
            'total_espected': row['total_espected'] ?? 0,
            'total_weight': row['total_weight'] ?? 0.0,
          };
        }
      }

      // 3. Process each ULD and its AWBs sequentially
      for (var uld in flightLocalUlds) {
        final uldPayload = {
          'uld_number': uld['uldNumber'],
          'pieces_total': uld['pieces'],
          'weight_total': uld['weight'],
          'is_break': uld['break'],
          'is_priority': uld['priority'],
          'status': 'Waiting',
          'id_flight': flightId,
        };

        final insertedUld =
            await supabase.from('ulds').insert(uldPayload).select().single();
        final uldId = insertedUld['id_uld'];

        List awbs = uld['awbs'] ?? [];
        for (var awb in awbs) {
          final awbNum = awb['awb_number'].toString();
          if (awbNum.isEmpty) continue;

          Map<String, dynamic>? currentAwbData = dbAwbsData[awbNum];
          String? currentAwbId = currentAwbData?['id'];

          final num formPieces = awb['pieces'] ?? 0;
          final num formWeight = awb['weight'] ?? 0.0;

          // If not in DB, insert into "awbs" master table
          if (currentAwbId == null) {
            final newAwbPayload = {
              'awb_number': awbNum,
              'total_pieces': awb['total'],
              'total_espected': formPieces,
              'total_weight': formWeight,
            };
            final insertedAwb = await supabase
                .from('awbs')
                .insert(newAwbPayload)
                .select()
                .single();
            currentAwbId = insertedAwb['id'].toString();
            dbAwbsData[awbNum] = {
              'id': currentAwbId,
              'total_espected': formPieces,
              'total_weight': formWeight,
            }; 
          } else {
            // Already exists, accumulate pieces and weight
            final num currentExpected = currentAwbData!['total_espected'];
            final num currentWeight = currentAwbData['total_weight'];
            
            final updatedExpected = currentExpected + formPieces;
            final updatedWeight = currentWeight + formWeight;

            await supabase
                .from('awbs')
                .update({
                  'total_espected': updatedExpected,
                  'total_weight': updatedWeight,
                })
                .eq('id', currentAwbId);

            currentAwbData['total_espected'] = updatedExpected;
            currentAwbData['total_weight'] = updatedWeight;
          }

          // Create the many-to-many split relationship using both UUID and natural key (for readability)
          final splitPayload = {
            'awb_id': currentAwbId,
            'awb_number': awbNum,
            'pieces': awb['pieces'],
            'weight': awb['weight'],
            'status': 'Pending',
            'flight_id': flightId,
            'uld_id': uldId,
            'house_number': awb['house_number'],
            'remarks': awb['remarks'],
          };
          await supabase.from('awb_splits').insert(splitPayload);
        }
      }
    }
  }
}
