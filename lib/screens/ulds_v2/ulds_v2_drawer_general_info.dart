import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;

class UldsV2GeneralInfo extends StatefulWidget {
  final Map<String, dynamic> uld;
  final bool dark;
  final String flightDisplay;

  const UldsV2GeneralInfo({
    super.key,
    required this.uld,
    required this.dark,
    required this.flightDisplay,
  });

  @override
  State<UldsV2GeneralInfo> createState() => _UldsV2GeneralInfoState();
}

enum FieldType { text, number, status, toggle }

class _UldsV2GeneralInfoState extends State<UldsV2GeneralInfo> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _numberCtrl;
  late TextEditingController _piecesCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _statusCtrl;
  late TextEditingController _remarksCtrl;
  bool _isPriority = false;
  bool _isBreak = false;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(text: widget.uld['uld_number']?.toString());
    _piecesCtrl = TextEditingController(text: widget.uld['pieces_total']?.toString() ?? '0');
    _weightCtrl = TextEditingController(text: widget.uld['weight_total']?.toString() ?? '0');
    _statusCtrl = TextEditingController(text: widget.uld['status']?.toString() ?? 'Waiting');
    _remarksCtrl = TextEditingController(text: widget.uld['remarks']?.toString());
    _isPriority = widget.uld['is_priority'] == true;
    _isBreak = widget.uld['is_break'] == true;
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final updates = {
        'uld_number': _numberCtrl.text,
        'pieces_total': int.tryParse(_piecesCtrl.text) ?? 0,
        'weight_total': double.tryParse(_weightCtrl.text) ?? 0.0,
        'status': _statusCtrl.text,
        'remarks': _remarksCtrl.text,
        'is_priority': _isPriority,
        'is_break': _isBreak,
      };

      await Supabase.instance.client
          .from('ulds')
          .update(updates)
          .eq('id_uld', widget.uld['id_uld']);
          
      widget.uld['uld_number'] = updates['uld_number'];
      widget.uld['pieces_total'] = updates['pieces_total'];
      widget.uld['weight_total'] = updates['weight_total'];
      widget.uld['status'] = updates['status'];
      widget.uld['remarks'] = updates['remarks'];
      widget.uld['is_priority'] = updates['is_priority'];
      widget.uld['is_break'] = updates['is_break'];

      setState(() => _isEditing = false);
    } catch (e) {
      debugPrint('Error updating ULD: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving changes: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildEditor(String label, TextEditingController ctrl, FieldType type, Color textP) {
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final fillC = widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5);

    if (type == FieldType.status) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: fillC, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: ['Waiting', 'Received', 'Pending', 'Checked', 'Ready', 'Delivered'].contains(ctrl.text) ? ctrl.text : 'Waiting',
            dropdownColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600),
            items: const [
              DropdownMenuItem(value: 'Waiting', child: Text('Waiting')),
              DropdownMenuItem(value: 'Received', child: Text('Received')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Checked', child: Text('Checked')),
              DropdownMenuItem(value: 'Ready', child: Text('Ready')),
              DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => ctrl.text = v);
            },
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 36,
        child: TextField(
          controller: ctrl,
          keyboardType: type == FieldType.number ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            fillColor: fillC,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: const Color(0xFF6366f1))),
          ),
        ),
      );
    }
  }

  Widget _buildToggleEditor(String label, bool value, ValueChanged<bool> onChanged, Color textP) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: value,
          dropdownColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          isExpanded: true,
          style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600),
          items: const [
            DropdownMenuItem(value: true, child: Text('Yes')),
            DropdownMenuItem(value: false, child: Text('No')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildModernDetail(String label, dynamic value, IconData icon, Color textP, Color textS, {TextEditingController? controller, FieldType type = FieldType.text, bool? toggleValue, ValueChanged<bool>? onToggleChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: textS, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        if (!_isEditing)
          Text(
            value?.toString().isNotEmpty == true ? value.toString() : '-',
            style: TextStyle(
              color: textP,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (type == FieldType.toggle)
          _buildToggleEditor(label, toggleValue ?? false, onToggleChanged ?? (_) {}, textP)
        else if (controller != null)
          _buildEditor(label, controller, type, textP)
        else
          Text(value?.toString().isNotEmpty == true ? value.toString() : '-', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: widget.dark ? Colors.black26 : Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, size: 16, color: widget.dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      appLanguage.value == 'es' ? 'Información General' : 'General Information',
                      style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    if (widget.flightDisplay.isNotEmpty && widget.flightDisplay != 'Standalone') ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFFe0e7ff),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flight_takeoff_rounded, size: 12, color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5)),
                            const SizedBox(width: 4),
                            Text(
                              widget.flightDisplay,
                              style: TextStyle(color: widget.dark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, color: _isEditing ? Colors.green : textS, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _isEditing ? _saveChanges : () => setState(() {
                    _isEditing = true;
                    _numberCtrl.text = widget.uld['uld_number']?.toString() ?? '';
                    _piecesCtrl.text = widget.uld['pieces_total']?.toString() ?? '0';
                    _weightCtrl.text = widget.uld['weight_total']?.toString() ?? '0';
                    _statusCtrl.text = widget.uld['status']?.toString() ?? 'Waiting';
                    _isPriority = widget.uld['is_priority'] == true;
                    _isBreak = widget.uld['is_break'] == true;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: _buildModernDetail('ULD Number', widget.uld['uld_number'], Icons.inventory_2_outlined, textP, textS, controller: _numberCtrl, type: FieldType.text)),
              const SizedBox(width: 12),
              Expanded(child: _buildModernDetail('Status', widget.uld['status'], Icons.info_outline_rounded, textP, textS, controller: _statusCtrl, type: FieldType.status)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildModernDetail('Pieces Total', widget.uld['pieces_total'], Icons.grid_view_rounded, textP, textS, controller: _piecesCtrl, type: FieldType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildModernDetail('Weight Total (kg)', widget.uld['weight_total'], Icons.scale_rounded, textP, textS, controller: _weightCtrl, type: FieldType.number)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildModernDetail(
                  'Break', 
                  widget.uld['is_break'] == true ? 'Yes' : 'No', 
                  Icons.call_split_rounded, 
                  textP, 
                  textS,
                  type: FieldType.toggle,
                  toggleValue: _isBreak,
                  onToggleChanged: (val) => setState(() => _isBreak = val),
               )),
               const SizedBox(width: 12),
              Expanded(child: _buildModernDetail(
                  'Priority', 
                  widget.uld['is_priority'] == true ? 'Yes' : 'No', 
                  Icons.star_border_rounded, 
                  textP, 
                  textS,
                  type: FieldType.toggle,
                  toggleValue: _isPriority,
                  onToggleChanged: (val) => setState(() => _isPriority = val),
               )),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernDetail('Remarks', widget.uld['remarks']?.toString() ?? '-', Icons.notes, textP, textS, controller: _remarksCtrl),
        ],
      ),
    );
  }
}
