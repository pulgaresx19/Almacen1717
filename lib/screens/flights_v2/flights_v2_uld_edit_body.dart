import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;
import '../flight_details_v2/flight_details_v2_add_awb_dialog.dart';

class FlightsV2UldEditBody extends StatefulWidget {
  final Map<String, dynamic> uld;
  final Map<String, dynamic> flight;
  final bool dark;
  final List<dynamic> ulds;
  final VoidCallback onCancel;
  final VoidCallback onSaveSuccess;

  const FlightsV2UldEditBody({
    super.key,
    required this.uld,
    required this.flight,
    required this.dark,
    required this.ulds,
    required this.onCancel,
    required this.onSaveSuccess,
  });

  @override
  State<FlightsV2UldEditBody> createState() => _FlightsV2UldEditBodyState();
}

class _FlightsV2UldEditBodyState extends State<FlightsV2UldEditBody> {
  final _uldNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  bool _isPriority = false;
  bool _isBreak = false;
  bool _autoPieces = true;
  bool _autoWeight = true;
  
  bool _isSubmitting = false;
  bool _hasAttemptedSave = false;
  
  List<Map<String, dynamic>> _awbs = [];

  bool get _isFlightLocked {
    return (widget.flight['is_ready'] == true) || 
           (widget.flight['is_checked'] == true) || 
           (widget.flight['start_break'] != null && widget.flight['start_break'].toString().trim().isNotEmpty && widget.flight['start_break'].toString() != 'null');
  }

  void _showHouseList(BuildContext context, String awb, List<String> houses) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          title: Text('House Numbers - $awb', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 16)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
            child: SizedBox(
              width: 350,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: houses.length,
                itemBuilder: (c, i) => ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                    child: Text('${i + 1}', style: TextStyle(fontSize: 10, color: widget.dark ? Colors.white : Colors.black)),
                  ),
                  title: Text(houses[i], style: TextStyle(color: widget.dark ? Colors.white : Colors.black)),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: TextStyle(color: widget.dark ? Colors.white70 : Colors.black87)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initEditState();
  }

  void _initEditState() {
    final u = widget.uld;
    _uldNumberCtrl.text = u['uld_number']?.toString() ?? '';
    _piecesCtrl.text = (u['pieces_total']?.toString() ?? u['pieces']?.toString() ?? '');
    _weightCtrl.text = (u['weight_total']?.toString() ?? u['weight']?.toString() ?? '');
    _remarksCtrl.text = (u['remarks']?.toString().toLowerCase() == 'null' ? '' : u['remarks']?.toString() ?? '');

    _isPriority = u['is_priority'] == true;
    _isBreak = u['is_break'] == true;
    _autoPieces = true;
    _autoWeight = true;

    _awbs = [];
    if (u['awb_splits'] != null) {
      final List splits = u['awb_splits'];
      for (var rawSplit in splits) {
        if (rawSplit is! Map) continue;
        final split = Map<String, dynamic>.from(rawSplit);
        final masterRaw = split['awbs'];
        final master = masterRaw is Map ? Map<String, dynamic>.from(masterRaw) : <String, dynamic>{};
        final combined = <String, dynamic>{...master, ...split};
        _awbs.add({
          'awb_number': master['awb_number']?.toString() ?? '',
          'pieces': split['pieces']?.toString() ?? split['pieces_split']?.toString() ?? '',
          'total': master['total_pieces']?.toString() ?? master['pieces']?.toString() ?? '',
          'weight': split['weight']?.toString() ?? split['weight_split']?.toString() ?? '',
          'house': combined['house_number'] is List
              ? (combined['house_number'] as List).join(', ')
              : combined['house_number']?.toString() ?? '',
          'remarks': combined['remarks']?.toString() ?? '',
          'awb_id': master['id']?.toString() ?? '',
          'split_id': split['id']?.toString() ?? '',
        });
      }
    }
    _recalcularTotales();
  }

  void _recalcularTotales() {
    if (!mounted) return;
    if (_autoPieces) {
      int totalPieces = 0;
      for (var a in _awbs) {
        totalPieces += int.tryParse(a['pieces']?.toString() ?? '0') ?? 0;
      }
      _piecesCtrl.text = totalPieces.toString();
    }
    if (_autoWeight) {
      double totalWeight = 0.0;
      for (var a in _awbs) {
        totalWeight += double.tryParse(a['weight']?.toString() ?? '0') ?? 0.0;
      }
      String formatted = totalWeight.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
      if (formatted.endsWith('.')) formatted = formatted.substring(0, formatted.length - 1);
      _weightCtrl.text = formatted;
    }
  }

  Future<void> _handleShowAddAwbDialog() async {
    final String currentUld = _uldNumberCtrl.text.trim().isNotEmpty ? _uldNumberCtrl.text.trim().toUpperCase() : 'ULD';
    final newAwb = await showAddAwbDialog(context, widget.dark, _awbs, currentUld);
    if (newAwb != null) {
      setState(() {
        _awbs.add(newAwb);
        _recalcularTotales();
      });
    }
  }

  Future<void> _handleSave() async {
    final currentUld = _uldNumberCtrl.text.trim().toUpperCase();
    if (currentUld.isEmpty) return;

    if (_awbs.isEmpty) {
      setState(() => _hasAttemptedSave = true);
      return;
    }

    setState(() => _isSubmitting = true);

    final exists = widget.ulds.any(
      (u) =>
          u['uld_number'] == currentUld &&
          u['id_uld'] != widget.uld['id_uld'],
    );

    if (exists) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLanguage.value == 'es'
                ? 'No se puede guardar: El ULD $currentUld ya existe en este vuelo.'
                : 'Cannot save: ULD $currentUld already exists in this flight.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final supa = Supabase.instance.client;
      final uldData = {
        'id_flight': widget.flight['id_flight'],
        'uld_number': currentUld,
        'pieces_total': int.tryParse(_piecesCtrl.text) ?? 0,
        'weight_total': double.tryParse(_weightCtrl.text) ?? 0.0,
        'is_priority': _isPriority,
        'is_break': _isBreak,
        'remarks': _remarksCtrl.text,
      };

      final uldId = widget.uld['id_uld']?.toString();
      if (uldId != null) {
        await supa.from('ulds').update(uldData).eq('id_uld', uldId);
      }

      final List<Map<String, dynamic>> itemsToRemove = [];
      final List<Map<String, dynamic>> itemsToAdd = [];

      if (!_isFlightLocked) {
        if (widget.uld['awb_splits'] != null) {
          final initialSplits = widget.uld['awb_splits'] as List;
          for (var initialSplit in initialSplits) {
            if (initialSplit is! Map) continue;
            final splitId = initialSplit['id']?.toString();
            if (splitId == null) continue;
            
            final stillExists = _awbs.any((a) => a['split_id'] == splitId);
            if (!stillExists) {
              itemsToRemove.add({
                'split_id': splitId,
                'awb_id': initialSplit['awb_id']?.toString(),
              });
            }
          }
        }

        for (var a in _awbs) {
          if (a['split_id'] == null || a['split_id'].toString().isEmpty) {
            itemsToAdd.add({
              'awb_number': a['awb_number'],
              'pieces': int.tryParse(a['pieces'].toString()) ?? 0,
              'total_pieces': int.tryParse(a['total'].toString()) ?? int.tryParse(a['pieces'].toString()) ?? 0,
              'weight': double.tryParse(a['weight'].toString()) ?? 0.0,
              'house_number': (a['house']?.toString() ?? '').split(RegExp(r'[,\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              'remarks': a['remarks'] ?? '',
              'awb_id': a['awb_id'],
            });
          }
        }

        await supa.rpc('update_uld_awbs_v2', params: {
          'p_uld_id': uldId,
          'p_flight_id': widget.flight['id_flight'],
          'p_awbs_to_add': itemsToAdd,
          'p_awbs_to_remove': itemsToRemove,
        });
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onSaveSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    bool isNum = false,
    bool disabled = false,
    Widget? suffix,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final bgC = widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
            ?suffix,
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: disabled ? (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3)) : bgC,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderC),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            textCapitalization: textCapitalization,
            inputFormatters: [
              if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
              if (formatters != null) ...formatters,
            ],
            style: TextStyle(color: disabled ? textS : textP, fontWeight: FontWeight.w500, fontSize: 13),
            enabled: !disabled,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, Color textP, Color textS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textS),
                    onPressed: widget.onCancel,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ULD Details', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 150,
                        height: 30,
                        child: TextField(
                          controller: _uldNumberCtrl,
                          style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderC)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderC)),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6)), borderSide: BorderSide(color: Color(0xFF6366f1))),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: TextStyle(color: textS, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _handleSave,
                    icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, size: 16),
                    label: Text(appLanguage.value == 'es' ? 'Guardar' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // ULD Info
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Pieces',
                      _piecesCtrl,
                      isNum: true,
                      disabled: _autoPieces,
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Auto', style: TextStyle(color: textS, fontSize: 10)),
                          const SizedBox(width: 2),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _autoPieces,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _autoPieces = v;
                                    _recalcularTotales();
                                  });
                                }
                              },
                              activeColor: const Color(0xFF6366f1),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Weight',
                      _weightCtrl,
                      isNum: true,
                      disabled: _autoWeight,
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Auto', style: TextStyle(color: textS, fontSize: 10)),
                          const SizedBox(width: 2),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _autoWeight,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _autoWeight = v;
                                    _recalcularTotales();
                                  });
                                }
                              },
                              activeColor: const Color(0xFF6366f1),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Remarks', _remarksCtrl),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _isPriority = !_isPriority),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isPriority ? const Color(0xFFeab308).withAlpha(20) : (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isPriority ? const Color(0xFFeab308).withAlpha(50) : borderC),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPriority ? Icons.star_rounded : Icons.star_border_rounded,
                            color: _isPriority ? const Color(0xFFeab308) : textS,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text('Priority', style: TextStyle(color: _isPriority ? const Color(0xFFeab308) : textS, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => setState(() => _isBreak = !_isBreak),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isBreak ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isBreak ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isBreak ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: _isBreak ? Colors.green : Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text('Break', style: TextStyle(color: _isBreak ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

        // AWBs List Header
        Container(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appLanguage.value == 'es' ? 'AWBs Asociados' : 'Associated AWBs', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                  foregroundColor: _isFlightLocked ? textS : textP,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _isFlightLocked ? borderC.withAlpha(128) : borderC)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _isFlightLocked ? null : _handleShowAddAwbDialog,
                icon: Icon(_isFlightLocked ? Icons.lock_outline_rounded : Icons.add_rounded, size: 14),
                label: Text(appLanguage.value == 'es' ? (_isFlightLocked ? 'Bloqueado' : 'Añadir') : (_isFlightLocked ? 'Locked' : 'Add'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),

        if (_awbs.isEmpty && _hasAttemptedSave)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withAlpha(50))),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(appLanguage.value == 'es' ? 'Debe añadir al menos un AWB.' : 'You must add at least one AWB.', style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                ],
              ),
            ),
          ),

        // AWBs List
        Expanded(
          child: Container(
            color: widget.dark ? const Color(0xFF1e293b).withAlpha(50) : const Color(0xFFF9FAFB),
            child: _awbs.isEmpty
                ? Center(child: Text(appLanguage.value == 'es' ? 'No hay AWBs.' : 'No AWBs.', style: TextStyle(color: textS)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: _awbs.length,
                    itemBuilder: (context, index) {
                      final split = _awbs[index];
                      final awbNumber = split['awb_number']?.toString() ?? '';
                      final splitPieces = split['pieces']?.toString() ?? '0';
                      final masterPieces = split['total']?.toString() ?? '0';
                      final splitWeight = split['weight']?.toString() ?? '0';
                      
                      List<String> houseList = [];
                      if (split['house']?.toString().trim().isNotEmpty == true) {
                        houseList = split['house'].toString().split(RegExp(r'[,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Linear Row
                                  Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: widget.dark ? const Color(0xFFf472b6).withAlpha(30) : const Color(0xFFdb2777).withAlpha(20),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: widget.dark ? const Color(0xFFf472b6).withAlpha(80) : const Color(0xFFdb2777).withAlpha(60)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('${index + 1}', style: TextStyle(color: widget.dark ? const Color(0xFFf472b6) : const Color(0xFFdb2777), fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('P: $splitPieces/$masterPieces', style: TextStyle(color: textS, fontSize: 12)),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('W: ${splitWeight}kg', style: TextStyle(color: textS, fontSize: 12)),
                                      ),
                                      if (!_isFlightLocked) const SizedBox(width: 32), // Space for delete button
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Bottom Row: House and Remarks
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // House Numbers
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('House Numbers', style: TextStyle(color: textS, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            if (houseList.isEmpty)
                                              Text('-', style: TextStyle(color: textP, fontSize: 13))
                                            else
                                              InkWell(
                                                onTap: () => _showHouseList(context, awbNumber, houseList),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF6366f1).withAlpha(20),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFF6366f1).withAlpha(50)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.list_alt_rounded, size: 12, color: Color(0xFF818cf8)),
                                                      const SizedBox(width: 6),
                                                      Text('${houseList.length} items', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Remarks
                                      Expanded(
                                        child: _buildMetric(
                                          'Remarks',
                                          (split['remarks']?.toString().trim().isNotEmpty == true && split['remarks']?.toString().trim().toLowerCase() != 'null')
                                              ? split['remarks'].toString()
                                              : '-',
                                          textP,
                                          textS,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!_isFlightLocked)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _awbs.removeAt(index);
                                      _recalcularTotales();
                                    });
                                  },
                                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: widget.dark ? Colors.redAccent.withAlpha(40) : Colors.redAccent.withAlpha(20),
                                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.delete_outline_rounded, color: widget.dark ? const Color(0xFFfca5a5) : Colors.red, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
