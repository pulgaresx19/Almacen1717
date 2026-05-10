import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'awbs_v2_formatters.dart';

class AwbsV2AddUldForm extends StatefulWidget {
  final List<Map<String, dynamic>> globalUlds;
  final Function(Map<String, dynamic>) onAdd;
  const AwbsV2AddUldForm({super.key, required this.globalUlds, required this.onAdd});

  @override
  State<AwbsV2AddUldForm> createState() => _AwbsV2AddUldFormState();
}

class _AwbsV2AddUldFormState extends State<AwbsV2AddUldForm> {
  final _uldNumberCtrl = TextEditingController();
  final _uldPiecesCtrl = TextEditingController();
  final _uldWeightCtrl = TextEditingController();
  final _uldRemarkCtrl = TextEditingController();

  bool _uldNumberError = false;
  String? _uldNumberErrorStr;
  bool _uldPiecesError = false;
  bool _autoPieces = true;
  bool _autoWeight = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _uldNumberCtrl.addListener(_onUldNumberChanged);
  }

  Future<void> _onUldNumberChanged() async {
    final text = _uldNumberCtrl.text.trim().toUpperCase();
    if (text.length == 10) {
      // Check local
      bool exists = widget.globalUlds.any((u) => u['uld_number'].toString().toUpperCase() == text);
      if (exists) {
        setState(() {
          _uldNumberError = true;
          _uldNumberErrorStr = appLanguage.value == 'es' ? 'Ya existe en la lista' : 'Already exists in list';
        });
        return;
      }

      setState(() => _isChecking = true);
      
      try {
        final res = await Supabase.instance.client
            .from('ulds')
            .select('uld_number')
            .eq('uld_number', text)
            .limit(1);
            
        if (!mounted) return;
        
        if (_uldNumberCtrl.text.trim().toUpperCase() == text) {
          if (res.isNotEmpty) {
            setState(() {
              _isChecking = false;
              _uldNumberError = true;
              _uldNumberErrorStr = appLanguage.value == 'es' ? 'ULD ya registrado' : 'ULD already exists';
            });
          } else {
            setState(() {
              _isChecking = false;
              _uldNumberError = false;
              _uldNumberErrorStr = null;
            });
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isChecking = false;
          });
        }
      }
    } else {
      if (_uldNumberError) {
        setState(() {
          _uldNumberError = false;
          _uldNumberErrorStr = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _uldNumberCtrl.dispose();
    _uldPiecesCtrl.dispose();
    _uldWeightCtrl.dispose();
    _uldRemarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final text = _uldNumberCtrl.text.trim().toUpperCase();
    bool exists = widget.globalUlds.any((u) => u['uld_number'].toString().toUpperCase() == text);

    if (text.isEmpty) {
      setState(() {
        _uldNumberError = true;
        _uldNumberErrorStr = null;
        _uldPiecesError = !_autoPieces && _uldPiecesCtrl.text.trim().isEmpty;
      });
      return;
    }

    if (exists) {
      setState(() {
        _uldNumberError = true;
        _uldNumberErrorStr = appLanguage.value == 'es' ? 'Ya existe en la lista' : 'Already exists in list';
        _uldPiecesError = !_autoPieces && _uldPiecesCtrl.text.trim().isEmpty;
      });
      return;
    }

    setState(() => _isChecking = true);

    bool dbExists = false;
    try {
      final res = await Supabase.instance.client
          .from('ulds')
          .select('uld_number')
          .eq('uld_number', text)
          .limit(1);
      if (res.isNotEmpty) {
        dbExists = true;
      }
    } catch (_) {}

    if (!mounted) return;

    if (dbExists) {
      setState(() {
        _isChecking = false;
        _uldNumberError = true;
        _uldNumberErrorStr = appLanguage.value == 'es' ? 'ULD ya registrado' : 'ULD already exists';
        _uldPiecesError = !_autoPieces && _uldPiecesCtrl.text.trim().isEmpty;
      });
      return;
    }

    setState(() {
      _isChecking = false;
      _uldNumberError = false;
      _uldNumberErrorStr = null;
      _uldPiecesError = !_autoPieces && _uldPiecesCtrl.text.trim().isEmpty;
    });

    if (_uldPiecesError) return;

    widget.onAdd({
      'type': 'uld',
      'uld_number': _uldNumberCtrl.text.trim(),
      'pieces': _autoPieces ? 'Auto' : _uldPiecesCtrl.text.trim(),
      'total_pieces': '',
      'weight': _autoWeight ? 'Auto' : _uldWeightCtrl.text.trim(),
      'remarks': _uldRemarkCtrl.text.trim(),
      'auto_pieces': _autoPieces,
      'auto_weight': _autoWeight,
      'awbs': <Map<String, dynamic>>[],
    });
    _uldNumberCtrl.clear();
    if (!_autoPieces) _uldPiecesCtrl.clear();
    if (!_autoWeight) _uldWeightCtrl.clear();
    _uldRemarkCtrl.clear();
    setState(() {
      _uldNumberError = false;
      _uldNumberErrorStr = null;
      _uldPiecesError = false;
    });
  }

  Widget _buildAutoCheckbox(bool value, Function(bool) onChanged) {
    return SizedBox(
      height: 16,
      width: 16,
      child: Checkbox(
        value: value,
        activeColor: const Color(0xFF6366f1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: isDarkMode.value ? Colors.white54 : Colors.black54, width: 1.5),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1, List<TextInputFormatter>? inputFormatters, int? maxLength, bool hasError = false, String? errorText, bool readOnly = false, Widget? trailingLabel, Function(String)? onChanged, TextCapitalization textCapitalization = TextCapitalization.none}) {
    final bool isError = hasError || errorText != null;
    final dark = isDarkMode.value;
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: isError ? Colors.redAccent : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)), fontSize: 12, fontWeight: FontWeight.w500)),
              trailingLabel ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            readOnly: readOnly,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: TextStyle(color: readOnly ? (dark ? Colors.white.withAlpha(120) : Colors.black54) : (dark ? Colors.white : Colors.black), fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              counterText: '',
              hintText: readOnly ? 'Auto' : null,
              hintStyle: TextStyle(color: dark ? Colors.white.withAlpha(76) : Colors.black.withAlpha(76), fontSize: 12),
              fillColor: isError ? Colors.redAccent.withAlpha(20) : (readOnly ? (dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6)) : (dark ? Colors.white.withAlpha(13) : Colors.white)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isError ? Colors.redAccent : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isError ? Colors.redAccent : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isError ? Colors.redAccent : const Color(0xFF8b5cf6), width: 1.5),
              ),
            ),
            onChanged: (val) {
              if (onChanged != null) onChanged(val);
              setState(() {});
            },
          ),
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
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('ULD No Break', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_uldNumberErrorStr != null)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _uldNumberErrorStr!,
                        style: const TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 140, child: _buildTextField('ULD Number', _uldNumberCtrl, maxLength: 10, inputFormatters: [UpperCaseTextFormatter()], hasError: _uldNumberError, onChanged: (_) { if (_uldNumberError) setState(() { _uldNumberError = false; _uldNumberErrorStr = null; }); })),
                  SizedBox(width: 95, child: _buildTextField('Pieces', _uldPiecesCtrl, isNumber: true, maxLength: 5, readOnly: _autoPieces, 
                    trailingLabel: _buildAutoCheckbox(_autoPieces, (val) {
                      setState(() {
                        _autoPieces = val;
                        if (_autoPieces) {
                          _uldPiecesError = false;
                          _uldPiecesCtrl.clear();
                        }
                      });
                    }),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], hasError: _uldPiecesError, onChanged: (_) { if (_uldPiecesError) setState(() => _uldPiecesError = false); })),
                  SizedBox(width: 95, child: _buildTextField('Weight', _uldWeightCtrl, isNumber: true, maxLength: 5, readOnly: _autoWeight, 
                    trailingLabel: _buildAutoCheckbox(_autoWeight, (val) {
                      setState(() {
                        _autoWeight = val;
                        if (_autoWeight) _uldWeightCtrl.clear();
                      });
                    }),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                  Expanded(child: _buildTextField('Remarks', _uldRemarkCtrl, inputFormatters: [SentenceCaseTextFormatter()], textCapitalization: TextCapitalization.sentences)),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: IconButton(
                      icon: _isChecking 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      onPressed: _isChecking ? null : _handleAdd,
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
