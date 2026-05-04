import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show appLanguage;
import 'flight_details_v2_formatters.dart';

Future<Map<String, dynamic>?> showAddAwbDialog(
    BuildContext context, 
    bool dark, 
    List<Map<String, dynamic>> existingAwbs, 
    String uldNumber, [
    List<Map<String, dynamic>>? globalAwbs,
    List<Map<String, dynamic>>? globalUlds,
]) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) {
      return _AddAwbDialogComponent(
        dark: dark, 
        existingAwbs: existingAwbs, 
        uldNumber: uldNumber,
        globalAwbs: globalAwbs ?? [],
        globalUlds: globalUlds ?? [],
      );
    },
  );
}

class _AddAwbDialogComponent extends StatefulWidget {
  final bool dark;
  final List<Map<String, dynamic>> existingAwbs;
  final String uldNumber;
  final List<Map<String, dynamic>> globalAwbs;
  final List<Map<String, dynamic>> globalUlds;

  const _AddAwbDialogComponent({
    required this.dark, 
    required this.existingAwbs, 
    required this.uldNumber,
    required this.globalAwbs,
    required this.globalUlds,
  });

  @override
  State<_AddAwbDialogComponent> createState() => _AddAwbDialogComponentState();
}

class _AddAwbDialogComponentState extends State<_AddAwbDialogComponent> {
  final awbNumCtrl = TextEditingController();
  final awbPiecesCtrl = TextEditingController();
  final awbTotalCtrl = TextEditingController();
  final awbWeightCtrl = TextEditingController();
  final awbHouseCtrl = TextEditingController();
  final awbRemCtrl = TextEditingController();

  int? dbTotalPieces;
  int? dbTotalExpected;
  int localPiecesSum = 0;
  bool isTotalLocked = false;
  String? piecesError;
  String? awbExistsError;
  int houseCount = 0;
  
  bool awbRequiredError = false;
  bool piecesRequiredError = false;
  bool totalRequiredError = false;

  @override
  void initState() {
    super.initState();
    awbNumCtrl.addListener(_onAwbNumChanged);
    awbPiecesCtrl.addListener(_validatePieces);
    awbHouseCtrl.addListener(_onHouseChanged);
    awbTotalCtrl.addListener(_onTotalChanged);
  }

  void _onTotalChanged() {
    if (totalRequiredError && awbTotalCtrl.text.isNotEmpty && mounted) {
      setState(() => totalRequiredError = false);
    }
    _validatePieces();
  }

  void _onHouseChanged() {
    final text = awbHouseCtrl.text;
    final lines = text.split('\n').where((e) => e.trim().isNotEmpty).toList();
    if (mounted && houseCount != lines.length) {
      setState(() {
        houseCount = lines.length;
      });
    }
  }

  void _validatePieces() {
    setState(() {
      if (piecesRequiredError && awbPiecesCtrl.text.isNotEmpty) {
        piecesRequiredError = false;
      }
      
      final entered = int.tryParse(awbPiecesCtrl.text) ?? 0;
      final t = int.tryParse(awbTotalCtrl.text) ?? 0;

      if (dbTotalPieces == null) {
        // It's a new AWB (or not found in DB). Validate against the entered total (t)
        if (t > 0 && entered > t) {
          piecesError = appLanguage.value == 'es' ? 'Máx. $t piezas' : 'Max $t pieces';
        } else {
          piecesError = null;
        }
        return;
      }
      
      if (t == 0) {
        piecesError = null;
        return;
      }
      
      final remaining = dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum;
      if (remaining <= 0) {
        piecesError = appLanguage.value == 'es' ? 'Sin piezas restantes' : 'No pieces remaining';
      } else if (entered > remaining) {
        piecesError = appLanguage.value == 'es' ? 'Máx. $remaining piezas' : 'Max $remaining pieces';
      } else {
        piecesError = null;
      }
    });
  }

  Future<void> _onAwbNumChanged() async {
    final text = awbNumCtrl.text.toUpperCase();
    
    if (awbRequiredError && text.isNotEmpty && mounted) {
      setState(() => awbRequiredError = false);
    }
    
    // Validate if it already exists
    final exists = widget.existingAwbs.any((e) => e['awb_number'] == text);
    if (exists && text.isNotEmpty) {
      if (mounted && awbExistsError == null) {
        setState(() {
          awbExistsError = appLanguage.value == 'es' ? 'El AWB ya existe' : 'AWB already exists';
        });
      }
    } else {
      if (mounted && awbExistsError != null) {
        setState(() {
          awbExistsError = null;
        });
      }
    }

    if (text.length == 13) {
      try {
        int tempLocalSum = 0;
        int? localTotalOverride;
        
        // Calculate local parts
        for (var a in widget.globalAwbs) {
          if (a['awb_number'] == text) {
            final t = int.tryParse(a['total_pieces'].toString());
            if (t != null && t > 0) localTotalOverride = t;
            tempLocalSum += int.tryParse(a['pieces'].toString()) ?? 0;
          }
        }
        for (var u in widget.globalUlds) {
          final nested = u['awbs'] as List? ?? [];
          for (var a in nested) {
            if (a['awb_number'] == text) {
              final t = int.tryParse(a['total_pieces'].toString());
              if (t != null && t > 0) localTotalOverride = t;
              tempLocalSum += int.tryParse(a['pieces'].toString()) ?? 0;
            }
          }
        }

        final res = await Supabase.instance.client
            .from('awbs')
            .select('total_pieces, total_espected')
            .eq('awb_number', text)
            .maybeSingle();
            
        if (mounted) {
          setState(() {
            localPiecesSum = tempLocalSum;
            if (res != null) {
              dbTotalPieces = res['total_pieces'] as int?;
              dbTotalExpected = res['total_espected'] as int?;
            } else if (localTotalOverride != null) {
              // Not in DB but exists locally
              dbTotalPieces = localTotalOverride;
              dbTotalExpected = 0;
            } else {
              dbTotalPieces = null;
              dbTotalExpected = null;
            }
            
            if (dbTotalPieces != null) {
              isTotalLocked = true;
              awbTotalCtrl.text = dbTotalPieces.toString();
            } else {
              isTotalLocked = false;
            }
            _validatePieces();
          });
        }
      } catch (_) {}
    } else {
      if ((isTotalLocked || localPiecesSum > 0) && mounted) {
        setState(() {
          isTotalLocked = false;
          awbTotalCtrl.clear();
          dbTotalPieces = null;
          dbTotalExpected = null;
          localPiecesSum = 0;
          piecesError = null;
        });
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
    bool hasError = false,
    int? minLines,
    int? maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);
    final borderC = hasError ? Colors.redAccent : (widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB));
    final bgC = widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            suffix ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: maxLines == 1 ? 48.0 : null,
          decoration: BoxDecoration(
            color: disabled ? (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3)) : bgC,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderC),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType ?? (isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
            textCapitalization: textCapitalization,
            minLines: minLines,
            maxLines: maxLines,
            inputFormatters: [
              if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
              if (formatters != null) ...formatters,
            ],
            style: TextStyle(color: disabled ? textS : textP, fontWeight: FontWeight.w500, fontSize: 14),
            enabled: !disabled,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: maxLines == 1 
                  ? const EdgeInsets.symmetric(horizontal: 16)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final bgCard = widget.dark ? const Color(0xFF0f172a) : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 500,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB',
                    style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (awbExistsError != null)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text(awbExistsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      if (piecesError != null)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text(piecesError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      if (piecesError == null && dbTotalPieces != null)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF22c55e).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            appLanguage.value == 'es'
                                ? 'Piezas restantes: ${dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum}'
                                : 'Remaining pieces: ${dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum}',
                            style: const TextStyle(color: Color(0xFF22c55e), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildTextField('AWB Number', awbNumCtrl, formatters: [AwbNumberFormatter()], hasError: awbExistsError != null || awbRequiredError),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField('Pieces', awbPiecesCtrl, isNum: true, maxLength: 6, formatters: [FilteringTextInputFormatter.digitsOnly], hasError: piecesError != null || piecesRequiredError),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField('Total', awbTotalCtrl, isNum: true, maxLength: 6, disabled: isTotalLocked, formatters: [FilteringTextInputFormatter.digitsOnly], hasError: totalRequiredError),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField('Weight', awbWeightCtrl, isNum: true, maxLength: 6, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Remarks', awbRemCtrl, textCapitalization: TextCapitalization.sentences, formatters: [SentenceCaseTextFormatter()]),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'House Number (Press Enter)',
                      awbHouseCtrl,
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.multiline,
                      formatters: [UpperCaseTextFormatter()],
                      minLines: 1,
                      maxLines: 3,
                      suffix: houseCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366f1).withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$houseCount',
                                style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                border: Border(top: BorderSide(color: borderC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                      style: TextStyle(
                        color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final awb = awbNumCtrl.text.toUpperCase();
                      final piecesStr = awbPiecesCtrl.text;
                      final totalStr = awbTotalCtrl.text;

                      bool hasValidationError = false;
                      setState(() {
                        awbRequiredError = awb.isEmpty;
                        piecesRequiredError = piecesStr.isEmpty;
                        totalRequiredError = totalStr.isEmpty;
                        hasValidationError = awbRequiredError || piecesRequiredError || totalRequiredError;
                      });

                      if (hasValidationError) return;
                      if (piecesError != null || awbExistsError != null) return;

                      Navigator.pop(context, {
                        'awb_number': awb,
                        'pieces': awbPiecesCtrl.text,
                        'total': awbTotalCtrl.text,
                        'weight': awbWeightCtrl.text,
                        'house': awbHouseCtrl.text,
                        'remarks': awbRemCtrl.text,
                      });
                    },
                    child: Text(appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
