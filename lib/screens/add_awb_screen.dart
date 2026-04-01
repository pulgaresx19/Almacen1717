import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage;

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
  bool _showExtraData = false;

  String? _selectedFlight;
  String _refUld = '';
  bool _isSavingAll = false;
  late final TextEditingController _refUldCtrl;

  List<Map<String, dynamic>> _flights = [];
  final List<Map<String, dynamic>> _localAwbs = [];
  final Set<String> _collapsedGroups = {};
  bool _totalLocked = false;

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

  void _showValidationDialog(List<String> missingFields, bool isMissingList) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (ctx) {
        String message;
        if (isMissingList) {
           message = appLanguage.value == 'es'
             ? 'No has añadido ningún AWB a la lista.\nPor favor, ingresa los datos y haz clic en "+ Add AWB" para proceder.'
             : 'You have not added any AWBs to the list.\nPlease enter the data and click "+ Add AWB" to proceed.';
        } else {
           String fieldsStr = missingFields.map((e) => '"$e"').join(', ');
           message = appLanguage.value == 'es'
             ? 'El campo $fieldsStr está ausente.\nPor favor, provea esta información para proceder.'
             : 'The field $fieldsStr is missing.\nPlease provide this information to proceed.';
           if (missingFields.length > 1) {
             message = appLanguage.value == 'es'
               ? 'Los campos $fieldsStr están ausentes.\nPor favor, provea esta información para proceder.'
               : 'The fields $fieldsStr are missing.\nPlease provide this information to proceed.';
           }
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFFef4444).withAlpha(100), width: 1.5),
          ),
          backgroundColor: const Color(0xFF1e293b),
          elevation: 20,
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFef4444),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appLanguage.value == 'es' ? 'Acción Requerida' : 'Action Required',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFcbd5e1),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: 200,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFef4444).withAlpha(76),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFef4444),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        appLanguage.value == 'es' ? 'ENTENDIDO' : 'UNDERSTOOD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    _awbNumberCtrl.dispose();
    _piecesCtrl.dispose();
    _totalCtrl.dispose();
    _weightCtrl.dispose();
    _houseCtrl.dispose();
    _remarksCtrl.dispose();
    _coordinatorCtrl.dispose();
    _locationCtrl.dispose();
    _refUldCtrl.dispose();
    super.dispose();
  }

  void _addLocalAwb() {
    List<String> errors = [];
    if (_awbNumberCtrl.text.trim().isEmpty) errors.add(appLanguage.value == 'es' ? 'Número' : 'Number');
    if (_piecesCtrl.text.trim().isEmpty) errors.add('Pieces');
    if (_totalCtrl.text.trim().isEmpty) errors.add('Total');

    if (errors.isNotEmpty) {
      _showValidationDialog(errors, false);
      return;
    }

    setState(() {
      String? flightLabel;
      if (_selectedFlight != null) {
        final f = _flights.firstWhere(
          (x) => x['id'].toString() == _selectedFlight,
          orElse: () => <String, dynamic>{},
        );
        if (f.isNotEmpty) {
          flightLabel = '${f['carrier']} ${f['number']}';
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
        'refUld': _refUld.trim().toUpperCase(),
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
      _refUldCtrl.clear();
      _refUld = '';
    });
  }

  Future<void> _saveAllAwbs() async {
    List<String> errors = [];
    if (_localAwbs.isEmpty) {
      if (_awbNumberCtrl.text.trim().isEmpty) errors.add(appLanguage.value == 'es' ? 'Número' : 'Number');
      if (_piecesCtrl.text.trim().isEmpty) errors.add('Pieces');
      if (_totalCtrl.text.trim().isEmpty) errors.add('Total');

      if (errors.isEmpty) {
        // Validation passes but hasn't been added to list
        _showValidationDialog([], true);
        return;
      } else {
        _showValidationDialog(errors, false);
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
          'refCarrier': 'WRHS',
          'refNumber': 'LOCAL',
          'refDate': dateStr,
          'refULD': a['refUld'],
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
    if (widget.onPop != null) {
      return _buildFormContent();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(
          appLanguage.value == 'es'
              ? 'Añadir Nuevo Air Waybill'
              : 'Add New Air Waybill',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1e293b),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appLanguage.value == 'es'
                            ? 'Detalles de AWB y Asignación'
                            : 'AWB Details & Assignment',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Extra Data?', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13, fontWeight: FontWeight.w600)),
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
                  const SizedBox(height: 16),


                  LayoutBuilder(
                    builder: (context, constraints) {
                      double baseWidth = _showExtraData ? 1435 : 1111;
                      double rWidth = constraints.maxWidth - baseWidth - 1;
                      if (rWidth < 180) rWidth = 180;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                        SizedBox(
                          width: 135,
                          child: _buildTextField('AWB Number', _awbNumberCtrl, '123-1234 5678', maxLen: 13, inputFormatters: [AwbNumberFormatter()]),
                        ),
                        SizedBox(width: 160, child: _buildFlightDropdown()),
                        SizedBox(
                          width: 130,
                          child: _buildTextField('Ref ULD', _refUldCtrl, 'AKE12345AA', maxLen: 10, inputFormatters: [UpperCaseTextFormatter()], textCapitalization: TextCapitalization.characters),
                        ),
                        SizedBox(
                          width: 90,
                          child: _buildTextField('Pieces', _piecesCtrl, '0', isNum: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                        ),
                        SizedBox(
                          width: 90,
                          child: _buildTextField('Total', _totalCtrl, '0', isNum: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly], readOnly: _totalLocked),
                        ),
                        SizedBox(
                          width: 90,
                          child: _buildTextField('Weight', _weightCtrl, '0.0', isNum: true, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
                        ),
                        SizedBox(
                          width: rWidth,
                          child: _buildTextField('Remarks', _remarksCtrl, 'Additional remarks...'),
                        ),
                        SizedBox(
                          width: 180,
                          child: _buildTextField('House Number', _houseCtrl, 'HAWB', maxLines: 3, inputFormatters: [UpperCaseTextFormatter()], textCapitalization: TextCapitalization.characters),
                        ),
                        if (_showExtraData) ...[
                          SizedBox(
                            width: 150,
                            child: _buildTextField('Data Coordinator', _coordinatorCtrl, 'Details...', maxLines: 3, minLines: 1, textCapitalization: TextCapitalization.sentences, inputFormatters: [SentenceCaseTextFormatter()]),
                          ),
                          SizedBox(
                            width: 150,
                            child: _buildTextField('Data Location', _locationCtrl, 'Details...', maxLines: 3, minLines: 1, textCapitalization: TextCapitalization.sentences, inputFormatters: [SentenceCaseTextFormatter()]),
                          ),
                        ],
                        SizedBox(
                          width: 140,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _addLocalAwb,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withAlpha(25),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              side: BorderSide(
                                color: Colors.white.withAlpha(25),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '+ Add AWB',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 16),

                  // Native table of added AWBs
                  if (_localAwbs.isNotEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: Builder(
                        builder: (context) {
                          Map<String, List<Map<String, dynamic>>> groupedAwbs =
                              {};
                          for (int i = 0; i < _localAwbs.length; i++) {
                            final a = _localAwbs[i];
                            final groupKey =
                                a['flightLabel'] ?? 'Standalone AWBs';
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(10),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withAlpha(20),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          groupName == 'Standalone AWBs'
                                              ? Icons.inventory_2_outlined
                                              : Icons.flight_takeoff_rounded,
                                          color: const Color(0xFF94a3b8),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          groupName,
                                          style: const TextStyle(
                                            color: Color(0xFFcbd5e1),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6366f1,
                                            ).withAlpha(40),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${groupItems.length} items',
                                            style: const TextStyle(
                                              color: Color(0xFF818cf8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(
                                            _collapsedGroups.contains(groupName)
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: const Color(0xFF94a3b8),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (_collapsedGroups.contains(
                                                groupName,
                                              )) {
                                                _collapsedGroups.remove(
                                                  groupName,
                                                );
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
                                        5: FlexColumnWidth(),      // remarks
                                        6: IntrinsicColumnWidth(), // coord/location
                                        7: IntrinsicColumnWidth(), // house
                                        8: IntrinsicColumnWidth(),
                                      },
                                      children: groupItems.asMap().entries.map((entry) {
                                        final i = entry.key;
                                        final item = entry.value;
                                        final int realIndex = item['index'];
                                        final a = item['awb'];
                                        final awbNum = a['awbNumber'];
                                        return TableRow(
                                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withAlpha(15)))),
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
                                                  Text(awbNum, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                  if (a['refUld'] != '' && a['refUld'] != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.inventory_2_outlined, size: 12, color: Color(0xFF94a3b8)),
                                                          const SizedBox(width: 4),
                                                          Text(a['refUld'], style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                              child: RichText(text: TextSpan(children: [
                                                const TextSpan(text: 'PIECES: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                TextSpan(text: '${a['pieces']}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
                                              ])),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                              child: RichText(text: TextSpan(children: [
                                                const TextSpan(text: 'TOTAL: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                TextSpan(text: '${a['total']}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
                                              ])),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                              child: RichText(text: TextSpan(children: [
                                                const TextSpan(text: 'WEIGHT: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                TextSpan(text: '${a['weight']}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
                                              ])),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                                              child: RichText(
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(children: [
                                                  const TextSpan(text: 'REMARKS: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                  TextSpan(
                                                    text: (a['remarks'] != null && a['remarks'].toString().isNotEmpty) ? a['remarks'].toString() : '-',
                                                    style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13),
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
                                                        decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.maps_home_work_outlined, size: 12, color: Color(0xFFcbd5e1)),
                                                            const SizedBox(width: 4),
                                                            Text('${houses.length} HAWB', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 11)),
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
                    ),
                ],
              ),
            ),
          ),
        ),
        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            border: Border(top: BorderSide(color: Colors.white.withAlpha(25))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
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

  Widget _buildFlightDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedFlight,
              hint: Text(
                'No Flight (Standalone)',
                style: TextStyle(color: Colors.white.withAlpha(150)),
              ),
              dropdownColor: const Color(0xFF1e293b),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
                      '${f['carrier']} ${f['number']} (${f['date-arrived']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedFlight = v),
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
    int? maxLen,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    int? maxLines = 1,
    int? minLines = 1,
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
        color: readOnly ? const Color(0xFFcbd5e1) : Colors.white,
        fontSize: 13,
      ),
      onChanged: (ctrl == _refUldCtrl) ? (v) => _refUld = v : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withAlpha(76),
          fontSize: 13,
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFF0f172a).withAlpha(150) : Colors.white.withAlpha(10),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
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
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFcbd5e1),
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
