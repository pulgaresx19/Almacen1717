import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<bool> handleBackRequest() async {
    bool hasData = _truckCompanyCtrl.text.isNotEmpty || _driverCtrl.text.isNotEmpty || _doorCtrl.text.isNotEmpty || _idPickupCtrl.text.isNotEmpty || _selectedAwbs.isNotEmpty;
    if (!hasData) return true;

    bool? discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text('Discard Changes?', style: TextStyle(color: Colors.white)),
        content: const Text('You have unsaved details. Are you sure you want to go back? All progress will be lost.', style: TextStyle(color: Color(0xFFcbd5e1))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
    return discard ?? false;
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
    super.dispose();
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

    if (_selectedAwbs.isEmpty) {
      _showMissingFieldAlert('Air Waybills (AWBs)');
      return;
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
        finalTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
        final parts = finalTime.split(':');
        hours = int.tryParse(parts[0]) ?? 0;
        minutes = int.tryParse(parts[1]) ?? 0;
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
        'list-pickup': _selectedAwbs.map((e) => e['AWB-number']?.toString() ?? '').toList(),
      };

      await Supabase.instance.client.from('Delivers').insert(payload);

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

  Widget _buildTextField(String label, TextEditingController controller, bool dark, IconData? icon, {int? maxLen, bool uppercase = false, Widget? suffixIcon}) {
    List<TextInputFormatter> formatters = [];
    if (maxLen != null) formatters.add(LengthLimitingTextInputFormatter(maxLen));
    if (uppercase) formatters.add(TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase())));
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

    return TextFormField(
      controller: controller,
      keyboardType: label == 'Time' ? TextInputType.datetime : TextInputType.text,
      style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 13),
      inputFormatters: formatters.isNotEmpty ? formatters : null,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), size: 18) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(bool dark) {
    const types = ['Walk-in', 'Appointment', 'Transfer', 'Import', 'Priority Load'];

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _typeCtrl.text.isNotEmpty ? _typeCtrl.text : 'Walk-in',
      dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
      style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 13),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5)),
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13),
        prefixIcon: Icon(Icons.category_rounded, color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), size: 18),
        filled: true,
        fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), width: 1.5),
        ),
      ),
      items: types.map((String val) {
        return DropdownMenuItem(
          value: val,
          child: Text(val),
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(10) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(awbNumber, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold)),
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

  Widget _buildAwbSelector(bool dark) {
    if (_isLoadingAwbs) {
      return const Center(child: CircularProgressIndicator());
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

    return Container(
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
      ),
      child: ListView.builder(
        itemCount: filteredAwbs.length,
        itemBuilder: (context, index) {
          final awb = filteredAwbs[index];
          final String awbNumber = awb['AWB-number']?.toString() ?? 'Unknown';
          final bool isSelected = _selectedAwbs.any((item) => item['AWB-number'] == awbNumber);

          var pieces = '-';
          var weight = '-';
          var status = '-';
          try {
            if (awb['data-AWB'] != null) {
              var dataAwb = awb['data-AWB'] as Map<String, dynamic>;
              if (dataAwb.containsKey('pieces')) pieces = dataAwb['pieces'].toString();
              if (dataAwb.containsKey('weight')) weight = dataAwb['weight'].toString();
              if (dataAwb.containsKey('status')) status = dataAwb['status'].toString();
            }
          } catch (_) {}

          return CheckboxListTile(
            activeColor: const Color(0xFF6366f1),
            checkColor: Colors.white,
            side: BorderSide(color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(awbNumber, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$pieces pcs / $weight kg', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            subtitle: Text(
              status,
              style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 12),
            ),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedAwbs.add(awb);
                } else {
                  _selectedAwbs.removeWhere((item) => item['AWB-number'] == awbNumber);
                }
              });
            },
          );
        },
      ),
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
                            Expanded(flex: 3, child: _buildTextField('Truck Company', _truckCompanyCtrl, dark, Icons.business_rounded)),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: _buildTextField('Driver', _driverCtrl, dark, Icons.person_rounded)),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _buildTextField('Door', _doorCtrl, dark, Icons.door_front_door_rounded, maxLen: 6, uppercase: true)),
                            const SizedBox(width: 16),
                            Expanded(flex: 3, child: _buildTextField('ID Pickup', _idPickupCtrl, dark, Icons.badge_rounded, maxLen: 10, uppercase: true, suffixIcon: IconButton(
                              icon: Icon(Icons.auto_awesome_rounded, color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), size: 18),
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
                              return _buildTextField('Time', _timeCtrl, dark, null, suffixIcon: IconButton(
                                icon: Icon(Icons.access_time_rounded, color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), size: 18),
                                onPressed: () async {
                                  FocusManager.instance.primaryFocus?.unfocus(); // Deep unfocus to avoid Web Engine text sync bug
                                  final selected = await showTimePicker(
                                    context: context, 
                                    initialTime: TimeOfDay.now(),
                                    builder: (context, child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (selected != null && mounted) {
                                    final hh = selected.hour.toString().padLeft(2, '0');
                                    final mm = selected.minute.toString().padLeft(2, '0');
                                    final newTime = '$hh:$mm';
                                    
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
                            Expanded(flex: 5, child: _buildTextField('Remarks', _remarksCtrl, dark, Icons.note_rounded)),
                            const SizedBox(width: 16),
                            Switch(
                              value: _isPriority,
                              onChanged: (v) => setState(() => _isPriority = v),
                              activeTrackColor: const Color(0xFF6366f1).withAlpha(128),
                              activeThumbColor: const Color(0xFF6366f1),
                            ),
                            const SizedBox(width: 6),
                            Text('Is Priority', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600)),
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
                        const SizedBox(height: 8),
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
                                child: _buildSelectedAwbsSummary(dark),
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
                  const SizedBox(height: 24),
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
