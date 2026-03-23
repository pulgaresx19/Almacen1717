import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddFlightScreen extends StatefulWidget {
  final Function(bool)? onPop;
  final bool isInline;
  const AddFlightScreen({super.key, this.onPop, this.isInline = false});

  @override
  State<AddFlightScreen> createState() => _AddFlightScreenState();
}

class _AddFlightScreenState extends State<AddFlightScreen> {
  // Flight Controllers
  final _carrierCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  // Break Counters
  int _cBreak = 0;
  int _cNoBreak = 0;
  bool _isBreakAuto = true;
  bool _isNoBreakAuto = true;
  final _breakCtrl = TextEditingController(text: 'Auto');
  final _noBreakCtrl = TextEditingController(text: 'Auto');

  String _status = 'Waiting';
  bool _isSaving = false;

  // ULD Controllers
  final _uldNumberCtrl = TextEditingController();
  final _uldPiecesCtrl = TextEditingController(text: 'Auto');
  final _uldWeightCtrl = TextEditingController(text: 'Auto');
  final _uldRemarksCtrl = TextEditingController();
  bool _uldPriority = false;
  bool _uldBreak = false;
  bool _isUldPiecesAuto = true;
  bool _isUldWeightAuto = true;

  // Nested Data
  final List<Map<String, dynamic>> _flightLocalUlds = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate() async {
    DateTime initD = DateTime.now();
    if (_dateCtrl.text.isNotEmpty) {
      try { initD = DateFormat('MM/dd/yyyy').parse(_dateCtrl.text); } catch (_) {}
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initD,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366f1),
              onPrimary: Colors.white,
              surface: Color(0xFF1e293b),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateCtrl.text = DateFormat('MM/dd/yyyy').format(picked));
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
             colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366f1),
              surface: Color(0xFF1e293b),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
        _timeCtrl.text = DateFormat('hh:mm a').format(dt).toUpperCase();
      });
    }
  }

  @override
  void dispose() {
    _carrierCtrl.dispose();
    _numberCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _remarksCtrl.dispose();
    _breakCtrl.dispose();
    _noBreakCtrl.dispose();
    _uldNumberCtrl.dispose();
    _uldPiecesCtrl.dispose();
    _uldWeightCtrl.dispose();
    _uldRemarksCtrl.dispose();
    super.dispose();
  }

  void _addLocalUld() {
    if (_uldNumberCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ULD Number required to add to local list.')));
      return;
    }
    setState(() {
      _flightLocalUlds.add({
        'uldNumber': _uldNumberCtrl.text.toUpperCase(),
        'pieces': _uldPiecesCtrl.text.isNotEmpty ? int.tryParse(_uldPiecesCtrl.text) : 0,
        'weight': _uldWeightCtrl.text.isNotEmpty ? double.tryParse(_uldWeightCtrl.text) : 0.0,
        'remarks': _uldRemarksCtrl.text,
        'priority': _uldPriority,
        'break': _uldBreak,
        'awbs': [], 
      });
      // Update auto breaks
      if (_uldBreak) {
        _cBreak++;
        if (_isBreakAuto) _breakCtrl.text = 'Auto';
      } else {
        _cNoBreak++;
        if (_isNoBreakAuto) _noBreakCtrl.text = 'Auto';
      }
      
      _uldNumberCtrl.clear();
      _uldPiecesCtrl.text = _isUldPiecesAuto ? 'Auto' : '';
      _uldWeightCtrl.text = _isUldWeightAuto ? 'Auto' : '';
      _uldRemarksCtrl.clear();
      _uldPriority = false;
      _uldBreak = false;
    });
  }

  Future<void> _showAddAwbDialog(int uldIndex) async {
    final awbNumCtrl = TextEditingController();
    final piecesCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final remCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1e293b),
          title: Text('Add AWB to ${_flightLocalUlds[uldIndex]['uldNumber']}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildTextField('AWB Number', awbNumCtrl, '123-1234 5678', isAwb: true)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildTextField('Pieces', piecesCtrl, '0', isNum: true)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildTextField('Total', totalCtrl, '0', isNum: true)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildTextField('Weight', weightCtrl, '0.0', isNum: true)),
                  ]
                ),
                const SizedBox(height: 12),
                _buildTextField('Remarks', remCtrl, 'Notas...'),
                const SizedBox(height: 12),
                _buildTextField('House Number', houseCtrl, 'HAWB1, HAWB2...', maxLines: null, minLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
              onPressed: () {
                if (awbNumCtrl.text.isNotEmpty && totalCtrl.text.isNotEmpty) {
                  setState(() {
                    _flightLocalUlds[uldIndex]['awbs'].add({
                      'awb_number': awbNumCtrl.text.toUpperCase(),
                      'pieces': int.tryParse(piecesCtrl.text) ?? 0,
                      'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                      'total': int.tryParse(totalCtrl.text) ?? 1,
                      'house_number': houseCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      'remarks': remCtrl.text,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add AWB', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _saveEverything() async {
    if (_carrierCtrl.text.isEmpty || _numberCtrl.text.isEmpty || _dateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrier, Number y Date son obligatorios')));
      return;
    }

    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      final fCarrier = _carrierCtrl.text.toUpperCase();
      final fNumber = _numberCtrl.text;
      
      String fDate = _dateCtrl.text;
      if (fDate.isNotEmpty) {
        try { fDate = DateFormat('yyyy-MM-dd').format(DateFormat('MM/dd/yyyy').parse(_dateCtrl.text)); } catch (_) {}
      }
      
      String fTime = _timeCtrl.text;
      if (fTime.isNotEmpty) {
        try { fTime = DateFormat('HH:mm').format(DateFormat('hh:mm a').parse(_timeCtrl.text)); } catch (_) {}
      }
      
      final flightPayload = {
        'carrier': fCarrier,
        'number': fNumber,
        'cant-break': _isBreakAuto ? _cBreak : (int.tryParse(_breakCtrl.text) ?? 0),
        'cant-noBreak': _isNoBreakAuto ? _cNoBreak : (int.tryParse(_noBreakCtrl.text) ?? 0),
        'date-arrived': fDate,
        'time-arrived': fTime.isEmpty ? null : fTime,
        'remarks': _remarksCtrl.text,
        'status': _status,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('Flight').insert([flightPayload]);
      
      if (_flightLocalUlds.isNotEmpty) {
        for (var uld in _flightLocalUlds) {
          final uldPayload = {
            'ULD number': uld['uldNumber'],
            'refCarrier': fCarrier,
            'refNumber': fNumber,
            'refDate': fDate,
            'pieces': uld['pieces'],
            'weight': uld['weight'],
            'isPriority': uld['priority'],
            'isBreak': uld['break'],
            'created_at': DateTime.now().toIso8601String(),
          };
          await supabase.from('ULD').insert([uldPayload]);

          List awbs = uld['awbs'];
          if (awbs.isNotEmpty) {
            for (var awb in awbs) {
              final awbNum = awb['awb_number'];
              final existingAwbList = await supabase.from('AWB').select('*').eq('AWB number', awbNum).limit(1);
              
              List currentDataAwb = [];
              bool isUpdate = existingAwbList.isNotEmpty;
              if (isUpdate) {
                 var dbDataAwb = existingAwbList[0]['data-AWB'];
                 if (dbDataAwb != null && dbDataAwb is List) currentDataAwb = List.from(dbDataAwb);
              }

              final newAwbItem = {
                'refCarrier': fCarrier,
                'refNumber': fNumber,
                'refDate': fDate,
                'refULD': uld['uldNumber'],
                'pieces': awb['pieces'],
                'weight': awb['weight'],
                'remarks': awb['remarks'],
                'isBreak': uld['break'],
                'house_number': awb['house_number']
              };
              currentDataAwb.add(newAwbItem);

              if (isUpdate) {
                await supabase.from('AWB').update({'total': awb['total'], 'data-AWB': currentDataAwb}).eq('AWB number', awbNum);
              } else {
                await supabase.from('AWB').insert([{'AWB number': awbNum, 'total': awb['total'], 'data-AWB': currentDataAwb, 'created_at': DateTime.now().toIso8601String()}]);
              }
            }
          }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Toda la estructura guardada con éxito', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        if (widget.onPop != null) {
          widget.onPop!(true);
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInline) {
      return _buildFormContent();
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: const Text('Add New Flight Process'),
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
            child: Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Flight Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
        
        // Linear Wrap replicating flex-wrap: wrap
        LayoutBuilder(
          builder: (context, constraints) {
            double rWidth = constraints.maxWidth - 775;
            if (rWidth < 180) rWidth = 180;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 90, child: _buildTextField('Carrier', _carrierCtrl, 'AMERICAN', maxLen: 10, isUpperCase: true)),
                SizedBox(width: 80, child: _buildTextField('Number', _numberCtrl, '204', isNum: true, maxLen: 10)),
                SizedBox(width: 85, child: _buildTextField('Break', _breakCtrl, '', disabled: _isBreakAuto, isNum: true, digitsOnly: true, maxLen: 5, titleTrailing: SizedBox(
                  width: 20, height: 20,
                  child: Checkbox(
                    value: _isBreakAuto,
                    activeColor: const Color(0xFF6366f1),
                    side: const BorderSide(color: Color(0xFF94a3b8)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) {
                      setState(() {
                        _isBreakAuto = v ?? true;
                        _breakCtrl.text = _isBreakAuto ? 'Auto' : '';
                      });
                    }
                  )
                ))),
                SizedBox(width: 85, child: _buildTextField('No Break', _noBreakCtrl, '', disabled: _isNoBreakAuto, isNum: true, digitsOnly: true, maxLen: 5, titleTrailing: SizedBox(
                  width: 20, height: 20,
                  child: Checkbox(
                    value: _isNoBreakAuto,
                    activeColor: const Color(0xFF6366f1),
                    side: const BorderSide(color: Color(0xFF94a3b8)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) {
                      setState(() {
                        _isNoBreakAuto = v ?? true;
                        _noBreakCtrl.text = _isNoBreakAuto ? 'Auto' : '';
                      });
                    }
                  )
                ))),
                SizedBox(width: 130, child: _buildTextField('Date Arrived', _dateCtrl, '__/__/____', readOnly: true, onTap: _selectDate, suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white70))),
                SizedBox(width: 120, child: _buildTextField('Time Arrived', _timeCtrl, '__:__ --', readOnly: true, onTap: _selectTime, suffixIcon: const Icon(Icons.access_time_rounded, size: 16, color: Colors.white70))),
                SizedBox(width: rWidth, child: _buildTextField('Remarks', _remarksCtrl, 'Notas adicionales...')),
                SizedBox(width: 100, child: _buildDropdown('Status')),
              ]
            );
          }
        ),
        
        const SizedBox(height: 24),
        const Divider(color: Color(0xFF334155)),
        const SizedBox(height: 16),

        const Text('Add ULD To Flight', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        
        LayoutBuilder(
          builder: (context, constraints) {
            double uldRWidth = constraints.maxWidth - 644;
            if (uldRWidth < 200) uldRWidth = 200;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 130, child: _buildTextField('ULD Number', _uldNumberCtrl, 'AKE12345AA', maxLen: 10, isUpperCase: true)),
                SizedBox(width: 95, child: _buildTextField('Pieces', _uldPiecesCtrl, '0', isNum: true, digitsOnly: true, disabled: _isUldPiecesAuto, titleTrailing: SizedBox(
                  width: 20, height: 20,
                  child: Checkbox(
                    value: _isUldPiecesAuto,
                    activeColor: const Color(0xFF6366f1),
                    side: const BorderSide(color: Color(0xFF94a3b8)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) {
                      setState(() {
                        _isUldPiecesAuto = v ?? true;
                        _uldPiecesCtrl.text = _isUldPiecesAuto ? 'Auto' : '';
                      });
                    }
                  )
                ))),
                SizedBox(width: 95, child: _buildTextField('Weight', _uldWeightCtrl, '0.0', isNum: true, allowDecimal: true, disabled: _isUldWeightAuto, titleTrailing: SizedBox(
                  width: 20, height: 20,
                  child: Checkbox(
                    value: _isUldWeightAuto,
                    activeColor: const Color(0xFF6366f1),
                    side: const BorderSide(color: Color(0xFF94a3b8)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) {
                      setState(() {
                        _isUldWeightAuto = v ?? true;
                        _uldWeightCtrl.text = _isUldWeightAuto ? 'Auto' : '';
                      });
                    }
                  )
                ))),
                SizedBox(width: uldRWidth, child: _buildTextField('Remarks', _uldRemarksCtrl, 'Notas del ULD...')),
                SizedBox(
                  width: 65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        const Text('Priority?', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
                        Switch(value: _uldPriority, activeColor: const Color(0xFF6366f1), onChanged: (v) => setState(() => _uldPriority = v)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        const Text('Break?', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
                        Switch(value: _uldBreak, activeColor: const Color(0xFF6366f1), onChanged: (v) => setState(() => _uldBreak = v)),
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
        
        const SizedBox(height: 16),
        
        // Native table replica format for ULDs inside flight
        if (_flightLocalUlds.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5), 
              borderRadius: BorderRadius.circular(8), 
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Column(
              children: _flightLocalUlds.asMap().entries.map((entry) {
                int i = entry.key;
                var u = entry.value;
                List awbs = u['awbs'];
                return Column(
                  children: [
                    Container(
                      color: Colors.white.withAlpha(15),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(50), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 13)),
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
                                  child: Text('Pieces: ${u['pieces'] ?? 'Auto'}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12))
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 95,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                  decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(6)), 
                                  child: Text('Weight: ${u['weight'] ?? 'Auto'}', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12))
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
                              ElevatedButton.icon(
                                onPressed: () => _showAddAwbDialog(i),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add AWB', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10b981), // Emerald
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFef4444), size: 20),
                                tooltip: 'Eliminar ULD',
                                onPressed: () {
                                  setState(() {
                                    if (_flightLocalUlds[i]['break'] == true) {
                                      _cBreak = (_cBreak > 0) ? _cBreak - 1 : 0;
                                    } else {
                                      _cNoBreak = (_cNoBreak > 0) ? _cNoBreak - 1 : 0;
                                    }
                                    _flightLocalUlds.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    if (awbs.isNotEmpty)
                      Table(
                        border: TableBorder(horizontalInside: BorderSide(color: Colors.white.withAlpha(25))),
                        columnWidths: const {
                           0: IntrinsicColumnWidth(),
                           1: FlexColumnWidth(),
                           2: IntrinsicColumnWidth(),
                           3: IntrinsicColumnWidth(),
                        },
                        children: awbs.map((a) => TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.subdirectory_arrow_right, color: Colors.white.withAlpha(128), size: 16)),
                            Padding(padding: const EdgeInsets.all(8), child: Text(a['awb_number'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${a['pieces']} pcs', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${a['weight']} kg', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13))),
                          ]
                        )).toList(),
                      ),
                    const Divider(height: 1, color: Colors.transparent),
                  ],
                );
              }).toList(),
            ),
          ),
        
                ],
              ),
            ),
          ),
        ),
        // Bottom Pinned Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0f172a),
            border: Border(top: BorderSide(color: Colors.white.withAlpha(25))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (widget.onPop != null) {
                      widget.onPop!(false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF94a3b8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CANCELAR', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveEverything,
                  icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_rounded),
                  label: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('GUARDAR VUELO + ULDs + AWBs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {bool isNum = false, bool digitsOnly = false, bool allowDecimal = false, int? maxLen, bool disabled = false, Widget? suffixIcon, VoidCallback? onTap, bool readOnly = false, bool isUpperCase = false, Widget? titleTrailing, bool isAwb = false, int? maxLines = 1, int? minLines}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
             if (titleTrailing != null) titleTrailing,
           ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: !disabled,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: isNum ? (allowDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number) : TextInputType.text,
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
        ),
      ],
    );
  }

  Widget _buildDropdown(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _status,
              isExpanded: true,
              dropdownColor: const Color(0xFF1e293b),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFcbd5e1), size: 20),
              items: ['Waiting', 'Received', 'Pending', 'Checked', 'Ready', 'Canceled']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) { if (v != null) setState(() => _status = v); },
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
