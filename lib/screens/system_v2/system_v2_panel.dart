import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'system_v2_logic.dart';
import 'system_v2_widgets.dart';

class SystemV2Panel extends StatefulWidget {
  final int panelId; // 1 for Left, 2 for Right
  final bool isSplitView;
  final VoidCallback onToggleSplit;
  final VoidCallback onCloseSplit;
  final String? oppositeSelectedFlightId;
  final ValueChanged<String?> onFlightSelected;
  final String authorName;

  const SystemV2Panel({
    super.key,
    required this.panelId,
    required this.isSplitView,
    required this.onToggleSplit,
    required this.onCloseSplit,
    required this.oppositeSelectedFlightId,
    required this.onFlightSelected,
    required this.authorName,
  });

  @override
  State<SystemV2Panel> createState() => _SystemV2PanelState();
}

class _SystemV2PanelState extends State<SystemV2Panel> {
  late final SystemPanelLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = SystemPanelLogic(panelId: widget.panelId, authorName: widget.authorName);
  }

  @override
  void didUpdateWidget(covariant SystemV2Panel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorName != widget.authorName) {
      _logic.authorName = widget.authorName;
    }
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final dark = isDarkMode.value;
        return Theme(
          data: dark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF6366f1),
                    surface: Color(0xFF1e293b),
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF4F46E5),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (dt != null) {
      _logic.date = dt;
      _logic.fetchFlights(dt, widget.onFlightSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([isDarkMode, _logic]),
      builder: (context, child) {
        final dark = isDarkMode.value;
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff);
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        bool isFlightReceived = false;
        final match = _logic.selectedFlightId != null
            ? _logic.flights.where((f) => '${f['carrier']}-${f['number']}' == _logic.selectedFlightId).toList()
            : [];
        if (match.isNotEmpty) {
          isFlightReceived = match.first['is_received'] == true;
        }

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(32),
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isSplitView || _logic.date != null)
                                Text(
                                  (widget.isSplitView ? '[System ${widget.panelId}]' : '') +
                                      (widget.isSplitView && _logic.date != null ? ' ' : '') +
                                      (_logic.date != null ? (appLanguage.value == 'es' ? 'Vuelos en esta fecha' : 'Flights on this date') : ''),
                                  style: TextStyle(color: textS, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              if (!isFlightReceived && _logic.lastReceivedUld != null) ...[
                                if (widget.isSplitView || _logic.date != null) const SizedBox(width: 16),
                                Builder(
                                  builder: (context) {
                                    final uld = _logic.lastReceivedUld!;
                                    final bool isBreak = uld['is_break'] == true;
                                    final String uldNum = uld['uld_number']?.toString() ?? '-';
                                    final Color statusColor = isBreak ? const Color(0xFF10b981) : const Color(0xFFef4444);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withAlpha(80)),
                                      ),
                                      child: Text(
                                        uldNum,
                                        style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickDate(context),
                                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                                label: Text(
                                  _logic.date == null
                                      ? (appLanguage.value == 'es' ? 'Seleccionar Fecha' : 'Select Date')
                                      : DateFormat('MM/dd/yyyy').format(_logic.date!),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366f1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              if (!widget.isSplitView && widget.panelId == 1 && MediaQuery.of(context).size.width >= 1100) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: widget.onToggleSplit,
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                                  color: const Color(0xFF6366f1),
                                  tooltip: appLanguage.value == 'es' ? 'Dividir vista' : 'Split view',
                                ),
                              ],
                              if (widget.isSplitView && widget.panelId == 2) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: widget.onCloseSplit,
                                  icon: const Icon(Icons.close_rounded, size: 28),
                                  color: Colors.redAccent,
                                  tooltip: appLanguage.value == 'es' ? 'Cerrar panel' : 'Close panel',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_logic.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                        ),
                      )
                    else if (_logic.flights.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            _logic.date == null
                                ? (appLanguage.value == 'es' ? 'Selecciona una fecha.' : 'Pick a date to load flights.')
                                : (appLanguage.value == 'es' ? 'No se encontraron vuelos.' : 'No flights found.'),
                            style: TextStyle(color: textS),
                          ),
                        ),
                      )
                    else ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _logic.flights.map((f) {
                          final chipId = '${f['carrier']}-${f['number']}';
                          final isSel = _logic.selectedFlightId == chipId;
                          final isOppositeSel = widget.oppositeSelectedFlightId == chipId;
                          final isReceived = f['is_received'] == true;
                          Color textColor = isOppositeSel
                              ? (dark ? Colors.white30 : Colors.black26)
                              : (isSel ? Colors.white : (isReceived ? const Color(0xFF10b981) : textP));
                          Color selColor = isReceived ? const Color(0xFF10b981) : const Color(0xFF6366f1);
                          Color unselBgColor = isOppositeSel
                              ? (dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6))
                              : (isReceived ? const Color(0xFF10b981).withAlpha(15) : bgCard);
                          Color borderColor = isSel || isOppositeSel
                              ? Colors.transparent
                              : (isReceived ? const Color(0xFF10b981).withAlpha(80) : borderC);

                          return ChoiceChip(
                            label: Text(
                              '${f['carrier'] ?? ''} ${f['number'] ?? ''}',
                              style: TextStyle(color: textColor, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                            ),
                            selected: isSel,
                            selectedColor: selColor,
                            backgroundColor: unselBgColor,
                            showCheckmark: false,
                            side: BorderSide(color: borderColor),
                            onSelected: isOppositeSel
                                ? null
                                : (v) => _logic.selectFlight(v ? chipId : null, v ? f : null, widget.onFlightSelected),
                          );
                        }).toList(),
                      ),
                      if (_logic.selectedFlightId != null) ...[
                        const SizedBox(height: 16),
                        if (_logic.isLoadingUlds)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                            ),
                          )
                        else if (_logic.ulds.isEmpty)
                          Text(
                            appLanguage.value == 'es' ? 'No hay ULDs registrados para este vuelo.' : 'No ULDs found for this flight.',
                            style: TextStyle(color: textS),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: _logic.ulds.length,
                              itemBuilder: (context, index) {
                                final uld = _logic.ulds[index];
                                return SystemV2UldItem(
                                  uld: uld,
                                  isFlightReceived: isFlightReceived,
                                  dark: dark,
                                  bgCard: bgCard,
                                  borderC: borderC,
                                  textP: textP,
                                  textS: textS,
                                  index: index,
                                  match: match,
                                  logic: _logic,
                                );
                              },
                            ),
                          ),
                        if (_logic.ulds.isNotEmpty) ...[
                             const SizedBox(height: 16),
                             SystemV2StatsFooter(
                               logic: _logic,
                               isFlightReceived: isFlightReceived,
                               dark: dark,
                               borderC: borderC,
                             ),
                        ]
                      ],
                    ],
                  ],
                ),
              ),
            ),
            SystemV2AwbOverlay(logic: _logic, dark: dark, textP: textP, textS: textS, borderC: borderC),
            SystemV2SuccessOverlay(logic: _logic, dark: dark, textP: textP),
          ],
        );
      },
    );
  }
}
