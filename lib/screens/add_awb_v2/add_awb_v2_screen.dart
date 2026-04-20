import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'add_awb_v2_formatters.dart';
import 'add_awb_v2_widgets.dart';
import 'add_awb_v2_table.dart';
import 'add_awb_v2_dialogs.dart';
import 'add_awb_v2_logic.dart';

part 'add_awb_v2_form.dart';

class AddAwbV2Screen extends StatefulWidget {
  final String? initialFlightId;
  final String? initialUld;
  final Function(bool)? onPop;

  const AddAwbV2Screen({
    super.key,
    this.initialFlightId,
    this.initialUld,
    this.onPop,
  });

  @override
  State<AddAwbV2Screen> createState() => AddAwbV2ScreenState();
}

class AddAwbV2ScreenState extends State<AddAwbV2Screen> {
  final _awbNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _coordinatorCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final Map<String, String> _coordinatorCounts = {};
  final Map<String, String> _itemLocations = {};
  final _searchAwbCtrl = TextEditingController();

  String? _selectedFlight;
  String _refUld = '';
  bool _isSavingAll = false;
  late final TextEditingController _refUldCtrl;
  bool _refUldCheck = true;
  bool _refFlightCheck = true;
  bool _isBreak = false;

  List<Map<String, dynamic>> _flights = [];
  List<Map<String, dynamic>> _uldsForFlight = [];
  bool _isLoadingUlds = false;
  final List<Map<String, dynamic>> _localAwbs = [];
  final Set<String> _collapsedGroups = {};
  bool _totalLocked = false;
  Timer? _uldDebounce;
  String? _awbNumberError;
  String? _piecesError;
  String? _totalError;
  int? _currentDbTotalPieces;
  int? _currentDbTotalExpected;

  void updateUI(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _checkUldBreakStatus() {
    if (_uldDebounce?.isActive ?? false) _uldDebounce!.cancel();
    _uldDebounce = Timer(const Duration(milliseconds: 500), () async {
      final uld = _refUldCtrl.text.trim();
      final flightId = _selectedFlight;
      if (uld.isEmpty) return;

      final isBreak = await AddAwbV2Logic.checkUldBreakStatus(uld, flightId);
      if (isBreak != null) {
        if (mounted) {
          setState(() {
            _isBreak = isBreak;
          });
        }
      }
    });
  }



  @override
  void initState() {
    super.initState();
    _selectedFlight = widget.initialFlightId;
    _refUld = widget.initialUld ?? '';
    _refUldCtrl = TextEditingController(text: _refUld);
    
    _awbNumberCtrl.addListener(() {
      final text = _awbNumberCtrl.text.toUpperCase();
      if (text.length == 13) {
        () async {
          int? dbTotalPieces;
          int? dbTotalExpected;

          for (var a in _localAwbs) {
            if (a['awbNumber'] == text) {
              if (dbTotalPieces == null && a['total'] != null) {
                dbTotalPieces = a['total'] as int;
              }
            }
          }

          try {
            final res = await Supabase.instance.client
                .from('awbs')
                .select('total_pieces, total_espected')
                .eq('awb_number', text)
                .maybeSingle();
            if (res != null) {
              if (res['total_pieces'] != null) {
                dbTotalPieces = res['total_pieces'] as int;
              }
              if (res['total_espected'] != null) {
                dbTotalExpected = res['total_espected'] as int;
              }
            }
          } catch (_) {}

          if (!mounted || _awbNumberCtrl.text.toUpperCase() != text) return;

          setState(() {
            _currentDbTotalPieces = dbTotalPieces;
            _currentDbTotalExpected = dbTotalExpected;
            if (dbTotalPieces != null) {
              _totalLocked = true;
              _totalCtrl.text = dbTotalPieces.toString();
            } else {
              _totalLocked = false;
              _totalCtrl.text = '';
            }
          });
        }();
      } else {
        if (_totalLocked) {
          setState(() {
            _totalLocked = false;
            _totalCtrl.text = '';
            _currentDbTotalPieces = null;
            _currentDbTotalExpected = null;
          });
        }
      }
    });

    _loadFlights();
  }


  Future<void> _loadFlights() async {
    final flights = await AddAwbV2Logic.loadFlights();
    if (mounted) {
      setState(() {
        _flights = flights;
      });
      _fetchUldsForFlight(_selectedFlight);
    }
  }

  Future<void> _fetchUldsForFlight(String? flightId) async {
    if (flightId == null || flightId == 'NONE') {
      if (mounted) setState(() { _uldsForFlight = []; _refUld = ''; _refUldCtrl.text = ''; _isBreak = false; });
      return;
    }
    setState(() => _isLoadingUlds = true);
    final ulds = await AddAwbV2Logic.loadUldsForFlight(flightId);
    if (mounted) {
      setState(() {
        _uldsForFlight = ulds;
        _isLoadingUlds = false;
        if (_refUld.isNotEmpty && _refUld != 'MANUAL' && !ulds.any((u) => u['uld_number'].toString() == _refUld)) {
           _refUld = '';
           _refUldCtrl.text = '';
           _isBreak = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _uldDebounce?.cancel();
    _awbNumberCtrl.dispose();
    _piecesCtrl.dispose();
    _totalCtrl.dispose();
    _weightCtrl.dispose();
    _houseCtrl.dispose();
    _remarksCtrl.dispose();
    _coordinatorCtrl.dispose();
    _locationCtrl.dispose();
    _refUldCtrl.dispose();
    _searchAwbCtrl.dispose();
    super.dispose();
  }

  void _addLocalAwb() {
    setState(() {
      _awbNumberError = _awbNumberCtrl.text.trim().isEmpty ? (appLanguage.value == 'es' ? 'Requerido' : 'Required') : null;
      _piecesError = _piecesCtrl.text.trim().isEmpty ? (appLanguage.value == 'es' ? 'Requerido' : 'Required') : null;
      _totalError = _totalCtrl.text.trim().isEmpty ? (appLanguage.value == 'es' ? 'Requerido' : 'Required') : null;

      if (_piecesError == null && _totalError == null) {
        final p = int.tryParse(_piecesCtrl.text) ?? 0;
        final t = int.tryParse(_totalCtrl.text) ?? 0;
        
        int totalToUse = _currentDbTotalPieces ?? t;
        if (totalToUse > 0) {
          int localExpected = 0;
          for (var a in _localAwbs) {
            if (a['awbNumber'] == _awbNumberCtrl.text.toUpperCase()) {
              localExpected += (a['pieces'] as int? ?? 0);
            }
          }
          int handled = (_currentDbTotalExpected ?? 0) + localExpected;
          int remaining = totalToUse - handled;
          
          if (remaining <= 0) {
            _piecesError = appLanguage.value == 'es' ? 'Sin piezas restantes' : 'No pieces remaining';
          } else if (p > remaining) {
            _piecesError = appLanguage.value == 'es' ? 'Máx. $remaining piezas' : 'Max $remaining pieces';
          }
        }
      }
    });

    if (_awbNumberError != null || _piecesError != null || _totalError != null) {
      return;
    }

    setState(() {
      String? flightLabel;
      String refCarrierOut = 'WRHS';
      String refNumberOut = 'LOCAL';

      if (_selectedFlight != null && _selectedFlight != 'NONE') {
        final f = _flights.firstWhere(
          (x) => x['id'].toString() == _selectedFlight,
          orElse: () => <String, dynamic>{},
        );
        if (f.isNotEmpty) {
          flightLabel = '${f['carrier']} ${f['number']}';
          refCarrierOut = f['carrier'];
          refNumberOut = f['number'];
        }
      }

      _localAwbs.add({
        'awbNumber': _awbNumberCtrl.text.trim().toUpperCase(),
        'pieces': int.tryParse(_piecesCtrl.text) ?? 1,
        'total': int.tryParse(_totalCtrl.text) ?? 1,
        'weight': double.tryParse(_weightCtrl.text) ?? 0.0,
        'house': _houseCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList(),
        'remarks': _remarksCtrl.text.trim().isEmpty
            ? null
            : _remarksCtrl.text.trim(),
        'coordinator': _coordinatorCtrl.text.trim().isNotEmpty ? _coordinatorCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}').toList() : null,
        'coordinatorCounts': Map<String, String>.from(_coordinatorCounts),
        'itemLocations': Map<String, String>.from(_itemLocations),
        'location': _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}').toList() : null,
        'flight_id': _selectedFlight == 'NONE' ? null : _selectedFlight,
        'flightLabel': flightLabel,
        'refCarrier': refCarrierOut,
        'refNumber': refNumberOut,
        'refUld': (_refUldCheck && _refUldCtrl.text.trim().isNotEmpty) ? _refUldCtrl.text.trim().toUpperCase() : 'MANUAL',
        'isBreak': (_refUldCheck && _refUldCtrl.text.trim().isNotEmpty && _refUldCtrl.text.trim().toUpperCase() != 'MANUAL') ? _isBreak : null,
      });

      _awbNumberCtrl.clear();
      _piecesCtrl.clear();
      _totalCtrl.clear();
      _weightCtrl.clear();
      _houseCtrl.clear();
      _awbNumberError = null;
      _piecesError = null;
      _totalError = null;
      _currentDbTotalPieces = null;
      _currentDbTotalExpected = null;
      _remarksCtrl.clear();
      _coordinatorCtrl.clear();
      _coordinatorCounts.clear();
      _itemLocations.clear();
      _locationCtrl.clear();
      
      if (!_refUldCheck) {
        _refUldCtrl.clear();
        _refUld = '';
        _isBreak = false;
      }
      
      if (!_refFlightCheck) {
        _selectedFlight = null;
      }
    });
  }

  Future<void> _saveAllAwbs() async {
    if (_localAwbs.isEmpty) {
      if (_awbNumberCtrl.text.trim().isNotEmpty || _piecesCtrl.text.trim().isNotEmpty || _totalCtrl.text.trim().isNotEmpty) {
        setState(() {
          _awbNumberError = _awbNumberCtrl.text.trim().isEmpty ? (appLanguage.value == 'es' ? 'Requerido' : 'Required') : null;
          _piecesError = _piecesCtrl.text.trim().isEmpty ? (appLanguage.value == 'es' ? 'Requerido' : 'Required') : null;
          _totalError = _totalCtrl.text.trim().isEmpty ? (appLanguage.value == 'es' ? 'Requerido' : 'Required') : null;
        });
        return;
      }

      showMissingFieldAlert(context, '', customMessage: appLanguage.value == 'es'
           ? 'No has añadido ningún AWB a la lista.\nPor favor, ingresa los datos y haz clic en "+ Add AWB" para proceder.'
           : 'You have not added any AWBs to the list.\nPlease enter the data and click "+ Add AWB" to proceed.');
      return;
    }

    setState(() => _isSavingAll = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      String userName = session?.user.email ?? 'Unknown';
      
      if (session != null) {
        if (session.user.userMetadata?['full_name'] != null) {
          userName = session.user.userMetadata!['full_name'].toString();
        }
        try {
          final profile = await Supabase.instance.client.from('users').select('full-name').eq('id', session.user.id).maybeSingle();
          if (profile != null && profile['full-name'] != null && profile['full-name'].toString().trim().isNotEmpty) {
            userName = profile['full-name'].toString().trim();
          }
        } catch (_) {}
      }

      await AddAwbV2Logic.saveAllAwbs(
        localAwbs: _localAwbs,
        userName: userName,
      );

      if (mounted) {
        await showSuccessSaveDialog(context, dark: isDarkMode.value, lang: appLanguage.value);
        if (mounted) {
          if (widget.onPop != null) {
            widget.onPop!(true);
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  bool get hasDataSync {
    if (_localAwbs.isNotEmpty) return true;
    if (_awbNumberCtrl.text.isNotEmpty ||
        _piecesCtrl.text.isNotEmpty ||
        _weightCtrl.text.isNotEmpty ||
        _totalCtrl.text.isNotEmpty ||
        _refUldCtrl.text.isNotEmpty ||
        _houseCtrl.text.isNotEmpty ||
        _coordinatorCtrl.text.isNotEmpty ||
        _locationCtrl.text.isNotEmpty ||
        _remarksCtrl.text.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> _onBackPressed() async {
    bool hasData = hasDataSync;

    if (!hasData) {
      if (widget.onPop != null) {
        widget.onPop!(false);
        return false;
      }
      return true;
    }

    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFFf59e0b).withAlpha(100),
            width: 2,
          ),
        ),
        title: const Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFf59e0b),
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Discard Data?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Any unsaved data entered for the Air Waybill will be permanently lost.\n\nDo you want to discard your changes and continue?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFcbd5e1),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'STAY',
              style: TextStyle(
                color: Color(0xFF94a3b8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFFef4444).withAlpha(100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 12.0,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DISCARD',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      if (widget.onPop != null) {
        widget.onPop!(false);
        return false;
      }
      return true;
    }
    return false;
  }

  Future<bool> handleBackRequest() async {
    final canPop = await _onBackPressed();
    if (canPop && widget.onPop == null) {
      if (mounted) Navigator.pop(context);
    }
    return canPop;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        if (widget.onPop != null) {
          return _buildFormContent(dark);
        }
        return Scaffold(
          backgroundColor: dark ? const Color(0xFF0f172a) : const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text(
              appLanguage.value == 'es' ? 'Añadir Nuevo Air Waybill' : 'Add New Air Waybill',
              style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827)),
            ),
            backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
            iconTheme: IconThemeData(color: dark ? Colors.white : const Color(0xFF111827)),
            elevation: 0,
          ),
          body: _buildFormContent(dark),
        );
      }
    );
  }


}
