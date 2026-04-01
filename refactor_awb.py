import os

content = """import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage;

class AddAwbScreen extends StatefulWidget {
  final String? initialFlightId;
  final String? initialUld;
  final Function(bool)? onPop;

  const AddAwbScreen({
    super.key,
    this.initialFlightId,
    this.initialUld,
    this.onPop,
  });

  @override
  State<AddAwbScreen> createState() => AddAwbScreenState();
}

class AddAwbScreenState extends State<AddAwbScreen> {
  final _awbNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  String? _selectedFlight;
  String _refUld = '';
  bool _isSavingAll = false;
  late final TextEditingController _refUldCtrl;

  List<Map<String, dynamic>> _flights = [];
  final List<Map<String, dynamic>> _localAwbs = [];
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _selectedFlight = widget.initialFlightId;
    _refUld = widget.initialUld ?? '';
    _refUldCtrl = TextEditingController(text: _refUld);
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    try {
      final res = await Supabase.instance.client
          .from('Flight')
          .select('id, carrier, number, date-arrived')
          .order('created_at');
      if (mounted) {
        setState(() {
          _flights = List.from(res);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _awbNumberCtrl.dispose();
    _piecesCtrl.dispose();
    _totalCtrl.dispose();
    _weightCtrl.dispose();
    _houseCtrl.dispose();
    _remarksCtrl.dispose();
    _refUldCtrl.dispose();
    super.dispose();
  }

  void _addLocalAwb() {
    if (_awbNumberCtrl.text.trim().isEmpty || _totalCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AWB Number & Total pieces are required.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      String? flightLabel;
      if (_selectedFlight != null) {
        final f = _flights.firstWhere((x) => x['id'].toString() == _selectedFlight, orElse: () => <String, dynamic>{});
        if (f.isNotEmpty) {
          flightLabel = '${f['carrier']} ${f['number']}';
        }
      }

      _localAwbs.add({
        'awbNumber': _awbNumberCtrl.text.trim().toUpperCase(),
        'pieces': int.tryParse(_piecesCtrl.text) ?? 1,
        'total': int.tryParse(_totalCtrl.text) ?? 1,
        'weight': double.tryParse(_weightCtrl.text) ?? 0.0,
        'house': _houseCtrl.text.trim().toUpperCase(),
        'remarks': _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
        'flight_id': _selectedFlight,
        'flightLabel': flightLabel,
        'refUld': _refUld.trim().toUpperCase(),
      });

      _awbNumberCtrl.clear();
      _piecesCtrl.clear();
      _totalCtrl.clear();
      _weightCtrl.clear();
      _houseCtrl.clear();
      _remarksCtrl.clear();
      _refUldCtrl.clear();
      _refUld = '';
    });
  }

  Future<void> _saveAllAwbs() async {
    if (_localAwbs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one AWB list.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSavingAll = true);

    try {
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      List<Map<String, dynamic>> payloads = [];

      for (var a in _localAwbs) {
        final dataAwb = {
          'flightID': a['flight_id'] ?? '0',
          'refCarrier': 'WRHS',
          'refNumber': 'LOCAL',
          'refDate': dateStr,
          'refULD': a['refUld'],
          'pieces': a['pieces'],
          'weight': a['weight'],
          'house': a['house'],
          'remarks': a['remarks'],
          'status': 'Received',
        };

        payloads.add({
          'AWB-number': a['awbNumber'],
          'total': a['total'],
          'data-AWB': dataAwb,
          'data-coordinator': {},
          'data-location': {},
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await Supabase.instance.client.from('AWB').insert(payloads);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return Dialog(
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: const Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10b981), size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Air Waybills saved successfully',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (!mounted) return;
        if (widget.onPop != null) {
          widget.onPop!(true);
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  bool get hasDataSync {
    if (_localAwbs.isNotEmpty) return true;
    if (_awbNumberCtrl.text.isNotEmpty || 
       _piecesCtrl.text.isNotEmpty || 
       _weightCtrl.text.isNotEmpty ||
       _totalCtrl.text.isNotEmpty ||
       _remarksCtrl.text.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> _onBackPressed() async {
    bool hasData = hasDataSync;

    if (!hasData) {
      if (widget.onPop != null) {
        widget.onPop!(false);
        return false;
      }
      return true;
    }

    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFFf59e0b).withAlpha(100), width: 2)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 60),
            SizedBox(height: 16),
            Text('Discard Data?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Any unsaved data entered for the AWB will be permanently lost.\\n\\nDo you want to discard your changes and continue?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 16, height: 1.4),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('STAY', style: TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFFef4444).withAlpha(100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      if (widget.onPop != null) {
        widget.onPop!(false);
        return false;
      }
      return true;
    }
    return false;
  }

  Future<bool> handleBackRequest() async {
    final canPop = await _onBackPressed();
    if (canPop && widget.onPop == null) {
      if (mounted) Navigator.pop(context);
    }
    return canPop;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onPop != null) {
      return _buildFormContent();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(appLanguage.value == 'es' ? 'Añadir Nuevo Air Waybill' : 'Add New Air Waybill', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1e293b),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appLanguage.value == 'es' ? 'Crear Detalles de Air Waybill' : 'Create Air Waybill Details', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double rWidth = constraints.maxWidth - 750; 
                      if (rWidth < 180) rWidth = 180;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          SizedBox(width: 130, child: _buildTextField('AWB Number', _awbNumberCtrl, '123-1234 5678', maxLen: 13, prefixIcon: Icons.numbers_rounded)),
                          SizedBox(width: 200, child: _buildFlightDropdown()),
                          SizedBox(width: 140, child: _buildTextField('Ref ULD', _refUldCtrl, 'AKE12345AA', maxLen: 10, prefixIcon: Icons.inventory_2_rounded)),
                          SizedBox(width: 90, child: _buildTextField('Pieces', _piecesCtrl, '0', isNum: true, prefixIcon: Icons.view_in_ar_rounded)),
                          SizedBox(width: 90, child: _buildTextField('Total', _totalCtrl, '0', isNum: true, prefixIcon: Icons.functions_rounded)),
                          SizedBox(width: 90, child: _buildTextField('Weight', _weightCtrl, '0.0', isNum: true, prefixIcon: Icons.scale_rounded)),
                          SizedBox(width: 180, child: _buildTextField('House Number', _houseCtrl, 'HAWB1, HAWB2...', prefixIcon: Icons.house_rounded)),
                          SizedBox(width: rWidth, child: _buildTextField('Remarks', _remarksCtrl, 'Notas del AWB...', prefixIcon: Icons.note_rounded)),
                          
                          SizedBox(
                            width: 140,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _addLocalAwb,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(25),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                side: BorderSide(color: Colors.white.withAlpha(25)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('+ Add AWB', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 16),

                  // Native table of added AWBs
                  if (_localAwbs.isNotEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5), 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: Builder(
                        builder: (context) {
                          Map<String, List<Map<String, dynamic>>> groupedAwbs = {};
                          for (int i = 0; i < _localAwbs.length; i++) {
                            final a = _localAwbs[i];
                            final groupKey = a['flightLabel'] ?? 'Standalone AWBs';
                            groupedAwbs.putIfAbsent(groupKey, () => []);
                            groupedAwbs[groupKey]!.add({'index': i, 'awb': a});
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedAwbs.entries.map((group) {
                              final groupName = group.key;
                              final groupItems = group.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(10),
                                      border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20)))
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(groupName == 'Standalone AWBs' ? Icons.inventory_2_outlined : Icons.flight_takeoff_rounded, color: const Color(0xFF94a3b8), size: 16),
                                        const SizedBox(width: 8),
                                        Text(groupName, style: const TextStyle(color: Color(0xFFcbd5e1), fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), borderRadius: BorderRadius.circular(4)),
                                          child: Text('${groupItems.length} items', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(_collapsedGroups.contains(groupName) ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94a3b8), size: 20),
                                          onPressed: () {
                                            setState(() {
                                              if (_collapsedGroups.contains(groupName)) {
                                                _collapsedGroups.remove(groupName);
                                              } else {
                                                _collapsedGroups.add(groupName);
                                              }
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!_collapsedGroups.contains(groupName))
                                    ListView.separated(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: groupItems.length,
                                      separatorBuilder: (c, i) => Divider(color: Colors.white.withAlpha(15), height: 1),
                                      itemBuilder: (ctx, i) {
                                        final item = groupItems[i];
                                        final int realIndex = item['index'];
                                        final a = item['awb'];
                                        final awbNum = a['awbNumber'];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(awbNum, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                    if (a['remarks'] != null) const SizedBox(height: 4),
                                                    if (a['remarks'] != null) Text(a['remarks'], style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1, 
                                                child: Text('${a['pieces']}/${a['total']} Pcs', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                                              ),
                                              Expanded(
                                                flex: 1, 
                                                child: Text('${a['weight']} kg', style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                                              ),
                                              if (a['refUld'] != '' && a['refUld'] != null)
                                                Expanded(
                                                  flex: 1, 
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withAlpha(20),
                                                      borderRadius: BorderRadius.circular(4)
                                                    ),
                                                    child: Text(a['refUld'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                                                  ),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Color(0xFFef4444), size: 18),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() => _localAwbs.removeAt(realIndex));
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$awbNum removed'), duration: const Duration(seconds: 1)));
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              );
                            }).toList(),
                          );
                        }
                      ),
                    ),

                ],
              ),
            ),
          ),
        ),
        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            border: Border(top: BorderSide(color: Colors.white.withAlpha(25)))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSavingAll ? null : _saveAllAwbs,
                  icon: _isSavingAll ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 20),
                  label: Text(appLanguage.value == 'es' ? 'Guardar Air Waybills' : 'Save Air Waybills', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFlightDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reference Flight', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10), 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: Colors.white.withAlpha(25))
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedFlight,
              hint: Text('No Flight (Standalone)', style: TextStyle(color: Colors.white.withAlpha(150))),
              dropdownColor: const Color(0xFF1e293b),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              menuMaxHeight: 300,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('No Flight (Standalone)')),
                ..._flights.map((f) => DropdownMenuItem<String?>(
                  value: f['id'].toString(),
                  child: Text('${f['carrier']} ${f['number']} (${f['date-arrived']})', overflow: TextOverflow.ellipsis),
                ))
              ],
              onChanged: (v) => setState(() => _selectedFlight = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {bool isNum = false, int? maxLen, IconData? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: ctrl,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            maxLength: maxLen,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (ctrl == _refUldCtrl) ? (v) => _refUld = v : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withAlpha(76), fontSize: 13),
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1), width: 1.5)),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: Colors.white.withAlpha(150)) : null,
            ),
          ),
        ),
      ],
    );
  }
}
"""

with open("c:\\App New\\lib\\screens\\add_awb_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
