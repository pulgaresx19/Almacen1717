import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AddAwbV2Logic {
  static Future<List<Map<String, dynamic>>> loadFlights() async {
    try {
      final res = await Supabase.instance.client
          .from('flights')
          .select()
          .order('date', ascending: false);
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

  static Future<List<Map<String, dynamic>>> loadUldsForFlight(String flightId) async {
    try {
      final res = await Supabase.instance.client
          .from('ulds')
          .select('id_uld, uld_number, is_break')
          .eq('id_flight', flightId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error loading ULDs: $e');
      return [];
    }
  }

  static Future<void> saveAllAwbs({
    required List<Map<String, dynamic>> localAwbs,
    required String userName,
  }) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    Set<String> uniqueAwbs = {};
    for (var a in localAwbs) {
       uniqueAwbs.add(a['awbNumber']);
    }
    
    final dbAwbs = await Supabase.instance.client.from('awbs').select('id, awb_number, total_espected, total_weight').inFilter('awb_number', uniqueAwbs.toList());
    
    Map<String, Map<String, dynamic>> dbAwbMap = {};
    for (var row in dbAwbs) {
       dbAwbMap[row['awb_number'].toString()] = Map.from(row);
    }



    Map<String, String> uldIdMap = {};
    for (var a in localAwbs) {
       final uldNum = a['refUld']?.toString().trim() ?? '';
       if (uldNum.isNotEmpty && uldNum != 'MANUAL') {
          final fId = a['flight_id'];
          final key = '${fId}_$uldNum';
          if (!uldIdMap.containsKey(key)) {
              var q = Supabase.instance.client.from('ulds').select('id_uld').eq('uld_number', uldNum);
              if (fId != null) q = q.eq('id_flight', fId);
              final res = await q.order('created_at', ascending: false).limit(1).maybeSingle();
              if (res != null) {
                 uldIdMap[key] = res['id_uld'].toString();
              } else {
                 uldIdMap[key] = '';
              }
          }
       }
    }

    for (var a in localAwbs) {
       final awbNum = a['awbNumber'];
       Map<String, dynamic>? currentAwbData = dbAwbMap[awbNum];
       String? currentAwbId = currentAwbData?['id']?.toString();
       
       bool hasCoordManual = a['coordinator'] != null && a['coordinator'].toString().isNotEmpty;
       Map<String, String>? coordCounts = a['coordinatorCounts'] as Map<String, String>?;
       bool hasCoordCounts = coordCounts != null && coordCounts.isNotEmpty;
       
       Map<String, dynamic>? coordRecord;
       if (hasCoordManual || hasCoordCounts) {
           coordRecord = {
               'processed_by': userName,
               'processed_at': nowUtc
           };
           if (a['refUld'] != null && a['refUld'] != 'MANUAL') {
               coordRecord['refULD'] = a['refUld'];
               coordRecord['refCarrier'] = a['refCarrier'];
               coordRecord['refNumber'] = a['refNumber'];
           }
           if (hasCoordManual) coordRecord['manual_entry'] = a['coordinator'];
            bool addedAnyCount = false;
            if (hasCoordCounts) {
                if (coordCounts['AGI Skid'] != null) {
                   final agiList = coordCounts['AGI Skid']!.split(RegExp(r'[,\s+]+')).where((e) => int.tryParse(e) != null && int.parse(e) > 0).toList();
                   for (int i = 0; i < agiList.length; i++) {
                      coordRecord['${i + 1}. AGI skid'] = int.parse(agiList[i]);
                      addedAnyCount = true;
                   }
                }
                for (String k in ['Pre Skid', 'Crate', 'Box', 'Other']) {
                   final val = coordCounts[k];
                   if (val != null && val.trim().isNotEmpty && val.trim() != '0') {
                      String safeKey = k == 'Pre Skid' ? 'Pre skid' : k;
                      coordRecord[safeKey] = int.parse(val.trim());
                      addedAnyCount = true;
                   }
                }
            }
            
            if (!hasCoordManual && !addedAnyCount && !coordRecord.containsKey('refULD')) {
                coordRecord = null;
            }
        }
        
       Map<String, dynamic>? itemLocs = a['itemLocations'] as Map<String, dynamic>?;
       bool hasItemLocs = itemLocs != null && itemLocs.isNotEmpty;
       
       Map<String, dynamic>? locRecord;
       if ((a['location'] != null && a['location'].toString().isNotEmpty) || hasItemLocs) {
           locRecord = {
               'processed_by': userName,
               'processed_at': nowUtc
           };
           if (a['refUld'] != null && a['refUld'] != 'MANUAL') {
               locRecord['refULD'] = a['refUld'];
               locRecord['refCarrier'] = a['refCarrier'];
               locRecord['refNumber'] = a['refNumber'];
           }
           if (a['location'] != null && a['location'].toString().isNotEmpty) locRecord['manual_entry'] = a['location'];
           if (hasItemLocs) {
               Map<String, String> sanitizedLocs = {};
               itemLocs.forEach((k, v) {
                 if (v.toString().trim().isNotEmpty) sanitizedLocs[k] = v.toString().trim();
               });
               locRecord['locations'] = sanitizedLocs;
           }
       }

       final num formExpected = a['pieces'] ?? 0;
       final num formWeight = a['weight'] ?? 0.0;
       final num formTotal = a['total'] ?? 1;

       int totalChecked = 0;
       if (hasCoordCounts) {
           if (coordCounts['AGI Skid'] != null) {
              final parts = coordCounts['AGI Skid']!.split(RegExp(r'[,\s-]+'));
              for (var p in parts) { totalChecked += int.tryParse(p) ?? 0; }
           }
           for (String k in ['Pre Skid', 'Crate', 'Box', 'Other']) {
              totalChecked += int.tryParse(coordCounts[k] ?? '') ?? 0;
           }
       }
       
       if (coordRecord != null && totalChecked != formExpected) {
           int diff = (totalChecked - formExpected).toInt();
           coordRecord['discrepancy_expected'] = formExpected;
           coordRecord['discrepancy_checked'] = totalChecked;
           coordRecord['discrepancy_amount'] = diff.abs();
           coordRecord['discrepancy_type'] = diff > 0 ? 'OVER' : 'SHORT';
       }

       if (currentAwbId == null) {
          List dataCoord = [];
          if (coordRecord != null) dataCoord.add(coordRecord);
          List dataLoc = [];
          if (locRecord != null) dataLoc.add(locRecord);
          
          final payload = {
            'awb_number': awbNum,
            'total_pieces': formTotal,
            'total_espected': formExpected,
            'total_weight': formWeight,
          };
          
          final ins = await Supabase.instance.client.from('awbs').insert(payload).select().single();
          currentAwbId = ins['id'].toString();
          dbAwbMap[awbNum] = {
             'id': currentAwbId,
             'total_espected': formExpected,
             'total_weight': formWeight,
          };
       } else {
          final num curExpected = currentAwbData!['total_espected'] ?? 0;
          final num curWeight = currentAwbData['total_weight'] ?? 0.0;
          
          final updatedExpected = curExpected + formExpected;
          final updatedWeight = curWeight + formWeight;

          await Supabase.instance.client.from('awbs').update({
             'total_espected': updatedExpected,
             'total_weight': updatedWeight,
          }).eq('id', currentAwbId);
          
          currentAwbData['total_espected'] = updatedExpected;
          currentAwbData['total_weight'] = updatedWeight;
       }
       
       final fId = a['flight_id'];
       String? uldId;
       final uldNum = a['refUld']?.toString().trim() ?? '';
       if (uldNum.isNotEmpty && uldNum != 'MANUAL') {
          final key = '${fId}_$uldNum';
          if (uldIdMap[key] != null && uldIdMap[key]!.isNotEmpty) {
             uldId = uldIdMap[key];
          }
       }
       
       final houseData = a['house'] != null && (a['house'] as List).isNotEmpty ? (a['house'] as List).join(', ') : null;
       
       final splitPayload = {
          'awb_id': currentAwbId,
          'pieces': formExpected,
          'weight': formWeight,
          'status': 'Pending',
          'flight_id': fId,
          'uld_id': uldId,
          'house_number': houseData,
          'remarks': a['remarks'],
          'data_coordinator': coordRecord != null ? [coordRecord] : null,
          'data_location': locRecord != null ? [locRecord] : null,
          'total_checked': totalChecked > 0 ? totalChecked : null,
       };
       await Supabase.instance.client.from('awb_splits').insert(splitPayload);
    }
  }
}