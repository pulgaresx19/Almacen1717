import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show currentUserData;

class CoordinatorV2Logic extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  DateTime? selectedDate;
  bool isLoadingFlights = false;
  List<Map<String, dynamic>> flights = [];
  String? selectedFlightId;
  
  bool isLoadingUlds = false;
  List<Map<String, dynamic>> ulds = [];

  Map<String, dynamic>? globalSearchResult;
  bool isGlobalSearching = false;

  String? selectedUldId;
  bool isLoadingUldAwbs = false;
  List<Map<String, dynamic>> uldAwbs = [];

  RealtimeChannel? _realtimeChannel;

  CoordinatorV2Logic() {
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeChannel = supabase.channel('coordinator_v2_changes');
    
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'flights',
      callback: (payload) {
        if (selectedDate != null) fetchFlights(selectedDate!);
      }
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ulds',
      callback: (payload) {
        if (selectedFlightId != null) fetchUldsForFlight(selectedFlightId!);
      }
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'awb_splits',
      callback: (payload) {
        if (selectedUldId != null) fetchAwbsForUld(selectedUldId!);
      }
    ).onPostgresChanges( // We can listen to damage_reports too if needed
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'damage_reports',
      callback: (payload) {
        if (selectedUldId != null) fetchAwbsForUld(selectedUldId!);
      }
    ).subscribe();
  }

  void selectUld(String uldId) {
    if (selectedUldId == uldId) {
      selectedUldId = null;
      uldAwbs = [];
    } else {
      selectedUldId = uldId;
      fetchAwbsForUld(uldId);
    }
    notifyListeners();
  }

  Future<void> fetchAwbsForUld(String uldId) async {
    final bool isRefetchingSame = selectedUldId == uldId && uldAwbs.isNotEmpty;
    if (!isRefetchingSame) {
      isLoadingUldAwbs = true;
      notifyListeners();
    }
    
    try {
      final res = await supabase
          .from('awb_splits')
          .select('*, awbs(*)')
          .eq('uld_id', uldId)
          .order('created_at', ascending: false);
      uldAwbs = List<Map<String, dynamic>>.from(res);
      
      // Auto-evaluate if all AWBs are checked
      bool allChecked = true;
      if (uldAwbs.isEmpty) allChecked = false;
      for (var awbSplit in uldAwbs) {
        final d = awbSplit['data_coordinator'];
        bool hasData = false;
        if (d is Map) {
          hasData = d.isNotEmpty;
        } else if (d is String) {
          hasData = d.trim().isNotEmpty && d != 'null' && d != '{}';
        }
        if (!hasData) {
          allChecked = false;
          break;
        }
      }

      final idx = ulds.indexWhere((u) => u['id_uld'].toString() == uldId);
      if (idx != -1) {
        final wasChecked = ulds[idx]['all_checked'] == true;
        ulds[idx]['all_checked'] = allChecked;
        
        // Auto-collapse if it just became fully checked AFTER being opened explicitly.
        if (allChecked && !wasChecked && isRefetchingSame && selectedUldId == uldId) {
          selectedUldId = null;
          uldAwbs = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching AWBs for ULD: $e');
      uldAwbs = [];
    }
    
    isLoadingUldAwbs = false;
    notifyListeners();
  }

  void disposeLogic() {
    _realtimeChannel?.unsubscribe();
  }

  @override
  void dispose() {
    disposeLogic();
    super.dispose();
  }

  Future<void> performGlobalSearch(String query) async {
    isGlobalSearching = true;
    notifyListeners();

    try {
      final resList = await supabase
          .from('ulds')
          .select()
          .ilike('uld_number', '%$query%')
          .limit(10);
      
      if (resList.isNotEmpty) {
        globalSearchResult = {'list': resList};
      } else {
        globalSearchResult = {
          'error': true,
          'message': 'Requested ULD not found.',
        };
      }
    } catch (e) {
      globalSearchResult = {'error': true, 'message': 'Error: $e'};
    }

    isGlobalSearching = false;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
    fetchFlights(date);
  }

  void selectFlight(String idFlight) {
    if (selectedFlightId == idFlight) {
      selectedFlightId = null; // deselect
      ulds = [];
    } else {
      selectedFlightId = idFlight;
      fetchUldsForFlight(idFlight);
    }
    notifyListeners();
  }

  Future<void> fetchUldsForFlight(String idFlight) async {
    final bool isRefetchingSame = selectedFlightId == idFlight && ulds.isNotEmpty;
    if (!isRefetchingSame) {
      isLoadingUlds = true;
      notifyListeners();
    }
    
    try {
      final res = await supabase.from('ulds').select().eq('id_flight', idFlight).order('created_at', ascending: true);
      ulds = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching ULDs: $e');
      ulds = [];
    }
    
    isLoadingUlds = false;
    notifyListeners();
  }

  Future<void> fetchFlights(DateTime dt) async {
    final bool isRefetchingSame = selectedDate == dt && flights.isNotEmpty;
    if (!isRefetchingSame) {
      isLoadingFlights = true;
      notifyListeners();
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(dt);
    final validDates = <String>[];
    for (int i = -15; i <= 15; i++) {
      validDates.add(DateFormat('yyyy-MM-dd').format(dt.add(Duration(days: i))));
    }

    try {
      final res = await supabase.from('flights').select(); // In full deployment we might limit this, but let's filter in memory for now due to date formatting.
      
      final validList = <Map<String, dynamic>>[];
      for (var f in res) {
        bool isDel = f['status']?.toString().toLowerCase() == 'delayed';
        if (isDel && f['time_delay'] != null && f['time_delay'].toString().isNotEmpty && f['time_delay'].toString() != '-') {
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
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    isLoadingFlights = false;
    notifyListeners();
  }

  Future<void> markUldReady(String uldId) async {
    try {
      final String userFullName = currentUserData.value?['full-name'] ?? 'Unknown User';
      final String nowIso = DateTime.now().toUtc().toIso8601String();
      await supabase.from('ulds').update({
        'time_checked': nowIso,
        'user_checked': userFullName,
      }).eq('id_uld', uldId);
      
      final idx = ulds.indexWhere((u) => u['id_uld'] == uldId);
      if (idx != -1) {
        ulds[idx]['time_checked'] = nowIso;
        ulds[idx]['user_checked'] = userFullName;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking ULD as ready: $e');
    }
  }
}
