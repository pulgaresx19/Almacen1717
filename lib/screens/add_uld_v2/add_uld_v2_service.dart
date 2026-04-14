import 'package:supabase_flutter/supabase_flutter.dart';

class AddUldV2Service {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchFlights() async {
    final res = await supabase.from('flights').select('id_flight, carrier, number, date').order('created_at');
    return res.map((row) => {
      'id': row['id_flight'],
      'carrier': row['carrier'],
      'number': row['number'],
      'date-arrived': row['date'] != null ? row['date'].toString().substring(0, 10) : '',
    }).toList();
  }

  Future<void> saveAllUlds(List<Map<String, dynamic>> localUlds, List<Map<String, dynamic>> flightsList) async {
    final nowStr = DateTime.now().toIso8601String();
    final todayStr = nowStr.substring(0, 10);

    String? dummyFlightId;
    if (localUlds.any((u) => u['flight_id'] == null)) {
      final dummyCheck = await supabase.from('flights')
          .select('id_flight')
          .eq('carrier', 'NF')
          .eq('number', '0000')
          .limit(1)
          .maybeSingle();

      if (dummyCheck == null) {
        final inserted = await supabase.from('flights').insert({
          'carrier': 'NF',
          'number': '0000',
          'cant_break': 0,
          'cant_nobreak': 0,
          'status': 'Waiting',
          'remarks': '',
          'date': todayStr,
        }).select().single();
        dummyFlightId = inserted['id_flight'].toString();
      } else {
        dummyFlightId = dummyCheck['id_flight'].toString();
      }
    }

    // 1. Gather all unique AWB numbers
    Set<String> uniqueAwbNumbers = {};
    for (var uld in localUlds) {
      for (var a in (uld['awbs'] ?? [])) {
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

    // 3. Process each ULD sequentially
    for (var uld in localUlds) {
      final flightId = uld['flight_id']?.toString() ?? dummyFlightId;

      final uldPayload = {
        'uld_number': uld['uldNumber'],
        'pieces_total': uld['pieces'],
        'weight_total': uld['weight'],
        'is_break': uld['break'],
        'is_priority': uld['priority'],
        'status': uld['status'] ?? 'Waiting',
        'id_flight': flightId,
      };

      final insertedUld = await supabase.from('ulds').insert(uldPayload).select().single();
      final uldId = insertedUld['id_uld'].toString();

      List awbs = uld['awbs'] ?? [];
      for (var awb in awbs) {
        final awbNum = awb['awb_number'].toString();
        if (awbNum.isEmpty) continue;

        Map<String, dynamic>? currentAwbData = dbAwbsData[awbNum];
        String? currentAwbId = currentAwbData?['id'];

        final num formPieces = awb['pieces'] ?? 0;
        final num formWeight = awb['weight'] ?? 0.0;

        // If not in DB, insert
        if (currentAwbId == null) {
          final newAwbPayload = {
            'awb_number': awbNum,
            'total_pieces': awb['total'],
            'total_espected': formPieces,
            'total_weight': formWeight,
          };
          final insertedAwb = await supabase.from('awbs').insert(newAwbPayload).select().single();
          currentAwbId = insertedAwb['id'].toString();
          dbAwbsData[awbNum] = {
            'id': currentAwbId,
            'total_espected': formPieces,
            'total_weight': formWeight,
          }; 
        } else {
          // Exists, update totals
          final num currentExpected = currentAwbData!['total_espected'];
          final num currentWeight = currentAwbData['total_weight'];
          
          final updatedExpected = currentExpected + formPieces;
          final updatedWeight = currentWeight + formWeight;

          await supabase.from('awbs').update({
                'total_espected': updatedExpected,
                'total_weight': updatedWeight,
              }).eq('id', currentAwbId);

          currentAwbData['total_espected'] = updatedExpected;
          currentAwbData['total_weight'] = updatedWeight;
        }

        // Insert into awb_splits
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

  Future<Map<String, dynamic>?> checkAwbTotal(String awbNumber) async {
    try {
      final res = await supabase.from('awbs').select('total_pieces, total_espected').eq('awb_number', awbNumber).maybeSingle();
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
}
