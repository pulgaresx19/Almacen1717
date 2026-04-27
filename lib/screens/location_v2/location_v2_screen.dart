import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../main.dart' show appLanguage, isDarkMode;
import 'location_v2_logic.dart';
import 'location_v2_ulds.dart';
import 'location_v2_uld_modal.dart';

class LocationV2Screen extends StatefulWidget {
  final bool isActive;
  const LocationV2Screen({super.key, required this.isActive});

  @override
  State<LocationV2Screen> createState() => _LocationV2ScreenState();
}

class _LocationV2ScreenState extends State<LocationV2Screen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final LocationV2Logic _logic = LocationV2Logic();
  bool _searchError = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _logic.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logic.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    if (picked != null) {
      _logic.setDate(picked);
    }
  }



  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_logic, isDarkMode]),
      builder: (context, child) {
        final dark = isDarkMode.value;
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Column(
          children: [
            // MAIN COMPONENT
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF0f172a).withAlpha(100) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCard),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD HEADER (Date Picker on right)
                    Row(
                      mainAxisAlignment: (!_logic.isLoadingFlights && _logic.flights.isNotEmpty) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                      children: [
                        if (!_logic.isLoadingFlights && _logic.flights.isNotEmpty)
                          SizedBox(
                            width: 200,
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _searchError 
                                      ? Colors.redAccent 
                                      : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                  width: _searchError ? 1.5 : 1.0,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
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
                                  color: textP,
                                  fontSize: 13,
                                ),
                                onChanged: (v) {
                                  if (_searchError) {
                                    setState(() { _searchError = false; });
                                  } else {
                                    setState(() {});
                                  }
                                },
                                onSubmitted: (v) {
                                  final query = v.trim().toUpperCase();
                                  if (query.isEmpty) return;
                                  
                                  final match = _logic.ulds.cast<Map<String,dynamic>?>().firstWhere(
                                    (u) {
                                      if (u == null) return false;
                                      final uldNum = u['uld_number']?.toString().toUpperCase() ?? '';
                                      // Only allow if checked
                                      if (u['time_checked'] == null) return false;
                                      return uldNum == query;
                                    },
                                    orElse: () => null,
                                  );
                                  
                                  if (match != null) {
                                    _searchController.clear();
                                    setState(() { _searchError = false; });
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => LocationV2UldModal(
                                        uld: match,
                                        logic: _logic,
                                      ),
                                    ).then((_) {
                                      _searchFocus.requestFocus();
                                    });
                                  } else {
                                    setState(() { _searchError = true; });
                                    _searchController.clear();
                                    _searchFocus.requestFocus();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: appLanguage.value == 'es' ? 'Buscar ULD...' : 'Search ULD...',
                                  hintStyle: TextStyle(
                                    color: textS.withAlpha(150),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          color: textS,
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                            _searchFocus.requestFocus();
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        

                        // DATE PICKER
                        ElevatedButton.icon(
                          onPressed: () => _pickDate(context),
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(
                            _logic.selectedDate == null
                                ? (appLanguage.value == 'es'
                                      ? 'Seleccionar Fecha'
                                      : 'Select Date')
                                : DateFormat('MM/dd/yyyy').format(_logic.selectedDate!),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 16),
                    
                    // CONTENT
                    if (_logic.isLoadingFlights)
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                      )
                    else if (_logic.selectedDate != null && _logic.flights.isEmpty)
                      Center(
                        child: Text(
                          appLanguage.value == 'es'
                              ? 'No se encontraron vuelos para esta fecha.'
                              : 'No flights found for this date.',
                          style: TextStyle(color: textS),
                        ),
                      )
                    else if (_logic.selectedDate == null)
                      Expanded(
                        child: Center(
                          child: Text(
                            appLanguage.value == 'es'
                                  ? 'Selecciona una fecha.'
                                  : 'Pick a date to load flights.',
                            style: TextStyle(color: textS),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _logic.flights.map((f) {
                                final chipId = f['id_flight']?.toString() ?? '';
                                final isSel = _logic.selectedFlightId == chipId && chipId.isNotEmpty;
                                final isReady = f['is_ready'] == true;

                                Color textColor = isSel
                                    ? Colors.white
                                    : (isReady ? const Color(0xFF10b981) : textP);
                                Color selColor = isReady
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFF6366f1);
                                Color unselBgColor = isReady
                                    ? const Color(0xFF10b981).withAlpha(15)
                                    : (dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff));
                                Color borderColor = isSel
                                    ? Colors.transparent
                                    : (isReady
                                        ? const Color(0xFF10b981).withAlpha(50)
                                        : borderCard);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ChoiceChip(
                                  label: Text(
                                    '${f['carrier'] ?? ''} ${f['number'] ?? ''}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: selColor,
                                  backgroundColor: unselBgColor,
                                  showCheckmark: false,
                                  side: BorderSide(color: borderColor),
                                  onSelected: (v) {
                                    if (chipId.isNotEmpty) {
                                      _logic.selectFlight(chipId);
                                      Future.delayed(const Duration(milliseconds: 50), () {
                                        _searchFocus.requestFocus();
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                            if (_logic.selectedFlightId != null) ...[
                              const SizedBox(height: 16),

                              LocationV2Ulds(
                                logic: _logic,
                                dark: dark,
                                textP: textP,
                                textS: textS,
                                bgCard: dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff),
                                borderC: borderCard,
                                searchQuery: _searchController.text,
                                onUldCompleted: () {
                                  if (mounted) {
                                    _searchFocus.requestFocus();
                                  }
                                },
                              ),
                            ]
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_logic.selectedFlightId != null && !_logic.isLoadingUlds && _logic.ulds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCard),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: '${_logic.ulds.where((u) => u['time_saved'] != null).length}', style: const TextStyle(color: Color(0xFF10b981), fontSize: 24, fontWeight: FontWeight.bold)),
                                    TextSpan(text: ' / ${_logic.ulds.length}', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(appLanguage.value == 'es' ? 'Guardados' : 'Saved', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 16), color: borderCard),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appLanguage.value == 'es' ? 'Mostrar\ncompletados' : 'Show\ncompleted',
                          style: TextStyle(color: textS, fontSize: 11),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _logic.showCompletedUlds,
                          onChanged: (val) => _logic.toggleShowCompleted(val),
                          activeTrackColor: const Color(0xFF6366f1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
