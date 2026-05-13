import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show appLanguage;
import 'coordinator_v2_logic.dart';

class CoordinatorV2AddAwbDialog extends StatefulWidget {
  final CoordinatorV2Logic logic;
  final String flightId;
  final String uldId;
  final bool dark;

  const CoordinatorV2AddAwbDialog({
    super.key,
    required this.logic,
    required this.flightId,
    required this.uldId,
    required this.dark,
  });

  @override
  State<CoordinatorV2AddAwbDialog> createState() => _CoordinatorV2AddAwbDialogState();
}

class _CoordinatorV2AddAwbDialogState extends State<CoordinatorV2AddAwbDialog> {
  final _awbCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();

  final _awbFocus = FocusNode();
  final _piecesFocus = FocusNode();
  final _totalFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _remarksFocus = FocusNode();
  final _houseFocus = FocusNode();

  final ValueNotifier<bool> _totalLocked = ValueNotifier<bool>(false);
  final ValueNotifier<Map<String, String>> _awbErrors = ValueNotifier<Map<String, String>>({});
  final ValueNotifier<List<String>> _houseNumbers = ValueNotifier<List<String>>([]);
  final ValueNotifier<int> _dbExpected = ValueNotifier<int>(0);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _awbCtrl.addListener(_onAwbChanged);
    _piecesCtrl.addListener(_validatePieces);
    _totalCtrl.addListener(_validatePieces);
    _totalLocked.addListener(_validatePieces);
    _dbExpected.addListener(_validatePieces);
  }

  void _validatePieces() {
    final text = _awbCtrl.text.toUpperCase();
    Map<String, String> current = Map.from(_awbErrors.value);

    // Clear required errors if user starts typing
    if (text.isNotEmpty) {
      if (current['AWB Number'] == 'Required' || current['AWB Number'] == 'Incomplete') {
        current.remove('AWB Number');
        current.remove('header_awb');
      }
    }
    if (_piecesCtrl.text.trim().isNotEmpty && _piecesCtrl.text.trim() != '0') {
      if (current['Pieces'] == 'Required') current.remove('Pieces');
    }
    if (_totalCtrl.text.trim().isNotEmpty && _totalCtrl.text.trim() != '0') {
      if (current['Total'] == 'Required') current.remove('Total');
    }

    // Duplicate check
    if (text.length == 13) {
      final uldData = widget.logic.ulds.firstWhere((u) => u['id_uld'].toString() == widget.uldId, orElse: () => <String, dynamic>{});
      final List splits = uldData['awb_splits'] is List ? uldData['awb_splits'] : [];
      if (splits.any((s) => s['awbs']?['awb_number'] == text || s['awb_number'] == text)) {
         current['header_awb'] = appLanguage.value == 'es' ? 'Duplicado' : 'Duplicate';
      } else {
         current.remove('header_awb');
      }
    } else {
       // Only clear if the user deleted characters and we had 'Duplicate'. 
       // If it was 'Incomplete', we leave it alone or clear it if they erased everything
       if (current['header_awb'] == 'Duplicate' || current['header_awb'] == 'Duplicado') {
          current.remove('header_awb');
       }
       if (text.isEmpty) {
          current.remove('header_awb');
       }
    }

    if (text.length < 13) {
      current.remove('header_pieces');
      current.remove('header_pieces_info');
      _awbErrors.value = current;
      return;
    }

    final p = int.tryParse(_piecesCtrl.text) ?? 0;
    final t = int.tryParse(_totalCtrl.text) ?? 0;

    if (t == 0) {
      current.remove('header_pieces');
      current.remove('header_pieces_info');
      _awbErrors.value = current;
      return;
    }

    final dbExp = _dbExpected.value;
    final localUsed = widget.logic.getLocalUsedPieces(text);
    final totalAllowed = t - dbExp - localUsed;

    if (_totalLocked.value) {
       if (totalAllowed <= 0) {
          current['header_pieces'] = appLanguage.value == 'es' ? 'AWB Completado' : 'AWB Completed';
          current.remove('header_pieces_info');
       } else {
          current['header_pieces_info'] = appLanguage.value == 'es' ? 'Piezas restantes: $totalAllowed' : 'Pieces remaining: $totalAllowed';
          current.remove('header_pieces');
       }
    } else {
       current.remove('header_pieces_info');
       current.remove('header_pieces');
    }

    if (p > totalAllowed) {
       if (totalAllowed <= 0) {
          current['header_pieces'] = appLanguage.value == 'es' ? 'AWB Completado' : 'AWB Completed';
       } else {
          current['header_pieces'] = 'Máx: $totalAllowed';
       }
    }
    
    // Clear pieces_info if there's an error (like Máx or AWB Completed)
    if (current.containsKey('header_pieces')) {
       current.remove('header_pieces_info');
    }

    _awbErrors.value = current;
  }

  Future<void> _onAwbChanged() async {
    final text = _awbCtrl.text.toUpperCase();
    _validatePieces();

    if (text.length == 13) {
      final res = await widget.logic.fetchAwbTotalAsync(text);
      if (!mounted) return;
      if (res != null) {
        _totalLocked.value = true;
        
        final t = res['total_pieces'] ?? 0;
        _dbExpected.value = (res['total_espected'] as num?)?.toInt() ?? 0;
        
        if (_totalCtrl.text != t.toString()) {
          _totalCtrl.text = t.toString();
        }
      } else {
        _totalLocked.value = false;
        _dbExpected.value = 0;
        _totalCtrl.clear();
      }
      _validatePieces();
    } else {
      if (_totalLocked.value) {
        _totalLocked.value = false;
        _dbExpected.value = 0;
        _totalCtrl.clear();
      }
    }
  }

  @override
  void dispose() {
    _awbCtrl.removeListener(_onAwbChanged);
    _piecesCtrl.removeListener(_validatePieces);
    _totalCtrl.removeListener(_validatePieces);
    _totalLocked.removeListener(_validatePieces);
    _dbExpected.removeListener(_validatePieces);
    
    _awbCtrl.dispose();
    _piecesCtrl.dispose();
    _totalCtrl.dispose();
    _weightCtrl.dispose();
    _remarksCtrl.dispose();
    _houseCtrl.dispose();

    _awbFocus.dispose();
    _piecesFocus.dispose();
    _totalFocus.dispose();
    _weightFocus.dispose();
    _remarksFocus.dispose();
    _houseFocus.dispose();

    _totalLocked.dispose();
    _awbErrors.dispose();
    _houseNumbers.dispose();
    _dbExpected.dispose();
    super.dispose();
  }

  void _addHouseNumber(String text) {
    final val = text.trim().toUpperCase();
    if (val.isNotEmpty && !_houseNumbers.value.contains(val)) {
      _houseNumbers.value = [..._houseNumbers.value, val];
    }
    _houseCtrl.clear();
  }

  Future<void> _handleSave() async {
    _awbErrors.value = {};
    final newAwb = _awbCtrl.text.trim().toUpperCase();
    Map<String, String> currentErrors = {};

    if (newAwb.isEmpty) {
      currentErrors['AWB Number'] = 'Required';
    } else if (newAwb.length < 13) {
      currentErrors['AWB Number'] = 'Incomplete';
      currentErrors['header_awb'] = appLanguage.value == 'es' ? 'Incompleto' : 'Incomplete';
    }
    
    if (_piecesCtrl.text.trim().isEmpty || _piecesCtrl.text.trim() == '0') currentErrors['Pieces'] = 'Required';
    if (_totalCtrl.text.trim().isEmpty || _totalCtrl.text.trim() == '0') currentErrors['Total'] = 'Required';
    
    if (currentErrors.isNotEmpty) { 
      _awbErrors.value = currentErrors; 
      return; 
    }
    
    setState(() => _isLoading = true);

    int actualDbExpected = _dbExpected.value;
    if (newAwb.length == 13) {
      final res = await widget.logic.fetchAwbTotalAsync(newAwb);
      if (!mounted) return;
      if (res != null) {
        actualDbExpected = (res['total_espected'] as num?)?.toInt() ?? 0;
      }
    }

    final p = int.tryParse(_piecesCtrl.text) ?? 0;
    final t = int.tryParse(_totalCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0.0;
    
    final localUsed = widget.logic.getLocalUsedPieces(newAwb);
    final totalAllowed = t - actualDbExpected - localUsed;

    if (p > totalAllowed) {
      if (totalAllowed <= 0) {
        currentErrors['Pieces'] = 'No pieces remaining';
      } else {
        currentErrors['Pieces'] = 'Max $totalAllowed pieces';
      }
      _awbErrors.value = currentErrors;
      setState(() => _isLoading = false);
      return;
    }

    final uldData = widget.logic.ulds.firstWhere((u) => u['id_uld'].toString() == widget.uldId, orElse: () => <String, dynamic>{});
    final List splits = uldData['awb_splits'] is List ? uldData['awb_splits'] : [];
    if (splits.any((s) => s['awbs']?['awb_number'] == newAwb || s['awb_number'] == newAwb)) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 48), 
            const SizedBox(height: 16), 
            Text('Duplicate AWB', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          content: SizedBox(
            width: 260,
            height: 70,
            child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  Text('The AWB "$newAwb" is already registered under this ULD. Please verify or modify.', textAlign: TextAlign.center, style: TextStyle(color: widget.dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)))
               ]
            )
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c), 
              child: const Text('OK', style: TextStyle(color: Color(0xFF6366f1), fontSize: 16, fontWeight: FontWeight.bold))
            )
          ]
        )
      );
      return;
    }

    if (_houseCtrl.text.trim().isNotEmpty) {
      final val = _houseCtrl.text.trim().toUpperCase();
      if (!_houseNumbers.value.contains(val)) _houseNumbers.value = [..._houseNumbers.value, val];
    }
    
    final remarks = _remarksCtrl.text.trim();
    final houseNumbersList = _houseNumbers.value;

    try {
      // Send total piece (which overrides pieces if not exists)
      await widget.logic.addNewAwb(newAwb, p, t, w, widget.uldId, widget.flightId, remarks, houseNumbersList);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgModal = widget.dark ? const Color(0xFF0f172a) : Colors.white;
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgInput = widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);
    final borderCol = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgModal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ValueListenableBuilder<Map<String, String>>(
          valueListenable: _awbErrors,
          builder: (context, err, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB',
                        style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (err.containsKey('header_awb'))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                          child: Text(err['header_awb']!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      if (err.containsKey('header_pieces'))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                          child: Text(err['header_pieces']!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      if (err.containsKey('header_pieces_info'))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF22c55e).withAlpha(20), borderRadius: BorderRadius.circular(6)),
                          child: Text(err['header_pieces_info']!, style: const TextStyle(color: Color(0xFF22c55e), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.close, color: textS),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildField('AWB Number', _awbCtrl, bgInput, textP, textS, '123-1234 5678', err.containsKey('AWB Number'), err['AWB Number'], isAwb: true, focusNode: _awbFocus)),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _buildField('Pieces', _piecesCtrl, bgInput, textP, textS, '0', err.containsKey('Pieces'), err['Pieces'], isNum: true, focusNode: _piecesFocus)),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: ValueListenableBuilder<bool>(
                        valueListenable: _totalLocked,
                        builder: (ctx, locked, _) => _buildField('Total', _totalCtrl, bgInput, textP, textS, '0', err.containsKey('Total'), err['Total'], isNum: true, disabled: locked, focusNode: _totalFocus),
                      )),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _buildField('Weight', _weightCtrl, bgInput, textP, textS, '0.0', false, null, isNum: true, focusNode: _weightFocus)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(appLanguage.value == 'es' ? 'Comentarios (Remarks)' : 'Remarks', _remarksCtrl, bgInput, textP, textS, 'Additional remarks...', false, null, isRemarks: true, focusNode: _remarksFocus),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('House Number', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          ValueListenableBuilder<List<String>>(
                            valueListenable: _houseNumbers,
                            builder: (context, hwbs, _) {
                              if (hwbs.isEmpty) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366f1).withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(hwbs.length.toString(), style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                              );
                            }
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedBuilder(
                        animation: _houseFocus,
                        builder: (context, _) {
                          final hasFocus = _houseFocus.hasFocus;
                          return Container(
                            padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              color: bgInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: hasFocus ? const Color(0xFF6366f1) : borderCol, width: hasFocus ? 1.5 : 1.0),
                            ),
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey == LogicalKeyboardKey.enter) {
                                    _addHouseNumber(_houseCtrl.text);
                                  }
                                }
                              },
                              child: TextField(
                                controller: _houseCtrl,
                                focusNode: _houseFocus,
                                style: TextStyle(color: textP, fontSize: 14),
                                textInputAction: TextInputAction.done,
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    return TextEditingValue(
                                      text: newValue.text.toUpperCase(),
                                      selection: newValue.selection,
                                    );
                                  }),
                                ],
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'HAWB...',
                                  hintStyle: TextStyle(color: textS),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  suffixIcon: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add_circle, color: Color(0xFF6366f1), size: 26),
                                    onPressed: () => _addHouseNumber(_houseCtrl.text),
                                  ),
                                ),
                                onSubmitted: _addHouseNumber,
                              ),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<List<String>>(
                        valueListenable: _houseNumbers,
                        builder: (context, hwbs, _) {
                          if (hwbs.isEmpty) return const SizedBox.shrink();
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: hwbs.map((hwb) {
                              return InputChip(
                                label: Text(hwb, style: TextStyle(color: widget.dark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFF6366f1).withAlpha(40),
                                deleteIcon: Icon(Icons.close_rounded, size: 14, color: widget.dark ? Colors.white70 : Colors.black54),
                                onDeleted: () {
                                  _houseNumbers.value = _houseNumbers.value.where((e) => e != hwb).toList();
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFF6366f1))),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: TextStyle(color: textS)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, Color bg, Color text, Color hint, String hintText, bool hasError, String? errorText, {bool isNum = false, bool disabled = false, bool isAwb = false, bool isRemarks = false, FocusNode? focusNode}) {
    final isDark = bg.computeLuminance() < 0.5;

    return AnimatedBuilder(
      animation: focusNode ?? AlwaysStoppedAnimation(null),
      builder: (context, _) {
        final hasFocus = focusNode?.hasFocus ?? false;

        final borderColor = hasError 
            ? const Color(0xFFEF4444) 
            : (hasFocus ? const Color(0xFF6366f1) : (disabled ? (isDark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6)) : (isDark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))));

        final bgColor = hasError 
            ? const Color(0xFFEF4444).withAlpha(isDark ? 20 : 10)
            : (disabled ? (isDark ? Colors.black.withAlpha(40) : const Color(0xFFF9FAFB)) : bg);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: hasError ? const Color(0xFFEF4444) : hint, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: (hasError || hasFocus) ? 1.5 : 1.0),
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focusNode,
                enabled: !disabled,
                keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                inputFormatters: [
                  if (isNum) LengthLimitingTextInputFormatter(5),
                  if (isNum) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  if (isAwb) AwbTextInputFormatter(),
                  if (isRemarks)
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isNotEmpty) {
                        return TextEditingValue(
                          text: newValue.text[0].toUpperCase() + newValue.text.substring(1),
                          selection: newValue.selection,
                        );
                      }
                      return newValue;
                    }),
                ],
                textCapitalization: label.contains('AWB') ? TextCapitalization.characters : (isRemarks ? TextCapitalization.sentences : TextCapitalization.none),
                style: TextStyle(color: disabled ? hint : text, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: TextStyle(color: hint.withAlpha(100), fontSize: 14),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );
      }
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
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
