import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemPanelLogic extends ChangeNotifier {
  final int panelId;
  String authorName;
  final Function(String, bool, String, String)? onUldToggled;
  final Function(String, String)? onFlightReceived;

  DateTime? date;
  List<Map<String, dynamic>> flights = [];
  bool isLoading = false;
  String? selectedFlightId;

  List<Map<String, dynamic>> ulds = [];
  bool isLoadingUlds = false;

  String searchQuery = '';

  bool showReceivedOverlay = false;
  Map<String, dynamic>? lastReceivedUld;
  Map<String, dynamic>? activeAwbOverlay;

  StreamSubscription<List<Map<String, dynamic>>>? _uldSub;
  StreamSubscription<List<Map<String, dynamic>>>? _flightSub;

  SystemPanelLogic({
    required this.panelId,
    required this.authorName,
    this.onUldToggled,
    this.onFlightReceived,
  });

  @override
  void dispose() {
    _uldSub?.cancel();
    _flightSub?.cancel();
    super.dispose();
  }

  void fetchFlights(DateTime dt, ValueChanged<String?> onFlightSelected) {
    _flightSub?.cancel();
    isLoading = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(dt);
    final validDates = <String>[];
    for (int i = -15; i <= 15; i++) {
      validDates.add(DateFormat('yyyy-MM-dd').format(dt.add(Duration(days: i))));
    }

    _flightSub = Supabase.instance.client
        .from('flights')
        .select()
        .order('date', ascending: false)
        .limit(300)
        .asStream().listen(
      (data) {
        final validList = <Map<String, dynamic>>[];
        for (var f in data) {
          bool hasDelay = f['time_delay'] != null && f['time_delay'].toString().isNotEmpty && f['time_delay'].toString() != '-';
          if (hasDelay) {
            try {
              final localDt = DateTime.parse(f['time_delay'].toString()).toLocal();
              if (DateFormat('yyyy-MM-dd').format(localDt) == dateStr) {
                validList.add(f);
              }
            } catch (_) {}
          } else {
            final fDateStr = f['date']?.toString();
            if (fDateStr != null && fDateStr.isNotEmpty) {
              final localDt = DateTime.parse(fDateStr).toLocal();
              if (DateFormat('yyyy-MM-dd').format(localDt) == dateStr) {
                validList.add(f);
              }
            }
          }
        }
        
        flights = validList;
        isLoading = false;
        
        if (selectedFlightId != null &&
            !flights.any((f) => '${f['carrier']}-${f['number']}' == selectedFlightId)) {
          selectedFlightId = null;
          ulds.clear();
          onFlightSelected(null);
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error: $e');
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void selectFlight(String? chipId, Map<String, dynamic>? flight, ValueChanged<String?> onFlightSelected) {
    selectedFlightId = chipId;
    onFlightSelected(chipId);
    lastReceivedUld = null;
    if (chipId == null || flight == null) {
      ulds.clear();
      notifyListeners();
    } else {
      notifyListeners();
      Future.microtask(() {
        _fetchUldsForFlight(flight);
        final sysTable = panelId == 1 ? 'system1' : 'system2';
        Supabase.instance.client
            .from(sysTable)
            .update({
              'carrier_flight$panelId': flight['carrier'],
              'number_flight$panelId': flight['number'],
              'date_flight$panelId': flight['date'] ?? flight['date_arrived'],
            })
            .eq('id', 1)
            .then((_) {}, onError: (e) => debugPrint('Err updating $sysTable: $e'));
      });
    }
  }

  // Cross-panel sync methods
  List<Map<String, dynamic>> get filteredUlds {
    if (searchQuery.trim().isEmpty) return ulds;
    final q = searchQuery.trim().toLowerCase();
    return ulds.where((u) {
      final uldNum = (u['uld_number']?.toString() ?? '').toLowerCase();
      final uldPcs = (u['pieces_total']?.toString() ?? '').toLowerCase();
      final uldWgt = (u['weight_total']?.toString() ?? '').toLowerCase();
      final isBreakStr = (u['is_break'] == true) ? 'break' : 'no break';
      
      return uldNum.contains(q) || uldPcs.contains(q) || uldWgt.contains(q) || isBreakStr.contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void syncUldToggled(String uldId, bool isChecked, String truckTime, String author) {
    try {
      final uld = ulds.firstWhere((u) => u['id_uld'] == uldId);
      final idx = flights.indexWhere((f) => '${f['carrier']}-${f['number']}' == selectedFlightId);
      
      if (isChecked) {
        if (idx != -1) {
          if (flights[idx]['local_first_truck'] == null && flights[idx]['first_truck'] == null) {
            flights[idx]['local_first_truck'] = truckTime;
          }
          flights[idx]['local_truck_arrived'] ??= <String, dynamic>{};
          String uldKey = uld['uld_number']?.toString() ?? 'Unknown';
          flights[idx]['local_truck_arrived'][uldKey] = truckTime;
        }
        uld['time_received'] = truckTime;
        uld['user_received'] = author;
      } else {
        uld['time_received'] = null;
        uld['user_received'] = null;
        if (idx != -1 && flights[idx]['local_truck_arrived'] != null) {
          String uldKey = uld['uld_number']?.toString() ?? 'Unknown';
          (flights[idx]['local_truck_arrived'] as Map).remove(uldKey);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  void syncFlightReceived(String firstTruckTime, String lastTruckTime) {
    final currentFlightIdx = flights.indexWhere((f) => '${f['carrier']}-${f['number']}' == selectedFlightId);
    if (currentFlightIdx != -1) {
      flights[currentFlightIdx]['is_received'] = true;
      flights[currentFlightIdx]['first_truck'] = firstTruckTime;
      flights[currentFlightIdx]['last_truck'] = lastTruckTime;
      showReceivedOverlay = true;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        showReceivedOverlay = false;
        notifyListeners();
      });
    }
  }

  void _fetchUldsForFlight(Map<String, dynamic> flight) {
    _uldSub?.cancel();
    isLoadingUlds = true;
    notifyListeners();

    _uldSub = Supabase.instance.client
        .from('ulds')
        .select()
        .eq('id_flight', flight['id_flight'])
        .asStream().listen(
      (data) {
        _processUldsData(data); // Matches perfectly using id_flight
      },
      onError: (e) {
        debugPrint('Error: $e');
        isLoadingUlds = false;
        notifyListeners();
      },
    );
  }

  void _processUldsData(List<Map<String, dynamic>> data) {
    final existingUlds = List<Map<String, dynamic>>.from(ulds);
    final mapped = List<Map<String, dynamic>>.from(
      data.map((x) => Map<String, dynamic>.from(x)),
    );

    for (var i = 0; i < mapped.length; i++) {
      var newUld = mapped[i];
      try {
        final old = existingUlds.firstWhere((e) => e['id_uld'] == newUld['id_uld']);
        if (old.containsKey('isExpanded')) newUld['isExpanded'] = old['isExpanded'];
        if (old.containsKey('awbList')) newUld['awbList'] = old['awbList'];
        if (old.containsKey('isLoadingAwbs')) newUld['isLoadingAwbs'] = old['isLoadingAwbs'];
        if (old.containsKey('selected')) newUld['selected'] = old['selected'];
      } catch (_) {}
    }

    mapped.sort((a, b) {
      String aNum = (a['uld_number'] ?? '').toString();
      String bNum = (b['uld_number'] ?? '').toString();
      bool aBulk = aNum.toUpperCase() == 'BULK';
      bool bBulk = bNum.toUpperCase() == 'BULK';
      if (aBulk && !bBulk) return -1;
      if (!aBulk && bBulk) return 1;
      bool aBreak = a['is_break'] == true;
      bool bBreak = b['is_break'] == true;
      if (aBreak && !bBreak) return -1;
      if (!aBreak && bBreak) return 1;
      return aNum.compareTo(bNum);
    });

    ulds = mapped;
    isLoadingUlds = false;
    notifyListeners();
  }

  Future<void> loadAwbs(Map<String, dynamic> uld) async {
    activeAwbOverlay = uld;
    if (uld['awbList'] == null && uld['id_uld'] != null) {
      uld['isLoadingAwbs'] = true;
      notifyListeners();
      
      try {
        final response = await Supabase.instance.client
            .from('awb_splits')
            .select('*, awbs(*)')
            .eq('uld_id', uld['id_uld']);

        List<Map<String, dynamic>> parsedAwbs = [];
        for (var split in response) {
          final awbData = split['awbs'];
          if (awbData != null) {
            parsedAwbs.add({
              'number': awbData['awb_number'] ?? '-',
              'pieces': split['pieces'] ?? 0,
              'weight': split['weight'] ?? 0,
              'remarks': split['remarks'] ?? '',
              'data-received': split['time_received'] != null ? {'user': split['user_received'], 'time': split['time_received']} : null,
            });
          }
        }
        uld['awbList'] = parsedAwbs;
      } catch (e) {
        debugPrint('Err AWB: $e');
        uld['awbList'] = [];
      }
      uld['isLoadingAwbs'] = false;
    }
    notifyListeners();
  }

  void closeAwbOverlay() {
    activeAwbOverlay = null;
    notifyListeners();
  }

  void toggleUldReceived(Map<String, dynamic> uld, bool isChecked) {
    final idx = flights.indexWhere((f) => '${f['carrier']}-${f['number']}' == selectedFlightId);
    String truckTime = DateTime.now().toUtc().toIso8601String();
    
    if (isChecked) {
      lastReceivedUld = uld;
      
      if (idx != -1) {
        if (flights[idx]['local_first_truck'] == null && flights[idx]['first_truck'] == null) {
          flights[idx]['local_first_truck'] = truckTime;
          if (date != null) {
            Supabase.instance.client.from('flights').update({'first_truck': truckTime})
                .eq('id_flight', flights[idx]['id_flight'])
                .catchError((e) => debugPrint('Flight First Truck Update Err: $e'));
          }
        }
        flights[idx]['local_truck_arrived'] ??= <String, dynamic>{};
        String uldKey = uld['uld_number']?.toString() ?? 'Unknown';
        flights[idx]['local_truck_arrived'][uldKey] = truckTime;
      }
      
      uld['time_received'] = truckTime;
      uld['user_received'] = authorName;

      Supabase.instance.client.from('ulds').update({
        'time_received': truckTime,
        'user_received': authorName,
      }).eq('id_uld', uld['id_uld']).catchError((e) => debugPrint('time_received Update Err: $e'));

      final bool isBreak = uld['is_break'] == true || uld['is_break']?.toString().toLowerCase() == 'true';
      
      Supabase.instance.client.rpc('rpc_receive_uld', params: {
        'p_uld_id': uld['id_uld'],
        'p_is_received': true,
        'p_is_break': isBreak,
      }).catchError((e) => debugPrint('Err RPC rpc_receive_uld: $e'));

      final sysTable = panelId == 1 ? 'system1' : 'system2';
      Supabase.instance.client.from(sysTable).update({
        'ULD_number$panelId': uld['uld_number'],
        'ULD_isBreak$panelId': isBreak,
      }).eq('id', 1).catchError((e) => debugPrint('Err updating $sysTable ULD: $e'));
      
      onUldToggled?.call(uld['id_uld'].toString(), true, truckTime, authorName);
    } else {
      uld['time_received'] = null;
      uld['user_received'] = null;
      if (lastReceivedUld?['id_uld'] == uld['id_uld']) lastReceivedUld = null;
      
      if (idx != -1 && flights[idx]['local_truck_arrived'] != null) {
        String uldKey = uld['uld_number']?.toString() ?? 'Unknown';
        (flights[idx]['local_truck_arrived'] as Map).remove(uldKey);
      }
      
      Supabase.instance.client.from('ulds').update({
        'time_received': null,
        'user_received': null,
      }).eq('id_uld', uld['id_uld']).catchError((e) => debugPrint('time_received Reset Err: $e'));

      final bool isBreak = uld['is_break'] == true || uld['is_break']?.toString().toLowerCase() == 'true';
      
      Supabase.instance.client.rpc('rpc_receive_uld', params: {
        'p_uld_id': uld['id_uld'],
        'p_is_received': false,
        'p_is_break': isBreak,
      }).catchError((e) => debugPrint('Err RPC rpc_receive_uld: $e'));

      final sysTable = panelId == 1 ? 'system1' : 'system2';
      Supabase.instance.client.from(sysTable).update({
        'ULD_number$panelId': null,
        'ULD_isBreak$panelId': null,
      }).eq('id', 1).catchError((e) => debugPrint('Err updating $sysTable ULD: $e'));

      onUldToggled?.call(uld['id_uld'].toString(), false, '', '');
    }
    notifyListeners();
  }

  Future<void> receiveFlight() async {
    final currentFlightIdx = flights.indexWhere((f) => '${f['carrier']}-${f['number']}' == selectedFlightId);
    
    if (date != null && currentFlightIdx != -1 && selectedFlightId != null) {
      final parts = selectedFlightId!.split('-');
      if (parts.length >= 2) {
        final truckArrivedJson = <String, dynamic>{};
        if (flights[currentFlightIdx]['local_truck_arrived'] is Map) {
          truckArrivedJson.addAll(Map<String, dynamic>.from(flights[currentFlightIdx]['local_truck_arrived']));
        }
        String lastTruckTime = DateTime.now().toUtc().toIso8601String();
        
        String? existingFirstTruck = flights[currentFlightIdx]['first_truck']?.toString();
        if (existingFirstTruck == null || existingFirstTruck.isEmpty || existingFirstTruck == 'null') {
          existingFirstTruck = flights[currentFlightIdx]['local_first_truck']?.toString();
        }
        
        String firstTruckTime = existingFirstTruck ?? lastTruckTime;
        
        // If neither the DB nor local_first_truck had a value, but we have items mapped, pick the oldest one
        if (existingFirstTruck == null && truckArrivedJson.isNotEmpty) {
          List<String> times = truckArrivedJson.values.map((v) => v.toString()).toList();
          times.sort((a, b) => a.compareTo(b));
          firstTruckTime = times.first;
        }

        await Supabase.instance.client.from('flights').update({
          'is_received': true,
          'first_truck': firstTruckTime,
          'last_truck': lastTruckTime,
        }).eq('id_flight', flights[currentFlightIdx]['id_flight']);

        flights[currentFlightIdx]['is_received'] = true;
        flights[currentFlightIdx]['first_truck'] = firstTruckTime;
        flights[currentFlightIdx]['last_truck'] = lastTruckTime;
        
        onFlightReceived?.call(firstTruckTime, lastTruckTime);
      }
    }

    final sysTable = panelId == 1 ? 'system1' : 'system2';
    Supabase.instance.client.from(sysTable).update({
      'carrier_flight$panelId': null,
      'number_flight$panelId': null,
      'date_flight$panelId': null,
      'ULD_number$panelId': null,
      'ULD_isBreak$panelId': null,
    }).eq('id', 1).catchError((e) => debugPrint('Error $sysTable reset: $e'));

    showReceivedOverlay = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      showReceivedOverlay = false;
      notifyListeners();
    });
  }
}
