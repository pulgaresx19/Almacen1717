import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;

class FlightsV2GeneralInfo extends StatefulWidget {
  final Map<String, dynamic> flight;
  final bool dark;

  const FlightsV2GeneralInfo({
    super.key,
    required this.flight,
    required this.dark,
  });

  @override
  State<FlightsV2GeneralInfo> createState() => _FlightsV2GeneralInfoState();
}

enum FieldType { text, number, status, date }

class _FlightsV2GeneralInfoState extends State<FlightsV2GeneralInfo> {
  // ... (keep state variables)
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _carrierCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _statusCtrl;
  late TextEditingController _cantBreakCtrl;
  late TextEditingController _cantNoBreakCtrl;
  late TextEditingController _startBreakCtrl;
  late TextEditingController _endBreakCtrl;
  late TextEditingController _firstTruckCtrl;
  late TextEditingController _lastTruckCtrl;
  late TextEditingController _remarksCtrl;
  late TextEditingController _timeDelayedCtrl;
  bool _timeDelayError = false;

  @override
  void initState() {
    super.initState();
    _carrierCtrl = TextEditingController(text: widget.flight['carrier']?.toString());
    _numberCtrl = TextEditingController(text: widget.flight['number']?.toString());
    _dateCtrl = TextEditingController(text: widget.flight['date']?.toString());
    _statusCtrl = TextEditingController(text: widget.flight['status']?.toString() ?? 'Waiting');
    _cantBreakCtrl = TextEditingController(text: widget.flight['cant_break']?.toString() ?? '0');
    _cantNoBreakCtrl = TextEditingController(text: widget.flight['cant_nobreak']?.toString() ?? '0');
    _startBreakCtrl = TextEditingController(text: widget.flight['start_break']?.toString());
    _endBreakCtrl = TextEditingController(text: widget.flight['end_break']?.toString());
    _firstTruckCtrl = TextEditingController(text: widget.flight['first_truck']?.toString());
    _lastTruckCtrl = TextEditingController(text: widget.flight['last_truck']?.toString());
    _remarksCtrl = TextEditingController(text: widget.flight['remarks']?.toString());
    _timeDelayedCtrl = TextEditingController(text: widget.flight['time_delay']?.toString());
  }

  Future<void> _saveChanges() async {
    if (_statusCtrl.text == 'Delayed' && (_timeDelayedCtrl.text.isEmpty || _timeDelayedCtrl.text == '-' || _timeDelayedCtrl.text == 'null')) {
      setState(() => _timeDelayError = true);
      return;
    }
    setState(() => _timeDelayError = false);

    setState(() => _isLoading = true);
    try {
      final updates = {
        'carrier': _carrierCtrl.text,
        'number': _numberCtrl.text,
        'date': _dateCtrl.text.isEmpty || _dateCtrl.text == '-' ? null : _dateCtrl.text,
        'status': _statusCtrl.text,
        'cant_break': int.tryParse(_cantBreakCtrl.text) ?? 0,
        'cant_nobreak': int.tryParse(_cantNoBreakCtrl.text) ?? 0,
        'start_break': _startBreakCtrl.text.isEmpty || _startBreakCtrl.text == '-' ? null : _startBreakCtrl.text,
        'end_break': _endBreakCtrl.text.isEmpty || _endBreakCtrl.text == '-' ? null : _endBreakCtrl.text,
        'first_truck': _firstTruckCtrl.text.isEmpty || _firstTruckCtrl.text == '-' || _firstTruckCtrl.text == 'null' ? null : _firstTruckCtrl.text,
        'last_truck': _lastTruckCtrl.text.isEmpty || _lastTruckCtrl.text == '-' || _lastTruckCtrl.text == 'null' ? null : _lastTruckCtrl.text,
        'time_delay': _statusCtrl.text != 'Delayed' ? null : (_timeDelayedCtrl.text.isEmpty || _timeDelayedCtrl.text == '-' || _timeDelayedCtrl.text == 'null' ? null : _timeDelayedCtrl.text),
        'remarks': _remarksCtrl.text,
      };

      await Supabase.instance.client
          .from('flights')
          .update(updates)
          .eq('id_flight', widget.flight['id_flight']);
          
      widget.flight['carrier'] = updates['carrier'];
      widget.flight['number'] = updates['number'];
      widget.flight['date'] = updates['date'];
      widget.flight['status'] = updates['status'];
      widget.flight['cant_break'] = updates['cant_break'];
      widget.flight['cant_nobreak'] = updates['cant_nobreak'];
      widget.flight['start_break'] = updates['start_break'];
      widget.flight['end_break'] = updates['end_break'];
      widget.flight['first_truck'] = updates['first_truck'];
      widget.flight['last_truck'] = updates['last_truck'];
      widget.flight['time_delay'] = updates['time_delay'];
      widget.flight['remarks'] = updates['remarks'];

      setState(() => _isEditing = false);
    } catch (e) {
      debugPrint('Error updating: $e');
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

  Widget _formatTimestamp(String? val, Color textP, Color textS) {
    if (val == null || val.isEmpty || val == '-') return Text('--:--', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600));
    try {
      final dt = DateTime.parse(val).toLocal();
      final timeStr = DateFormat('hh:mm a').format(dt);
      final dateStr = DateFormat('MM/dd').format(dt);
      return RichText(
        text: TextSpan(
          text: timeStr,
          style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
          children: [
            TextSpan(
              text: ' ($dateStr)',
              style: TextStyle(color: widget.dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), fontSize: 12, fontWeight: FontWeight.w500),
            )
          ]
        ),
      );
    } catch (_) {
      return Text(val, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600));
    }
  }

  Widget _buildEditor(String label, TextEditingController ctrl, FieldType type, Color textP, {bool isError = false}) {
    final borderC = isError ? Colors.redAccent.withAlpha(150) : (widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB));
    final fillC = isError ? Colors.redAccent.withAlpha(20) : (widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5));

    if (type == FieldType.status) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: fillC, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: ['Waiting', 'Received', 'Pending', 'Checked', 'Ready', 'Delayed', 'Canceled'].contains(ctrl.text) ? ctrl.text : 'Waiting',
            dropdownColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600),
            items: const [
              DropdownMenuItem(value: 'Waiting', child: Text('Waiting')),
              DropdownMenuItem(value: 'Received', child: Text('Received')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Checked', child: Text('Checked')),
              DropdownMenuItem(value: 'Ready', child: Text('Ready')),
              DropdownMenuItem(value: 'Delayed', child: Text('Delayed')),
              DropdownMenuItem(value: 'Canceled', child: Text('Canceled')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => ctrl.text = v);
            },
          ),
        ),
      );
    } else if (type == FieldType.date) {
      return InkWell(
        onTap: () async {
          DateTime initialDate = DateTime.now();
          if (ctrl.text.isNotEmpty && ctrl.text != '-') {
            try { initialDate = DateTime.parse(ctrl.text).toLocal(); } catch (_) {}
          }
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            if (!mounted) return;
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(initialDate),
            );
            if (pickedTime != null) {
               final newDt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
               setState(() {
                 ctrl.text = newDt.toUtc().toIso8601String();
                 _timeDelayError = false;
               });
            }
          }
        },
        child: Container(
          height: 36,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: fillC, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
          child: _formatTimestamp(ctrl.text, textP, textP.withAlpha(150)),
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

  Widget _buildModernDetail(String label, dynamic value, IconData icon, Color textP, Color textS, {TextEditingController? controller, FieldType type = FieldType.text, bool isError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isError ? Colors.redAccent : (widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280))),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isError ? Colors.redAccent : textS, fontSize: 11)),
            if (isError) ...[
              const Spacer(),
              Text(appLanguage.value == 'es' ? '* Requerido' : '* Required', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _isEditing && controller != null
            ? _buildEditor(label, controller, type, textP, isError: isError)
            : (value is Widget 
                ? value 
                : Text(value.toString().isNotEmpty ? value.toString() : '-', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600))),
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
              Icon(Icons.flight_takeoff_rounded, size: 16, color: widget.dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appLanguage.value == 'es' ? 'Información General' : 'General Information',
                  style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              if (_isLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, color: _isEditing ? Colors.green : textS, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _isEditing ? _saveChanges : () => setState(() => _isEditing = true),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildModernDetail('Carrier', widget.flight['carrier']?.toString() ?? '-', Icons.business, textP, textS, controller: _carrierCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail('Number', widget.flight['number']?.toString() ?? '-', Icons.tag, textP, textS, controller: _numberCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail(appLanguage.value == 'es' ? 'Llegada' : 'Arrive Time', _formatTimestamp(widget.flight['date']?.toString(), textP, textS), Icons.schedule, textP, textS, controller: _dateCtrl, type: FieldType.date)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail(appLanguage.value == 'es' ? 'Estado' : 'Status', widget.flight['status']?.toString() ?? 'Waiting', Icons.info_outline, textP, textS, controller: _statusCtrl, type: FieldType.status)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail('Break ULD', widget.flight['cant_break']?.toString() ?? '0', Icons.inventory_2_outlined, textP, textS, controller: _cantBreakCtrl, type: FieldType.number)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail('No-Break ULD', widget.flight['cant_nobreak']?.toString() ?? '0', Icons.all_inbox, textP, textS, controller: _cantNoBreakCtrl, type: FieldType.number)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildModernDetail('First Truck', _formatTimestamp(widget.flight['first_truck']?.toString(), textP, textS), Icons.local_shipping_outlined, textP, textS, controller: _firstTruckCtrl, type: FieldType.date)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail('Last Truck', _formatTimestamp(widget.flight['last_truck']?.toString(), textP, textS), Icons.local_shipping, textP, textS, controller: _lastTruckCtrl, type: FieldType.date)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail('Start Break', _formatTimestamp(widget.flight['start_break']?.toString(), textP, textS), Icons.play_circle_outline, textP, textS, controller: _startBreakCtrl, type: FieldType.date)),
              const SizedBox(width: 8),
              Expanded(child: _buildModernDetail('End Break', _formatTimestamp(widget.flight['end_break']?.toString(), textP, textS), Icons.stop_circle_outlined, textP, textS, controller: _endBreakCtrl, type: FieldType.date)),
              const SizedBox(width: 8),
              Expanded(
                flex: (_statusCtrl.text == 'Delayed' || (widget.flight['status'] == 'Delayed')) ? 1 : 2,
                child: _buildModernDetail('Remarks', widget.flight['remarks']?.toString() ?? '-', Icons.notes, textP, textS, controller: _remarksCtrl),
              ),
              if (_statusCtrl.text == 'Delayed' || (widget.flight['status'] == 'Delayed')) ...[
                const SizedBox(width: 8),
                Expanded(child: _buildModernDetail(appLanguage.value == 'es' ? 'Hora Delay' : 'Delayed Time', _formatTimestamp(widget.flight['time_delay']?.toString(), const Color(0xFFf97316), const Color(0xFFea580c)), Icons.history_toggle_off_rounded, const Color(0xFFf97316), const Color(0xFFea580c), controller: _timeDelayedCtrl, type: FieldType.date, isError: _timeDelayError)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

