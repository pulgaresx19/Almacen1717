import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show appLanguage;
import 'flight_details_v2_add_awb_dialog.dart';
import 'flight_details_v2_formatters.dart';

Future<bool?> showAddUldComponent(
  BuildContext context,
  Map<String, dynamic> flight,
  bool dark,
  List<dynamic> existingUlds, [
  Map<String, dynamic>? uld,
]) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withAlpha(150),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: _AddUldComponentInternal(
            flight: flight,
            dark: dark,
            existingUlds: existingUlds,
            uld: uld,
          ),
        ),
      );
    },
    transitionBuilder: (context, a1, a2, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(a1.value),
        child: FadeTransition(opacity: a1, child: child),
      );
    },
  );
  
  if (result == true && context.mounted) {
    await _showSaveSuccessDialog(context, dark);
  }
  
  return result;
}

Future<void> _showSaveSuccessDialog(BuildContext context, bool dark) async {
  bool dialogOpen = true;
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withAlpha(100),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1e293b) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF10b981).withAlpha(40), blurRadius: 40, offset: const Offset(0, 10))],
              border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(20), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48)),
                const SizedBox(height: 24),
                Text(appLanguage.value == 'es' ? '¡Actualizado!' : 'Updated!', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(appLanguage.value == 'es' ? 'La información se guardó correctamente.' : 'Information saved successfully.', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (c, a1, a2, child) => Transform.scale(scale: Curves.easeOutBack.transform(a1.value), child: FadeTransition(opacity: a1, child: child)),
  ).then((_) => dialogOpen = false);

  await Future.delayed(const Duration(milliseconds: 1500));
  
  if (context.mounted && dialogOpen) {
    Navigator.of(context).pop();
  }
}

class _AddUldComponentInternal extends StatefulWidget {
  final Map<String, dynamic> flight;
  final bool dark;
  final List<dynamic> existingUlds;
  final Map<String, dynamic>? uld;

  const _AddUldComponentInternal({
    required this.flight,
    required this.dark,
    required this.existingUlds,
    this.uld,
  });

  @override
  State<_AddUldComponentInternal> createState() => _AddUldComponentInternalState();
}

class _AddUldComponentInternalState extends State<_AddUldComponentInternal> {
  final _uldNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  bool _isPriority = false;
  bool _isBreak = true;
  bool _autoPieces = true;
  bool _autoWeight = true;

  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _awbs = [];

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

  @override
  void initState() {
    super.initState();
    if (widget.uld != null) {
      final u = widget.uld!;
      _uldNumberCtrl.text = u['uld_number']?.toString() ?? '';
      _piecesCtrl.text = (u['pieces_total']?.toString() ?? u['pieces']?.toString() ?? '');
      _weightCtrl.text = (u['weight_total']?.toString() ?? u['weight']?.toString() ?? '');
      _remarksCtrl.text = (u['remarks']?.toString().toLowerCase() == 'null' ? '' : u['remarks']?.toString() ?? '');

      _isPriority = u['is_priority'] == true;
      _isBreak = u['is_break'] == true;
      _autoPieces = true;
      _autoWeight = true;

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
    }
    _recalcularTotales();
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
            Text(label, style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
            ?suffix,
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: disabled ? (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3)) : bgC,
            borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(color: disabled ? textS : textP, fontWeight: FontWeight.w500, fontSize: 14),
            enabled: !disabled,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);
    final bgCard = widget.dark ? const Color(0xFF0f172a) : Colors.white;
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    final carrier = widget.flight['carrier'] ?? '';
    final number = widget.flight['number'] ?? '';

    return Container(
      width: 650,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderC, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.uld != null
                          ? (appLanguage.value == 'es'
                              ? 'Editar ${_uldNumberCtrl.text.isNotEmpty ? _uldNumberCtrl.text : 'ULD'}'
                              : 'Edit ${_uldNumberCtrl.text.isNotEmpty ? _uldNumberCtrl.text : 'ULD'}')
                          : (appLanguage.value == 'es' ? 'Añadir ULD al Vuelo' : 'Add ULD to Flight'),
                      style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('$carrier $number', style: TextStyle(color: textP, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textS),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          'ULD Number',
                          _uldNumberCtrl,
                          maxLength: 10,
                          textCapitalization: TextCapitalization.characters,
                          formatters: [UpperCaseTextFormatter()],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          'Pieces',
                          _piecesCtrl,
                          isNum: true,
                          disabled: _autoPieces,
                          maxLength: 6,
                          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                          suffix: SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _autoPieces,
                              activeColor: const Color(0xFF6366f1),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) => setState(() {
                                _autoPieces = v ?? true;
                                if (_autoPieces) _recalcularTotales();
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          'Weight',
                          _weightCtrl,
                          isNum: true,
                          disabled: _autoWeight,
                          maxLength: 6,
                          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          suffix: SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _autoWeight,
                              activeColor: const Color(0xFF6366f1),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) => setState(() {
                                _autoWeight = v ?? true;
                                if (_autoWeight) _recalcularTotales();
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Priority', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star_rounded, color: textS, size: 18),
                                  const Spacer(),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: _isPriority,
                                      onChanged: (v) => setState(() => _isPriority = v),
                                      activeTrackColor: const Color(0xFFf59e0b),
                                      activeThumbColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Break', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.broken_image_rounded, color: textS, size: 18),
                                  const Spacer(),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: _isBreak,
                                      onChanged: (v) => setState(() => _isBreak = v),
                                      activeTrackColor: const Color(0xFF22c55e),
                                      activeThumbColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Remarks',
                    _remarksCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    formatters: [SentenceCaseTextFormatter()],
                  ),
                  const SizedBox(height: 16),

                  // AWBs Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, color: textP, size: 20),
                          const SizedBox(width: 8),
                          Text('AWBs', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366f1).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_awbs.length}',
                              style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6),
                          foregroundColor: textP,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderC),
                          ),
                        ),
                        onPressed: _handleShowAddAwbDialog,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_awbs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderC, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_add, color: textS.withAlpha(100), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            appLanguage.value == 'es' ? 'No hay AWBs añadidos.' : 'No AWBs added yet.',
                            style: TextStyle(color: textS),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _awbs.asMap().entries.map((e) {
                        final i = e.key;
                        final a = e.value;

                        List<String> houses = [];
                        final hRaw = a['house']?.toString() ?? '';
                        if (hRaw.isNotEmpty) {
                          houses = hRaw.split(RegExp(r'[,\n]')).map((str) => str.trim()).where((str) => str.isNotEmpty).toList();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderC),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366f1).withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          a['awb_number'] ?? '',
                                          style: TextStyle(color: textP, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 16),
                                        Text('${a['pieces']} / ${a['total']?.toString().isEmpty ?? true ? '-' : a['total']} pcs', style: TextStyle(color: textS, fontSize: 13)),
                                        const SizedBox(width: 16),
                                        Text('${a['weight']?.toString().isEmpty ?? true ? '-' : a['weight']} kg', style: TextStyle(color: textS, fontSize: 13)),
                                        
                                        if (a['remarks'] != null && a['remarks'].toString().isNotEmpty) ...[
                                          const SizedBox(width: 16),
                                          Icon(Icons.notes_rounded, size: 14, color: textS.withAlpha(150)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              a['remarks'],
                                              style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ] else
                                          const Spacer(),

                                        if (houses.isNotEmpty) ...[
                                          const SizedBox(width: 16),
                                          InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                                                  title: Text(appLanguage.value == 'es' ? 'House Numbers' : 'House Numbers', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                                  content: SizedBox(
                                                    width: 300,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: houses.asMap().entries.map((eh) {
                                                        final hi = eh.key;
                                                        final h = eh.value;
                                                        return Padding(
                                                          padding: const EdgeInsets.only(bottom: 8.0),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 24,
                                                                height: 24,
                                                                alignment: Alignment.center,
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFF3b82f6).withAlpha(30),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: Text(
                                                                  '${hi + 1}',
                                                                  style: const TextStyle(color: Color(0xFF60a5fa), fontSize: 11, fontWeight: FontWeight.bold),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Text(h, style: TextStyle(color: textS, fontSize: 14)),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3b82f6).withAlpha(30),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.house_siding_rounded, size: 12, color: Color(0xFF60a5fa)),
                                                  const SizedBox(width: 4),
                                                  Text('${houses.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF60a5fa), fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _awbs.removeAt(i);
                                        _recalcularTotales();
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: borderC))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                    style: const TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF6366f1).withAlpha(150),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : () async {
                    final currentUld = _uldNumberCtrl.text.trim().toUpperCase();
                    if (currentUld.isEmpty) return;

                    setState(() => _isSubmitting = true);

                    final exists = widget.existingUlds.any(
                      (u) =>
                          u['uld_number'] == currentUld &&
                          (widget.uld == null || u['id_uld'] != widget.uld!['id_uld']),
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

                      String? uldId;

                      if (widget.uld != null) {
                        uldId = widget.uld!['id_uld']?.toString();
                        if (uldId != null) {
                          await supa.from('ulds').update(uldData).eq('id_uld', uldId);
                        }
                      } else {
                        final res = await supa.from('ulds').insert(uldData).select('id_uld').single();
                        uldId = res['id_uld']?.toString();
                      }

                      // Calculate AWBs to remove and add
                      final List<Map<String, dynamic>> itemsToRemove = [];
                      final List<Map<String, dynamic>> itemsToAdd = [];

                      if (widget.uld != null && widget.uld!['awb_splits'] != null) {
                        final initialSplits = widget.uld!['awb_splits'] as List;
                        for (var initialSplit in initialSplits) {
                          if (initialSplit is! Map) continue;
                          final splitId = initialSplit['id']?.toString();
                          if (splitId == null) continue;
                          
                          // Check if it still exists in _awbs
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
                            'awb_id': a['awb_id'], // Might be empty if brand new
                          });
                        }
                      }

                      await supa.rpc('update_uld_awbs_v2', params: {
                        'p_uld_id': uldId,
                        'p_flight_id': widget.flight['id_flight'],
                        'p_awbs_to_add': itemsToAdd,
                        'p_awbs_to_remove': itemsToRemove,
                      });

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              widget.uld != null
                                  ? (appLanguage.value == 'es' ? 'Editar ULD' : 'Edit ULD')
                                  : (appLanguage.value == 'es' ? 'Crear ULD' : 'Create ULD'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
