import 'dart:async';
import 'dart:convert';
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
          .eq('is_break', true)
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
      final res = await supabase.from('ulds').select().eq('id_flight', idFlight).eq('is_break', true).order('created_at', ascending: true);
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
      List<Map<String, dynamic>> finalDiscrepancies = [];
      
      // Fetch the latest AWBs for this ULD directly to ensure accurate discrepancy counting,
      // because the user might click "Ready" when the ULD is collapsed and uldAwbs is empty.
      final res = await supabase
          .from('awb_splits')
          .select('*, awbs(*)')
          .eq('uld_id', uldId);
      final List<Map<String, dynamic>> currentAwbs = List<Map<String, dynamic>>.from(res);

      for (var awbSplit in currentAwbs) {
        final dynamic d = awbSplit['data_coordinator'];
        Map? dataCoord;
        
        if (d is Map) {
          dataCoord = d;
        } else if (d is String && d.trim().isNotEmpty && d != 'null') {
          try {
            dataCoord = jsonDecode(d); 
          } catch (_) {}
        }
        
        if (dataCoord != null && dataCoord['discrepancy_amount'] != null) {
          final String awbNum = awbSplit['awbs']?['awb_number']?.toString() ?? 'Unknown AWB';
          finalDiscrepancies.add({
            'awb': awbNum,
            'amount': dataCoord['discrepancy_amount'],
            'type': dataCoord['discrepancy_type'],
          });
        }
      }

      final String userFullName = currentUserData.value?['full-name'] ?? 'Unknown User';
      final String nowIso = DateTime.now().toUtc().toIso8601String();
      
      await supabase.from('ulds').update({
        'time_checked': nowIso,
        'user_checked': userFullName,
        'discrepancies_summary': finalDiscrepancies,
      }).eq('id_uld', uldId);

      final idx = ulds.indexWhere((u) => u['id_uld'].toString() == uldId);
      if (idx != -1) {
        ulds[idx]['time_checked'] = nowIso;
        ulds[idx]['user_checked'] = userFullName;
        ulds[idx]['discrepancies_summary'] = finalDiscrepancies;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking ULD as ready: $e');
    }
  }

  Future<void> addNewAwb(String awbNumber, int pieces, int total, double weight, String uldId, String flightId, String remarks, List<String> houseNumbers) async {
    bool isNewAwb = false;
    dynamic masterAwbId;
    num originalExpected = 0;
    num originalWeight = 0.0;

    try {
      final existingAwb = await supabase
          .from('awbs')
          .select('id, total_espected, total_weight')
          .eq('awb_number', awbNumber)
          .limit(1);
      
      if (existingAwb.isNotEmpty) {
        masterAwbId = existingAwb.first['id'];
        originalExpected = existingAwb.first['total_espected'] ?? 0;
        originalWeight = existingAwb.first['total_weight'] ?? 0.0;
        
        await supabase.from('awbs').update({
          'total_espected': originalExpected + pieces,
          'total_weight': originalWeight + weight,
        }).eq('id', masterAwbId);
        
      } else {
        isNewAwb = true;
        final insertedAwb = await supabase.from('awbs').insert({
          'awb_number': awbNumber,
          'total_pieces': total,
          'total_espected': pieces,
          'total_weight': weight,
        }).select('id').single();
        masterAwbId = insertedAwb['id'];
      }
      
      await supabase.from('awb_splits').insert({
        'uld_id': int.tryParse(uldId) ?? uldId,
        'awb_id': masterAwbId,
        'pieces': pieces,
        'weight': weight,
        'status': 'Pending',
        'flight_id': int.tryParse(flightId) ?? flightId,
        'house_number': houseNumbers,
        'remarks': remarks,
        'is_new': true,
      });
    } catch (e) {
      debugPrint('Error adding new AWB, attempting rollback: $e');
      // Compensation (Rollback) layer
      if (masterAwbId != null) {
        try {
          if (isNewAwb) {
            await supabase.from('awbs').delete().eq('id', masterAwbId);
          } else {
            await supabase.from('awbs').update({
              'total_espected': originalExpected,
              'total_weight': originalWeight,
            }).eq('id', masterAwbId);
          }
        } catch (rollbackError) {
          debugPrint('Fatal: Rollback failed: $rollbackError');
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchAwbTotalAsync(String awbNumber) async {
    try {
      final res = await supabase
          .from('awbs')
          .select('id, total_pieces, total_weight, total_espected')
          .eq('awb_number', awbNumber)
          .limit(1);
      if (res.isNotEmpty) return res.first;
      return null;
    } catch (_) {
      return null;
    }
  }

  int getLocalUsedPieces(String awbNumber) {
    int used = 0;
    for (var u in ulds) {
      final splits = (u['awb_splits'] is List) ? u['awb_splits'] as List : [];
      for (var s in splits) {
        final master = s['awbs'] ?? {};
        if (master['awb_number'] == awbNumber || s['awb_number'] == awbNumber) {
          used += (s['pieces'] as num?)?.toInt() ?? (s['pieces_split'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return used;
  }
}
