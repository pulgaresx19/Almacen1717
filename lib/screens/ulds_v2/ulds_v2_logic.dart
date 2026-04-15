import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UldsV2Logic extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> uldsList = [];
  Map<String, Map<String, dynamic>> flightsMap = {};
  RealtimeChannel? _realtimeChannel;

  UldsV2Logic() {
    _initRealtime();
  }

  void _initRealtime() {
    _realtimeChannel = supabase
        .channel('public:ulds_v2_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ulds',
          callback: (payload) {
            fetchUlds(silent: true);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> fetchUlds({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final res = await supabase.from('ulds').select().order('created_at', ascending: false);
      uldsList = List<Map<String, dynamic>>.from(res);

      // Sort: Breaks first, then No Breaks. Within the same group, sort by ULD number.
      uldsList.sort((a, b) {
        final aBreak = a['is_break'] == true;
        final bBreak = b['is_break'] == true;
        if (aBreak != bBreak) {
          return aBreak ? -1 : 1;
        }
        final aNum = (a['uld_number'] ?? '').toString().toLowerCase();
        final bNum = (b['uld_number'] ?? '').toString().toLowerCase();
        return aNum.compareTo(bNum);
      });
      
      // Fetch flights to match flight_id
      Set<String> flightIds = {};
      for (var u in uldsList) {
        if (u['id_flight'] != null) {
          flightIds.add(u['id_flight'].toString());
        }
      }

      if (flightIds.isNotEmpty) {
        final fRes = await supabase.from('flights').select('id_flight, carrier, number, date').inFilter('id_flight', flightIds.toList());
        for (var f in fRes) {
          flightsMap[f['id_flight'].toString()] = f;
        }
      }

    } catch (e) {
      debugPrint('Error fetching V2 ULDs: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}
