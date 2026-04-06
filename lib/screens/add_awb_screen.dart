import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;

class AddAwbScreen extends StatefulWidget {
  final String? initialFlightId;
  final String? initialUld;
  final Function(bool)? onPop;

  const AddAwbScreen({
    super.key,
    this.initialFlightId,
    this.initialUld,
    this.onPop,
  });

  @override
  State<AddAwbScreen> createState() => AddAwbScreenState();
}

class AddAwbScreenState extends State<AddAwbScreen> {
  final _awbNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _coordinatorCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _searchAwbCtrl = TextEditingController();
  bool _showExtraData = false;

  String? _selectedFlight;
  String _refUld = '';
  bool _isSavingAll = false;
  late final TextEditingController _refUldCtrl;
  bool _refUldCheck = false;
  bool _refFlightCheck = true;
  bool _isBreak = false;

  List<Map<String, dynamic>> _flights = [];
  final List<Map<String, dynamic>> _localAwbs = [];
  final Set<String> _collapsedGroups = {};
  bool _totalLocked = false;
  Timer? _uldDebounce;

  void _checkUldBreakStatus() {
    if (_uldDebounce?.isActive ?? false) _uldDebounce!.cancel();
    _uldDebounce = Timer(const Duration(milliseconds: 500), () async {
      final uld = _refUldCtrl.text.trim();
      final flightId = _selectedFlight;
      if (uld.isEmpty) return;

      try {
        var query = Supabase.instance.client
            .from('ULD')
            .select('isBreak')
            .eq('ULD-number', uld);

        if (flightId != null) {
          final fMatch = _flights.where((f) => f['id'].toString() == flightId);
          if (fMatch.isNotEmpty) {
            query = query.eq('refCarrier', fMatch.first['carrier']).eq('refNumber', fMatch.first['number']);
          }
        } else {
            query = query.eq('refCarrier', 'WRHS');
        }

        final res = await query.order('created_at', ascending: false).limit(1).maybeSingle();
        if (res != null && res['isBreak'] != null) {
          if (mounted) {
            setState(() {
              _isBreak = res['isBreak'];
            });
          }
        }
      } catch (_) {}
    });
  }

  void _showCustomListDialog(String title, List<String> items) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withAlpha(20))),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                items.length > 1 ? '$title (${items.length})' : title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String val = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20, height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                              child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(val, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 14))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        bool foundLocally = false;
        String foundTotal = '';
        for (var a in _localAwbs) {
          if (a['awbNumber'] == text) {
            foundLocally = true;
            foundTotal = a['total'].toString();
            break;
          }
        }
        
        if (foundLocally) {
          setState(() {
            _totalLocked = true;
            if (_totalCtrl.text != foundTotal) {
              _totalCtrl.text = foundTotal;
            }
          });
        } else {
          () async {
            try {
              final res = await Supabase.instance.client.from('AWB').select('total').eq('AWB-number', text).maybeSingle();
              if (res != null && res['total'] != null && _awbNumberCtrl.text.toUpperCase() == text) {
                if (mounted) {
                  setState(() {
                    _totalLocked = true;
                    _totalCtrl.text = res['total'].toString();
                  });
                }
              }
            } catch (_) {}
          }();
        }
      } else {
        if (_totalLocked) {
          setState(() {
            _totalLocked = false;
            _totalCtrl.text = '';
          });
        }
      }
    });

    _loadFlights();
  }

  void _showMissingFieldAlert(String fieldName, {String? customMessage}) {
    showDialog(
      context: context,
      builder: (alertCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withAlpha(50)),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Action Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              customMessage ?? 'The field "$fieldName" is missing.\nPlease provide this information to proceed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFcbd5e1),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFef4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(alertCtx),
                child: const Text(
                  'UNDERSTOOD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFlights() async {
    try {
      final res = await Supabase.instance.client
          .from('Flight')
          .select('id, carrier, number, date-arrived')
          .order('created_at');
      if (mounted) {
        setState(() {
          _flights = List.from(res);
        });
      }
    } catch (_) {}
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
    String? missingField;
    if (_awbNumberCtrl.text.trim().isEmpty) {
      missingField = appLanguage.value == 'es' ? 'Número de AWB' : 'AWB Number';
    } else if (_piecesCtrl.text.trim().isEmpty) {
      missingField = appLanguage.value == 'es' ? 'Piezas' : 'Pieces';
    } else if (_totalCtrl.text.trim().isEmpty) {
      missingField = 'Total';
    }

    if (missingField != null) {
      _showMissingFieldAlert(missingField);
      return;
    }

    setState(() {
      String? flightLabel;
      String refCarrierOut = 'WRHS';
      String refNumberOut = 'LOCAL';

      if (_selectedFlight != null) {
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
        'coordinator': _showExtraData && _coordinatorCtrl.text.trim().isNotEmpty ? _coordinatorCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}').toList() : null,
        'location': _showExtraData && _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}').toList() : null,
        'flight_id': _selectedFlight,
        'flightLabel': flightLabel,
        'refCarrier': refCarrierOut,
        'refNumber': refNumberOut,
        'refUld': _refUld.trim().toUpperCase(),
        'isBreak': _isBreak,
      });

      _awbNumberCtrl.clear();
      _piecesCtrl.clear();
      _totalCtrl.clear();
      _weightCtrl.clear();
      _houseCtrl.clear();
      _remarksCtrl.clear();
      _coordinatorCtrl.clear();
      _locationCtrl.clear();
      _showExtraData = false;
      
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
      String? missingField;
      if (_awbNumberCtrl.text.trim().isEmpty) {
        missingField = appLanguage.value == 'es' ? 'Número de AWB' : 'AWB Number';
      } else if (_piecesCtrl.text.trim().isEmpty) {
        missingField = appLanguage.value == 'es' ? 'Piezas' : 'Pieces';
      } else if (_totalCtrl.text.trim().isEmpty) {
        missingField = 'Total';
      }

      if (missingField == null) {
        // Validation passes but hasn't been added to list
        _showMissingFieldAlert('', customMessage: appLanguage.value == 'es'
             ? 'No has añadido ningún AWB a la lista.\nPor favor, ingresa los datos y haz clic en "+ Add AWB" para proceder.'
             : 'You have not added any AWBs to the list.\nPlease enter the data and click "+ Add AWB" to proceed.');
        return;
      } else {
        _showMissingFieldAlert(missingField);
        return;
      }
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
          final profile = await Supabase.instance.client.from('Users').select('full-name').eq('id', session.user.id).maybeSingle();
          if (profile != null && profile['full-name'] != null && profile['full-name'].toString().trim().isNotEmpty) {
            userName = profile['full-name'].toString().trim();
          }
        } catch (_) {}
      }

      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final dateStr = nowUtc.substring(0, 10);
      
      Map<String, Map<String, dynamic>> mergedAwbs = {};
      for (var a in _localAwbs) {
        final num = a['awbNumber'];
        if (!mergedAwbs.containsKey(num)) {
           mergedAwbs[num] = {
             'AWB-number': num,
             'total': a['total'],
             'data-AWB': [],
             'data-coordinator': a['coordinator'] != null ? {'manual_entry': a['coordinator'], 'user': userName, 'time': nowUtc} : {},
             'data-location': a['location'] != null ? {'manual_entry': a['location'], 'user': userName, 'time': nowUtc} : {},
           };
        }
        
        final dataAwbItem = {
          'flightID': a['flight_id'] ?? '0',
          'refCarrier': a['refCarrier'] ?? 'WRHS',
          'refNumber': a['refNumber'] ?? 'LOCAL',
          'refDate': dateStr,
          'refULD': a['refUld'],
          'isBreak': a['isBreak'],
          'pieces': a['pieces'],
          'weight': a['weight'],
          'house_number': a['house'],
          'remarks': a['remarks'],
          'status': 'Received',
        };
        
        (mergedAwbs[num]!['data-AWB'] as List).add(dataAwbItem);
      }

      if (mergedAwbs.isNotEmpty) {
         final awbNumbers = mergedAwbs.keys.toList();
         final existingDbAwbs = await Supabase.instance.client.from('AWB').select('AWB-number, data-AWB').inFilter('AWB-number', awbNumbers);
         final existingAwbMap = { for (var e in existingDbAwbs) e['AWB-number'] : e['data-AWB'] };
         
         for (var awbNum in mergedAwbs.keys) {
            if (existingAwbMap.containsKey(awbNum)) {
               var dbData = existingAwbMap[awbNum];
               if (dbData is List) {
                  (mergedAwbs[awbNum]!['data-AWB'] as List).insertAll(0, dbData);
               } else if (dbData is Map) {
                  (mergedAwbs[awbNum]!['data-AWB'] as List).insert(0, dbData);
               }
            }
         }
         
         final finalAwbPayloads = mergedAwbs.values.map((v) {
           final n = v['AWB-number'];
           Map<String, dynamic> out = {
             'AWB-number': n,
             'total': v['total'],
             'data-AWB': v['data-AWB'],
             'data-coordinator': v['data-coordinator'],
             'data-location': v['data-location'],
           };
           if (!existingAwbMap.containsKey(n)) {
              out['created_at'] = DateTime.now().toIso8601String();
           }
           return out;
         }).toList();
         
         await Supabase.instance.client.from('AWB').upsert(finalAwbPayloads, onConflict: 'AWB-number');
         
         // After AWBs are upserted, update their corresponding ULD rows if a Ref ULD is provided
         Map<String, Map<String, dynamic>> uldUpdates = {};

         for (var a in _localAwbs) {
           final uldNum = a['refUld']?.toString().trim() ?? '';
           final car = a['refCarrier'];
           final num = a['refNumber'];
           if (uldNum.isNotEmpty) {
             final key = '${car}_${num}_$uldNum';
             if (!uldUpdates.containsKey(key)) {
               uldUpdates[key] = {
                 'refCarrier': car,
                 'refNumber': num,
                 'uldNumber': uldNum,
                 'isBreak': a['isBreak'],
                 'awbsToAdd': [],
               };
             }
             uldUpdates[key]!['awbsToAdd'].add({
               'awb_number': a['awbNumber'],
               'pieces': a['pieces'],
               'weight': a['weight'],
               'total': a['total'],
               'house_number': a['house'],
               'remarks': a['remarks'],
               'isBreak': a['isBreak'],
             });
           }
         }

         for (final val in uldUpdates.values) {
           final uldNum = val['uldNumber'];
           final car = val['refCarrier'];
           final num = val['refNumber'];

           try {
             var query = Supabase.instance.client
                 .from('ULD')
                 .select('id, data-ULD')
                 .eq('ULD-number', uldNum);

             if (car != 'WRHS') {
               query = query.eq('refCarrier', car).eq('refNumber', num);
             }

             final uldRecords = await query.order('created_at', ascending: false).limit(1);

             if (uldRecords.isNotEmpty) {
               final uldRow = uldRecords.first;
               List currentAwbs = [];
               if (uldRow['data-ULD'] is List) {
                 currentAwbs = List.from(uldRow['data-ULD']);
               }

               bool changed = false;
               for (var newAwb in val['awbsToAdd']) {
                 bool exists = currentAwbs.any((existing) => existing['awb_number'] == newAwb['awb_number']);
                 if (!exists) {
                   currentAwbs.add(newAwb);
                   changed = true;
                 }
               }
               
               if (changed) {
                 await Supabase.instance.client
                     .from('ULD')
                     .update({'data-ULD': currentAwbs})
                     .eq('id', uldRow['id']);
               }
             }
           } catch (_) {}
         }
      }

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            Future.delayed(const Duration(seconds: 1), () {
              if (ctx.mounted && Navigator.canPop(ctx)) {
                Navigator.pop(ctx);
              }
            });
            return Dialog(
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF10b981),
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Air Waybills saved successfully',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (!mounted) return;
        if (widget.onPop != null) {
          widget.onPop!(true);
        } else {
          Navigator.pop(context, true);
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

  Widget _buildFormContent(bool dark) {
    final Color textP = dark ? Colors.white : const Color(0xFF111827);
    final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final Color bgCard = dark ? const Color(0xFF1e293b) : const Color(0xFFffffff);
    final Color borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upper Form Container
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderC),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_outlined, color: textP, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        appLanguage.value == 'es' ? 'Detalles de AWB y Asignación' : 'AWB Details & Assignment',
                        style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Extra Data?', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Switch(
                        value: _showExtraData, 
                        activeThumbColor: const Color(0xFF6366f1), 
                        onChanged: (v) => setState(() => _showExtraData = v)
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  double baseWidth = _showExtraData ? 1225 : 1087;
                  double rWidth = constraints.maxWidth - baseWidth - 1;
                  if (rWidth < 70) rWidth = 70;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: 135,
                        child: _buildTextField('AWB Number', _awbNumberCtrl, '123-1234 5678', dark: dark, textP: textP, maxLen: 13, inputFormatters: [AwbNumberFormatter()]),
                      ),
                      SizedBox(width: 170, child: _buildFlightDropdown(
                        dark, textP, borderC,
                        titleTrailing: SizedBox(
                          width: 20, height: 20,
                          child: Checkbox(
                            value: _refFlightCheck,
                            activeColor: const Color(0xFF6366f1),
                            side: const BorderSide(color: Color(0xFF94a3b8)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => setState(() => _refFlightCheck = v ?? true),
                          ),
                        ),
                      )),
                      SizedBox(
                        width: 135,
                        child: _buildTextField(
                          'Ref ULD', _refUldCtrl, 'AKE12345AA',
                          dark: dark, textP: textP, maxLen: 10,
                          inputFormatters: [UpperCaseTextFormatter()],
                          textCapitalization: TextCapitalization.characters,
                          titleTrailing: _refUld.trim().isNotEmpty ? SizedBox(
                            width: 20, height: 20,
                            child: Checkbox(
                              value: _refUldCheck,
                              activeColor: const Color(0xFF6366f1),
                              side: const BorderSide(color: Color(0xFF94a3b8)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) => setState(() => _refUldCheck = v ?? false),
                            )
                          ) : null,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Break?', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                                  Switch(
                                    value: _isBreak,
                                    onChanged: (v) => setState(() => _isBreak = v),
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF22c55e),
                                    inactiveThumbColor: dark ? const Color(0xFFbdc3c7) : const Color(0xFF9CA3AF),
                                    inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                                    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) return Colors.transparent;
                                      return const Color(0xFFef4444).withAlpha(180);
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 75,
                        child: _buildTextField('Pieces', _piecesCtrl, '0', isNum: true, dark: dark, textP: textP, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      ),
                      SizedBox(
                        width: 75,
                        child: _buildTextField('Total', _totalCtrl, '0', isNum: true, dark: dark, textP: textP, inputFormatters: [FilteringTextInputFormatter.digitsOnly], readOnly: _totalLocked),
                      ),
                      SizedBox(
                        width: 75,
                        child: _buildTextField('Weight', _weightCtrl, '0.0', isNum: true, dark: dark, textP: textP, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
                      ),
                      SizedBox(
                        width: rWidth,
                        child: _buildTextField('Remarks', _remarksCtrl, 'Additional remarks...', dark: dark, textP: textP, textCapitalization: TextCapitalization.sentences, inputFormatters: [SentenceCaseTextFormatter()]),
                      ),
                      SizedBox(
                        width: 140,
                        child: _buildTextField('House Number', _houseCtrl, 'HAWB', dark: dark, textP: textP, maxLines: 3, inputFormatters: [UpperCaseTextFormatter()], textCapitalization: TextCapitalization.characters),
                      ),
                      if (_showExtraData) ...[
                        SizedBox(
                          width: 120,
                          child: _buildTextField('Data Coordinator', _coordinatorCtrl, 'Details...', dark: dark, textP: textP, maxLines: 3, minLines: 1, textCapitalization: TextCapitalization.characters, inputFormatters: [UpperCaseTextFormatter()]),
                        ),
                        SizedBox(
                          width: 120,
                          child: _buildTextField('Data Location', _locationCtrl, 'Details...', dark: dark, textP: textP, maxLines: 3, minLines: 1, textCapitalization: TextCapitalization.characters, inputFormatters: [UpperCaseTextFormatter()]),
                        ),
                      ],
                      if (!_showExtraData)
                        SizedBox(
                          width: 110,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _addLocalAwb,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15),
                              foregroundColor: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              elevation: 0,
                              side: BorderSide(color: dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('+ Add AWB', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  );
                }
              ),
              if (_showExtraData) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _addLocalAwb,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15),
                        foregroundColor: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                        side: BorderSide(color: dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('+ Add AWB', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Persistent Form Container Gap
        const SizedBox(height: 16),

        // Persistent Container for Native table of added AWBs
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderC),
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt_rounded, color: textP, size: 20),
                            const SizedBox(width: 8),
                            Text('Added AWBs', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                               width: 300,
                               height: 40,
                               decoration: BoxDecoration(
                                  color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderC),
                               ),
                               child: TextField(
                                  controller: _searchAwbCtrl,
                                  style: TextStyle(color: textP, fontSize: 13),
                                  onChanged: (v) => setState(() {}),
                                  decoration: InputDecoration(
                                     hintText: appLanguage.value == 'es' ? 'Buscar AWB...' : 'Search AWB...',
                                     hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                                     prefixIcon: Icon(Icons.search_rounded, color: textP.withAlpha(76), size: 16),
                                     border: InputBorder.none,
                                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                               ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appLanguage.value == 'es' ? 'Vea y gestione todos los AWBs que serán guardados.' : 'View and manage all AWBs pending to be saved.', 
                          style: TextStyle(color: textS, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderC),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _localAwbs.isNotEmpty
                              ? SingleChildScrollView(
                                  child: Builder(
                                    builder: (context) {
                                      Map<String, List<Map<String, dynamic>>> groupedAwbs = {};
                                      for (int i = 0; i < _localAwbs.length; i++) {
                                        final a = _localAwbs[i];
                                        if (_searchAwbCtrl.text.isNotEmpty) {
                                          final term = _searchAwbCtrl.text.toLowerCase();
                                          final number = (a['awbNumber'] ?? '').toString().toLowerCase();
                                          if (!number.contains(term)) continue;
                                        }
                                        final groupKey = a['flightLabel'] ?? 'Standalone AWBs';
                                        groupedAwbs.putIfAbsent(groupKey, () => []);
                                        groupedAwbs[groupKey]!.add({'index': i, 'awb': a});
                                      }

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: groupedAwbs.entries.map((group) {
                                          final groupName = group.key;
                                          final groupItems = group.value;

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                                                  border: Border(bottom: BorderSide(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      groupName == 'Standalone AWBs' ? Icons.inventory_2_outlined : Icons.flight_takeoff_rounded,
                                                      color: textS,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      groupName,
                                                      style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontWeight: FontWeight.bold, fontSize: 13),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF6366f1).withAlpha(40),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '${groupItems.length} items',
                                                        style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    IconButton(
                                                      icon: Icon(
                                                        _collapsedGroups.contains(groupName) ? Icons.visibility_off : Icons.visibility,
                                                        color: textS,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (_collapsedGroups.contains(groupName)) {
                                                            _collapsedGroups.remove(groupName);
                                                          } else {
                                                            _collapsedGroups.add(groupName);
                                                          }
                                                        });
                                                      },
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (!_collapsedGroups.contains(groupName))
                                                Table(
                                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                                  columnWidths: const {
                                                    0: IntrinsicColumnWidth(),
                                                    1: IntrinsicColumnWidth(),
                                                    2: IntrinsicColumnWidth(),
                                                    3: IntrinsicColumnWidth(),
                                                    4: IntrinsicColumnWidth(),
                                                    5: FlexColumnWidth(),
                                                    6: IntrinsicColumnWidth(),
                                                    7: IntrinsicColumnWidth(),
                                                    8: IntrinsicColumnWidth(),
                                                  },
                                                  children: groupItems.asMap().entries.map((entry) {
                                                    final i = entry.key;
                                                    final item = entry.value;
                                                    final int realIndex = item['index'];
                                                    final a = item['awb'];
                                                    final awbNum = a['awbNumber'];
                                                    return TableRow(
                                                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)))),
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 16, right: 12, top: 12, bottom: 12),
                                                          child: Container(
                                                            width: 24, height: 24,
                                                            alignment: Alignment.center,
                                                            decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                                                            child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold)),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 24, top: 12, bottom: 12),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(awbNum, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                                                              if (a['refUld'] != '' && a['refUld'] != null)
                                                                Padding(
                                                                  padding: const EdgeInsets.only(top: 4),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.inventory_2_outlined, size: 12, color: textS),
                                                                      const SizedBox(width: 4),
                                                                      Text(a['refUld'], style: TextStyle(color: textS, fontSize: 12)),
                                                                      const SizedBox(width: 6),
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                                        decoration: BoxDecoration(
                                                                          color: (a['isBreak'] == true) ? const Color(0xFF22c55e).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                                                                          borderRadius: BorderRadius.circular(4),
                                                                        ),
                                                                        child: Text(
                                                                          (a['isBreak'] == true) ? 'BREAK' : 'NO BREAK',
                                                                          style: TextStyle(
                                                                            color: (a['isBreak'] == true) ? const Color(0xFF22c55e) : const Color(0xFFef4444),
                                                                            fontSize: 9,
                                                                            fontWeight: FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                                          child: RichText(text: TextSpan(children: [
                                                            TextSpan(text: 'PIECES: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                                                            TextSpan(text: '${a['pieces']}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                                                          ])),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                                          child: RichText(text: TextSpan(children: [
                                                            TextSpan(text: 'TOTAL: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                                                            TextSpan(text: '${a['total']}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                                                          ])),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                                          child: RichText(text: TextSpan(children: [
                                                            TextSpan(text: 'WEIGHT: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                                                            TextSpan(text: '${a['weight']}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                                                          ])),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                                                          child: RichText(
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            text: TextSpan(children: [
                                                              TextSpan(text: 'REMARKS: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                                                              TextSpan(
                                                                text: (a['remarks'] != null && a['remarks'].toString().isNotEmpty) ? a['remarks'].toString() : '-',
                                                                style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                                                              ),
                                                            ]),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                                                          child: Builder(
                                                            builder: (ctx) {
                                                              List<String> houses = (a['house'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                                                              if (houses.isEmpty) return const SizedBox.shrink();
                                                              return Align(
                                                                alignment: Alignment.centerLeft,
                                                                child: InkWell(
                                                                  onTap: () => _showCustomListDialog('House Numbers', houses),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                    decoration: BoxDecoration(color: dark ? const Color(0xFF1e293b) : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                                                                    child: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Icon(Icons.maps_home_work_outlined, size: 12, color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)),
                                                                        const SizedBox(width: 4),
                                                                        Text('${houses.length} HAWB', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 11)),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
                                                          child: ((a['coordinator'] != null && (a['coordinator'] is List ? (a['coordinator'] as List).isNotEmpty : a['coordinator'].toString().isNotEmpty)) || (a['location'] != null && (a['location'] is List ? (a['location'] as List).isNotEmpty : a['location'].toString().isNotEmpty))) ? Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              if (a['coordinator'] != null && (a['coordinator'] is List ? (a['coordinator'] as List).isNotEmpty : a['coordinator'].toString().isNotEmpty))
                                                                InkWell(
                                                                  onTap: () {
                                                                    List<String> dcList = a['coordinator'] is List ? (a['coordinator'] as List).map((e) => e.toString()).toList() : a['coordinator'].toString().split('\n').where((e) => e.trim().isNotEmpty).toList();
                                                                    _showCustomListDialog('Data Coordinator', dcList);
                                                                  },
                                                                  customBorder: const CircleBorder(),
                                                                  child: Container(
                                                                    margin: const EdgeInsets.only(right: 6),
                                                                    padding: const EdgeInsets.all(6),
                                                                    decoration: BoxDecoration(color: Colors.amber.withAlpha(30), shape: BoxShape.circle),
                                                                    child: const Icon(Icons.person_outline, size: 14, color: Colors.amber),
                                                                  ),
                                                                ),
                                                              if (a['location'] != null && (a['location'] is List ? (a['location'] as List).isNotEmpty : a['location'].toString().isNotEmpty))
                                                                InkWell(
                                                                  onTap: () {
                                                                    List<String> locList = a['location'] is List ? (a['location'] as List).map((e) => e.toString()).toList() : a['location'].toString().split('\n').where((e) => e.trim().isNotEmpty).toList();
                                                                    _showCustomListDialog('Data Location', locList);
                                                                  },
                                                                  customBorder: const CircleBorder(),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.all(6),
                                                                    decoration: BoxDecoration(color: Colors.green.withAlpha(30), shape: BoxShape.circle),
                                                                    child: const Icon(Icons.location_on_outlined, size: 14, color: Colors.green),
                                                                  ),
                                                                ),
                                                            ],
                                                          ) : const SizedBox.shrink(),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                                                          child: IconButton(
                                                            icon: const Icon(Icons.close, color: Color(0xFFef4444), size: 18),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                            onPressed: () {
                                                              setState(() => _localAwbs.removeAt(realIndex));
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'No AWBs added yet',
                                    style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom Action Bar
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSavingAll ? null : _saveAllAwbs,
                  icon: _isSavingAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    appLanguage.value == 'es' ? 'Guardar AWBs' : 'Save AWBs',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlightDropdown(bool dark, Color textP, Color borderC, {Widget? titleTrailing}) {
    String formatFlightDate(String? d) {
       if (d == null || d.trim().isEmpty) return '';
       final parts = d.split('-');
       if (parts.length >= 3) return '${parts[1]}/${parts[2]}';
       return d;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleTrailing != null)
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text(
                   'Reference Flight',
                   style: TextStyle(
                     color: Color(0xFFcbd5e1),
                     fontSize: 13,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
                 titleTrailing,
              ],
           )
        else
           const Text(
             'Reference Flight',
             style: TextStyle(
               color: Color(0xFFcbd5e1),
               fontSize: 13,
               fontWeight: FontWeight.w500,
             ),
           ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderC),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedFlight,
              hint: Text(
                'No Flight (Standalone)',
                style: TextStyle(color: textP.withAlpha(150)),
              ),
              dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
              isExpanded: true,
              style: TextStyle(color: textP, fontSize: 13),
              menuMaxHeight: 300,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No Flight (Standalone)'),
                ),
                ..._flights.map(
                  (f) => DropdownMenuItem<String?>(
                    value: f['id'].toString(),
                    child: Text(
                      '${f['carrier']} ${f['number']} (${formatFlightDate(f['date-arrived']?.toString())})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _selectedFlight = v);
                _checkUldBreakStatus();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool isNum = false,
    required bool dark,
    required Color textP,
    int? maxLen,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    int? maxLines = 1,
    int? minLines = 1,
    Widget? titleTrailing,
  }) {
    Widget field = TextField(
      controller: ctrl,
      keyboardType: maxLines == null || maxLines > 1 ? TextInputType.multiline : (isNum ? TextInputType.number : TextInputType.text),
      textCapitalization: textCapitalization,
      maxLength: maxLen,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: readOnly ? (dark ? const Color(0xFFcbd5e1) : const Color(0xFF6B7280)) : textP,
        fontSize: 13,
      ),
      onChanged: (ctrl == _refUldCtrl) ? (v) {
        setState(() => _refUld = v);
        _checkUldBreakStatus();
      } : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: textP.withAlpha(76),
          fontSize: 13,
        ),
        filled: true,
        fillColor: readOnly ? (dark ? const Color(0xFF0f172a).withAlpha(150) : const Color(0xFFF3F4F6)) : (dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6366f1),
            width: 1.5,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleTrailing != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              titleTrailing,
            ],
          )
        else
          Text(
            label,
            style: TextStyle(
              color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

class AwbNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 3) {
        buffer.write('-');
      } else if (i == 7) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class SentenceCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    List<String> lines = newValue.text.split('\n');
    for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) {
            String leftPad = '';
            String rightPad = '';
            String core = lines[i];

            while (core.isNotEmpty && core.startsWith(' ')) {
              leftPad += ' ';
              core = core.substring(1);
            }
            while (core.isNotEmpty && core.endsWith(' ')) {
              rightPad += ' ';
              core = core.substring(0, core.length - 1);
            }

            if (core.isNotEmpty) {
               String first = core[0].toUpperCase();
               String rest = core.substring(1).toLowerCase();
               lines[i] = leftPad + first + rest + rightPad;
            }
        }
    }

    return TextEditingValue(
      text: lines.join('\n'),
      selection: newValue.selection,
    );
  }
}
