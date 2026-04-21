import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
part 'add_deliver_v2_awb_drawer.dart';
part 'add_deliver_v2_uld_drawer.dart';
part 'add_deliver_v2_awb_selector.dart';
part 'add_deliver_v2_uld_selector.dart';
part 'add_deliver_v2_import_pane.dart';
part 'add_deliver_v2_form_widgets.dart';
part 'add_deliver_v2_submit.dart';

class AddDeliverV2Screen extends StatefulWidget {
  final Function(bool)? onPop;

  const AddDeliverV2Screen({super.key, this.onPop});

  @override
  State<AddDeliverV2Screen> createState() => AddDeliverV2ScreenState();
}

class AddDeliverV2ScreenState extends State<AddDeliverV2Screen> {
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
  String? _missingField;

  List<Map<String, dynamic>> _allAwbs = [];
  final List<Map<String, dynamic>> _selectedAwbs = [];
  final Map<String, TextEditingController> _deliveryPcsControllers = {};
  final Map<String, TextEditingController> _deliveryRemarkControllers = {};
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
  StreamSubscription<List<Map<String, dynamic>>>? _awbSub;
  final Map<String, bool> _overLimitErrors = {};

  bool _showUldTab = false;
  List<Map<String, dynamic>> _allUlds = [];
  final List<Map<String, dynamic>> _selectedUlds = [];
  bool _isLoadingUlds = true;
  StreamSubscription<List<Map<String, dynamic>>>? _uldSub;

  @override
  void initState() {
    super.initState();
    _typeCtrl.text = 'Walk-in';
    _timeCtrl.text = 'NOW';
    
    _awbSub = Supabase.instance.client
        .from('awbs')
        .select()
        .order('awb_number', ascending: true)
        .asStream().listen((data) {
      if (mounted) {
        setState(() {
          _allAwbs = List<Map<String, dynamic>>.from(data);
          _isLoadingAwbs = false;
        });
      }
    });



    _uldSub = Supabase.instance.client
        .from('ulds')
        .select('*, flights:id_flight(carrier, number, date)')
        .order('created_at', ascending: false)
        .asStream().listen((data) {
      if (mounted) {
        setState(() {
          _allUlds = List<Map<String, dynamic>>.from(data);
          _isLoadingUlds = false;
        });
      }
    });
  }



  bool get hasDataSync {
    return _truckCompanyCtrl.text.isNotEmpty || 
           _driverCtrl.text.isNotEmpty || 
           _doorCtrl.text.isNotEmpty || 
           _idPickupCtrl.text.isNotEmpty || 
           _selectedAwbs.isNotEmpty ||
           _selectedUlds.isNotEmpty ||
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
    _awbSub?.cancel();
    _uldSub?.cancel();
    for (var c in _deliveryPcsControllers.values) {
      c.dispose();
    }
    for (var c in _deliveryRemarkControllers.values) {
      c.dispose();
    }
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
                            Expanded(flex: 4, child: _buildTextField('Remarks', _remarksCtrl, dark, null, hint: appLanguage.value == 'es' ? 'Notas del conductor...' : 'Driver additional notes...', capitalizeFirst: true)),
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
                            Text('Select Items (list_deliver)', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
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
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    TextInputFormatter.withFunction((oldValue, newValue) {
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
                                    })
                                  ],
                                  style: TextStyle(color: textP, fontSize: 13),
                                  onChanged: (v) => setState(() {}),
                                  decoration: InputDecoration(
                                     hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
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
                            ? 'Seleccione uno o mÃƒÆ’Ã‚Â¡s AWBs o ULDs para aÃƒÆ’Ã‚Â±adirlos al listado de pickup.' 
                            : 'Select one or more AWBs or ULDs to add them to the pickup list.',
                          style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        if (_typeCtrl.text != 'Import') ...[
                           Row(
                             children: [
                               GestureDetector(
                                 onTap: () => setState(() => _showUldTab = false),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                   decoration: BoxDecoration(
                                      color: !_showUldTab ? const Color(0xFF6366f1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                   ),
                                   child: Text('AWB Numbers', style: TextStyle(color: !_showUldTab ? Colors.white : textS, fontWeight: FontWeight.bold)),
                                 ),
                               ),
                               const SizedBox(width: 8),
                               GestureDetector(
                                 onTap: () => setState(() => _showUldTab = true),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                   decoration: BoxDecoration(
                                      color: _showUldTab ? const Color(0xFF6366f1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                   ),
                                   child: Text('No Break ULDs', style: TextStyle(color: _showUldTab ? Colors.white : textS, fontWeight: FontWeight.bold)),
                                 ),
                               ),
                             ]
                           ),
                           const SizedBox(height: 16),
                        ],
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _typeCtrl.text == 'Import' 
                                      ? _buildAwbSelector(dark) 
                                      : (_showUldTab ? _buildUldSelector(dark) : _buildAwbSelector(dark)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _typeCtrl.text == 'Import' ? _buildImportAwbRightPane(dark, textP, textS, borderC) : _buildSelectedItemsSummary(dark),
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
              title: Text(appLanguage.value == 'es' ? 'AÃƒÆ’Ã‚Â±adir Nueva Entrega' : 'Add New Deliver', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.w600)),
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
