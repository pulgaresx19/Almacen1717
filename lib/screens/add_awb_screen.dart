import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddAwbScreen extends StatefulWidget {
  final String? initialFlightId;
  final String? initialUld;
  const AddAwbScreen({super.key, this.initialFlightId, this.initialUld});

  @override
  State<AddAwbScreen> createState() => _AddAwbScreenState();
}

class _AddAwbScreenState extends State<AddAwbScreen> {
  final _awbNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  String? _selectedFlight;
  String _refUld = '';
  bool _isSaving = false;
  late final TextEditingController _refUldCtrl;

  List<Map<String, dynamic>> _flights = [];

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
    _awbNumberCtrl.dispose();
    _piecesCtrl.dispose();
    _totalCtrl.dispose();
    _weightCtrl.dispose();
    _houseCtrl.dispose();
    _remarksCtrl.dispose();
    _refUldCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAWB() async {
    if (_awbNumberCtrl.text.isEmpty || _totalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AWB Number y Total son obligatorios')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dataAwb = {
        'flightID': _selectedFlight ?? '0',
        'refULD': _refUld.toUpperCase(),
        'pieces': int.tryParse(_piecesCtrl.text) ?? 1,
        'weight': double.tryParse(_weightCtrl.text) ?? 0.0,
        'house': _houseCtrl.text.toUpperCase(),
        'remarks': _remarksCtrl.text,
        'status': 'Received',
      };

      final payload = {
        'AWB-number': _awbNumberCtrl.text.toUpperCase(),
        'total': int.tryParse(_totalCtrl.text) ?? 1,
        'data-AWB': dataAwb,
        'data-coordinator': {},
        'data-location': {},
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('AWB').insert(payload);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ AWB registrado con éxito'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: const Text('Add New AWB'),
        backgroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ingrese el nuevo Air Waybill libremente a la base de datos.', style: TextStyle(color: Color(0xFF94a3b8))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildTextField('AWB Number', _awbNumberCtrl, '123-1234 5678', maxLen: 13)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reference Flight', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedFlight,
                              hint: const Text('No Flight (Standalone)', style: TextStyle(color: Colors.white)),
                              dropdownColor: const Color(0xFF1e293b),
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('No Flight (Standalone)')),
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ref ULD', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _refUldCtrl,
                          onChanged: (v) => _refUld = v,
                          maxLength: 10,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'AKE12345AA',
                            hintStyle: TextStyle(color: Colors.white.withAlpha(76)),
                            filled: true,
                            fillColor: Colors.white.withAlpha(10),
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8b5cf6), width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Pieces', _piecesCtrl, '0', isNum: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Total', _totalCtrl, '0', isNum: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Weight', _weightCtrl, '0.0', isNum: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildTextField('House Number', _houseCtrl, 'HAWB1, HAWB2...')),
                   const SizedBox(width: 16),
                   Expanded(flex: 2, child: _buildTextField('Remarks', _remarksCtrl, 'Notas del AWB...')),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAWB,
                  icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_rounded),
                  label: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar AWB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {bool isNum = false, int? maxLen}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          maxLength: maxLen,
           style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
             hintStyle: TextStyle(color: Colors.white.withAlpha(76)),
            filled: true,
             fillColor: Colors.white.withAlpha(13),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
             enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF8b5cf6), width: 1.5)),
          ),
        ),
      ],
    );
  }
}
