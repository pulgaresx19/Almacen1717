import 'package:flutter/material.dart';
import '../../main.dart' show isDarkMode;
import 'add_uld_v2_logic.dart';
import 'add_uld_v2_widgets.dart';
import 'add_uld_v2_dialogs.dart';
import 'add_uld_v2_table.dart';

class AddUldV2Screen extends StatefulWidget {
  final Function(bool)? onPop;
  final bool isInline;
  
  const AddUldV2Screen({super.key, this.onPop, this.isInline = false});

  @override
  State<AddUldV2Screen> createState() => AddUldV2ScreenState();
}

class AddUldV2ScreenState extends State<AddUldV2Screen> {
  late final AddUldV2Logic _logic;
  final _uldNumberCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  String? _selectedFlight;
  bool _isPriority = false;
  bool _isBreak = true;
  
  final Map<String, String> _fieldErrors = {};

  bool _isFlightChk = true;
  bool _isPiecesChk = true;
  bool _isWeightChk = true;

  @override
  void initState() {
    super.initState();
    _logic = AddUldV2Logic()..init();
    _piecesCtrl.text = 'Auto';
    _weightCtrl.text = 'Auto';
  }

  @override
  void dispose() {
    _logic.dispose();
    _uldNumberCtrl.dispose();
    _piecesCtrl.dispose();
    _weightCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _addLocalUld(AddUldV2Logic logic) {
    setState(() {
      _fieldErrors.clear();
    });
    if (_uldNumberCtrl.text.trim().isEmpty) {
      setState(() {
        _fieldErrors['ULD Number'] = 'Required';
      });
      return;
    }
    
    logic.addLocalUld(
      uldNumber: _uldNumberCtrl.text,
      pieces: _piecesCtrl.text,
      weight: _weightCtrl.text,
      remarks: _remarksCtrl.text,
      priority: _isPriority,
      isBreak: _isBreak,
      flightId: _selectedFlight,
      isPiecesChk: _isPiecesChk,
      isWeightChk: _isWeightChk,
    );

    setState(() {
      _uldNumberCtrl.clear();
      _piecesCtrl.text = _isPiecesChk ? 'Auto' : '';
      _weightCtrl.text = _isWeightChk ? 'Auto' : '';
      _remarksCtrl.clear();
      _isPriority = false;
      _isBreak = true;
      if (!_isFlightChk) {
        _selectedFlight = null;
      }
    });
  }

  Future<bool> _onBackPressed(AddUldV2Logic logic) async {
    bool hasData = logic.hasDataSync(
      _uldNumberCtrl.text.isNotEmpty || 
      (_piecesCtrl.text.isNotEmpty && _piecesCtrl.text != 'Auto') || 
      (_weightCtrl.text.isNotEmpty && _weightCtrl.text != 'Auto') ||
      _remarksCtrl.text.isNotEmpty
    );

    if (!hasData) {
      if (widget.onPop != null) {
        widget.onPop!(false);
        return false;
      }
      return true;
    }

    final shouldPop = await showDiscardDialog(context);

    if (shouldPop) {
      if (widget.onPop != null) {
        widget.onPop!(false);
        return false;
      }
      return true;
    }
    return false;
  }

  Future<bool> handleBackRequest() async {
    return _onBackPressed(_logic);
  }

  void _saveAllUlds(AddUldV2Logic logic) {
    if (logic.localUlds.isEmpty) {
      showRequiredFieldError(context, 'ULD List (Add at least 1 ULD)');
      return;
    }

    final emptyUld = logic.localUlds.firstWhere((u) => (u['awbs'] as List).isEmpty, orElse: () => <String, dynamic>{});
    if (emptyUld.isNotEmpty) {
      showRequiredFieldError(context, 'AWBs for ULD ${emptyUld['uldNumber']}');
      return;
    }

    logic.saveAllUlds(() async {
      // Success
      await showSaveSuccessDialog(context);
      
      if (mounted) {
        if (widget.onPop != null) {
          widget.onPop!(true);
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    }, (errorMsg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errorMsg'), backgroundColor: Colors.red));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _logic,
      builder: (listenableCtx, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (v, r) async {
            if (v) return;
            final canPop = await _onBackPressed(_logic);
            if (!mounted) return;
            if (canPop && widget.onPop == null) {
              Navigator.of(this.context).pop();
            }
          },
          child: ValueListenableBuilder<bool>(
            valueListenable: isDarkMode,
            builder: (darkCtx, dark, child) {
              final textP = dark ? Colors.white : const Color(0xFF111827);
              final bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
              final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
          
              final content = _buildFormContent(_logic, dark, textP, bgCard, borderC);
          
              if (widget.isInline) {
                return content;
              }
          
              return Scaffold(
                backgroundColor: dark ? const Color(0xFF0f172a) : const Color(0xFFF3F4F6),
                appBar: AppBar(
                  title: Text('Add New ULDs', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.w600)),
                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                  elevation: 0,
                  iconTheme: IconThemeData(color: textP),
                  bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderC, height: 1)),
                ),
                body: Padding(padding: const EdgeInsets.all(24), child: content),
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildFormContent(AddUldV2Logic logic, bool dark, Color textP, Color bgCard, Color borderC) {
    return Column(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.assignment_rounded, color: textP, size: 20), const SizedBox(width: 8), Text('ULD Details & Assignment', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double rWidth = constraints.maxWidth - 965; 
                        if (rWidth < 180) rWidth = 180;
                        return Wrap(
                          spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            SizedBox(width: 130, child: buildUldTextField('ULD Number', _uldNumberCtrl, 'AKE12345AA', maxLen: 10, isUpperCase: true, hasError: _fieldErrors.containsKey('ULD Number'), errorText: _fieldErrors['ULD Number'])),
                            SizedBox(width: 200, child: buildUldFlightDropdown(
                              logic,
                              _selectedFlight,
                              (v) => setState(() => _selectedFlight = v),
                              titleTrailing: SizedBox(
                                width: 20, height: 20,
                                child: Checkbox(value: _isFlightChk, activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => setState(() => _isFlightChk = v ?? true))
                              )
                            )),
                            SizedBox(width: 90, child: buildUldTextField('Pieces', _piecesCtrl, '0', isNum: true, digitsOnly: true, disabled: _isPiecesChk,
                              titleTrailing: SizedBox(
                                width: 20, height: 20,
                                child: Checkbox(value: _isPiecesChk, activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => setState(() { _isPiecesChk = v ?? true; _piecesCtrl.text = _isPiecesChk ? 'Auto' : ''; }))
                              )
                            )),
                            SizedBox(width: 90, child: buildUldTextField('Weight', _weightCtrl, '0.0', isNum: true, allowDecimal: true, disabled: _isWeightChk,
                              titleTrailing: SizedBox(
                                width: 20, height: 20,
                                child: Checkbox(value: _isWeightChk, activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => setState(() { _isWeightChk = v ?? true; _weightCtrl.text = _isWeightChk ? 'Auto' : ''; }))
                              )
                            )),
                            SizedBox(width: rWidth, child: buildUldTextField('Remarks', _remarksCtrl, 'Additional remarks...', isSentenceCase: true)),
                            SizedBox(
                              width: 125,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Priority?', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 48, padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(10))),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(Icons.star_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                                        Switch(value: _isPriority, onChanged: (v) => setState(() => _isPriority = v), activeThumbColor: Colors.white, activeTrackColor: const Color(0xFFf59e0b), inactiveThumbColor: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 125,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Break?', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 48, padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(10))),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(Icons.broken_image_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                                        Switch(value: _isBreak, onChanged: (v) => setState(() => _isBreak = v), activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF22c55e), inactiveThumbColor: dark ? const Color(0xFFbdc3c7) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB), trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) { if (states.contains(WidgetState.selected)) return Colors.transparent; return const Color(0xFFef4444).withAlpha(180); })),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120, height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15), foregroundColor: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16), side: BorderSide(color: dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: () => _addLocalUld(logic),
                                child: const Text('+ Add ULD', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Table Area via Widget
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                  child: AddUldV2TableWidget(
                    logic: logic,
                    dark: dark,
                    textP: textP,
                    borderC: borderC,
                    bgCard: bgCard,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 32)),
                    onPressed: logic.isSaving ? null : () => _saveAllUlds(logic),
                    icon: logic.isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_rounded),
                    label: Text(logic.isSaving ? 'Processing...' : 'Save ULDs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
