import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;
import 'flights_v2_inline_add_awb_form.dart';

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
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final bgC = widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
            suffix ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: ctrl,
            keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            textCapitalization: textCapitalization,
            inputFormatters: [
              if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
              if (formatters != null) ...formatters,
            ],
            style: TextStyle(color: disabled ? (widget.dark ? Colors.white54 : Colors.black54) : textP, fontWeight: FontWeight.w500, fontSize: 13),
            enabled: !disabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: disabled ? (widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFE5E7EB)) : bgC,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    final carrier = widget.flight['carrier'] ?? '';
    final number = widget.flight['number'] ?? '';

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
                      Text(appLanguage.value == 'es' ? 'Manifiesto del ULD' : 'ULD Manifest', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('$carrier $number', style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // ULD Info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: borderC))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_rounded, size: 18, color: textP),
                  const SizedBox(width: 8),
                  Text('ULD Details', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 122,
                    child: _buildTextField(
                      'ULD Number',
                      _uldNumberCtrl,
                      maxLength: 10,
                      textCapitalization: TextCapitalization.characters,
                      formatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 75,
                    child: _buildTextField(
                      'Pieces',
                      _piecesCtrl,
                      isNum: true,
                      disabled: _autoPieces,
                      maxLength: 5,
                      suffix: SizedBox(
                        width: 14,
                        height: 14,
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
                          checkColor: Colors.white,
                          side: BorderSide(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          splashRadius: 0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 75,
                    child: _buildTextField(
                      'Weight',
                      _weightCtrl,
                      isNum: true,
                      disabled: _autoWeight,
                      maxLength: 5,
                      suffix: SizedBox(
                        width: 14,
                        height: 14,
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
                          checkColor: Colors.white,
                          side: BorderSide(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          splashRadius: 0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 95,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Priority?', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: widget.dark ? Colors.white.withAlpha(13) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.star_rounded, color: textS, size: 16),
                              Switch(
                                value: _isPriority,
                                onChanged: (v) => setState(() => _isPriority = v),
                                activeTrackColor: const Color(0xFFf59e0b),
                                activeThumbColor: Colors.white,
                                inactiveThumbColor: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF),
                                inactiveTrackColor: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 95,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Break?', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: widget.dark ? Colors.white.withAlpha(13) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.broken_image_rounded, color: textS, size: 16),
                              Switch(
                                value: _isBreak,
                                onChanged: (v) => setState(() => _isBreak = v),
                                activeTrackColor: const Color(0xFF22c55e),
                                activeThumbColor: Colors.white,
                                inactiveThumbColor: widget.dark ? const Color(0xFFbdc3c7) : const Color(0xFF9CA3AF),
                                inactiveTrackColor: widget.dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.transparent;
                                  }
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
                    width: double.infinity,
                    child: _buildTextField(
                      'Remarks',
                      _remarksCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      formatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) {
                            if (newValue.text.isEmpty) return newValue;
                            final text = newValue.text;
                            final formatted = text[0].toUpperCase() + text.substring(1).toLowerCase();
                            return TextEditingValue(
                              text: formatted,
                              selection: newValue.selection,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // AWBs List
        Expanded(
          child: Container(
            color: widget.dark ? const Color(0xFF1e293b).withAlpha(50) : const Color(0xFFF9FAFB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Expanded(
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
                      final isExpanded = split['isExpanded'] == true;
                      
                      return GestureDetector(
                        onTap: () {
                          if (houseList.isNotEmpty || (split['remarks']?.toString().trim().isNotEmpty == true && split['remarks']?.toString().trim().toLowerCase() != 'null')) {
                            setState(() {
                              split['isExpanded'] = !isExpanded;
                            });
                          }
                        },
                        child: Container(
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
                                            width: 28, height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(color: const Color(0xFF3b82f6).withAlpha(30), shape: BoxShape.circle),
                                            child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF60a5fa), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3,
                                            child: Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                          ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('$splitPieces/$masterPieces pcs', style: TextStyle(color: textS, fontSize: 13)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('$splitWeight kg', style: TextStyle(color: textS, fontSize: 13)),
                                    ),
                                    Icon(
                                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: textS.withAlpha(150),
                                      size: 20,
                                    ),
                                    if (!_isFlightLocked) ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _awbs.removeAt(index);
                                            _recalcularTotales();
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                if (isExpanded) ...[
                                  const SizedBox(height: 12),
                                  
                                  // Bottom Row: House and Remarks
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // House Numbers
                                      if (houseList.isNotEmpty)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.home_work_outlined, size: 14, color: textP),
                                                  const SizedBox(width: 6),
                                                  Text('House Num:', style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                                                ]
                                              ),
                                              const SizedBox(height: 6),
                                              ...houseList.map((h) => 
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 4, left: 6),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets.only(top: 5, right: 6),
                                                        width: 4, height: 4,
                                                        decoration: BoxDecoration(color: textS, shape: BoxShape.circle),
                                                      ),
                                                      Expanded(child: Text(h.trim(), style: TextStyle(color: textS, fontSize: 12))),
                                                    ],
                                                  ),
                                                )
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (houseList.isNotEmpty && (split['remarks']?.toString().trim().isNotEmpty == true && split['remarks']?.toString().trim().toLowerCase() != 'null'))
                                        const SizedBox(width: 16),
                                      // Remarks
                                      if (split['remarks']?.toString().trim().isNotEmpty == true && split['remarks']?.toString().trim().toLowerCase() != 'null')
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.notes_rounded, size: 14, color: textP),
                                                  const SizedBox(width: 6),
                                                  Text('Remarks:', style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                                                ]
                                              ),
                                              const SizedBox(height: 6),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 6),
                                                child: Text(
                                                  split['remarks'].toString(), 
                                                  style: TextStyle(color: textS, fontSize: 12)
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                                  ], // End Column children
                                ), // End Column
                              ), // End Padding
                            ], // End Stack children
                          ), // End Stack
                        ), // End Container
                      ); // End GestureDetector
                    },
                  ),
                ), // Close Expanded for list
              ], // Close Column children
            ), // Close Column
          ), // Close Container
        ), // Close outer Expanded

        if (!_isFlightLocked)
          FlightsV2InlineAddAwbForm(
            dark: widget.dark,
            appLanguage: appLanguage,
            textP: textP,
            textS: textS,
            borderC: borderC,
            existingAwbs: _awbs,
            uldNumber: _uldNumberCtrl.text.trim().isNotEmpty ? _uldNumberCtrl.text.trim().toUpperCase() : 'ULD',
            onAdd: (newAwb) {
              setState(() {
                _awbs.add(newAwb);
                _recalcularTotales();
              });
            },
          ),
          
        // Action Buttons at the bottom
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(top: BorderSide(color: borderC)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: TextStyle(color: textS, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _handleSave,
                icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, size: 16),
                label: Text(appLanguage.value == 'es' ? 'Guardar' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ], // Close main Column children
    );
  }
}
