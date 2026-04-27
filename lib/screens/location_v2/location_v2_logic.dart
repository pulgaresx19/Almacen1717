import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LocationV2Logic extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  DateTime? selectedDate;

  bool isLoadingFlights = false;
  List<Map<String, dynamic>> flights = [];
  String? selectedFlightId;

  bool isLoadingUlds = false;
  List<Map<String, dynamic>> ulds = [];
  String? selectedUldId;
  
  List<Map<String, dynamic>> allFlightAwbs = [];

  bool isLoadingUldAwbs = false;
  List<Map<String, dynamic>> uldAwbs = [];

  RealtimeChannel? _uldsSubscription;

  bool showCompletedUlds = false;

  void toggleShowCompleted(bool v) {
    showCompletedUlds = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _uldsSubscription?.unsubscribe();
    super.dispose();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
    fetchFlights(date);
  }

  void selectFlight(String idFlight) {
    if (selectedFlightId == idFlight) {
      selectedFlightId = null;
      ulds = [];
      selectedUldId = null;
      uldAwbs = [];
      _uldsSubscription?.unsubscribe();
      _uldsSubscription = null;
    } else {
      selectedFlightId = idFlight;
      selectedUldId = null;
      uldAwbs = [];
      fetchUldsForFlight(idFlight);
      _subscribeToUlds(idFlight);
    }
    notifyListeners();
  }

  void _subscribeToUlds(String idFlight) {
    _uldsSubscription?.unsubscribe();
    _uldsSubscription = supabase
        .channel('public:ulds:location_$idFlight')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ulds',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_flight',
            value: idFlight,
          ),
          callback: (payload) {
            // Re-fetch ULDs when a change occurs (e.g. coordinator approves one)
            fetchUldsForFlight(idFlight, isSilent: true);
          },
        )
        .subscribe();
  }

  void selectUld(String idUld) {
    if (selectedUldId == idUld) {
      selectedUldId = null;
      uldAwbs = [];
    } else {
      selectedUldId = idUld;
      fetchAwbsForUld(idUld);
    }
    notifyListeners();
  }

  Future<void> fetchFlights(DateTime dt) async {
    isLoadingFlights = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(dt);

    try {
      final res = await supabase.from('flights').select();
      
      final validList = <Map<String, dynamic>>[];
      for (var f in res) {
        bool hasDelay = f['time_delay'] != null && f['time_delay'].toString().isNotEmpty && f['time_delay'].toString() != '-';
        if (hasDelay) {
          try {
            final localDt = DateTime.parse(f['time_delay'].toString()).toLocal();
            if (DateFormat('yyyy-MM-dd').format(localDt) == dateStr) {
              validList.add(f);
            }
          } catch (_) {}
        } else {
          try {
            if (f['date'] != null && f['date'].toString().isNotEmpty) {
              final localDt = DateTime.parse(f['date'].toString()).toLocal();
              if (DateFormat('yyyy-MM-dd').format(localDt) == dateStr) {
                validList.add(f);
              }
            }
          } catch (_) {}
        }
      }

      flights = validList;
      if (selectedFlightId != null && !flights.any((f) => f['id_flight']?.toString() == selectedFlightId)) {
        selectedFlightId = null;
        ulds = [];
        selectedUldId = null;
        uldAwbs = [];
      }
    } catch (e) {
      debugPrint('Error fetching flights: $e');
    }

    isLoadingFlights = false;
    notifyListeners();
  }

  Future<void> markUldAsCompleted(String idUld) async {
    try {
      final session = supabase.auth.currentSession;
      String userName = session?.user.email ?? 'Unknown';
      
      if (session != null) {
        if (session.user.userMetadata?['full_name'] != null) {
          userName = session.user.userMetadata!['full_name'].toString();
        }
        try {
          final profile = await supabase.from('users').select('full_name').eq('id', session.user.id).maybeSingle();
          if (profile != null && profile['full_name'] != null && profile['full_name'].toString().trim().isNotEmpty) {
            userName = profile['full_name'].toString().trim();
          }
        } catch (_) {}
      }

      // Optimistic Update: instantly update the UI while the database saves in the background
      final index = ulds.indexWhere((u) => u['id_uld']?.toString() == idUld);
      if (index != -1) {
        ulds[index]['time_saved'] = DateTime.now().toUtc().toIso8601String();
        ulds[index]['user_saved'] = userName;
        notifyListeners();
      }
      
      await supabase.from('ulds').update({
        'time_saved': DateTime.now().toUtc().toIso8601String(),
        'user_saved': userName,
      }).eq('id_uld', idUld);

      // No need to manually refetch, as the subscription should pick it up,
      // but we can manually refetch to be fast:
      if (selectedFlightId != null) {
        fetchUldsForFlight(selectedFlightId!, isSilent: true);
      }
    } catch (e) {
      debugPrint('Error marking ULD as completed: $e');
    }
  }

  Future<void> fetchUldsForFlight(String idFlight, {bool isSilent = false}) async {
    if (!isSilent) {
      isLoadingUlds = true;
      notifyListeners();
    }
    
    try {
      final res = await supabase
          .from('ulds')
          .select()
          .eq('id_flight', idFlight)
          .eq('is_break', true);

      List<Map<String, dynamic>> fetchedUlds = List<Map<String, dynamic>>.from(res);
      
      fetchedUlds.sort((a, b) {
        final aNum = a['uld_number']?.toString().toUpperCase() ?? '';
        final bNum = b['uld_number']?.toString().toUpperCase() ?? '';
        
        if (aNum == 'BULK' && bNum != 'BULK') return -1;
        if (bNum == 'BULK' && aNum != 'BULK') return 1;
        
        return aNum.compareTo(bNum);
      });
      
      ulds = fetchedUlds;

      if (ulds.isNotEmpty) {
        try {
          List<Map<String, dynamic>> tempAwbs = [];
          for (var uld in ulds) {
            final id = uld['id_uld'];
            if (id != null) {
              final awbsRes = await supabase.from('awb_splits').select('*, awbs(*)').eq('uld_id', id);
              tempAwbs.addAll(List<Map<String, dynamic>>.from(awbsRes));
            }
          }
          allFlightAwbs = tempAwbs;
        } catch (e) {
          debugPrint('Error en la carga masiva de AWBs: $e');
        }
      } else {
        allFlightAwbs = [];
      }
    } catch (e) {
      debugPrint('Error fetching ULDs: $e');
      ulds = [];
    }
    
    isLoadingUlds = false;
    notifyListeners();
  }

  Future<void> fetchAwbsForUld(String idUld) async {
    isLoadingUldAwbs = true;
    notifyListeners();
    
    try {
      final res = await supabase
          .from('awb_splits')
          .select('*, awbs(*)')
          .eq('uld_id', idUld)
          .order('created_at', ascending: false);
      uldAwbs = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching AWBs for ULD: $e');
      uldAwbs = [];
    }
    
    isLoadingUldAwbs = false;
    notifyListeners();
  }
}
