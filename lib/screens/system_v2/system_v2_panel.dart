import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'system_v2_logic.dart';
import 'system_v2_widgets.dart';

class SystemV2Panel extends StatefulWidget {
  final int panelId; // 1 for Left, 2 for Right
  final bool isSplitView;
  final VoidCallback onToggleSplit;
  final VoidCallback onCloseSplit;
  final ValueChanged<String?> onFlightSelected;
  final String authorName;
  final Function(String uldId, bool isChecked, String truckTime, String author)? onUldToggled;
  final Function(String firstTruck, String lastTruck)? onFlightReceived;

  const SystemV2Panel({
    super.key,
    required this.panelId,
    required this.isSplitView,
    required this.onToggleSplit,
    required this.onCloseSplit,
    required this.onFlightSelected,
    required this.authorName,
    this.onUldToggled,
    this.onFlightReceived,
  });

  @override
  State<SystemV2Panel> createState() => SystemV2PanelState();
}

class SystemV2PanelState extends State<SystemV2Panel> {
  late final SystemPanelLogic _logic;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logic = SystemPanelLogic(
      panelId: widget.panelId,
      authorName: widget.authorName,
      onUldToggled: widget.onUldToggled,
      onFlightReceived: widget.onFlightReceived,
    );
  }

  @override
  void didUpdateWidget(covariant SystemV2Panel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorName != widget.authorName) {
      _logic.authorName = widget.authorName;
    }
  }

  void syncUld(String uldId, bool isChecked, String truckTime, String author) {
    _logic.syncUldToggled(uldId, isChecked, truckTime, author);
  }

  void syncFlightRec(String firstTruck, String lastTruck) {
    _logic.syncFlightReceived(firstTruck, lastTruck);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
                              SizedBox(
                                width: 200,
                                child: Container(
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: _logic.setSearchQuery,
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(10),
                                    TextInputFormatter.withFunction(
                                      (oldValue, newValue) => newValue.copyWith(
                                        text: newValue.text.toUpperCase(),
                                      ),
                                    ),
                                  ],
                                  style: TextStyle(
                                    color: dark ? Colors.white : const Color(0xFF111827),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: appLanguage.value == 'es' ? 'Buscar ULD...' : 'Search ULD...',
                                    hintStyle: TextStyle(
                                      color: dark ? const Color(0xFF94a3b8).withAlpha(150) : const Color(0xFF4B5563).withAlpha(150),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    suffixIcon: _logic.searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              _logic.setSearchQuery('');
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          )
                                        : null,
                                  ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'System ${widget.panelId}',
                            style: TextStyle(
                              color: dark ? Colors.white.withAlpha(150) : const Color(0xFF6B7280),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
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
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                        ),
                      )
                    else if (_logic.flights.isEmpty)
                      Expanded(
                        child: Center(
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
                          final isReceived = f['is_received'] == true;
                          Color textColor = isSel ? Colors.white : (isReceived ? const Color(0xFF10b981) : textP);
                          Color selColor = isReceived ? const Color(0xFF10b981) : const Color(0xFF6366f1);
                          Color unselBgColor = isReceived ? const Color(0xFF10b981).withAlpha(15) : bgCard;
                          Color borderColor = isSel ? Colors.transparent : (isReceived ? const Color(0xFF10b981).withAlpha(80) : borderC);

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
                            onSelected: (v) => _logic.selectFlight(v ? chipId : null, v ? f : null, widget.onFlightSelected),
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
                              itemCount: _logic.filteredUlds.length,
                              itemBuilder: (context, index) {
                                final uld = _logic.filteredUlds[index];
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
