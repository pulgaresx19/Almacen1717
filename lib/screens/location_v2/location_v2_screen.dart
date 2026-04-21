import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;
import 'location_v2_logic.dart';
import 'location_v2_ulds.dart';
import 'location_v2_scanner_modal.dart';

class AwbInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 3) formatted += '-';
      if (i == 7) formatted += ' ';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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

  Future<void> _handleScannerSubmit(String query) async {
    try {
      if (_logic.selectedFlightId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLanguage.value == 'es' ? 'Selecciona un vuelo primero' : 'Select a flight first')),
        );
        _searchFocus.requestFocus();
        return;
      }

      if (_logic.allFlightAwbs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ DEBUG: La lista en memoria está vacía. ULDs cargados: ${_logic.ulds.length}'),
            backgroundColor: Colors.orange,
          ),
        );
        _searchFocus.requestFocus();
        return;
      }

      final cleanQuery = query.replaceAll(RegExp(r'[^0-9A-Z]'), '');

      final matches = _logic.allFlightAwbs.where((split) {
        final uldId = split['uld_id']?.toString();
        if (uldId != null) {
          final uldInfo = _logic.ulds.cast<Map<String, dynamic>?>().firstWhere(
            (u) => u != null && u['id_uld']?.toString() == uldId,
            orElse: () => null,
          );
          if (uldInfo != null && uldInfo['time_saved'] != null) {
            return false;
          }
        }

        final master = split['awbs'];
        Map<String, dynamic> masterMap = {};
        if (master is Map<String, dynamic>) {
          masterMap = master;
        } else if (master is List && master.isNotEmpty) {
          masterMap = master.first as Map<String, dynamic>;
        }

        final awbNumber = (masterMap['awb_number'] ?? split['awb_number'] ?? '').toString().toUpperCase();
        final cleanAwb = awbNumber.replaceAll(RegExp(r'[^0-9A-Z]'), '');
        
        return cleanQuery.isNotEmpty && cleanAwb.contains(cleanQuery);
      }).toList();

      if (!mounted) return;
      if (matches.isEmpty) {
        await LocationV2ScannerModal.show(context, query: query, matches: matches, logic: _logic);
      } else if (matches.length == 1) {
        _searchController.clear();
        await LocationV2ScannerModal.show(context, query: query, matches: matches, logic: _logic);
      } else {
        _searchController.clear();
        await LocationV2ScannerModal.show(context, query: query, matches: matches, logic: _logic);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error interno en buscador: $e'), backgroundColor: Colors.red),
      );
    }
    
    // Always keep focus for next scan, but only after dialog closes
    if (mounted) {
      _searchFocus.requestFocus();
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
            // HEADER TITLE AND SEARCH
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: isSidebarExpandedNotifier,
                  builder: (context, expanded, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: expanded ? 0 : 44,
                    );
                  },
                ),
                Text(
                  'Location',
                  style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  width: 320,
                  height: 42,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [AwbInputFormatter()],
                          style: TextStyle(color: textP, fontSize: 13),
                          onChanged: (v) => setState(() {}),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              _handleScannerSubmit(v.trim().toUpperCase());
                            }
                          },
                          decoration: InputDecoration(
                            hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                            hintStyle: TextStyle(
                              color: textP.withAlpha(76),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: textS,
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (_searchController.text.trim().isNotEmpty) {
                            _handleScannerSubmit(_searchController.text.trim().toUpperCase());
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: _searchController.text.trim().isEmpty
                                ? (dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6))
                                : const Color(0xFF6366f1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: _searchController.text.trim().isEmpty
                                ? (dark ? Colors.white30 : Colors.black26)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Reduced spacing to maximize table space
            
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
                          Text(
                            appLanguage.value == 'es'
                                ? 'Vuelos en esta fecha'
                                : 'Flights on this date',
                            style: TextStyle(
                              color: textS,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 32),
                    
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
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
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

                                return ChoiceChip(
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
                                );
                              }).toList(),
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
          ],
        );
      },
    );
  }
}
