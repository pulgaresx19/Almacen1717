import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final supabase = Supabase.instance.client;

  // Notifiers for each table
  final ValueNotifier<List<Map<String, dynamic>>> awbSplits = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> awbs = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> damageReports = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> deliveries = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> flights = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> system1 = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> system2 = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> ulds = ValueNotifier([]);

  StreamSubscription? _awbSplitsSub;
  StreamSubscription? _awbsSub;
  StreamSubscription? _damageReportsSub;
  StreamSubscription? _deliveriesSub;
  StreamSubscription? _flightsSub;
  StreamSubscription? _system1Sub;
  StreamSubscription? _system2Sub;
  StreamSubscription? _uldsSub;

  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _awbSplitsSub = supabase.from('awb_splits').stream(primaryKey: ['id']).listen((data) {
      awbSplits.value = data;
    });

    _awbsSub = supabase.from('awbs').stream(primaryKey: ['id']).order('awb_number', ascending: true).listen((data) {
      awbs.value = data;
    });

    _damageReportsSub = supabase.from('damage_reports').stream(primaryKey: ['id']).listen((data) {
      damageReports.value = data;
    });

    _deliveriesSub = supabase.from('deliveries').stream(primaryKey: ['id_delivery']).order('time', ascending: true).listen((data) {
      deliveries.value = data;
    });

    _flightsSub = supabase.from('flights').stream(primaryKey: ['id_flight']).listen((data) {
      flights.value = data;
    });

    _system1Sub = supabase.from('system1').stream(primaryKey: ['id']).eq('id', 1).listen((data) {
      system1.value = data;
    });

    _system2Sub = supabase.from('system2').stream(primaryKey: ['id']).eq('id', 1).listen((data) {
      system2.value = data;
    });

    _uldsSub = supabase.from('ulds').stream(primaryKey: ['id_uld']).listen((data) {
      ulds.value = data;
    });
  }

  void dispose() {
    _awbSplitsSub?.cancel();
    _awbsSub?.cancel();
    _damageReportsSub?.cancel();
    _deliveriesSub?.cancel();
    _flightsSub?.cancel();
    _system1Sub?.cancel();
    _system2Sub?.cancel();
    _uldsSub?.cancel();
    _isInitialized = false;
  }
}

final realtimeService = RealtimeService();
