import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'awbs_v2_formatters.dart';

Future<void> showUnifiedOptionsDialog({
  required BuildContext context,
  required bool dark,
  required Color textP,
  required Color textS,
  required Color borderC,
  required TextEditingController houseCtrl,
  required TextEditingController piecesCtrl,
  required Map<String, String> coordinatorCounts,
  required Map<String, String> itemLocations,
  required VoidCallback onSave,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) => _UnifiedOptionsDialog(
      dark: dark,
      textP: textP,
      textS: textS,
      borderC: borderC,
      houseCtrl: houseCtrl,
      piecesCtrl: piecesCtrl,
      coordinatorCounts: coordinatorCounts,
      itemLocations: itemLocations,
      onSave: onSave,
    ),
  );
}

class _UnifiedOptionsDialog extends StatefulWidget {
  final bool dark;
  final Color textP;
  final Color textS;
  final Color borderC;
  final TextEditingController houseCtrl;
  final TextEditingController piecesCtrl;
  final Map<String, String> coordinatorCounts;
  final Map<String, String> itemLocations;
  final VoidCallback onSave;

  const _UnifiedOptionsDialog({
    required this.dark,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.houseCtrl,
    required this.piecesCtrl,
    required this.coordinatorCounts,
    required this.itemLocations,
    required this.onSave,
  });

  @override
  State<_UnifiedOptionsDialog> createState() => _UnifiedOptionsDialogState();
}

class _UnifiedOptionsDialogState extends State<_UnifiedOptionsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  late Map<String, TextEditingController> _coordCtrls;
  int _enteredPieces = 0;
  int _expectedPieces = 0;
  int _agiLastLen = 0;

  Map<String, TextEditingController> _locCtrls = {};
  int _totalCheckedLoc = 0;
  Map<String, List<String>> _breakdownParts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _expectedPieces = int.tryParse(widget.piecesCtrl.text) ?? 0;
    
    _coordCtrls = {
      'AGI Skid': TextEditingController(text: widget.coordinatorCounts['AGI Skid'] ?? ''),
      'Pre Skid': TextEditingController(text: widget.coordinatorCounts['Pre Skid'] ?? ''),
      'Crate': TextEditingController(text: widget.coordinatorCounts['Crate'] ?? ''),
      'Box': TextEditingController(text: widget.coordinatorCounts['Box'] ?? ''),
      'Other': TextEditingController(text: widget.coordinatorCounts['Other'] ?? ''),
    };
    
    _updateCoordCount();
    _rebuildLocDataFrom(widget.coordinatorCounts, forceClear: false);

    _tabController.addListener(() {
      if (_tabController.index == 2 && !_tabController.indexIsChanging) {
        Map<String, String> tempCoord = {};
        _coordCtrls.forEach((k, v) {
          if (v.text.trim().isNotEmpty) tempCoord[k] = v.text.trim();
        });
        _rebuildLocDataFrom(tempCoord, forceClear: false);
      }
      setState(() {});
    });
  }
  
  void _updateCoordCount() {
    int sum = 0;
    _coordCtrls.forEach((key, ctrl) {
      if (key == 'AGI Skid') {
        final parts = ctrl.text.split(RegExp(r'[,\s-]+'));
        for (var p in parts) { sum += int.tryParse(p) ?? 0; }
      } else {
        sum += int.tryParse(ctrl.text) ?? 0;
      }
    });
    if (sum != _enteredPieces) setState(() => _enteredPieces = sum);
  }

  void _rebuildLocDataFrom(Map<String, String> currentCoordData, {bool forceClear = true}) {
    Map<String, TextEditingController> oldCtrls = _locCtrls;
    _locCtrls = {};
    _totalCheckedLoc = 0;
    _breakdownParts = {};

    currentCoordData.forEach((k, v) {
      final parts = v.split(RegExp(r'[,\s\+]+')).where((e) => int.tryParse(e) != null && int.parse(e) > 0).toList();
      if (parts.isNotEmpty) {
        _breakdownParts[k] = parts;
        _totalCheckedLoc += parts.map((e) => int.tryParse(e) ?? 0).fold(0, (a, b) => a + b);
        for (int i = 0; i < parts.length; i++) {
          String key = '${k}__$i';
          String oldVal = '';
          if (!forceClear && oldCtrls.containsKey(key)) {
            oldVal = oldCtrls[key]!.text;
          } else if (!forceClear && widget.itemLocations.containsKey(key)) {
            oldVal = widget.itemLocations[key]!;
          }
          _locCtrls[key] = TextEditingController(text: oldVal);
        }
      }
    });
    
    for (var c in oldCtrls.entries) {
      if (!_locCtrls.containsKey(c.key)) {
        c.value.dispose();
      }
    }
  }

  String _getLocDisplayName(String key, int count) {
    if (count <= 1) return key.toUpperCase();
    if (key == 'Box') return 'BOXES';
    return '${key.toUpperCase()}S';
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _coordCtrls.values) { c.dispose(); }
    for (var c in _locCtrls.values) { c.dispose(); }
    super.dispose();
  }

  Future<bool> _runDiscrepancyCheck() async {
    if (_enteredPieces != _expectedPieces && _enteredPieces > 0) {
      bool isOver = _enteredPieces > _expectedPieces;
      int diff = isOver ? (_enteredPieces - _expectedPieces) : (_expectedPieces - _enteredPieces);
      String discrepancyType = isOver ? 'OVER' : 'SHORT';
      String descText = isOver 
          ? 'Total checked ($_enteredPieces) is greater than declared pieces ($_expectedPieces).\n\n'
          : 'Total checked ($_enteredPieces) is less than declared pieces ($_expectedPieces).\n\n';

      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text('Pieces Discrepancy', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: widget.dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 15, height: 1.5),
              children: [
                TextSpan(text: descText),
                const TextSpan(text: 'There is a difference of '),
                TextSpan(
                  text: '[$diff $discrepancyType]',
                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)
                ),
                const TextSpan(text: ' pieces.\nDo you want to save the report anyway?'),
              ]
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false), 
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8)))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(c, true), 
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return confirm == true;
    }
    return true;
  }

  void _handleSave() async {
    if (widget.piecesCtrl.text.trim().isNotEmpty) {
      bool canSave = await _runDiscrepancyCheck();
      if (!canSave) return;
    }

    widget.coordinatorCounts.clear();
    _coordCtrls.forEach((k, v) {
      if (v.text.trim().isNotEmpty) widget.coordinatorCounts[k] = v.text.trim();
    });

    widget.itemLocations.clear();
    _locCtrls.forEach((k, v) {
      if (v.text.trim().isNotEmpty) widget.itemLocations[k] = v.text.trim();
    });

    widget.onSave();
    if (mounted) Navigator.pop(context);
  }

  Widget _buildHouseTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enter House Numbers (one per line)', style: TextStyle(color: widget.textP, fontWeight: FontWeight.bold)),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.houseCtrl,
                builder: (context, value, child) {
                  final count = value.text.split('\n').where((e) => e.trim().isNotEmpty).length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: widget.houseCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              style: TextStyle(color: widget.textP, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. HAWB123456\nHAWB987654',
                hintStyle: TextStyle(color: widget.textS.withAlpha(100)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorTab() {
    if (widget.piecesCtrl.text.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'You must insert Pieces previously to proceed with the Data Coordinator.',
            style: TextStyle(color: widget.textS, fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('EXPECTED', style: TextStyle(color: widget.textS, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_expectedPieces', style: TextStyle(color: widget.textP, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 35, color: widget.dark ? Colors.white24 : Colors.grey.shade300),
              Column(
                children: [
                  Text('COUNTED', style: TextStyle(color: widget.textS, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_enteredPieces', style: TextStyle(color: _enteredPieces == _expectedPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...['AGI Skid', 'Pre Skid', 'Crate', 'Box', 'Other'].map((label) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _coordCtrls[label],
              keyboardType: label == 'AGI Skid' ? TextInputType.text : TextInputType.number,
              inputFormatters: [
                if (label == 'AGI Skid')
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\s+]'))
                else
                  FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(color: widget.textP),
              onChanged: (val) {
                if (label == 'AGI Skid') {
                  if (val.endsWith(' ') && val.length > _agiLastLen) {
                    final newText = '${val.substring(0, val.length - 1)} + ';
                    _coordCtrls[label]!.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  }
                  _agiLastLen = _coordCtrls[label]!.text.length;
                }
                _updateCoordCount();
              },
              decoration: InputDecoration(
                labelText: label == 'AGI Skid' ? 'AGI Skid (space separated)' : label,
                labelStyle: TextStyle(color: widget.textS, fontSize: label == 'AGI Skid' ? 13 : 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    bool hasCoordData = false;
    _coordCtrls.forEach((k, v) { if (v.text.trim().isNotEmpty) hasCoordData = true; });

    if (widget.piecesCtrl.text.trim().isEmpty || !hasCoordData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'You must complete Data Coordinator first to enable Data Location.',
            style: TextStyle(color: widget.textS, fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('EXPECTED', style: TextStyle(color: widget.textS, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_expectedPieces', style: TextStyle(color: widget.textP, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 35, color: widget.dark ? Colors.white24 : Colors.grey.shade300),
              Column(
                children: [
                  Text('COUNTED', style: TextStyle(color: widget.textS, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_totalCheckedLoc', style: TextStyle(color: _totalCheckedLoc == _expectedPieces ? const Color(0xFF10b981) : const Color(0xFFf59e0b), fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._breakdownParts.entries.map((entry) {
            int groupTotal = entry.value.map((e) => int.tryParse(e) ?? 0).fold(0, (a, b) => a + b);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.borderC)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24, height: 24, alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), shape: BoxShape.circle),
                        child: Text('${entry.value.length}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(_getLocDisplayName(entry.key, entry.value.length), style: TextStyle(color: widget.textP, fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      Text('$groupTotal pcs', style: TextStyle(color: widget.textS, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(entry.value.length, (i) {
                    String key = '${entry.key}__$i';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: widget.dark ? Colors.white.withAlpha(10) : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(4)),
                            child: Text('${entry.value[i]} pcs', style: TextStyle(color: widget.textP, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 35,
                              child: TextField(
                                controller: _locCtrls[key],
                                textCapitalization: TextCapitalization.characters,
                                style: TextStyle(color: widget.textP, fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Location (e.g. WH1-A-12)',
                                  hintStyle: TextStyle(color: widget.textS.withAlpha(100), fontSize: 12, fontWeight: FontWeight.normal),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.borderC), borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: widget.borderC)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF6366f1),
                labelColor: const Color(0xFF6366f1),
                unselectedLabelColor: widget.textS,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'House'),
                  Tab(text: 'Coordinator'),
                  Tab(text: 'Location'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHouseTab(),
                  _buildCoordinatorTab(),
                  _buildLocationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: widget.textS)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366f1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _handleSave,
          child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
