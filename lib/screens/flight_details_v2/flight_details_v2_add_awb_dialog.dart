import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show appLanguage;
import 'flight_details_v2_formatters.dart';

Future<Map<String, dynamic>?> showAddAwbDialog(
    BuildContext context, bool dark, List<Map<String, dynamic>> existingAwbs) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) {
      return _AddAwbDialogComponent(dark: dark, existingAwbs: existingAwbs);
    },
  );
}

class _AddAwbDialogComponent extends StatefulWidget {
  final bool dark;
  final List<Map<String, dynamic>> existingAwbs;

  const _AddAwbDialogComponent({required this.dark, required this.existingAwbs});

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
  bool isTotalLocked = false;
  String? piecesError;

  @override
  void initState() {
    super.initState();
    awbNumCtrl.addListener(_onAwbNumChanged);
    awbPiecesCtrl.addListener(_validatePieces);
  }

  void _validatePieces() {
    if (dbTotalPieces == null) return;
    setState(() {
      final entered = int.tryParse(awbPiecesCtrl.text) ?? 0;
      final remaining = dbTotalPieces! - (dbTotalExpected ?? 0);
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
    if (text.length == 13) {
      try {
        final res = await Supabase.instance.client
            .from('awbs')
            .select('total_pieces, total_espected')
            .eq('awb_number', text)
            .maybeSingle();
        if (res != null && mounted) {
          setState(() {
            dbTotalPieces = res['total_pieces'] as int?;
            dbTotalExpected = res['total_espected'] as int?;
            if (dbTotalPieces != null) {
              isTotalLocked = true;
              awbTotalCtrl.text = dbTotalPieces.toString();
              _validatePieces();
            }
          });
        }
      } catch (_) {}
    } else {
      if (isTotalLocked && mounted) {
        setState(() {
          isTotalLocked = false;
          awbTotalCtrl.clear();
          dbTotalPieces = null;
          dbTotalExpected = null;
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
            Text(
              label,
              style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildTextField('AWB Number', awbNumCtrl, formatters: [AwbNumberFormatter()]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField('Pieces', awbPiecesCtrl, isNum: true, maxLength: 6, formatters: [FilteringTextInputFormatter.digitsOnly]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField('Total', awbTotalCtrl, isNum: true, maxLength: 6, disabled: isTotalLocked, formatters: [FilteringTextInputFormatter.digitsOnly]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField('Weight', awbWeightCtrl, isNum: true, maxLength: 6, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                        ),
                      ],
                    ),
                    if (piecesError != null || dbTotalPieces != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4),
                        child: Row(
                          children: [
                            if (piecesError != null)
                              Expanded(
                                child: Text(piecesError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            if (piecesError == null && dbTotalPieces != null)
                              Expanded(
                                child: Text(
                                  appLanguage.value == 'es'
                                      ? 'Piezas restantes: ${dbTotalPieces! - (dbTotalExpected ?? 0)}'
                                      : 'Remaining pieces: ${dbTotalPieces! - (dbTotalExpected ?? 0)}',
                                  style: const TextStyle(color: Color(0xFF22c55e), fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildTextField('Remarks', awbRemCtrl, textCapitalization: TextCapitalization.sentences, formatters: [SentenceCaseTextFormatter()]),
                    const SizedBox(height: 16),
                    _buildTextField('House Number (Press Enter)', awbHouseCtrl),
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
                      if (piecesError != null) return;
                      final awb = awbNumCtrl.text.toUpperCase();
                      if (awb.isEmpty) return;
                      
                      if (widget.existingAwbs.any((e) => e['awb_number'] == awb)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              appLanguage.value == 'es' ? 'Este AWB ya existe en la lista.' : 'This AWB already exists in the list.',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

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
