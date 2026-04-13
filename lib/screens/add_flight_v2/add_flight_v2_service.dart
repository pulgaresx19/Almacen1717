import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddFlightV2Service {
  Future<Map<String, dynamic>?> fetchAwbTotal(String awbNumber) async {
    try {
      final res = await Supabase.instance.client
          .from('AWB')
          .select('total')
          .eq('AWB-number', awbNumber)
          .maybeSingle();
      return res;
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

    // Transforma las fechas y horas al formato esperado
    String fDate = dateArrived;
    if (fDate.isNotEmpty) {
      try { fDate = DateFormat('yyyy-MM-dd').format(DateFormat('MM/dd/yyyy').parse(dateArrived)); } catch (_) {}
    }
    
    String? fTime = timeArrived;
    if (fTime.isNotEmpty) {
      try { fTime = DateFormat('HH:mm').format(DateFormat('hh:mm a').parse(timeArrived)); } catch (_) {}
    } else {
      fTime = null;
    }

    String fDelayedDate = delayedDate;
    if (fDelayedDate.isNotEmpty) {
      try { fDelayedDate = DateFormat('yyyy-MM-dd').format(DateFormat('MM/dd/yyyy').parse(delayedDate)); } catch (_) {}
    }
    
    String fDelayedTime = delayedTime;
    if (fDelayedTime.isNotEmpty) {
      try { fDelayedTime = DateFormat('HH:mm').format(DateFormat('hh:mm a').parse(delayedTime)); } catch (_) {}
    }

    final flightPayload = {
      'carrier': carrier,
      'number': number,
      'cant-break': breakCount,
      'cant-noBreak': noBreakCount,
      'date-arrived': fDate,
      'time-arrived': fTime,
      'remarks': remarks,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (status == 'Delayed' && fDelayedDate.isNotEmpty && fDelayedTime.isNotEmpty) {
       try {
         final dDate = DateFormat('yyyy-MM-dd').parse(fDelayedDate);
         final dTime = DateFormat('HH:mm').parse(fDelayedTime);
         final dt = DateTime(dDate.year, dDate.month, dDate.day, dTime.hour, dTime.minute);
         flightPayload['time-delayed'] = dt.toUtc().toIso8601String();
       } catch (_) {}
    }

    await supabase.from('Flight').insert([flightPayload]);
    
    if (flightLocalUlds.isNotEmpty) {
      List<Map<String, dynamic>> uldPayloads = [];
      Map<String, Map<String, dynamic>> mergedAwbs = {};

      for (var uld in flightLocalUlds) {
        List awbs = uld['awbs'] ?? [];
        final dataUld = awbs.map((a) => {
          'awb_number': a['awb_number'],
          'pieces': a['pieces'],
          'weight': a['weight'],
          'total': a['total'],
          'house_number': a['house_number'],
          'remarks': a['remarks'],
        }).toList();

        uldPayloads.add({
          'ULD-number': uld['uldNumber'],
          'refCarrier': carrier,
          'refNumber': number,
          'refDate': fDate,
          'pieces': uld['pieces'],
          'weight': uld['weight'],
          'isPriority': uld['priority'],
          'isBreak': uld['break'],
          'status': 'Waiting',
          'data-ULD': dataUld,
          'created_at': DateTime.now().toIso8601String(),
        });

        for (var awb in awbs) {
          final num = awb['awb_number'];
          if (!mergedAwbs.containsKey(num)) {
             mergedAwbs[num] = {
               'AWB-number': num,
               'total': awb['total'],
               'data-AWB': [],
             };
          }
          (mergedAwbs[num]!['data-AWB'] as List).add({
              'refCarrier': carrier,
              'refNumber': number,
              'refDate': fDate,
              'refULD': uld['uldNumber'],
              'pieces': awb['pieces'],
              'weight': awb['weight'],
              'remarks': awb['remarks'],
              'isBreak': uld['break'],
              'house_number': awb['house_number']
          });
        }
      }

      await supabase.from('ULD').insert(uldPayloads);

      if (mergedAwbs.isNotEmpty) {
         final awbNumbers = mergedAwbs.keys.toList();
         final existingDbAwbs = await supabase.from('AWB').select('AWB-number, data-AWB').inFilter('AWB-number', awbNumbers);
         
         final existingAwbMap = { for (var e in existingDbAwbs) e['AWB-number'] : e['data-AWB'] };
         
         for (var awbNum in mergedAwbs.keys) {
            if (existingAwbMap.containsKey(awbNum)) {
               var dbData = existingAwbMap[awbNum];
               if (dbData is List) {
                  (mergedAwbs[awbNum]!['data-AWB'] as List).insertAll(0, dbData);
               }
            }
         }
         
         final finalAwbPayloads = mergedAwbs.values.map((v) {
           final n = v['AWB-number'];
           Map<String, dynamic> out = {
             'AWB-number': n,
             'total': v['total'],
             'data-AWB': v['data-AWB'],
           };
           if (!existingAwbMap.containsKey(n)) {
              out['created_at'] = DateTime.now().toIso8601String();
           }
           return out;
         }).toList();
         
         await supabase.from('AWB').upsert(finalAwbPayloads, onConflict: 'AWB-number');
      }
    }
  }
}
