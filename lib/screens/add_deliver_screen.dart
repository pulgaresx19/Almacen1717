import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;

class AddDeliverScreen extends StatefulWidget {
  final Function(bool)? onPop;

  const AddDeliverScreen({super.key, this.onPop});

  @override
  State<AddDeliverScreen> createState() => AddDeliverScreenState();
}

class AddDeliverScreenState extends State<AddDeliverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _truckCompanyCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _doorCtrl = TextEditingController();
  final _idPickupCtrl = TextEditingController();
  final _typeCtrl = TextEditingController(text: 'Walk-in');
  final _timeCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _searchAwbCtrl = TextEditingController();

  bool _isPriority = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _allAwbs = [];
  final List<Map<String, dynamic>> _selectedAwbs = [];
  final List<Map<String, dynamic>> _importAwbs = [];

  final _importAwbNumberCtrl = TextEditingController();
  final _importPiecesCtrl = TextEditingController();
  final _importTotalCtrl = TextEditingController();
  final _importWeightCtrl = TextEditingController();
  final _importHouseCtrl = TextEditingController();
  final _importRemarksCtrl = TextEditingController();
  bool _importTotalLocked = false;
  final Set<String> _expandedImports = {};

  bool _isLoadingAwbs = true;

  @override
  void initState() {
    super.initState();
    _typeCtrl.text = 'Walk-in';
    _timeCtrl.text = 'NOW';
    _fetchAwbs();
  }

  Future<void> _fetchAwbs() async {
    try {
      final res = await Supabase.instance.client.from('AWB').select();
      if (mounted) {
        setState(() {
          _allAwbs = List<Map<String, dynamic>>.from(res);
          _isLoadingAwbs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAwbs = false);
    }
  }

  bool get hasDataSync {
    return _truckCompanyCtrl.text.isNotEmpty || 
           _driverCtrl.text.isNotEmpty || 
           _doorCtrl.text.isNotEmpty || 
           _idPickupCtrl.text.isNotEmpty || 
           _selectedAwbs.isNotEmpty ||
           _importAwbs.isNotEmpty;
  }

  Future<bool> handleBackRequest() async {
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
            'Any unsaved data entered for the Delivery will be permanently lost.\n\nDo you want to discard your changes and continue?',
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

  @override
  void dispose() {
    _truckCompanyCtrl.dispose();
    _driverCtrl.dispose();
    _doorCtrl.dispose();
    _idPickupCtrl.dispose();
    _typeCtrl.dispose();
    _timeCtrl.dispose();
    _remarksCtrl.dispose();
    _searchAwbCtrl.dispose();
    _importAwbNumberCtrl.dispose();
    _importPiecesCtrl.dispose();
    _importTotalCtrl.dispose();
    _importWeightCtrl.dispose();
    _importHouseCtrl.dispose();
    _importRemarksCtrl.dispose();
    super.dispose();
  }

  void _addImportAwb() {
    String? missingField;
    if (_importAwbNumberCtrl.text.trim().isEmpty) {
      missingField = 'AWB Number';
    } else if (_importPiecesCtrl.text.trim().isEmpty) {
      missingField = 'Pieces';
    } else if (_importTotalCtrl.text.trim().isEmpty) {
      missingField = 'Total';
    }

    if (missingField != null) {
      _showMissingFieldAlert(missingField);
      return;
    }

    setState(() {
      _importAwbs.add({
         'awbNumber': _importAwbNumberCtrl.text.trim().toUpperCase(),
         'pieces': int.tryParse(_importPiecesCtrl.text) ?? 1,
         'total': int.tryParse(_importTotalCtrl.text) ?? 1,
         'weight': double.tryParse(_importWeightCtrl.text) ?? 0.0,
         'house': _importHouseCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList(),
         'remarks': _importRemarksCtrl.text.trim().isEmpty ? null : _importRemarksCtrl.text.trim(),
      });
      _importAwbNumberCtrl.clear();
      _importPiecesCtrl.clear();
      _importTotalCtrl.clear();
      _importWeightCtrl.clear();
      _importHouseCtrl.clear();
      _importRemarksCtrl.clear();
      _importTotalLocked = false;
    });
  }

  void _showMissingFieldAlert(String fieldName) {
    showDialog(
      context: context,
      builder: (alertCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withAlpha(50)),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Action Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The field "$fieldName" is missing.\nPlease provide this information to proceed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFcbd5e1),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFef4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(alertCtx),
                child: const Text(
                  'UNDERSTOOD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayload() async {
    if (_truckCompanyCtrl.text.trim().isEmpty) {
      _showMissingFieldAlert('Truck Company');
      return;
    }
    if (_driverCtrl.text.trim().isEmpty) {
      _showMissingFieldAlert('Driver');
      return;
    }
    if (_idPickupCtrl.text.trim().isEmpty) {
      _showMissingFieldAlert('ID Pickup');
      return;
    }

    if (_typeCtrl.text == 'Import') {
      if (_importAwbs.isEmpty) {
        _showMissingFieldAlert('Air Waybills (AWBs)');
        return;
      }
    } else {
      if (_selectedAwbs.isEmpty) {
        _showMissingFieldAlert('Air Waybills (AWBs)');
        return;
      }
    }

    String finalTime = _timeCtrl.text.trim();
    if (_typeCtrl.text == 'Appointment') {
      if (finalTime.isEmpty || finalTime == 'NOW') {
        _showMissingFieldAlert('Time');
        return;
      }
    } else {
      if (finalTime.isEmpty || finalTime == 'NOW') {
        final now = DateTime.now();
        finalTime = DateFormat('hh:mm a').format(now);
      }
    }

    setState(() => _isLoading = true);
    
    String doorText = _doorCtrl.text.trim();
    if (doorText.isEmpty) doorText = 'PENDING';

    try {
      final nowForDate = DateTime.now();
      int hours = 0;
      int minutes = 0;
      if (finalTime.contains(':')) {
        try {
          if (finalTime.toUpperCase().contains('M')) {
            final dtParsed = DateFormat('hh:mm a').parse(finalTime.toUpperCase());
            hours = dtParsed.hour;
            minutes = dtParsed.minute;
          } else {
            final parts = finalTime.split(':');
            hours = int.tryParse(parts[0]) ?? 0;
            minutes = int.tryParse(parts[1]) ?? 0;
          }
        } catch (_) {
          final parts = finalTime.split(':');
          hours = int.tryParse(parts[0]) ?? 0;
          minutes = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
      }
      final timeDeliverDate = DateTime(nowForDate.year, nowForDate.month, nowForDate.day, hours, minutes);

      final payload = {
        'truck-company': _truckCompanyCtrl.text.trim(),
        'driver': _driverCtrl.text.trim(),
        'door': doorText,
        'id-pickup': _idPickupCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'status': 'Waiting',
        'time-deliver': timeDeliverDate.toUtc().toIso8601String(),
        'remarks': _remarksCtrl.text.trim(),
        'isPriority': _isPriority,
        'list-pickup': _typeCtrl.text == 'Import' ? _importAwbs.map((e) => e['awbNumber']?.toString() ?? '').toList() : _selectedAwbs.map((e) => e['AWB-number']?.toString() ?? '').toList(),
      };

      await Supabase.instance.client.from('Delivers').insert(payload);

      if (_typeCtrl.text == 'Import' && _importAwbs.isNotEmpty) {
        Map<String, Map<String, dynamic>> mergedAwbs = {};
        final nowUtc = DateTime.now().toUtc().toIso8601String();
        for (var a in _importAwbs) {
          final num = a['awbNumber'];
          if (!mergedAwbs.containsKey(num)) {
             mergedAwbs[num] = {
               'AWB-number': num,
               'total': a['total'],
               'data-AWB': [],
             };
          }
          (mergedAwbs[num]!['data-AWB'] as List).add({
             'flightID': null,
             'refCarrier': 'WRHS',
             'refNumber': 'IMP',
             'refDate': nowUtc.substring(0, 10),
             'refULD': 'IMPORT',
             'pieces': a['pieces'],
             'weight': a['weight'],
             'remarks': a['remarks'],
             'house_number': a['house'],
             'status': 'Received',
          });
        }
        
        final awbNumbers = mergedAwbs.keys.toList();
        final existingDbAwbs = await Supabase.instance.client.from('AWB').select('AWB-number, data-AWB').inFilter('AWB-number', awbNumbers);
        final existingAwbMap = { for (var e in existingDbAwbs) e['AWB-number'] : e['data-AWB'] };
        
        for (var awbNum in mergedAwbs.keys) {
           if (existingAwbMap.containsKey(awbNum)) {
              var dbData = existingAwbMap[awbNum];
              if (dbData is List) {
                 (mergedAwbs[awbNum]!['data-AWB'] as List).insertAll(0, dbData);
              } else if (dbData is Map) {
                 (mergedAwbs[awbNum]!['data-AWB'] as List).insert(0, dbData);
              }
           }
        }
        
        final finalAwbPayloads = mergedAwbs.values.map((v) {
          final n = v['AWB-number'];
          Map<String, dynamic> out = {
            'AWB-number': n,
            'total': v['total'],
            'data-AWB': v['data-AWB'],
          };
          if (!existingAwbMap.containsKey(n)) {
             out['created_at'] = DateTime.now().toIso8601String();
          }
          return out;
        }).toList();
        
        await Supabase.instance.client.from('AWB').upsert(finalAwbPayloads, onConflict: 'AWB-number');
      }

      if (mounted) {
        await showDialog(
          context: context,
          barrierColor: Colors.black45,
          barrierDismissible: false,
          builder: (ctx) {
            Future.delayed(const Duration(seconds: 2), () {
              if (ctx.mounted) Navigator.pop(ctx);
            });
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF1e293b),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10b981),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appLanguage.value == 'es' ? 'Entrega creada exitosamente' : 'Delivery created successfully',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (mounted && widget.onPop != null) widget.onPop!(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, bool dark, IconData? icon, {String hint = '', int? maxLen, bool uppercase = false, bool capitalizeWords = false, Widget? suffixIcon, int? maxLines = 1, int? minLines, Function(String)? onChanged, bool readOnly = false}) {
    List<TextInputFormatter> formatters = [];
    if (maxLen != null) formatters.add(LengthLimitingTextInputFormatter(maxLen));
    if (uppercase) formatters.add(TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase())));
    if (capitalizeWords) {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        String t = newValue.text;
        String res = '';
        bool capNext = true;
        for (int i = 0; i < t.length; i++) {
          if (t[i] == ' ') {
            res += ' ';
            capNext = true;
          } else {
            res += capNext ? t[i].toUpperCase() : t[i].toLowerCase();
            capNext = false;
          }
        }
        return newValue.copyWith(text: res);
      }));
    }
    
    if (label == 'Pieces' || label == 'Total') {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (label == 'Weight') {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')));
    }
    
    if (label == 'AWB Number') {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        var text = newValue.text;
        text = text.replaceAll(RegExp(r'[^0-9]'), '');
        if (text.length > 11) text = text.substring(0, 11);

        var formatted = '';
        for (int i = 0; i < text.length; i++) {
          if (i == 3) formatted += '-';
          if (i == 7) formatted += ' ';
          formatted += text[i];
        }

        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }));
    }
    if (label == 'Time') {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
        var oldText = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (text.length > 4) text = text.substring(0, 4);

        if (text.length > oldText.length) { // user is adding chars
          if (text.isNotEmpty) {
            int h1 = int.parse(text[0]);
            if (h1 > 2) {
              text = '0$text';
              if (text.length > 4) text = text.substring(0, 4);
            }
          }
          if (text.length >= 2) {
            int h = int.parse(text.substring(0, 2));
            if (h > 23) return oldValue;
          }
          if (text.length >= 3) {
            int m1 = int.parse(text[2]);
            if (m1 > 5) {
              text = '${text.substring(0, 2)}0${text[2]}';
              if (text.length > 4) text = text.substring(0, 4);
            }
          }
          if (text.length >= 4) {
            int m = int.parse(text.substring(2, 4));
            if (m > 59) return oldValue;
          }
        }

        var formatted = '';
        for (int i = 0; i < text.length; i++) {
          if (i == 2) formatted += ':';
          formatted += text[i];
        }

        int offset = formatted.length;
        if (newValue.selection.end < formatted.length && newValue.selection.end >= 0) {
          offset = newValue.selection.end;
          // Jump over colon if necessary
          if (offset == 2 && formatted.length > 2) offset = 3;
        }

        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: offset),
        );
      }));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          keyboardType: label == 'Time' 
              ? TextInputType.datetime 
              : (label == 'Pieces' || label == 'Total' || label == 'Weight' 
                  ? TextInputType.number 
                  : (maxLines == null || maxLines > 1 ? TextInputType.multiline : TextInputType.text)),
          style: TextStyle(color: readOnly ? (dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)) : (dark ? Colors.white : const Color(0xFF111827)), fontSize: 13),
          inputFormatters: formatters.isNotEmpty ? formatters : null,
          textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: dark ? Colors.white.withAlpha(76) : Colors.black.withAlpha(76), fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(bool dark) {
    const types = ['Walk-in', 'Appointment', 'Transfer', 'Import', 'Priority Load'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _typeCtrl.text.isNotEmpty ? _typeCtrl.text : 'Walk-in',
          dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
          style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF)),
          decoration: InputDecoration(
            filled: true,
            fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), width: 1.5),
            ),
          ),
          items: types.map((String val) {
            IconData iconData;
            switch (val) {
              case 'Walk-in': iconData = Icons.directions_walk_rounded; break;
              case 'Appointment': iconData = Icons.calendar_month_rounded; break;
              case 'Transfer': iconData = Icons.swap_horiz_rounded; break;
              case 'Import': iconData = Icons.move_to_inbox_rounded; break;
              case 'Priority Load': iconData = Icons.bolt_rounded; break;
              default: iconData = Icons.circle;
            }
            return DropdownMenuItem(
              value: val,
              child: Row(
                children: [
                  Icon(iconData, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), size: 16),
                  const SizedBox(width: 8),
                  Text(val),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                 _typeCtrl.text = val;
                 if (val == 'Appointment') {
                   if (_timeCtrl.text == 'NOW') _timeCtrl.clear();
                 } else {
                   if (_timeCtrl.text.isEmpty) _timeCtrl.text = 'NOW';
                 }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSelectedAwbsSummary(bool dark) {
    if (_selectedAwbs.isEmpty) {
      return Container(
         decoration: BoxDecoration(
           color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
         ),
         child: Center(
           child: Text(
             appLanguage.value == 'es' ? 'Ningún AWB seleccionado' : 'No AWBs selected',
             style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
           )
         ),
       );
    }

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1e293b) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366f1).withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF6366f1), size: 18),
                const SizedBox(width: 8),
                Text('${_selectedAwbs.length} ${appLanguage.value == 'es' ? 'Seleccionados' : 'Selected'}', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _selectedAwbs.length,
              itemBuilder: (context, index) {
                final awb = _selectedAwbs[index];
                final String awbNumber = awb['AWB-number']?.toString() ?? 'Unknown';

                      // Calculate pieces/weight for display
                      int expectedPieces = 0;
                      double totalWeight = 0.0;
                      if (awb['data-AWB'] is List) {
                        for (var item in awb['data-AWB']) {
                           expectedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
                           totalWeight += double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
                        }
                      } else if (awb['data-AWB'] is Map) {
                           expectedPieces += int.tryParse(awb['data-AWB']['pieces']?.toString() ?? '0') ?? 0;
                           totalWeight += double.tryParse(awb['data-AWB']['weight']?.toString() ?? '0') ?? 0.0;
                      }
                      
                      final totalVal = awb['total']?.toString() ?? '0';
                      final weightStr = totalWeight.toString().replaceAll(RegExp(r'\.$|\.0$'), '');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(10) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                        child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(awbNumber, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Pcs: $expectedPieces', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Tot: $totalVal', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text('Wgt: ${weightStr}kg', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _selectedAwbs.removeWhere((item) => item['AWB-number'] == awbNumber);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting') || s.contains('espera')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('pending') || s.contains('pendiente')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (s.contains('completed') || s.contains('completado') || s.contains('ready') || s.contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('received') || s.contains('recibido') || s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('checked')){
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
    }

    return Container(
      width: 76,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status, 
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAwbDrawer(BuildContext context, Map<String, dynamic> u, bool dark, int receivedPieces, int expectedPieces, String status) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        final Set<int> expandedCards = {};

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBuilder) {
            String formatChicagoTime(String? timeStr) {
               if (timeStr == null) return '-';
               final dt = DateTime.tryParse(timeStr);
               if (dt == null) return '-';
               final utc = dt.isUtc ? dt : dt.toUtc();
               final chicago = utc.subtract(const Duration(hours: 5));
               int h = chicago.hour;
               String amPm = h >= 12 ? 'PM' : 'AM';
               if (h == 0) { h = 12; }
               else if (h > 12) { h -= 12; }
               String hh = h.toString().padLeft(2, '0');
               String mm = chicago.minute.toString().padLeft(2, '0');
               String mth = chicago.month.toString().padLeft(2, '0');
               String dd = chicago.day.toString().padLeft(2, '0');
               String yy = chicago.year.toString();
               return '$hh:$mm $amPm $mth/$dd/$yy';
            }

            List<Widget> buildCombinedAuditItems() {
              List awbList = [];
              if (u['data-AWB'] is List) {
                awbList = u['data-AWB'];
              } else if (u['data-AWB'] is Map) {
                awbList = [u['data-AWB']];
              }

              List dcList = [];
              if (u['data-coordinator'] is List) {
                dcList = u['data-coordinator'];
              } else if (u['data-coordinator'] is Map && (u['data-coordinator'] as Map).isNotEmpty) {
                dcList = [u['data-coordinator']];
              }

              List locList = [];
              if (u['data-location'] is List) {
                locList = u['data-location'];
              } else if (u['data-location'] is Map && (u['data-location'] as Map).isNotEmpty) {
                locList = [u['data-location']];
              }

              if (awbList.isEmpty) return [Text('No flight data available.', style: TextStyle(color: textS))];
              
              return awbList.asMap().entries.map((entry) {
                final int idx = entry.key;
                final e = entry.value;
                final isBreak = e['isBreak'] == true;
                final uldNum = e['refULD']?.toString() ?? '';
                final uldDcData = dcList.where((dc) => dc['refULD']?.toString() == uldNum || dcList.length == 1).toList();
                final isExpanded = expandedCards.contains(idx);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Collapsible Header Area
                      InkWell(
                        onTap: () {
                           setStateBuilder(() {
                              if (isExpanded) {
                                expandedCards.remove(idx);
                              } else {
                                expandedCards.add(idx);
                              }
                           });
                        },
                        borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text('ULD: ${e['refULD'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBreak ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isBreak ? const Color(0xFF10b981).withAlpha(50) : const Color(0xFFef4444).withAlpha(50)),
                                ),
                                child: Text(isBreak ? 'BREAK' : 'NO BREAK', style: TextStyle(color: isBreak ? const Color(0xFF10b981) : const Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: textS),
                            ]
                          )
                        )
                      ),
                      
                      // Expanded Content Area
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(padding: EdgeInsets.only(bottom: 12), child: Divider(height: 1)),
                              // --- FLIGHT INFO ---
                              Row(
                                children: [
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Flight', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['refCarrier'] ?? ''} ${e['refNumber'] ?? ''}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Date', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['refDate'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                ]
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Pieces', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['pieces'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Weight', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['weight'] ?? '-'} kg', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                ]
                              ),
                              if (e['remarks'] != null && e['remarks'].toString().isNotEmpty) ...[
                                 const SizedBox(height: 12),
                                 Text('Remarks: ${e['remarks']}', style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic)),
                              ],

                              // --- NO BREAK MAPPED AWBs ---
                              if (!isBreak && uldNum.isNotEmpty)
                                FutureBuilder<List<dynamic>>(
                                  future: Supabase.instance.client.from('ULD').select('data-ULD').eq('ULD-number', uldNum).maybeSingle().then((res) => (res?['data-ULD'] as List<dynamic>?) ?? []),
                                  builder: (ctx, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                                    }
                                    final listData = snapshot.data ?? [];
                                    if (listData.isEmpty) return const SizedBox.shrink();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                        Row(children: [
                                          Icon(Icons.inventory_2_outlined, size: 16, color: textP),
                                          const SizedBox(width: 8),
                                          Text('Mapped AWBs in ULD', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ]),
                                        const SizedBox(height: 12),
                                        ...listData.map((d) {
                                           return Container(
                                             margin: const EdgeInsets.only(bottom: 6),
                                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                             decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(6)),
                                             child: Row(
                                               children: [
                                                 Expanded(flex: 2, child: Text(d['awb_number']?.toString() ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13))),
                                                 Expanded(flex: 1, child: Text('Pieces: ${d['pieces'] ?? '-'}', style: TextStyle(color: textS, fontSize: 12))),
                                                 Expanded(flex: 1, child: Text('Total: ${d['total'] ?? '-'}', style: TextStyle(color: textS, fontSize: 12))),
                                               ]
                                             )
                                           );
                                        }),
                                      ]
                                    );
                                  }
                                ),

                              // --- COORDINATOR AUDIT ---
                              if (uldDcData.isNotEmpty) ...[
                                 const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                 Row(children: [
                                    Icon(Icons.assignment_turned_in_outlined, size: 16, color: textP),
                                    const SizedBox(width: 8),
                                    Text('Coordinator Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]),
                                 const SizedBox(height: 12),
                                 ...uldDcData.map((dc) {
                                    Map bd = (dc['breakdown'] is Map) ? dc['breakdown'] as Map : {};
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                             children: [
                                                Icon(Icons.person_outline, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(dc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                const Spacer(),
                                                Icon(Icons.access_time, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(formatChicagoTime(dc['time']), style: TextStyle(color: textS, fontSize: 12)),
                                             ]
                                          ),
                                          if (bd.isNotEmpty) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               children: bd.entries.map((entry) {
                                                 if (entry.value is List && (entry.value as List).isEmpty) return const SizedBox.shrink();
                                                 if (entry.value is num && entry.value == 0) return const SizedBox.shrink();
                                                 return Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                   decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF6366f1).withAlpha(50))),
                                                   child: Text('${entry.key}: ${entry.value is List ? entry.value.join(', ') : entry.value}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                                 );
                                               }).toList(),
                                             ),
                                          ],
                                          if (dc['manual_entry'] != null) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               crossAxisAlignment: WrapCrossAlignment.center,
                                               children: [
                                                 Text('Manual Entry:', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                 ...(dc['manual_entry'] is List ? dc['manual_entry'] as List : [dc['manual_entry']]).map((entry) {
                                                   return Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                     decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF6366f1).withAlpha(50))),
                                                     child: Text(entry.toString(), style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                                   );
                                                 }),
                                               ],
                                             ),
                                          ]
                                        ]
                                      )
                                    );
                                 }),
                              ],

                              // --- LOCATION AUDIT ---
                              if (locList.isNotEmpty && awbList.last == e) ...[
                                 const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                 Row(children: [
                                    Icon(Icons.location_on_outlined, size: 16, color: textP),
                                    const SizedBox(width: 8),
                                    Text('Location Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]),
                                 const SizedBox(height: 12),
                                 ...locList.map((loc) {
                                    Map itemLocs = (loc['itemLocations'] is Map) ? loc['itemLocations'] as Map : {};
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                             children: [
                                                Icon(Icons.person_outline, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(loc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                const Spacer(),
                                                Icon(Icons.access_time, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(formatChicagoTime(loc['time']), style: TextStyle(color: textS, fontSize: 12)),
                                             ]
                                          ),
                                          if (itemLocs.isNotEmpty) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               children: itemLocs.entries.map((entry) {
                                                 if (entry.value == null || entry.value.toString().isEmpty) return const SizedBox.shrink();
                                                 return Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                   decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(50))),
                                                   child: Text('${entry.key} ➔ ${entry.value}', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
                                                 );
                                               }).toList(),
                                             ),
                                          ],
                                          if (loc['manual_entry'] != null) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               crossAxisAlignment: WrapCrossAlignment.center,
                                               children: [
                                                 Text('Manual Entry:', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                 ...(loc['manual_entry'] is List ? loc['manual_entry'] as List : [loc['manual_entry']]).map((entry) {
                                                   return Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                     decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(50))),
                                                     child: Text(entry.toString(), style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
                                                   );
                                                 }),
                                               ],
                                             ),
                                          ]
                                        ]
                                      )
                                    );
                                 }),
                              ]
                            ]
                          )
                        )
                    ]
                  )
                );
              }).toList();
            }

            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: bg,
                elevation: 16,
                child: SizedBox(
                  width: 520, // slightly wider to fit everything beautifully
                  height: double.infinity,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AWB Traceability', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(u['AWB-number']?.toString() ?? 'N/A', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: textP),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            // Totals Summary
                            Text('Pieces Summary', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                              child: Column(
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Root Total:', style: TextStyle(color: textS)), Text(u['total']?.toString() ?? '-', style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Expected (Manifest):', style: TextStyle(color: textS)), Text(expectedPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Received (Coordinator):', style: TextStyle(color: textS)), Text(receivedPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Calculated Status:', style: TextStyle(color: textS)), _buildStatusBadge(status)]),
                                ]
                              )
                            ),
                            const SizedBox(height: 32),
                            
                            Text('ULD Traceability Flow', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...buildCombinedAuditItems(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            );
          }
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      }
    );
  }

  Widget _buildAwbSelector(bool dark) {
    if (_isLoadingAwbs) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
    }
    if (_allAwbs.isEmpty) {
      return Center(
        child: Text(
          appLanguage.value == 'es' ? 'No hay AWBs disponibles' : 'No AWBs available',
          style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
        ),
      );
    }
    
    var filteredAwbs = _allAwbs;
    if (_searchAwbCtrl.text.isNotEmpty) {
      final term = _searchAwbCtrl.text.toLowerCase();
      filteredAwbs = _allAwbs.where((awb) {
        final awbNumber = (awb['AWB-number']?.toString() ?? '').toLowerCase();
        return awbNumber.contains(term);
      }).toList();
    }
    
    final isImport = _typeCtrl.text == 'Import';

    return Container(
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: DataTable(
                    showCheckboxColumn: false,
                    checkboxHorizontalMargin: 12,
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 44,
                    headingRowHeight: 40,
                    headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                    dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                    dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12),
                    headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 11),
                    columns: [
                      const DataColumn(label: Text('#')),
                      const DataColumn(label: Text('AWB Number')),
                      const DataColumn(label: Text('Expected')),
                      const DataColumn(label: Text('Received')),
                      const DataColumn(label: Text('Total')),
                      const DataColumn(label: Text('Weight')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('')),
                      if (!isImport) const DataColumn(label: Text('')),
                    ],
                    rows: List.generate(filteredAwbs.length, (index) {
                      final awb = filteredAwbs[index];
                      final String awbNumber = awb['AWB-number']?.toString() ?? 'Unknown';
                      final bool isSelected = _selectedAwbs.any((item) => item['AWB-number'] == awbNumber);

                      int expectedPieces = 0;
                      double totalWeight = 0.0;
                      if (awb['data-AWB'] is List) {
                        for (var item in awb['data-AWB']) {
                           expectedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
                           totalWeight += double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
                        }
                      } else if (awb['data-AWB'] is Map) {
                           expectedPieces += int.tryParse(awb['data-AWB']['pieces']?.toString() ?? '0') ?? 0;
                           totalWeight += double.tryParse(awb['data-AWB']['weight']?.toString() ?? '0') ?? 0.0;
                      }

                      int receivedPieces = 0;
                      if (awb['data-coordinator'] != null) {
                        List dcList = [];
                        if (awb['data-coordinator'] is List) {
                          dcList = awb['data-coordinator'] as List;
                        } else if (awb['data-coordinator'] is Map && (awb['data-coordinator'] as Map).isNotEmpty) {
                          dcList = [awb['data-coordinator']];
                        }
                        
                        for (var item in dcList) {
                           if (item is Map) {
                              if (item.containsKey('breakdown') && item['breakdown'] is Map) {
                                 Map breakdown = item['breakdown'];
                                 if (breakdown['AGI Skid'] is List) {
                                    for (var val in breakdown['AGI Skid']) {
                                       receivedPieces += int.tryParse(val.toString()) ?? 0;
                                    }
                                 }
                                 for (String k in ['Pre Skid', 'Crate', 'Box', 'Other']) {
                                    receivedPieces += int.tryParse(breakdown[k]?.toString() ?? '0') ?? 0;
                                 }
                              } else {
                                 receivedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
                              }
                           }
                        }
                      }
                      
                      String status = 'Pending';
                      if (receivedPieces > 0 && receivedPieces < expectedPieces) {
                        status = 'In Progress';
                      } else if (receivedPieces >= expectedPieces && expectedPieces > 0) {
                        status = 'Ready';
                      }

                      return DataRow(
                        selected: !isImport && isSelected,
                        onSelectChanged: isImport ? null : (val) {
                          setState(() {
                            if (val == true) {
                              _selectedAwbs.add(awb);
                            } else {
                              _selectedAwbs.removeWhere((item) => item['AWB-number'] == awbNumber);
                            }
                          });
                        },
                        cells: [
                          DataCell(Text('${index + 1}', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600))),
                          DataCell(Text(awbNumber, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                          DataCell(Text('$expectedPieces pcs')),
                          DataCell(Text('$receivedPieces pcs', style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(awb['total']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366f1)))),
                          DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\\.$|\\.0$'), '')} kg')),
                          DataCell(_buildStatusBadge(status)),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF6366f1), size: 20),
                              onPressed: () => _showAwbDrawer(context, awb, dark, receivedPieces, expectedPieces, status),
                              tooltip: 'Ver Info',
                            ),
                          ),
                          if (!isImport) DataCell(
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF6366f1),
                              side: BorderSide(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af)),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedAwbs.add(awb);
                                  } else {
                                    _selectedAwbs.removeWhere((item) => item['AWB-number'] == awbNumber);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImportAwbRightPane(bool dark, Color textP, Color textS, Color borderC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
             decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
             ),
             child: _importAwbs.isEmpty
                ? Center(child: Text(appLanguage.value == 'es' ? 'Ningún AWB de importación añadido' : 'No imported AWBs added', style: TextStyle(color: textS)))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF6366f1), size: 18),
                            const SizedBox(width: 8),
                            Text('${_importAwbs.length} ${appLanguage.value == 'es' ? 'Añadidos' : 'Added'}', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                      Expanded(
                        child: ListView.builder(
                           padding: const EdgeInsets.all(8),
                           itemCount: _importAwbs.length,
                           itemBuilder: (ctx, idx) {
                               final awb = _importAwbs[idx];
                               final String awbNum = awb['awbNumber'];
                               final bool isExpanded = _expandedImports.contains(awbNum);

                               return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                           Container(
                                             width: 20, height: 20,
                                             margin: const EdgeInsets.only(right: 8),
                                             alignment: Alignment.center,
                                             decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                                             child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                                           ),
                                           Expanded(
                                             flex: 5,
                                             child: Text(awb['awbNumber'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 13)),
                                           ),
                                           Expanded(
                                             flex: 3,
                                             child: Text('Pcs: ${awb['pieces']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                                           ),
                                           Expanded(
                                             flex: 3,
                                             child: Text('Tot: ${awb['total']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                                           ),
                                           Expanded(
                                             flex: 4,
                                             child: Text('Wgt: ${awb['weight'].toString().replaceAll(RegExp(r'\.$|\.0$'), '')}kg', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                                           ),
                                           const SizedBox(width: 4),
                                           IconButton(
                                             constraints: const BoxConstraints(),
                                             padding: EdgeInsets.zero,
                                             icon: Icon(isExpanded ? Icons.visibility_off : Icons.visibility, size: 18, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
                                             onPressed: () {
                                               setState(() {
                                                 if (isExpanded) {
                                                   _expandedImports.remove(awbNum);
                                                 } else {
                                                   _expandedImports.add(awbNum);
                                                 }
                                               });
                                             },
                                           ),
                                           const SizedBox(width: 8),
                                           IconButton(
                                             constraints: const BoxConstraints(),
                                             padding: EdgeInsets.zero,
                                             icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                                             onPressed: () => setState(() => _importAwbs.removeAt(idx)),
                                           ),
                                        ]
                                      ),
                                      if (isExpanded) ...[
                                        const SizedBox(height: 8),
                                        Divider(height: 1, color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('House Number', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text((awb['house'] as List).isEmpty ? 'N/A' : (awb['house'] as List).join('\n'), style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Remarks', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text(awb['remarks'] ?? 'N/A', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  )
                               );
                            }
                        )
                      )
                    ]
                  )
          )
        ),
        const SizedBox(height: 16),
        Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(color: dark ? const Color(0xFF1e293b) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB))),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
                Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     SizedBox(width: 150, child: _buildTextField('AWB Number', _importAwbNumberCtrl, dark, null, hint: '123-4567 8910', onChanged: (val) {
                       var pureDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
                       if (pureDigits.length == 11) {
                         final text = val.trim().toUpperCase();
                         () async {
                           try {
                             final res = await Supabase.instance.client.from('AWB').select('total').eq('AWB-number', text).maybeSingle();
                             if (res != null && res['total'] != null && _importAwbNumberCtrl.text.toUpperCase() == text) {
                               if (mounted) {
                                  setState(() {
                                     _importTotalLocked = true;
                                     _importTotalCtrl.text = res['total'].toString();
                                  });
                               }
                             }
                           } catch (_) {}
                         }();
                       } else {
                         if (_importTotalLocked) {
                           setState(() {
                             _importTotalLocked = false;
                             _importTotalCtrl.clear();
                           });
                         }
                       }
                     })),
                     const SizedBox(width: 8),
                     SizedBox(width: 80, child: _buildTextField('Pieces', _importPiecesCtrl, dark, null, hint: '0')),
                     const SizedBox(width: 8),
                     SizedBox(width: 80, child: _buildTextField('Total', _importTotalCtrl, dark, null, hint: '0', readOnly: _importTotalLocked)),
                     const SizedBox(width: 8),
                     SizedBox(width: 80, child: _buildTextField('Weight', _importWeightCtrl, dark, null, hint: '0')),
                     const SizedBox(width: 8),
                     Expanded(child: _buildTextField('House No.', _importHouseCtrl, dark, null, hint: 'HAWB', maxLines: 3, minLines: 1, uppercase: true)),
                   ]
                ),
                const SizedBox(height: 12),
                Row(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Expanded(child: _buildTextField('Remarks', _importRemarksCtrl, dark, null, hint: 'Remarks of the AWB')),
                     const SizedBox(width: 16),
                     SizedBox(
                       height: 48,
                       width: 140,
                       child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15),
                            foregroundColor: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5),
                            elevation: 0,
                            side: BorderSide(color: dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: _addImportAwb,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Add AWB', style: TextStyle(fontWeight: FontWeight.bold)),
                       ),
                     ),
                   ]
                ),
             ]
           )
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

        final content = Column(
          children: [
            Expanded(
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            Icon(Icons.local_shipping_rounded, color: textP, size: 20),
                            const SizedBox(width: 8),
                            Text('Deliver Information', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(flex: 3, child: _buildTextField('Truck Company', _truckCompanyCtrl, dark, null, hint: 'FedEx', uppercase: true)),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: _buildTextField('Driver', _driverCtrl, dark, null, hint: 'John Doe', capitalizeWords: true)),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _buildTextField('Door', _doorCtrl, dark, null, maxLen: 6, uppercase: true, hint: '05')),
                            const SizedBox(width: 16),
                            Expanded(flex: 3, child: _buildTextField('ID Pickup', _idPickupCtrl, dark, null, maxLen: 10, uppercase: true, hint: 'ID12345', suffixIcon: IconButton(
                              icon: Icon(Icons.auto_awesome_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                              onPressed: () {
                                final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
                                final rnd = Random();
                                final id = String.fromCharCodes(Iterable.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
                                setState(() {
                                  _idPickupCtrl.text = id;
                                });
                              },
                              tooltip: 'Autogenerate ID',
                            ))),
                            const SizedBox(width: 16),
                            SizedBox(width: 185, child: _buildTypeDropdown(dark)),
                            const SizedBox(width: 16),
                            SizedBox(width: 140, child: Builder(builder: (context) {
                              return _buildTextField('Time', _timeCtrl, dark, null, hint: '14:30', suffixIcon: IconButton(
                                icon: Icon(Icons.access_time_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                                onPressed: () async {
                                  FocusManager.instance.primaryFocus?.unfocus(); // Deep unfocus to avoid Web Engine text sync bug
                                  final selected = await showTimePicker(
                                    context: context, 
                                    initialTime: TimeOfDay.now(),
                                    builder: (context, child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (selected != null && mounted) {
                                    final dtObj = DateTime(2000, 1, 1, selected.hour, selected.minute);
                                    final newTime = DateFormat('hh:mm a').format(dtObj);
                                    
                                    _timeCtrl.clear(); // Force update by clearing first 
                                    setState(() {
                                      _timeCtrl.text = newTime;
                                      _timeCtrl.selection = TextSelection.collapsed(offset: newTime.length);
                                    });
                                  }
                                },
                              ));
                            })),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: _buildTextField('Remarks', _remarksCtrl, dark, null, hint: appLanguage.value == 'es' ? 'Notas del conductor...' : 'Driver additional notes...')),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 130,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Priority?', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(Icons.star_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                                        Switch(
                                          value: _isPriority,
                                          onChanged: (v) => setState(() => _isPriority = v),
                                          activeThumbColor: Colors.white,
                                          activeTrackColor: const Color(0xFFf59e0b),
                                          inactiveThumbColor: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF),
                                          inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                            Icon(Icons.list_alt_rounded, color: textP, size: 20),
                            const SizedBox(width: 8),
                            Text('Select Air Waybills (list-pickup)', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                               width: 300,
                               height: 40,
                               decoration: BoxDecoration(
                                  color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderC),
                               ),
                               child: TextField(
                                  controller: _searchAwbCtrl,
                                  style: TextStyle(color: textP, fontSize: 13),
                                  onChanged: (v) => setState(() {}),
                                  decoration: InputDecoration(
                                     hintText: appLanguage.value == 'es' ? 'Buscar AWB...' : 'Search AWB...',
                                     hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                                     prefixIcon: Icon(Icons.search_rounded, color: textP.withAlpha(76), size: 16),
                                     border: InputBorder.none,
                                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                               ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appLanguage.value == 'es' 
                            ? 'Seleccione uno o más AWBs para añadirlos al listado de pickup.' 
                            : 'Select one or more AWBs to add them to the pickup list.',
                          style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildAwbSelector(dark),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: _typeCtrl.text == 'Import' ? _buildImportAwbRightPane(dark, textP, textS, borderC) : _buildSelectedAwbsSummary(dark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                        ),
                        onPressed: _isLoading ? null : _submitPayload,
                        icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _isLoading ? 'Processing...' : (appLanguage.value == 'es' ? 'Guardar Entrega' : 'Save Deliver'), 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        );

        if (widget.onPop == null) {
          return Scaffold(
            backgroundColor: dark ? const Color(0xFF0f172a) : const Color(0xFFF3F4F6),
            appBar: AppBar(
              title: Text(appLanguage.value == 'es' ? 'Añadir Nueva Entrega' : 'Add New Deliver', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.w600)),
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
}
