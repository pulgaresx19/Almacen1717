import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddUldScreen extends StatefulWidget {
  final Function(bool)? onPop;
  final bool isInline;
  const AddUldScreen({super.key, this.onPop, this.isInline = false});

  @override
  State<AddUldScreen> createState() => AddUldScreenState();
}

class AddUldScreenState extends State<AddUldScreen> {
  final _uldNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  String? _selectedFlight;
  bool _isPriority = false;
  bool _isBreak = false;
  bool _isSaving = false;

  bool _isFlightChk = true;
  bool _isPiecesChk = true;
  bool _isWeightChk = true;

  List<Map<String, dynamic>> _flights = [];
  final List<Map<String, dynamic>> _localUlds = [];
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _piecesCtrl.text = 'Auto';
    _weightCtrl.text = 'Auto';
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    try {
      final res = await Supabase.instance.client.from('Flight').select('id, carrier, number, date-arrived').order('created_at');
      if (mounted) {
        setState(() {
          _flights = List.from(res);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _uldNumberCtrl.dispose();
    _piecesCtrl.dispose();
    _weightCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _addLocalUld() {
    if (_uldNumberCtrl.text.trim().isEmpty) {
      _showRequiredFieldError(context, 'ULD Number');
      return;
    }
    setState(() {
      String? flightLabel;
      if (_selectedFlight != null) {
        final f = _flights.firstWhere((x) => x['id'].toString() == _selectedFlight, orElse: () => <String, dynamic>{});
        if (f.isNotEmpty) {
          flightLabel = '${f['carrier']} ${f['number']}';
        }
      }

      _localUlds.add({
        'uldNumber': _uldNumberCtrl.text.toUpperCase(),
        'pieces': _piecesCtrl.text.isNotEmpty && _piecesCtrl.text != 'Auto' ? (int.tryParse(_piecesCtrl.text) ?? 0) : 0,
        'weight': _weightCtrl.text.isNotEmpty && _weightCtrl.text != 'Auto' ? (double.tryParse(_weightCtrl.text) ?? 0.0) : 0.0,
        'remarks': _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
        'status': 'Waiting',
        'priority': _isPriority,
        'break': _isBreak,
        'flight_id': _selectedFlight,
        'flightLabel': flightLabel,
        'isAutoPieces': _isPiecesChk,
        'isAutoWeight': _isWeightChk,
        'awbs': [],
        'showAwbs': true,
      });

      _uldNumberCtrl.clear();
      _piecesCtrl.text = _isPiecesChk ? 'Auto' : '';
      _weightCtrl.text = _isWeightChk ? 'Auto' : '';
      _remarksCtrl.clear();
      _isPriority = false;
      _isBreak = false;
      if (!_isFlightChk) {
        _selectedFlight = null;
      }
    });
  }

  void _showRequiredFieldError(BuildContext context, String fieldName) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFFef4444).withAlpha(100), width: 2)),
        title: const Column(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFef4444), size: 60),
            SizedBox(height: 16),
            Text('Action Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('The field "$fieldName" is missing.\nPlease provide this information to proceed.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 16, height: 1.4)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0)),
            onPressed: () => Navigator.pop(c),
            child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  Future<void> _showAddAwbDialog(int uldIndex) async {
    final awbNumCtrl = TextEditingController();
    final piecesCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final remCtrl = TextEditingController();
    final totalLocked = ValueNotifier<bool>(false);

    awbNumCtrl.addListener(() {
      final text = awbNumCtrl.text.toUpperCase();
      if (text.length == 13) {
        bool foundLocally = false;
        String foundTotal = '';
        for (var u in _localUlds) {
          for (var a in (u['awbs'] as List)) {
            if (a['awb_number'] == text) {
              foundLocally = true;
              foundTotal = a['total'].toString();
              break;
            }
          }
          if (foundLocally) break;
        }

        if (foundLocally) {
          totalLocked.value = true;
          if (totalCtrl.text != foundTotal) {
            totalCtrl.text = foundTotal;
          }
        } else {
          () async {
            try {
              final res = await Supabase.instance.client.from('AWB').select('total').eq('AWB-number', text).maybeSingle();
              if (res != null && res['total'] != null && awbNumCtrl.text.toUpperCase() == text) {
                totalLocked.value = true;
                totalCtrl.text = res['total'].toString();
              }
            } catch (_) {}
          }();
        }
      } else {
        if (totalLocked.value) {
          totalLocked.value = false;
          totalCtrl.text = '0';
        }
      }
    });

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              title: Text('Add AWB to ${_localUlds[uldIndex]['uldNumber']}', style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildTextField('AWB Number', awbNumCtrl, '123-1234 5678', isAwb: true)),
                          const SizedBox(width: 8),
                          Expanded(flex: 3, child: _buildTextField('Pieces', piecesCtrl, '0', isNum: true, digitsOnly: true)),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3, 
                            child: ValueListenableBuilder<bool>(
                              valueListenable: totalLocked,
                              builder: (ctx, locked, _) => _buildTextField('Total', totalCtrl, '0', isNum: true, digitsOnly: true, disabled: locked),
                            )
                          ),
                          const SizedBox(width: 8),
                          Expanded(flex: 3, child: _buildTextField('Weight', weightCtrl, '0.0', isNum: true, allowDecimal: true)),
                        ]
                      ),
                      const SizedBox(height: 12),
                      _buildTextField('Remarks', remCtrl, 'Additional remarks...'),
                      const SizedBox(height: 12),
                      _buildTextField('House Number', houseCtrl, 'HAWB', maxLines: 3, minLines: 1, isUpperCase: true),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8)))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
                  onPressed: () {
                    final newAwb = awbNumCtrl.text.trim().toUpperCase();
                    if (newAwb.isEmpty) { _showRequiredFieldError(ctx, 'AWB Number'); return; }
                    if (piecesCtrl.text.trim().isEmpty || piecesCtrl.text.trim() == '0') { _showRequiredFieldError(ctx, 'Pieces'); return; }
                    if (totalCtrl.text.trim().isEmpty || totalCtrl.text.trim() == '0') { _showRequiredFieldError(ctx, 'Total'); return; }
                    
                    final existingAwbs = _localUlds[uldIndex]['awbs'] as List;
                    if (existingAwbs.any((a) => a['awb_number'] == newAwb)) {
                        showDialog(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            backgroundColor: const Color(0xFF1e293b),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b)),
                                SizedBox(width: 8),
                                Text('Duplicate AWB', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            content: Text('The AWB "$newAwb" is already registered under this ULD. Please verify or modify the existing entry.', style: const TextStyle(color: Color(0xFFcbd5e1))),
                            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK', style: TextStyle(color: Color(0xFF6366f1))))],
                          )
                        );
                        return;
                      }

                      setState(() {
                        _localUlds[uldIndex]['awbs'].add({
                          'awb_number': newAwb,
                          'pieces': int.tryParse(piecesCtrl.text) ?? 0,
                          'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                          'total': int.tryParse(totalCtrl.text) ?? 1,
                          'house_number': houseCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                          'remarks': remCtrl.text.trim().isEmpty ? null : remCtrl.text.trim(),
                        });
                        if (_localUlds[uldIndex]['isAutoPieces'] == true) {
                          _localUlds[uldIndex]['pieces'] = (_localUlds[uldIndex]['awbs'] as List).fold<int>(0, (s, a) => s + ((a['pieces'] as num).toInt()));
                        }
                        if (_localUlds[uldIndex]['isAutoWeight'] == true) {
                          _localUlds[uldIndex]['weight'] = (_localUlds[uldIndex]['awbs'] as List).fold<double>(0.0, (s, a) => s + ((a['weight'] as num).toDouble()));
                        }
                      });
                      Navigator.pop(ctx);
                  },
                  child: const Text('Add AWB', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
      }
    );
  }

  Future<void> _saveAllUlds() async {
    if (_localUlds.isEmpty) {
      _showRequiredFieldError(context, 'ULD List (Add at least 1 ULD)');
      return;
    }

    final emptyUld = _localUlds.firstWhere((u) => (u['awbs'] as List).isEmpty, orElse: () => {});
    if (emptyUld.isNotEmpty) {
      _showRequiredFieldError(context, 'AWBs for ULD ${emptyUld['uldNumber']}');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      List<Map<String, dynamic>> payloads = [];
      Map<String, Map<String, dynamic>> mergedAwbs = {};
      final nowStr = DateTime.now().toIso8601String();
      final todayStr = nowStr.substring(0, 10);
      final timeStr = DateTime.now().toLocal().toString().substring(11, 16);

      bool needsDummy = _localUlds.any((u) => u['flight_id'] == null);
      if (needsDummy) {
        final dummyCheck = await supabase.from('Flight')
            .select('id')
            .eq('carrier', 'NF')
            .eq('number', '0000')
            .eq('date-arrived', todayStr)
            .maybeSingle();

        if (dummyCheck == null) {
          await supabase.from('Flight').insert({
            'carrier': 'NF',
            'number': '0000',
            'cant-break': 0,
            'cant-noBreak': 0,
            'date-arrived': todayStr,
            'time-arrived': timeStr,
            'remarks': '',
            'status': 'Waiting',
            'created_at': nowStr,
          });
        }
      }

      for (var uld in _localUlds) {
        String? carrier = 'NF';
        String? number = '0000';
        String? date = todayStr;

        if (uld['flight_id'] != null) {
          final f = _flights.firstWhere((x) => x['id'].toString() == uld['flight_id'], orElse: () => {});
          if (f.isNotEmpty) {
            carrier = f['carrier'];
            number = f['number'];
            date = f['date-arrived'];
          }
        }

        payloads.add({
          'ULD-number': uld['uldNumber'],
          'pieces': uld['pieces'],
          'weight': uld['weight'],
          'isPriority': uld['priority'],
          'isBreak': uld['break'],
          'status': uld['status'],
          'remarks': uld['remarks'],
          'refCarrier': carrier,
          'refNumber': number,
          'refDate': date,
          'data-ULD': uld['awbs'],
          'created_at': nowStr,
        });

        // Group AWBs to also save them independently
        for (var awb in (uld['awbs'] as List)) {
          final num = awb['awb_number'];
          if (!mergedAwbs.containsKey(num)) {
             mergedAwbs[num] = {
               'AWB-number': num,
               'total': awb['total'],
               'data-AWB': [],
             };
          }
          (mergedAwbs[num]!['data-AWB'] as List).add({
              'refCarrier': carrier,
              'refNumber': number,
              'refDate': date,
              'refULD': uld['uldNumber'],
              'pieces': awb['pieces'],
              'weight': awb['weight'],
              'remarks': awb['remarks'],
              'isBreak': uld['break'],
              'house_number': awb['house_number']
          });
        }
      }

      await supabase.from('ULD').insert(payloads);

      // Upsert collected AWBs
      if (mergedAwbs.isNotEmpty) {
         final awbNumbers = mergedAwbs.keys.toList();
         final existingDbAwbs = await supabase.from('AWB').select('AWB-number, data-AWB').inFilter('AWB-number', awbNumbers);
         
         final existingAwbMap = { for (var e in existingDbAwbs) e['AWB-number'] : e['data-AWB'] };
         
         for (var awbNum in mergedAwbs.keys) {
            if (existingAwbMap.containsKey(awbNum)) {
               var dbData = existingAwbMap[awbNum];
               if (dbData is List) {
                  (mergedAwbs[awbNum]!['data-AWB'] as List).insertAll(0, dbData);
               }
            }
         }
         
         final finalAwbPayloads = mergedAwbs.values.map((v) {
           final n = v['AWB-number'];
           Map<String, dynamic> out = {
             'AWB-number': n,
             'total': v['total'],
             'data-AWB': v['data-AWB'],
           };
           if (!existingAwbMap.containsKey(n)) {
              out['created_at'] = nowStr;
           }
           return out;
         }).toList();
         
         await supabase.from('AWB').upsert(finalAwbPayloads, onConflict: 'AWB-number');
      }
      
      if (mounted) {
        await showDialog(
          context: context,
          barrierColor: Colors.black45,
          barrierDismissible: false,
          builder: (ctx) {
            Future.delayed(const Duration(seconds: 2), () {
              if (ctx.mounted) Navigator.pop(ctx);
            });
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF1e293b),
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10b981), size: 64),
                    SizedBox(height: 16),
                    Text(
                      'ULDs saved successfully',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get hasDataSync {
    if (_localUlds.isNotEmpty) return true;
    if (_uldNumberCtrl.text.isNotEmpty || 
       (_piecesCtrl.text.isNotEmpty && _piecesCtrl.text != 'Auto') || 
       (_weightCtrl.text.isNotEmpty && _weightCtrl.text != 'Auto') ||
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFFf59e0b).withAlpha(100), width: 2)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 60),
            SizedBox(height: 16),
            Text('Discard Data?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Any unsaved data entered for the ULD will be permanently lost.\n\nDo you want to discard your changes and continue?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 16, height: 1.4),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('STAY', style: TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFFef4444).withAlpha(100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
    if (widget.isInline) {
      return _buildFormContent();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: const Text('Add New ULDs'),
        backgroundColor: const Color(0xFF1e293b),
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
                  const Text('ULD Details & Assignment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double rWidth = constraints.maxWidth - 844; 
                      if (rWidth < 180) rWidth = 180;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          SizedBox(width: 130, child: _buildTextField('ULD Number', _uldNumberCtrl, 'AKE12345AA', maxLen: 10, isUpperCase: true)),
                          SizedBox(width: 200, child: _buildFlightDropdown(
                            titleTrailing: SizedBox(
                              width: 20, height: 20,
                              child: Checkbox(
                                value: _isFlightChk,
                                activeColor: const Color(0xFF6366f1),
                                side: const BorderSide(color: Color(0xFF94a3b8)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) => setState(() => _isFlightChk = v ?? true),
                              )
                            )
                          )),
                          SizedBox(width: 90, child: _buildTextField('Pieces', _piecesCtrl, '0', isNum: true, digitsOnly: true, disabled: _isPiecesChk,
                            titleTrailing: SizedBox(
                              width: 20, height: 20,
                              child: Checkbox(
                                value: _isPiecesChk,
                                activeColor: const Color(0xFF6366f1),
                                side: const BorderSide(color: Color(0xFF94a3b8)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) => setState(() {
                                  _isPiecesChk = v ?? true;
                                  _piecesCtrl.text = _isPiecesChk ? 'Auto' : '';
                                }),
                              )
                            )
                          )),
                          SizedBox(width: 90, child: _buildTextField('Weight', _weightCtrl, '0.0', isNum: true, allowDecimal: true, disabled: _isWeightChk,
                            titleTrailing: SizedBox(
                              width: 20, height: 20,
                              child: Checkbox(
                                value: _isWeightChk,
                                activeColor: const Color(0xFF6366f1),
                                side: const BorderSide(color: Color(0xFF94a3b8)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) => setState(() {
                                  _isWeightChk = v ?? true;
                                  _weightCtrl.text = _isWeightChk ? 'Auto' : '';
                                }),
                              )
                            )
                          )),
                          SizedBox(width: rWidth, child: _buildTextField('Remarks', _remarksCtrl, 'Additional remarks...')),
                          SizedBox(
                            width: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  const Text('Priority?', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
                                  Switch(value: _isPriority, activeThumbColor: const Color(0xFF6366f1), onChanged: (v) => setState(() => _isPriority = v)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  const Text('Break?', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
                                  Switch(value: _isBreak, activeThumbColor: const Color(0xFF6366f1), onChanged: (v) => setState(() => _isBreak = v)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _addLocalUld,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(25),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                side: BorderSide(color: Colors.white.withAlpha(25)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('+ Add ULD', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      );
                    }
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 16),

                  // Native table of added ULDs
                  if (_localUlds.isNotEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5), 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: Builder(
                        builder: (context) {
                          Map<String, List<Map<String, dynamic>>> groupedUlds = {};
                          for (int i = 0; i < _localUlds.length; i++) {
                            final u = _localUlds[i];
                            final groupKey = u['flightLabel'] ?? 'Standalone ULDs';
                            groupedUlds.putIfAbsent(groupKey, () => []);
                            groupedUlds[groupKey]!.add({'index': i, 'uld': u});
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedUlds.entries.map((group) {
                              final groupName = group.key;
                              final groupItems = group.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(10),
                                      border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20)))
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(groupName == 'Standalone ULDs' ? Icons.inventory_2_outlined : Icons.flight_takeoff_rounded, color: const Color(0xFF94a3b8), size: 16),
                                        const SizedBox(width: 8),
                                        Text(groupName, style: const TextStyle(color: Color(0xFFcbd5e1), fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                          child: Text('${groupItems.length} items', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(_collapsedGroups.contains(groupName) ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94a3b8), size: 20),
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
                                      ]
                                    )
                                  ),
                                  if (!_collapsedGroups.contains(groupName))
                                    ...groupItems.asMap().entries.map((groupEntry) {
                                      int groupIndex = groupEntry.key;
                                      var item = groupEntry.value;
                                      int i = item['index'];
                                      var u = item['uld'];
                                      List awbs = u['awbs'] ?? [];
                                      return Column(
                                        children: [
                                          Container(
                                            color: Colors.white.withAlpha(15),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            margin: const EdgeInsets.only(bottom: 2),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 32, height: 32,
                                                        alignment: Alignment.center,
                                                        decoration: const BoxDecoration(color: Color(0x326366f1), shape: BoxShape.circle),
                                                        child: Text('${groupIndex + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 13)),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      SizedBox(
                                                      width: 115,
                                                      child: Text(u['uldNumber'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5))
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Container(
                                                      width: 95,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                                      decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(6)), 
                                                      child: Text('Pieces: ${u['pieces']}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12))
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      width: 95,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                                      decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(6)), 
                                                      child: Text('Weight: ${u['weight']}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12))
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      width: 90,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                                      decoration: BoxDecoration(color: (u['priority'] == true) ? const Color(0xFFf59e0b).withAlpha(50) : Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(6)), 
                                                      child: Text('Priority: ${(u['priority'] == true) ? 'Yes' : 'No'}', style: TextStyle(color: (u['priority'] == true) ? const Color(0xFFfde68a) : const Color(0xFFcbd5e1), fontSize: 12, fontWeight: (u['priority'] == true) ? FontWeight.bold : FontWeight.normal))
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      width: 80,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                                      decoration: BoxDecoration(color: (u['break'] == true) ? const Color(0xFF10b981).withAlpha(50) : const Color(0xFFef4444).withAlpha(50), borderRadius: BorderRadius.circular(6)), 
                                                      child: Text('Break: ${(u['break'] == true) ? 'Yes' : 'No'}', style: TextStyle(color: (u['break'] == true) ? const Color(0xFF6ee7b7) : const Color(0xFFfca5a5), fontSize: 12, fontWeight: FontWeight.bold))
                                                    ),
                                                    const SizedBox(width: 16),
                                                    if (u['remarks'] != null && u['remarks'].toString().isNotEmpty)
                                                      Expanded(
                                                        child: Text('Rem: ${u['remarks']}', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 32, height: 32,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withAlpha(15), 
                                                      shape: BoxShape.circle
                                                    ),
                                                    child: Text(
                                                      '${awbs.length}', 
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    icon: Icon(
                                                      (u['showAwbs'] ?? true) ? Icons.visibility : Icons.visibility_off, 
                                                      color: (u['showAwbs'] ?? true) ? const Color(0xFF94a3b8) : const Color(0xFF64748b), 
                                                      size: 20
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _localUlds[i]['showAwbs'] = !(u['showAwbs'] ?? true);
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(width: 12),
                                                  ElevatedButton.icon(
                                                    onPressed: () => _showAddAwbDialog(i),
                                                    icon: const Icon(Icons.add, size: 16),
                                                    label: const Text('Add AWB', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF10b981),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                                    onPressed: () {
                                                      setState(() => _localUlds.removeAt(i));
                                                    },
                                                  )
                                                ]
                                              )
                                            ],
                                          ),
                                        ),
                                        if (awbs.isNotEmpty && (u['showAwbs'] ?? true))
                                          Table(
                                            columnWidths: const {
                                              0: IntrinsicColumnWidth(),
                                              1: IntrinsicColumnWidth(),
                                              2: IntrinsicColumnWidth(),
                                              3: IntrinsicColumnWidth(),
                                              4: IntrinsicColumnWidth(),
                                              5: FlexColumnWidth(),
                                              6: IntrinsicColumnWidth(),
                                              7: IntrinsicColumnWidth(),
                                            },
                                            children: awbs.asMap().entries.map((entry) {
                                              final aInt = entry.key;
                                              final a = entry.value;
                                              return TableRow(
                                                children: [
                                                  Padding(padding: const EdgeInsets.all(8), child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0x14ffffff), shape: BoxShape.circle), child: Center(child: Text('${aInt + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
                                                  Padding(padding: const EdgeInsets.only(left: 8, right: 32, top: 8, bottom: 8), child: Text(a['awb_number'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                                                  Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8), child: RichText(text: TextSpan(children: [
                                                    const TextSpan(text: 'PIECES: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                    TextSpan(text: '${a['pieces']}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                                                  ]))),
                                                  Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8), child: RichText(text: TextSpan(children: [
                                                    const TextSpan(text: 'TOTAL: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                    TextSpan(text: '${a['total'] ?? 0}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                                                  ]))),
                                                  Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8), child: RichText(text: TextSpan(children: [
                                                    const TextSpan(text: 'WEIGHT: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                    TextSpan(text: '${a['weight']}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                                                  ]))),
                                                  Padding(padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8), child: RichText(
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    text: TextSpan(children: [
                                                      const TextSpan(text: 'REMARKS: ', style: TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
                                                      TextSpan(text: a['remarks']?.isNotEmpty == true ? a['remarks'] : '-', style: const TextStyle(color: Color(0xFF94a3b8), fontStyle: FontStyle.italic, fontSize: 12)),
                                                    ]),
                                                  )),
                                                  Padding(padding: const EdgeInsets.all(8), child: Builder(
                                                    builder: (ctx) {
                                                      final rawH = a['house_number'];
                                                      final List<String> items = (rawH is List) ? rawH.map((e) => e.toString()).toList() : [];
                                                      if (items.isEmpty) {
                                                        return const SizedBox.shrink();
                                                      }
                                                      return Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: InkWell(
                                                          onTap: () {
                                                              showDialog(
                                                                context: ctx,
                                                                builder: (c) => Dialog(
                                                                  backgroundColor: const Color(0xFF1e293b),
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withAlpha(20))),
                                                                  child: Container(
                                                                    width: 320,
                                                                    padding: const EdgeInsets.all(20),
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text('House Numbers (${items.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                        const SizedBox(height: 16),
                                                                        Flexible(
                                                                          child: SingleChildScrollView(
                                                                            child: Column(
                                                                              children: items.asMap().entries.map((ent) => Padding(
                                                                                padding: const EdgeInsets.only(bottom: 12),
                                                                                child: Row(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Container(
                                                                                      width: 20, height: 20,
                                                                                      alignment: Alignment.center,
                                                                                      decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                                                                                      child: Text('${ent.key + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                                                                                    ),
                                                                                    const SizedBox(width: 12),
                                                                                    Expanded(child: Text(ent.value, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 14))),
                                                                                  ],
                                                                                ),
                                                                              )).toList(),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 12),
                                                                        Align(
                                                                          alignment: Alignment.centerRight,
                                                                          child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                          },
                                                          borderRadius: BorderRadius.circular(12),
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(Icons.maps_home_work_outlined, size: 12, color: Color(0xFFcbd5e1)),
                                                                const SizedBox(width: 4),
                                                                Text('${items.length} HAWB', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 11)),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  )),
                                                  Padding(
                                                    padding: const EdgeInsets.all(6),
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(4),
                                                      onTap: () {
                                                        setState(() {
                                                          _localUlds[i]['awbs'].removeAt(aInt);
                                                          if (_localUlds[i]['isAutoPieces'] == true) {
                                                            _localUlds[i]['pieces'] = (_localUlds[i]['awbs'] as List).fold<int>(0, (s, a) => s + ((a['pieces'] as num).toInt()));
                                                          }
                                                          if (_localUlds[i]['isAutoWeight'] == true) {
                                                            _localUlds[i]['weight'] = (_localUlds[i]['awbs'] as List).fold<double>(0.0, (s, a) => s + ((a['weight'] as num).toDouble()));
                                                          }
                                                        });
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: Icon(Icons.close, color: Colors.redAccent.withAlpha(200), size: 16),
                                                      ),
                                                    ),
                                                  ),
                                                ]
                                              );
                                            }).toList(),
                                          ),
                                        const Divider(height: 1, color: Colors.transparent),
                                      ],
                                    );
                                  }),
                                ],
                              );
                            }).toList(),
                          );
                        }
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Bottom Pinned Action Bar
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(right: 24.0, bottom: 24.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                onPressed: _isSaving ? null : _saveAllUlds,
                icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _isSaving ? 'Processing...' : 'Save ULDs', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {bool isNum = false, bool digitsOnly = false, bool allowDecimal = false, int? maxLen, bool disabled = false, Widget? suffixIcon, VoidCallback? onTap, bool readOnly = false, bool isUpperCase = false, Widget? titleTrailing, bool isAwb = false, int? maxLines = 1, int? minLines, bool expands = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
             titleTrailing ?? const SizedBox.shrink(),
           ],
        ),
        const SizedBox(height: 6),
        expands 
        ? Expanded(
            child: _buildInnerTextField(ctrl, disabled, readOnly, onTap, isNum, allowDecimal, isUpperCase, isAwb, digitsOnly, maxLen, null, null, true, hint, suffixIcon)
          )
        : _buildInnerTextField(ctrl, disabled, readOnly, onTap, isNum, allowDecimal, isUpperCase, isAwb, digitsOnly, maxLen, maxLines, minLines, false, hint, suffixIcon),
      ],
    );
  }

  Widget _buildInnerTextField(TextEditingController ctrl, bool disabled, bool readOnly, VoidCallback? onTap, bool isNum, bool allowDecimal, bool isUpperCase, bool isAwb, bool digitsOnly, int? maxLen, int? maxLines, int? minLines, bool expands, String hint, Widget? suffixIcon) {
    return TextField(
      controller: ctrl,
      enabled: !disabled,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: (maxLines == null || maxLines > 1) ? TextInputType.multiline : (isNum ? (allowDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number) : TextInputType.text),
      textCapitalization: isUpperCase ? TextCapitalization.characters : TextCapitalization.none,
          inputFormatters: [
            if (isAwb) AwbTextInputFormatter(),
            if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
            if (allowDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            if (isUpperCase) TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection)),
          ],
          maxLength: maxLen,
          maxLines: maxLines,
          minLines: minLines,
          expands: expands,
          textAlignVertical: expands ? TextAlignVertical.top : null,
          style: TextStyle(color: disabled ? Colors.white.withAlpha(120) : Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withAlpha(76), fontSize: 12),
            filled: true,
            fillColor: disabled ? Colors.white.withAlpha(5) : Colors.white.withAlpha(13),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8b5cf6), width: 1.5)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(10))),
            suffixIcon: suffixIcon,
          ),
        );
  }

  Widget _buildFlightDropdown({Widget? titleTrailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Reference Flight', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            titleTrailing ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedFlight,
              hint: const Text('Standalone ULD', style: TextStyle(color: Colors.white, fontSize: 12)),
              dropdownColor: const Color(0xFF1e293b),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFcbd5e1), size: 20),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Standalone ULD')),
                ..._flights.map((f) => DropdownMenuItem<String?>(
                  value: f['id'].toString(),
                  child: Text('${f['carrier']} ${f['number']} (${f['date-arrived']})'),
                ))
              ],
              onChanged: (v) => setState(() => _selectedFlight = v),
            ),
          ),
        ),
      ],
    );
  }
}

class AwbTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.length > 11) raw = raw.substring(0, 11);
    
    String formatted = '';
    for (int i = 0; i < raw.length; i++) {
        if (i == 3) formatted += '-';
        if (i == 7) formatted += ' ';
        formatted += raw[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ResizeHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94a3b8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width * 0.45, size.height), Offset(size.width, size.height * 0.45), paint);
    canvas.drawLine(Offset(size.width * 0.9, size.height), Offset(size.width, size.height * 0.9), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
