import 'package:flutter/material.dart';

import '../../main.dart' show appLanguage;

Future<void> showAddUldComponent(BuildContext context, Map<String, dynamic> flight, bool dark) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withAlpha(150),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: _AddUldComponentInternal(flight: flight, dark: dark),
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
}

class _AddUldComponentInternal extends StatefulWidget {
  final Map<String, dynamic> flight;
  final bool dark;

  const _AddUldComponentInternal({required this.flight, required this.dark});

  @override
  State<_AddUldComponentInternal> createState() => _AddUldComponentInternalState();
}

class _AddUldComponentInternalState extends State<_AddUldComponentInternal> {
  final _uldNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController(text: 'Auto');
  final _weightCtrl = TextEditingController(text: 'Auto');
  final _remarksCtrl = TextEditingController();

  bool _isPriority = false;
  bool _isBreak = true;
  bool _autoPieces = true;
  bool _autoWeight = true;

  final List<Map<String, dynamic>> _awbs = [];

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNum = false, bool disabled = false, Widget? suffix}) {
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

  void _showAddAwbDialog() {
    final awbNumCtrl = TextEditingController();
    final awbPiecesCtrl = TextEditingController();
    final awbTotalCtrl = TextEditingController();
    final awbWeightCtrl = TextEditingController();
    final awbHouseCtrl = TextEditingController();
    final awbRemCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final textP = widget.dark ? Colors.white : const Color(0xFF111827);
        final bgCard = widget.dark ? const Color(0xFF1e293b) : Colors.white;

        return AlertDialog(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildTextField('AWB Number', awbNumCtrl)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField('Pieces', awbPiecesCtrl, isNum: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Total Pieces', awbTotalCtrl, isNum: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField('Weight', awbWeightCtrl, isNum: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('House Number', awbHouseCtrl),
                  const SizedBox(height: 12),
                  _buildTextField('Remarks', awbRemCtrl),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Color(0xFF94a3b8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                setState(() {
                  _awbs.add({
                    'awb_number': awbNumCtrl.text.toUpperCase(),
                    'pieces': awbPiecesCtrl.text,
                    'total': awbTotalCtrl.text,
                    'weight': awbWeightCtrl.text,
                    'house': awbHouseCtrl.text,
                    'remarks': awbRemCtrl.text,
                  });
                });
                Navigator.pop(ctx);
              },
              child: Text(appLanguage.value == 'es' ? 'Añadir' : 'Add'),
            ),
          ],
        );
      },
    );
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
      width: 600,
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
                    Text(appLanguage.value == 'es' ? 'Añadir ULD al Vuelo' : 'Add ULD to Flight', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$carrier $number', style: TextStyle(color: textP, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textS),
                  onPressed: () => Navigator.pop(context),
                )
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
                      Expanded(flex: 4, child: _buildTextField('ULD Number', _uldNumberCtrl)),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          'Pieces', _piecesCtrl, isNum: true, disabled: _autoPieces,
                          suffix: SizedBox(
                            width: 20, height: 20,
                            child: Checkbox(
                              value: _autoPieces,
                              activeColor: const Color(0xFF6366f1),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) => setState(() {
                                _autoPieces = v ?? true;
                                _piecesCtrl.text = _autoPieces ? 'Auto' : '';
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          'Weight', _weightCtrl, isNum: true, disabled: _autoWeight,
                          suffix: SizedBox(
                            width: 20, height: 20,
                            child: Checkbox(
                              value: _autoWeight,
                              activeColor: const Color(0xFF6366f1),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) => setState(() {
                                _autoWeight = v ?? true;
                                _weightCtrl.text = _autoWeight ? 'Auto' : '';
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Priority', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
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
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Break', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
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
                  _buildTextField('Remarks', _remarksCtrl),
                  
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
                            decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                            child: Text('${_awbs.length}', style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6),
                          foregroundColor: textP,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderC)),
                        ),
                        onPressed: _showAddAwbDialog,
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
                          Text(appLanguage.value == 'es' ? 'No hay AWBs añadidos.' : 'No AWBs added yet.', style: TextStyle(color: textS)),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _awbs.asMap().entries.map((e) {
                        final i = e.key;
                        final a = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderC),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), shape: BoxShape.circle),
                                child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a['awb_number'] ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Pcs: ${a['pieces']} • Wgt: ${a['weight']}', style: TextStyle(color: textS, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _awbs.removeAt(i);
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    )
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
                  child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Logic to be implemented
                  },
                  child: Text(appLanguage.value == 'es' ? 'Crear ULD' : 'Create ULD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
