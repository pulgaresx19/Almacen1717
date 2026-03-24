import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddUldScreen extends StatefulWidget {
  final Function(bool)? onPop;
  final bool isInline;
  const AddUldScreen({super.key, this.onPop, this.isInline = false});

  @override
  State<AddUldScreen> createState() => _AddUldScreenState();
}

class _AddUldScreenState extends State<AddUldScreen> {
  final _uldNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  String _status = 'Waiting';
  String? _selectedFlight;
  bool _isPriority = false;
  bool _isBreak = false;
  bool _isSaving = false;

  List<Map<String, dynamic>> _flights = [];
  final List<Map<String, dynamic>> _localUlds = [];

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    try {
      final res = await Supabase.instance.client.from('Flight').select('id, carrier, number, date-arrived').order('created_at');
      if (mounted) {
        setState(() {
          _flights = List.from(res);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _uldNumberCtrl.dispose();
    _piecesCtrl.dispose();
    _weightCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _addLocalUld() {
    if (_uldNumberCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ULD Number es obligatorio')));
      return;
    }
    setState(() {
      _localUlds.add({
        'uldNumber': _uldNumberCtrl.text.toUpperCase(),
        'pieces': _piecesCtrl.text.isNotEmpty ? int.tryParse(_piecesCtrl.text) : 0,
        'weight': _weightCtrl.text.isNotEmpty ? double.tryParse(_weightCtrl.text) : 0.0,
        'remarks': _remarksCtrl.text,
        'priority': _isPriority,
        'break': _isBreak,
        'status': _status,
        'flight_id': _selectedFlight,
      });

      _uldNumberCtrl.clear();
      _piecesCtrl.clear();
      _weightCtrl.clear();
      _remarksCtrl.clear();
      _isPriority = false;
      _isBreak = false;
      _status = 'Waiting';
      _selectedFlight = null;
    });
  }

  Future<void> _saveAllUlds() async {
    if (_localUlds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añade al menos 1 ULD a la lista.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      List<Map<String, dynamic>> payloads = [];
      for (var uld in _localUlds) {
        String? carrier;
        String? number;
        String? date;

        if (uld['flight_id'] != null) {
          final f = _flights.firstWhere((x) => x['id'].toString() == uld['flight_id'], orElse: () => {});
          if (f.isNotEmpty) {
            carrier = f['carrier'];
            number = f['number'];
            date = f['date-arrived'];
          }
        }

        payloads.add({
          'ULD-number': uld['uldNumber'],
          'pieces': uld['pieces'],
          'weight': uld['weight'],
          'isPriority': uld['priority'],
          'isBreak': uld['break'],
          'status': uld['status'],
          'remarks': uld['remarks'],
          'refCarrier': carrier,
          'refNumber': number,
          'refDate': date,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await Supabase.instance.client.from('ULD').insert(payloads);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ULDs guardados con éxito'), backgroundColor: Colors.green));
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInline) {
      return _buildFormContent();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: const Text('Add New ULDs'),
        backgroundColor: const Color(0xFF1e293b),
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
                  const Text('ULD Details & Assignment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double rWidth = constraints.maxWidth - 664; // 110+200+70+70+65+65+100 + 84gaps = 764.
                      if (rWidth < 180) rWidth = 180;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          SizedBox(width: 110, child: _buildTextField('ULD Number', _uldNumberCtrl, 'AKE123...', maxLen: 10)),
                          SizedBox(width: 200, child: _buildFlightDropdown()),
                          SizedBox(width: 70, child: _buildTextField('Pieces', _piecesCtrl, '0', isNum: true)),
                          SizedBox(width: 70, child: _buildTextField('Weight', _weightCtrl, '0.0', isNum: true)),
                          SizedBox(width: 100, child: _buildSimpleDropdown('Status', _status, ['Waiting', 'Received', 'Pending', 'Checked', 'Saved', 'Ready'], (v) => setState(() => _status = v!))),
                          SizedBox(width: rWidth, child: _buildTextField('Remarks', _remarksCtrl, 'Notas adicionales...')),
                          SizedBox(
                            width: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  const Text('Priority?', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
                                  Switch(value: _isPriority, activeThumbColor: const Color(0xFF6366f1), onChanged: (v) => setState(() => _isPriority = v)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  const Text('Break?', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
                                  Switch(value: _isBreak, activeThumbColor: const Color(0xFF6366f1), onChanged: (v) => setState(() => _isBreak = v)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _addLocalUld,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(25),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                side: BorderSide(color: Colors.white.withAlpha(25)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('+ Add ULD', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      );
                    }
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 16),

                  // Native table of added ULDs
                  if (_localUlds.isNotEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5), 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: Column(
                        children: _localUlds.asMap().entries.map((entry) {
                          int i = entry.key;
                          var u = entry.value;
                          return Container(
                            color: Colors.white.withAlpha(15),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  u['remarks'] != null && u['remarks'].toString().isNotEmpty
                                    ? '${i + 1}. ULD: ${u['uldNumber']} | Pcs: ${u['pieces']} | Wgt: ${u['weight']} | Status: ${u['status']} | Rem: ${u['remarks']}'
                                    : '${i + 1}. ULD: ${u['uldNumber']} | Pcs: ${u['pieces']} | Wgt: ${u['weight']} | Status: ${u['status']}', 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() => _localUlds.removeAt(i));
                                  },
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Bottom Pinned Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0f172a),
            border: Border(top: BorderSide(color: Colors.white.withAlpha(25))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (widget.onPop != null) {
                      widget.onPop!(false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF94a3b8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CANCELAR', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAllUlds,
                  icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_rounded),
                  label: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('GUARDAR TODOS LOS ULDs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {bool isNum = false, int? maxLen, bool disabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: !disabled,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          maxLength: maxLen,
          style: TextStyle(color: disabled ? Colors.white.withAlpha(120) : Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withAlpha(76), fontSize: 12),
            filled: true,
            fillColor: disabled ? Colors.white.withAlpha(5) : Colors.white.withAlpha(13),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8b5cf6), width: 1.5)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(10))),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDropdown(String label, String val, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              isExpanded: true,
              dropdownColor: const Color(0xFF1e293b),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFcbd5e1), size: 20),
              items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reference Flight', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedFlight,
              hint: const Text('Standalone ULD', style: TextStyle(color: Colors.white, fontSize: 12)),
              dropdownColor: const Color(0xFF1e293b),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFcbd5e1), size: 20),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Standalone ULD')),
                ..._flights.map((f) => DropdownMenuItem<String?>(
                  value: f['id'].toString(),
                  child: Text('${f['carrier']} ${f['number']} (${f['date-arrived']})'),
                ))
              ],
              onChanged: (v) => setState(() => _selectedFlight = v),
            ),
          ),
        ),
      ],
    );
  }
}
