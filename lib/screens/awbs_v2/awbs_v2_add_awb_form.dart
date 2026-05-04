import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'awbs_v2_formatters.dart';
import 'awbs_v2_unified_options_dialog.dart';
class AwbsV2AddAwbForm extends StatefulWidget {
  final List<Map<String, dynamic>> globalAwbs;
  final List<Map<String, dynamic>> globalUlds;
  final Function(Map<String, dynamic>) onAdd;
  const AwbsV2AddAwbForm({super.key, required this.globalAwbs, required this.globalUlds, required this.onAdd});

  @override
  State<AwbsV2AddAwbForm> createState() => _AwbsV2AddAwbFormState();
}

class _AwbsV2AddAwbFormState extends State<AwbsV2AddAwbForm> {
  final _awbNumberCtrl = TextEditingController();
  final _awbPiecesCtrl = TextEditingController();
  final _awbTotalCtrl = TextEditingController();
  final _awbWeightCtrl = TextEditingController();
  final _awbRemarkCtrl = TextEditingController();
  final _awbHouseCtrl = TextEditingController();
  
  final Map<String, String> _coordinatorCounts = {};
  final Map<String, String> _itemLocations = {};

  String? _awbNumberError;
  String? _awbPiecesError;
  String? _awbTotalError;
  
  int? dbTotalPieces;
  int? dbTotalExpected;
  int localPiecesSum = 0;
  bool isTotalLocked = false;

  @override
  void initState() {
    super.initState();
    _awbNumberCtrl.addListener(_onAwbNumChanged);
    _awbPiecesCtrl.addListener(_validatePieces);
    _awbTotalCtrl.addListener(_validatePieces);
  }

  Future<void> _onAwbNumChanged() async {
    final text = _awbNumberCtrl.text.toUpperCase();
    
    if (text.length == 13) {
      try {
        int tempLocalSum = 0;
        int? localTotalOverride;
        
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
              dbTotalPieces = localTotalOverride;
              dbTotalExpected = 0;
            } else {
              dbTotalPieces = null;
              dbTotalExpected = null;
            }
            
            if (dbTotalPieces != null) {
              isTotalLocked = true;
              _awbTotalCtrl.text = dbTotalPieces.toString();
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
          _awbTotalCtrl.clear();
          dbTotalPieces = null;
          dbTotalExpected = null;
          localPiecesSum = 0;
          if (_awbPiecesError != 'Required') _awbPiecesError = null;
        });
      }
    }
  }

  void _validatePieces() {
    setState(() {
      if (_awbPiecesError == 'Required' && _awbPiecesCtrl.text.isNotEmpty) {
        _awbPiecesError = null;
      }
      
      final entered = int.tryParse(_awbPiecesCtrl.text) ?? 0;
      final t = int.tryParse(_awbTotalCtrl.text) ?? 0;

      if (dbTotalPieces == null) {
        if (t > 0 && entered > t) {
          _awbPiecesError = appLanguage.value == 'es' ? 'Máx. $t piezas' : 'Max $t pieces';
        } else if (_awbPiecesError != 'Required') {
          _awbPiecesError = null;
        }
        return;
      }
      
      if (t == 0) {
        if (_awbPiecesError != 'Required') _awbPiecesError = null;
        return;
      }
      
      final remaining = dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum;
      if (remaining <= 0) {
        _awbPiecesError = appLanguage.value == 'es' ? 'Sin piezas restantes' : 'No pieces remaining';
      } else if (entered > remaining) {
        _awbPiecesError = appLanguage.value == 'es' ? 'Máx. $remaining piezas' : 'Max $remaining pieces';
      } else if (_awbPiecesError != 'Required') {
        _awbPiecesError = null;
      }
    });
  }

  @override
  void dispose() {
    _awbNumberCtrl.dispose();
    _awbPiecesCtrl.dispose();
    _awbTotalCtrl.dispose();
    _awbWeightCtrl.dispose();
    _awbRemarkCtrl.dispose();
    _awbHouseCtrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    setState(() {
      _awbNumberError = _awbNumberCtrl.text.trim().isEmpty ? 'Required' : null;
      _awbPiecesError = _awbPiecesCtrl.text.trim().isEmpty ? 'Required' : null;
      _awbTotalError = _awbTotalCtrl.text.trim().isEmpty ? 'Required' : null;
    });

    if (_awbNumberError != null || _awbPiecesError != null || _awbTotalError != null) return;

    widget.onAdd({
      'type': 'awb',
      'awb_number': _awbNumberCtrl.text.trim(),
      'pieces': _awbPiecesCtrl.text.trim(),
      'total_pieces': _awbTotalCtrl.text.trim(),
      'weight': _awbWeightCtrl.text.trim(),
      'remarks': _awbRemarkCtrl.text.trim(),
      'house_number': _awbHouseCtrl.text.trim(),
      'data_coordinator': Map<String, String>.from(_coordinatorCounts),
      'data_location': Map<String, String>.from(_itemLocations),
    });
    _awbNumberCtrl.clear();
    _awbPiecesCtrl.clear();
    _awbTotalCtrl.clear();
    _awbWeightCtrl.clear();
    _awbRemarkCtrl.clear();
    _awbHouseCtrl.clear();
    setState(() {
      _coordinatorCounts.clear();
      _itemLocations.clear();
      _awbNumberError = null;
      _awbPiecesError = null;
      _awbTotalError = null;
    });
  }

  void _showUnifiedOptions(BuildContext context, bool dark, Color textP, Color textS, Color borderC) {
    showUnifiedOptionsDialog(
      context: context,
      dark: dark,
      textP: textP,
      textS: textS,
      borderC: borderC,
      houseCtrl: _awbHouseCtrl,
      piecesCtrl: _awbPiecesCtrl,
      coordinatorCounts: _coordinatorCounts,
      itemLocations: _itemLocations,
      onSave: () => setState(() {}),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1, List<TextInputFormatter>? inputFormatters, int? maxLength, String? errorText, bool readOnly = false, FocusNode? focusNode, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: errorText != null ? const Color(0xFFef4444) : (isDarkMode.value ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: TextFormField(
              controller: ctrl,
              focusNode: focusNode,
              readOnly: readOnly,
              keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              maxLines: maxLines,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                counterText: '',
                fillColor: errorText != null ? const Color(0xFFef4444).withAlpha(10) : (!readOnly ? (isDarkMode.value ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6)) : (isDarkMode.value ? Colors.white.withAlpha(5) : const Color(0xFFE5E7EB))),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: errorText != null ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: errorText != null ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: errorText != null ? const BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) {
                if (onChanged != null) onChanged(val);
                setState(() {});
              },
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(errorText, style: const TextStyle(color: Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Air Waybill (AWB)', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_awbPiecesError == null && dbTotalPieces != null)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF22c55e).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        appLanguage.value == 'es'
                            ? 'Piezas restantes: ${dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum}'
                            : 'Remaining pieces: ${dbTotalPieces! - (dbTotalExpected ?? 0) - localPiecesSum}',
                        style: const TextStyle(color: Color(0xFF22c55e), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 140, child: _buildTextField('AWB Number', _awbNumberCtrl, maxLength: 13, inputFormatters: [AwbNumberFormatter()], errorText: _awbNumberError, onChanged: (_) { if (_awbNumberError != null) setState(() => _awbNumberError = null); })),
                  SizedBox(width: 85, child: _buildTextField('Pieces', _awbPiecesCtrl, isNumber: true, inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ], errorText: _awbPiecesError, onChanged: (_) { if (_awbPiecesError == 'Required') setState(() => _awbPiecesError = null); })),
                  SizedBox(width: 85, child: _buildTextField('Total', _awbTotalCtrl, isNumber: true, readOnly: isTotalLocked, inputFormatters: [FilteringTextInputFormatter.digitsOnly], errorText: _awbTotalError, onChanged: (_) { if (_awbTotalError != null) setState(() => _awbTotalError = null); })),
                  SizedBox(width: 95, child: _buildTextField('Weight', _awbWeightCtrl, isNumber: true, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                  Expanded(child: _buildTextField('Remarks', _awbRemarkCtrl)),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12, right: 12),
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderC),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: (_awbHouseCtrl.text.trim().isNotEmpty || _coordinatorCounts.isNotEmpty || _itemLocations.isNotEmpty) 
                            ? const Color(0xFF6366f1) 
                            : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)),
                        size: 20,
                      ),
                      onPressed: () => _showUnifiedOptions(context, dark, textP, textS, borderC),
                      tooltip: 'More Options',
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _awbNumberCtrl.text.isNotEmpty ? const Color(0xFF6366f1) : (dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)), 
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add_rounded, color: _awbNumberCtrl.text.isNotEmpty ? Colors.white : (dark ? Colors.white54 : Colors.black38), size: 20),
                      onPressed: _awbNumberCtrl.text.isNotEmpty ? _handleAdd : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
