import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;

class AddAwbScreen extends StatefulWidget {
  final String? initialFlightId;
  final String? initialUld;
  final Function(bool)? onPop;

  const AddAwbScreen({super.key, this.initialFlightId, this.initialUld, this.onPop});

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
        const SnackBar(content: Text('AWB Number & Total pieces are required.')),
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
          const SnackBar(content: Text('✅ AWB successfully saved'), backgroundColor: Colors.green),
        );
        if (widget.onPop != null) {
          widget.onPop!(true);
        } else {
          Navigator.pop(context, true);
        }
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
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final primaryColor = dark ? const Color(0xFF8b5cf6) : const Color(0xFF6366f1);

        final content = Column(
          children: [
            Expanded(
              child: Form(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderC),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.document_scanner_rounded, color: textP, size: 20),
                                const SizedBox(width: 8),
                                Text('Air Waybill Information', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildTextField('AWB Number', _awbNumberCtrl, dark, '123-1234 5678', maxLen: 13, prefixIcon: Icons.numbers_rounded)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Reference Flight', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB), 
                                          borderRadius: BorderRadius.circular(12), 
                                          border: Border.all(color: borderC)
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String?>(
                                            value: _selectedFlight,
                                            hint: Text('No Flight (Standalone)', style: TextStyle(color: dark ? Colors.white.withAlpha(150) : const Color(0xFF6B7280))),
                                            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                            isExpanded: true,
                                            style: TextStyle(color: textP, fontSize: 13),
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
                                      Text('Ref ULD', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 48,
                                        child: TextField(
                                          controller: _refUldCtrl,
                                          onChanged: (v) => _refUld = v,
                                          maxLength: 10,
                                          style: TextStyle(color: textP, fontSize: 13),
                                          decoration: InputDecoration(
                                            hintText: 'AKE12345AA',
                                            hintStyle: TextStyle(color: dark ? Colors.white.withAlpha(76) : const Color(0xFF9CA3AF), fontSize: 13),
                                            filled: true,
                                            fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                            counterText: '',
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                                            prefixIcon: Icon(Icons.inventory_2_rounded, size: 18, color: dark ? Colors.white.withAlpha(150) : const Color(0xFF6B7280)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('Pieces', _piecesCtrl, dark, '0', isNum: true, prefixIcon: Icons.view_in_ar_rounded)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('Total', _totalCtrl, dark, '0', isNum: true, prefixIcon: Icons.functions_rounded)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('Weight', _weightCtrl, dark, '0.0', isNum: true, prefixIcon: Icons.scale_rounded)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                 Expanded(child: _buildTextField('House Number', _houseCtrl, dark, 'HAWB1, HAWB2...', prefixIcon: Icons.house_rounded)),
                                 const SizedBox(width: 16),
                                 Expanded(flex: 2, child: _buildTextField('Remarks', _remarksCtrl, dark, 'Notas del AWB...', prefixIcon: Icons.note_rounded)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveAWB,
                            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_rounded),
                            label: Text(appLanguage.value == 'es' ? 'Guardar AWB' : 'Save AWB', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        if (widget.onPop == null) {
          return Scaffold(
            backgroundColor: dark ? const Color(0xFF0f172a) : const Color(0xFFF3F4F6),
            appBar: AppBar(
              title: Text(appLanguage.value == 'es' ? 'Añadir Nuevo AWB' : 'Add New AWB', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.w600)),
              backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: textP),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderC, height: 1)),
            ),
            body: Padding(padding: const EdgeInsets.all(24), child: content),
          );
        }

        return content;
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, bool dark, String hint, {bool isNum = false, int? maxLen, IconData? prefixIcon}) {
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final primaryColor = dark ? const Color(0xFF8b5cf6) : const Color(0xFF6366f1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: ctrl,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            maxLength: maxLen,
            style: TextStyle(color: textP, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: dark ? Colors.white.withAlpha(76) : const Color(0xFF9CA3AF), fontSize: 13),
              filled: true,
              fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: dark ? Colors.white.withAlpha(150) : const Color(0xFF6B7280)) : null,
            ),
          ),
        ),
      ],
    );
  }
}
