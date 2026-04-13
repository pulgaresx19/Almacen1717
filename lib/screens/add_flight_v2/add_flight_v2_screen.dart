import 'package:flutter/material.dart';
import '../../main.dart' show isDarkMode, appLanguage;
import 'add_flight_v2_logic.dart';
import 'add_flight_v2_widgets.dart';
import 'add_flight_v2_uld_list.dart';

class AddFlightV2Screen extends StatefulWidget {
  final Function(bool)? onPop;
  final bool isInline;
  const AddFlightV2Screen({super.key, this.onPop, this.isInline = false});

  @override
  State<AddFlightV2Screen> createState() => AddFlightV2ScreenState();
}

class AddFlightV2ScreenState extends State<AddFlightV2Screen> {
  late AddFlightV2Logic logic;

  @override
  void initState() {
    super.initState();
    logic = AddFlightV2Logic();
  }

  @override
  void dispose() {
    logic.disposeAll();
    super.dispose();
  }


  Future<bool> handleBackRequest() async {
    return await _onBackPressed();
  }

  Future<bool> _onBackPressed() async {
    bool hasData = logic.hasDataSync;
    if (!hasData) {
      if (widget.onPop != null) { widget.onPop!(false); return false; }
      return true;
    }

    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFFf59e0b).withAlpha(100), width: 2)),
        title: const Column(children: [Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 60), SizedBox(height: 16), Text('Discard Data?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22))]),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Any unsaved data entered for the flight, ULDs, and AWBs will be permanently lost.\n\nDo you want to discard your changes and continue?', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 16, height: 1.4)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)), onPressed: () => Navigator.pop(context, false), child: const Text('STAY', style: TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold, letterSpacing: 1.2))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0)), onPressed: () => Navigator.pop(context, true), child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))),
        ],
      ),
    );

    if (shouldPop == true) {
      if (widget.onPop != null) { widget.onPop!(false); return false; }
      return true;
    }
    return false;
  }

  void _saveEverything() {
    logic.saveEverything(
      context, 
      showValidationError: (msg) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1e293b),
          title: const Text('Validation Error', style: TextStyle(color: Colors.white)),
          content: Text(msg, style: const TextStyle(color: Color(0xFFcbd5e1))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Color(0xFF6366f1))))]
        ));
      }, 
      onError: (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red));
      },
      onSuccess: () async {
        bool dialogOpen = true;
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, anim1, anim2) {
            final dark = isDarkMode.value;
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(color: dark ? const Color(0xFF1e293b) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF10b981).withAlpha(40), blurRadius: 40, offset: const Offset(0, 10))], border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(20), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48)),
                      const SizedBox(height: 24),
                      Text(appLanguage.value == 'es' ? '¡Vuelo Creado!' : 'Flight Created!', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(appLanguage.value == 'es' ? 'La estructura del vuelo se ha guardado exitosamente.' : 'Flight structure created successfully.', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, anim1, anim2, child) => Transform.scale(scale: Curves.easeOutBack.transform(anim1.value), child: FadeTransition(opacity: anim1, child: child)),
        ).then((_) => dialogOpen = false);

        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) {
          if (dialogOpen) Navigator.of(context).pop();
          if (widget.onPop != null) { widget.onPop!(true); } else if (Navigator.canPop(context)) { Navigator.pop(context, true); }
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final bool shouldPop = await _onBackPressed();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: isDarkMode,
        builder: (context, dark, child) {
          return AnimatedBuilder(
            animation: logic,
            builder: (context, _) {
              final textP = dark ? Colors.white : const Color(0xFF111827);
              final bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
              final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
              final content = _buildFormContent(dark, textP, bgCard, borderC);
              if (widget.isInline) return content;
              return Scaffold(
                backgroundColor: dark ? const Color(0xFF0f172a) : const Color(0xFFF3F4F6),
                appBar: AppBar(
                  title: Text('Add New Flight Process (V2)', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.w600)),
                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                  elevation: 0, iconTheme: IconThemeData(color: textP),
                  bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderC, height: 1)),
                ),
                body: Padding(padding: const EdgeInsets.all(24), child: content),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildFormContent(bool dark, Color textP, Color bgCard, Color borderC) {
    return Column(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [Icon(Icons.flight_takeoff_rounded, color: textP, size: 20), const SizedBox(width: 8), Text('Flight Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold))],
                    ),
                    const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            double rWidth = constraints.maxWidth - 775; if (rWidth < 180) rWidth = 180;
            return Wrap(
              spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 90, child: buildTextField('Carrier', logic.carrierCtrl, 'AMERICAN', maxLen: 10, isUpperCase: true, hasError: logic.fieldErrors.containsKey('Carrier'), errorText: logic.fieldErrors['Carrier'])),
                SizedBox(width: 80, child: buildTextField('Number', logic.numberCtrl, '204', isUpperCase: true, maxLen: 10, hasError: logic.fieldErrors.containsKey('Number'), errorText: logic.fieldErrors['Number'])),
                SizedBox(width: 85, child: buildTextField('Break', logic.breakCtrl, '', disabled: logic.isBreakAuto, isNum: true, digitsOnly: true, maxLen: 5, titleTrailing: SizedBox(
                  width: 20, height: 20, child: Checkbox(value: logic.isBreakAuto, activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => logic.setBreakAuto(v ?? true))
                ))),
                SizedBox(width: 85, child: buildTextField('No Break', logic.noBreakCtrl, '', disabled: logic.isNoBreakAuto, isNum: true, digitsOnly: true, maxLen: 5, titleTrailing: SizedBox(
                  width: 20, height: 20, child: Checkbox(value: logic.isNoBreakAuto, activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => logic.setNoBreakAuto(v ?? true))
                ))),
                SizedBox(width: 130, child: buildTextField('Date Arrived', logic.dateCtrl, '__/__/____', readOnly: true, onTap: () => logic.selectDate(context), suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white70), hasError: logic.fieldErrors.containsKey('Date Arrived'), errorText: logic.fieldErrors['Date Arrived'])),
                SizedBox(width: 120, child: buildTextField('Time Arrived', logic.timeCtrl, '__:__ --', readOnly: true, onTap: () => logic.selectTime(context), suffixIcon: const Icon(Icons.access_time_rounded, size: 16, color: Colors.white70))),
                SizedBox(width: rWidth, child: buildTextField('Remarks', logic.remarksCtrl, 'Additional remarks...')),
                SizedBox(width: 100, child: buildDropdown('Status', dark, logic)),
                if (logic.status == 'Delayed') ...[
                   SizedBox(width: 130, child: buildTextField('Delayed Date', logic.delayedDateCtrl, '__/__/____', readOnly: true, onTap: () => logic.selectDelayedDate(context), suffixIcon: const Icon(Icons.event_busy, size: 16, color: Color(0xFFfdba74)))),
                   SizedBox(width: 120, child: buildTextField('Delayed Time', logic.delayedTimeCtrl, '__:__ --', readOnly: true, onTap: () => logic.selectDelayedTime(context), suffixIcon: const Icon(Icons.timer_off, size: 16, color: Color(0xFFfdba74)))),
                ],
              ]
            );
          }
        ),
        const SizedBox(height: 24), Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)), const SizedBox(height: 16),
        Row(children: [Icon(Icons.inventory_2_rounded, color: textP, size: 20), const SizedBox(width: 8), Text('Add ULD To Flight', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            double uldRWidth = constraints.maxWidth - 764; if (uldRWidth < 200) uldRWidth = 200;
            return Wrap(
              spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 130, child: buildTextField('ULD Number', logic.uldNumberCtrl, 'AKE12345AA', maxLen: 10, isUpperCase: true, hasError: logic.fieldErrors.containsKey('ULD Number'), errorText: logic.fieldErrors['ULD Number'])),
                SizedBox(width: 95, child: buildTextField('Pieces', logic.uldPiecesCtrl, '0', isNum: true, digitsOnly: true, disabled: logic.isUldPiecesAuto, titleTrailing: SizedBox(
                  width: 20, height: 20, child: Checkbox(value: logic.isUldPiecesAuto, activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => logic.toggleUldPiecesAuto(v ?? true))
                ))),
                SizedBox(width: 95, child: buildTextField('Weight', logic.uldWeightCtrl, '0.0', isNum: true, allowDecimal: true, disabled: logic.isUldWeightAuto, titleTrailing: SizedBox(
                  width: 20, height: 20, child: Checkbox(value: logic.isUldWeightAuto, activeColor: const Color(0xFF6366f1), side: const BorderSide(color: Color(0xFF94a3b8)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => logic.toggleUldWeightAuto(v ?? true))
                ))),
                SizedBox(width: uldRWidth, child: buildTextField('Remarks', logic.uldRemarksCtrl, 'ULD remarks...')),
                SizedBox(
                  width: 125,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Priority?', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 6),
                      Container(
                        height: 48, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.star_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                            Switch(value: logic.uldPriority, onChanged: logic.setUldPriority, activeThumbColor: Colors.white, activeTrackColor: const Color(0xFFf59e0b), inactiveThumbColor: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
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
                      const Text('Break?', style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 6),
                      Container(
                        height: 48, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(25))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.broken_image_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                            Switch(
                              value: logic.uldBreak, onChanged: logic.setUldBreak, activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF22c55e), inactiveThumbColor: dark ? const Color(0xFFbdc3c7) : const Color(0xFF9CA3AF), inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                              trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) { if (states.contains(WidgetState.selected)) return Colors.transparent; return const Color(0xFFef4444).withAlpha(180); }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120, height: 48,
                  child: ElevatedButton(
                    onPressed: () { logic.addLocalUld(context, showDuplicateError: (msg) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1e293b), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                          title: const Column(children: [Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 48), SizedBox(height: 16), Text('Duplicate ULD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]), 
                          content: SizedBox(
                            width: 260,
                            height: 70,
                            child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                  Text('The ULD "$msg" is already in this flight list. Please enter a different ULD number.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFcbd5e1)))
                               ]
                            )
                          ), 
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Color(0xFF6366f1), fontSize: 16, fontWeight: FontWeight.bold)))]
                        )
                      );
                    });},
                    style: ElevatedButton.styleFrom(backgroundColor: dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15), foregroundColor: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16), side: BorderSide(color: dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
              Expanded(
                  child: Container(
                    width: double.infinity, decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.list_alt_rounded, color: textP, size: 20), const SizedBox(width: 8), Text('Linked ULDs (flight-manifest)', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(),
                                  Container(
                                     width: 300, height: 40, decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20), border: Border.all(color: borderC)),
                                     child: TextField(
                                        controller: logic.searchUldCtrl, style: TextStyle(color: textP, fontSize: 13), onChanged: (v) => logic.rebuild(), decoration: InputDecoration(hintText: appLanguage.value == 'es' ? 'Buscar ULD...' : 'Search ULD...', hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13), prefixIcon: Icon(Icons.search_rounded, color: textP.withAlpha(76), size: 16), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))
                                     ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('View and manage all ULDs assigned to this flight.', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                            child: Container(
                              decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: logic.flightLocalUlds.isNotEmpty
                                ? AddFlightV2UldList(logic: logic, dark: dark, textP: textP, borderC: borderC)
                : Center(child: Text('No ULDs linked to this flight', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500))),
              ),
            ),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 32)),
              onPressed: logic.isSaving ? null : _saveEverything,
              icon: logic.isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_rounded),
              label: Text(logic.isSaving ? 'Processing...' : 'Save Flight', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
