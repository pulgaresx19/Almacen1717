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
  bool _refUldCheck = false;
  bool _refFlightCheck = true;
  bool _isBreak = false;

  List<Map<String, dynamic>> _flights = [];
  final List<Map<String, dynamic>> _localAwbs = [];
  final Set<String> _collapsedGroups = {};
  bool _totalLocked = false;
  Timer? _uldDebounce;

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
              final res = await Supabase.instance.client.from('awbs').select('total_espected').eq('awb_number', text).maybeSingle();
              if (res != null && res['total_espected'] != null && _awbNumberCtrl.text.toUpperCase() == text) {
                if (mounted) {
                  setState(() {
                    _totalLocked = true;
                    _totalCtrl.text = res['total_espected'].toString();
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
    final flights = await AddAwbV2Logic.loadFlights();
    if (mounted) {
      setState(() {
        _flights = flights;
        if (_selectedFlight == null && flights.isNotEmpty) {
          _selectedFlight = flights.first['id_flight']?.toString();
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

    final p = int.tryParse(_piecesCtrl.text) ?? 0;
    final t = int.tryParse(_totalCtrl.text) ?? 0;
    if (t > 0 && p > t) {
       showDialog(context: context, builder: (c) => AlertDialog(
         backgroundColor: const Color(0xFF1e293b),
         title: const Text('Validation Error', style: TextStyle(color: Colors.white)),
         content: const Text('Total pieces cannot be less than the received pieces.', style: TextStyle(color: Color(0xFFcbd5e1))),
         actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK', style: TextStyle(color: Color(0xFF6366f1))))]
       ));
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
        'coordinator': _coordinatorCtrl.text.trim().isNotEmpty ? _coordinatorCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}').toList() : null,
        'coordinatorCounts': Map<String, String>.from(_coordinatorCounts),
        'itemLocations': Map<String, String>.from(_itemLocations),
        'location': _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}').toList() : null,
        'flight_id': _selectedFlight,
        'flightLabel': flightLabel,
        'refCarrier': refCarrierOut,
        'refNumber': refNumberOut,
        'refUld': _refUld.trim().isEmpty ? 'MANUAL' : _refUld.trim().toUpperCase(),
        'isBreak': _isBreak,
      });

      _awbNumberCtrl.clear();
      _piecesCtrl.clear();
      _totalCtrl.clear();
      _weightCtrl.clear();
      _houseCtrl.clear();
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
          final profile = await Supabase.instance.client.from('users').select('full-name').eq('id', session.user.id).maybeSingle();
          if (profile != null && profile['full-name'] != null && profile['full-name'].toString().trim().isNotEmpty) {
            userName = profile['full-name'].toString().trim();
          }
        } catch (_) {}
      }

      final nowUtc = DateTime.now().toUtc().toIso8601String();
      
      Set<String> uniqueAwbs = {};
      for (var a in _localAwbs) {
         uniqueAwbs.add(a['awbNumber']);
      }
      
      final dbAwbs = await Supabase.instance.client.from('awbs').select('id, awb_number, total_espected, total_weight, data-coordinator, data-location').inFilter('awb_number', uniqueAwbs.toList());
      
      Map<String, Map<String, dynamic>> dbAwbMap = {};
      for (var row in dbAwbs) {
         dbAwbMap[row['awb_number'].toString()] = Map.from(row);
      }

      String? dummyFlightId;
      if (_localAwbs.any((a) => a['flight_id'] == null)) {
         final dummyCheck = await Supabase.instance.client.from('flights').select('id_flight').eq('carrier', 'NF').eq('number', '0000').limit(1).maybeSingle();
         if (dummyCheck != null) {
            dummyFlightId = dummyCheck['id_flight'].toString();
         } else {
            final ins = await Supabase.instance.client.from('flights').insert({'carrier': 'NF', 'number': '0000', 'status': 'Waiting', 'date': nowUtc.substring(0, 10)}).select().single();
            dummyFlightId = ins['id_flight'].toString();
         }
      }

      Map<String, String> uldIdMap = {};
      for (var a in _localAwbs) {
         final uldNum = a['refUld']?.toString().trim() ?? '';
         if (uldNum.isNotEmpty && uldNum != 'MANUAL') {
            final fId = a['flight_id'] ?? dummyFlightId;
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

      for (var a in _localAwbs) {
         final awbNum = a['awbNumber'];
         Map<String, dynamic>? currentAwbData = dbAwbMap[awbNum];
         String? currentAwbId = currentAwbData?['id']?.toString();
         
         bool hasCoordManual = a['coordinator'] != null && a['coordinator'].toString().isNotEmpty;
         Map<String, String>? coordCounts = a['coordinatorCounts'] as Map<String, String>?;
         bool hasCoordCounts = coordCounts != null && coordCounts.isNotEmpty;
         
         Map<String, dynamic>? coordRecord;
         if (hasCoordManual || hasCoordCounts) {
             coordRecord = {
                 'refULD': a['refUld'],
                 'refCarrier': a['refCarrier'],
                 'refNumber': a['refNumber'],
                 'user': userName,
                 'time': nowUtc
             };
             if (hasCoordManual) coordRecord['manual_entry'] = a['coordinator'];
             if (hasCoordCounts) {
                 coordRecord['breakdown'] = {
                    'AGI Skid': coordCounts['AGI Skid'] != null ? coordCounts['AGI Skid']!.split(RegExp(r'[,\s+]+')).where((e) => int.tryParse(e) != null && int.parse(e) > 0).toList() : [],
                    'Pre Skid': coordCounts['Pre Skid'] ?? '0',
                    'Crate': coordCounts['Crate'] ?? '0',
                    'Box': coordCounts['Box'] ?? '0',
                    'Other': coordCounts['Other'] ?? '0',
                 };
             }
         }
         
         Map<String, dynamic>? itemLocs = a['itemLocations'] as Map<String, dynamic>?;
         bool hasItemLocs = itemLocs != null && itemLocs.isNotEmpty;
         
         Map<String, dynamic>? locRecord;
         if ((a['location'] != null && a['location'].toString().isNotEmpty) || hasItemLocs) {
             locRecord = {
                 'refULD': a['refUld'],
                 'refCarrier': a['refCarrier'],
                 'refNumber': a['refNumber'],
                 'user': userName,
                 'time': nowUtc
             };
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
              'data-coordinator': dataCoord.isEmpty ? {} : dataCoord,
              'data-location': dataLoc.isEmpty ? {} : dataLoc,
            };
            
            final ins = await Supabase.instance.client.from('awbs').insert(payload).select().single();
            currentAwbId = ins['id'].toString();
            dbAwbMap[awbNum] = {
               'id': currentAwbId,
               'total_espected': formExpected,
               'total_weight': formWeight,
               'data-coordinator': payload['data-coordinator'],
               'data-location': payload['data-location'],
            };
         } else {
            final num curExpected = currentAwbData!['total_espected'] ?? 0;
            final num curWeight = currentAwbData['total_weight'] ?? 0.0;
            
            List dataCoord = [];
            if (currentAwbData['data-coordinator'] is List) {
               dataCoord = List.from(currentAwbData['data-coordinator']);
            } else if (currentAwbData['data-coordinator'] is Map && currentAwbData['data-coordinator'].isNotEmpty) {
               dataCoord = [currentAwbData['data-coordinator']];
            }
            if (coordRecord != null) dataCoord.add(coordRecord);
            
            List dataLoc = [];
            if (currentAwbData['data-location'] is List) {
               dataLoc = List.from(currentAwbData['data-location']);
            } else if (currentAwbData['data-location'] is Map && currentAwbData['data-location'].isNotEmpty) {
               dataLoc = [currentAwbData['data-location']];
            }
            if (locRecord != null) dataLoc.add(locRecord);
            
            final updatedExpected = curExpected + formExpected;
            final updatedWeight = curWeight + formWeight;

            await Supabase.instance.client.from('awbs').update({
               'total_espected': updatedExpected,
               'total_weight': updatedWeight,
               'data-coordinator': dataCoord.isEmpty ? {} : dataCoord,
               'data-location': dataLoc.isEmpty ? {} : dataLoc,
            }).eq('id', currentAwbId);
            
            currentAwbData['total_espected'] = updatedExpected;
            currentAwbData['total_weight'] = updatedWeight;
            currentAwbData['data-coordinator'] = dataCoord.isEmpty ? {} : dataCoord;
            currentAwbData['data-location'] = dataLoc.isEmpty ? {} : dataLoc;
         }
         
         final fId = a['flight_id'] ?? dummyFlightId;
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
         };
         await Supabase.instance.client.from('awb_splits').insert(splitPayload);
      }

      if (mounted) {
        bool dialogOpen = true;
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, anim1, anim2) {
            final dark = isDarkMode.value;
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1e293b) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10b981).withAlpha(40),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        appLanguage.value == 'es' ? '¡AWB Guardada!' : 'AWB Saved!',
                        style: TextStyle(
                          color: dark ? Colors.white : const Color(0xFF111827),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLanguage.value == 'es' ? 'Las Guías Aéreas se guardaron exitosamente.' : 'Air Waybills saved successfully.',
                        style: TextStyle(
                          color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, anim1, anim2, child) {
            return Transform.scale(
              scale: Curves.easeOutBack.transform(anim1.value),
              child: FadeTransition(
                opacity: anim1,
                child: child,
              ),
            );
          },
        ).then((_) => dialogOpen = false);

        await Future.delayed(const Duration(milliseconds: 2000));
        
        if (mounted) {
          if (dialogOpen) {
            Navigator.of(context).pop();
          }
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
