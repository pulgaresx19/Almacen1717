import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show isDarkMode;
import '../add_awb_v2/add_awb_v2_formatters.dart';
import '../add_awb_v2/add_awb_v2_dialogs.dart';

class AwbsV2AddAwbForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AwbsV2AddAwbForm({super.key, required this.onAdd});

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

  void _showHouseNumberDialog(BuildContext context, bool dark, Color textP, Color textS, Color borderC) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _awbHouseCtrl,
            builder: (context, value, child) {
              final count = value.text.split('\n').where((e) => e.trim().isNotEmpty).length;
              return Row(
                children: [
                  Text('House Numbers', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: _awbHouseCtrl,
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              style: TextStyle(color: textP, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter one house number per line',
                hintStyle: TextStyle(color: textS, fontSize: 13),
                filled: true,
                fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
            ),
          ],
        );
      },
    ).then((_) => setState(() {}));
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
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(width: 140, child: _buildTextField('AWB Number', _awbNumberCtrl, maxLength: 13, inputFormatters: [AwbNumberFormatter()], errorText: _awbNumberError, onChanged: (_) { if (_awbNumberError != null) setState(() => _awbNumberError = null); })),
                  SizedBox(width: 85, child: _buildTextField('Pieces', _awbPiecesCtrl, isNumber: true, inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      final p = int.tryParse(newValue.text) ?? 0;
                      final t = int.tryParse(_awbTotalCtrl.text) ?? 0;
                      if (_awbTotalCtrl.text.isNotEmpty && t > 0 && p > t) return oldValue;
                      return newValue;
                    })
                  ], errorText: _awbPiecesError, onChanged: (_) { if (_awbPiecesError != null) setState(() => _awbPiecesError = null); })),
                  SizedBox(width: 85, child: _buildTextField('Total', _awbTotalCtrl, isNumber: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly], errorText: _awbTotalError, onChanged: (_) { if (_awbTotalError != null) setState(() => _awbTotalError = null); })),
                  SizedBox(width: 95, child: _buildTextField('Weight', _awbWeightCtrl, isNumber: true, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                  SizedBox(width: 240, child: _buildTextField('Remarks', _awbRemarkCtrl)),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 12),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderC),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.home_work_outlined, 
                                  color: _awbHouseCtrl.text.trim().isNotEmpty ? const Color(0xFF6366f1) : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)), 
                                  size: 18
                                ),
                                if (_awbHouseCtrl.text.trim().isNotEmpty)
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFef4444),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                      child: Center(
                                        child: Text(
                                          '${_awbHouseCtrl.text.split('\n').where((e) => e.trim().isNotEmpty).length}',
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: () => _showHouseNumberDialog(context, dark, textP, textS, borderC),
                            tooltip: 'House Number',
                          ),
                          Container(width: 1, height: 24, color: borderC),
                          IconButton(
                            icon: Icon(
                              Icons.assignment_add, 
                              color: _awbPiecesCtrl.text.trim().isEmpty 
                                  ? (dark ? const Color(0xFF475569) : const Color(0xFF9CA3AF))
                                  : (_coordinatorCounts.isNotEmpty ? const Color(0xFF6366f1) : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563))), 
                              size: 18
                            ),
                            onPressed: _awbPiecesCtrl.text.trim().isEmpty ? null : () => showCoordinatorDataDialog(
                              context: context,
                              dark: dark,
                              textP: textP,
                              textS: textS,
                              expectedPieces: int.tryParse(_awbTotalCtrl.text) ?? 0,
                              coordinatorCounts: _coordinatorCounts,
                              onSave: () => setState(() {
                                // Calculate total received pieces from coordinator counts
                                int totalRec = 0;
                                _coordinatorCounts.forEach((k, v) {
                                  if (k == 'discrepancy_amount' || k == 'discrepancy_type') return;
                                  totalRec += int.tryParse(v) ?? 0;
                                });
                                _awbPiecesCtrl.text = totalRec.toString();
                              }),
                            ),
                            tooltip: 'Data Coordinator',
                          ),
                          Container(width: 1, height: 24, color: borderC),
                          IconButton(
                            icon: Icon(
                              Icons.location_on_outlined, 
                              color: _coordinatorCounts.isEmpty 
                                  ? (dark ? const Color(0xFF475569) : const Color(0xFF9CA3AF)) 
                                  : (_itemLocations.isNotEmpty ? const Color(0xFF10b981) : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563))), 
                              size: 18
                            ),
                            onPressed: _coordinatorCounts.isEmpty ? null : () => showItemLocationEntryDialog(
                              context: context,
                              expectedPieces: int.tryParse(_awbTotalCtrl.text) ?? 0, // In standard flow, expected pieces is checked, but using total received might be better
                              coordinatorCounts: _coordinatorCounts,
                              itemLocations: _itemLocations,
                              onSave: () => setState(() {}),
                            ),
                            tooltip: 'Data Location',
                          ),
                        ],
                      ),
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
