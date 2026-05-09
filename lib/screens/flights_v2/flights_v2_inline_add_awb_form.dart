import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FlightsV2InlineAddAwbForm extends StatefulWidget {
  final bool dark;
  final ValueNotifier<String> appLanguage;
  final Color textP;
  final Color textS;
  final Color borderC;
  final List<Map<String, dynamic>> existingAwbs;
  final String uldNumber;
  final Function(Map<String, dynamic>) onAdd;

  const FlightsV2InlineAddAwbForm({
    super.key,
    required this.dark,
    required this.appLanguage,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.existingAwbs,
    required this.uldNumber,
    required this.onAdd,
  });

  @override
  State<FlightsV2InlineAddAwbForm> createState() => _FlightsV2InlineAddAwbFormState();
}

class _FlightsV2InlineAddAwbFormState extends State<FlightsV2InlineAddAwbForm> {
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

  @override
  void dispose() {
    awbNumCtrl.dispose();
    awbPiecesCtrl.dispose();
    awbTotalCtrl.dispose();
    awbWeightCtrl.dispose();
    awbHouseCtrl.dispose();
    awbRemCtrl.dispose();
    super.dispose();
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
      setState(() => houseCount = lines.length);
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
        if (t > 0 && entered > t) {
          piecesError = widget.appLanguage.value == 'es' ? 'Máx. $t piezas' : 'Max $t pcs';
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
        piecesError = widget.appLanguage.value == 'es' ? 'Completado' : 'Completed';
      } else if (entered > remaining) {
        piecesError = widget.appLanguage.value == 'es' ? 'Máx. $remaining' : 'Max $remaining';
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
    
    final exists = widget.existingAwbs.any((e) => e['awb_number'] == text || e['awb'] == text);
    if (exists && text.isNotEmpty) {
      if (mounted && awbExistsError == null) setState(() => awbExistsError = widget.appLanguage.value == 'es' ? 'Duplicado' : 'Duplicate');
    } else {
      if (mounted && awbExistsError != null) setState(() => awbExistsError = null);
    }

    if (text.length == 13) {
      try {
        final res = await Supabase.instance.client
            .from('awbs')
            .select('total_pieces, total_espected')
            .eq('awb_number', text)
            .maybeSingle();
            
        if (mounted) {
          setState(() {
            if (res != null) {
              dbTotalPieces = res['total_pieces'] as int?;
              dbTotalExpected = res['total_espected'] as int?;
            } else {
              dbTotalPieces = null;
              dbTotalExpected = null;
            }
            localPiecesSum = 0; // For inline, we only validate against DB
            
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
    bool expands = false,
    double? height,
  }) {
    final borderC = hasError ? Colors.redAccent : (widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB));
    final focusedBorderC = hasError ? Colors.redAccent : const Color(0xFF8b5cf6);
    final bgC = widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: widget.textS, fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(
              height: 14,
              child: suffix ?? const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: height,
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType ?? ((maxLines == null || maxLines > 1 || expands) ? TextInputType.multiline : (isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text)),
            textCapitalization: textCapitalization,
            minLines: expands ? null : minLines,
            maxLines: expands ? null : maxLines,
            expands: expands,
            textAlignVertical: expands ? TextAlignVertical.top : null,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            if (formatters != null) ...formatters,
          ],
          style: TextStyle(color: disabled ? widget.textS : widget.textP, fontWeight: FontWeight.w500, fontSize: 12),
          enabled: !disabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: disabled ? (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3)) : bgC,
            contentPadding: maxLines == 1 ? const EdgeInsets.symmetric(horizontal: 12, vertical: 14) : const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderC),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusedBorderC, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderC),
            ),
          ),
        ),
      ),
    ],
  );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: widget.borderC)),
        color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded, size: 18, color: widget.textP),
              const SizedBox(width: 8),
              Text('AWB Details', style: TextStyle(color: widget.textP, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (awbExistsError != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                  child: Text(awbExistsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              if (piecesError != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                  child: Text(piecesError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              if (piecesError == null && dbTotalPieces != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF22c55e).withAlpha(20), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    widget.appLanguage.value == 'es' ? 'Máx: ${dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum} piezas' : 'Max ${dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum} pcs',
                    style: const TextStyle(color: Color(0xFF22c55e), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 125,
                    child: _buildTextField(
                      'AWB Number', awbNumCtrl, 
                      maxLength: 13, textCapitalization: TextCapitalization.characters,
                      formatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          String text = newValue.text.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
                          if (text.length > 3) text = '${text.substring(0, 3)}-${text.substring(3)}';
                          if (text.length > 8) text = '${text.substring(0, 8)} ${text.substring(8)}';
                          return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
                        })
                      ],
                      hasError: awbExistsError != null || awbRequiredError,
                    )
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 75, 
                    child: _buildTextField(
                      'Pieces', awbPiecesCtrl, 
                      maxLength: 5, isNum: true, formatters: [FilteringTextInputFormatter.digitsOnly],
                      hasError: piecesError != null || piecesRequiredError,
                    )
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 75, 
                    child: _buildTextField('Total', awbTotalCtrl, maxLength: 5, isNum: true, disabled: isTotalLocked, formatters: [FilteringTextInputFormatter.digitsOnly], hasError: totalRequiredError)
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 75, child: _buildTextField('Weight', awbWeightCtrl, maxLength: 5, isNum: true, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))])),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      'House Num', awbHouseCtrl, 
                      textCapitalization: TextCapitalization.characters,
                      expands: true,
                      height: 44.0, // Fixed height to match other fields
                      formatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          ),
                        ),
                      ],
                      suffix: houseCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                              child: Center(
                                child: Text('$houseCount', style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Remarks', awbRemCtrl, 
                      textCapitalization: TextCapitalization.sentences,
                      formatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) return newValue;
                          return TextEditingValue(
                            text: newValue.text[0].toUpperCase() + newValue.text.substring(1),
                            selection: newValue.selection,
                          );
                        })
                      ]
                    )
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140, height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = awbNumCtrl.text.trim();
                        final piecesStr = awbPiecesCtrl.text.trim();
                        final totalStr = awbTotalCtrl.text.trim();

                        bool hasValidation = false;
                        setState(() {
                          awbRequiredError = text.length < 13;
                          piecesRequiredError = piecesStr.isEmpty || piecesStr == '0';
                          totalRequiredError = totalStr.isEmpty || totalStr == '0';
                          hasValidation = awbRequiredError || piecesRequiredError || totalRequiredError;
                          if (text.isNotEmpty && text.length < 13) awbExistsError = widget.appLanguage.value == 'es' ? 'Incompleto' : 'Incomplete';
                        });

                        if (hasValidation) return;
                        if (piecesError != null || awbExistsError != null) return;

                        widget.onAdd({
                          'awb_number': awbNumCtrl.text.trim(),
                          'pieces': awbPiecesCtrl.text.trim().isEmpty ? '0' : awbPiecesCtrl.text.trim(),
                          'total': awbTotalCtrl.text.trim().isEmpty ? '0' : awbTotalCtrl.text.trim(),
                          'weight': awbWeightCtrl.text.trim().isEmpty ? '0' : awbWeightCtrl.text.trim(),
                          'house': awbHouseCtrl.text.trim(),
                          'remarks': awbRemCtrl.text.trim(),
                        });
                        
                        setState(() {
                          awbNumCtrl.clear();
                          awbPiecesCtrl.clear();
                          awbTotalCtrl.clear();
                          awbWeightCtrl.clear();
                          awbHouseCtrl.clear();
                          awbRemCtrl.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15), 
                        foregroundColor: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), 
                        elevation: 0, 
                        padding: const EdgeInsets.symmetric(horizontal: 16), 
                        side: BorderSide(color: widget.dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text(widget.appLanguage.value == 'es' ? '+ Añadir AWB' : '+ Add AWB', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
