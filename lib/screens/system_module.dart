import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode;

class SystemModule extends StatefulWidget {
  final bool singlePanelMode;
  final String? titleOverride;
  const SystemModule({
    super.key,
    this.singlePanelMode = false,
    this.titleOverride,
  });

  @override
  State<SystemModule> createState() => _SystemModuleState();
}

class _SystemModuleState extends State<SystemModule> {
  DateTime? _dateLeft;
  DateTime? _dateRight;

  Map<String, dynamic>? _activeAwbOverlayLeft;
  Map<String, dynamic>? _activeAwbOverlayRight;

  List<Map<String, dynamic>> _flightsLeft = [];
  List<Map<String, dynamic>> _flightsRight = [];

  bool _isLoadingLeft = false;
  bool _isLoadingRight = false;

  String? _selectedFlightIdLeft;
  String? _selectedFlightIdRight;

  List<Map<String, dynamic>> _uldsLeft = [];
  List<Map<String, dynamic>> _uldsRight = [];
  bool _isLoadingUldsLeft = false;
  bool _isLoadingUldsRight = false;

  bool _showReceivedOverlayLeft = false;
  bool _showReceivedOverlayRight = false;

  final Map<dynamic, bool> _savedUldCheckboxState = {};

  Future<void> _fetchUldsForFlight(
    bool isLeft,
    Map<String, dynamic> flight,
  ) async {
    if (isLeft) {
      setState(() => _isLoadingUldsLeft = true);
    } else {
      setState(() => _isLoadingUldsRight = true);
    }

    try {
      final res = await Supabase.instance.client
          .from('ULD')
          .select()
          .eq('refCarrier', flight['carrier'])
          .eq('refNumber', flight['number'])
          .eq('refDate', flight['date-arrived']);

      if (mounted) {
        setState(() {
          final mapped = List<Map<String, dynamic>>.from(
            res.map((x) => Map<String, dynamic>.from(x)),
          );
          for (var u in mapped) {
            if (u['id'] != null &&
                _savedUldCheckboxState.containsKey(u['id'])) {
              u['selected'] = _savedUldCheckboxState[u['id']];
            } else {
              u['selected'] = false;
            }
          }

          mapped.sort((a, b) {
            String aNum = (a['ULD-number'] ?? '').toString();
            String bNum = (b['ULD-number'] ?? '').toString();

            bool aBulk = aNum.toUpperCase() == 'BULK';
            bool bBulk = bNum.toUpperCase() == 'BULK';
            if (aBulk && !bBulk) return -1;
            if (!aBulk && bBulk) return 1;

            bool aBreak = a['isBreak'] == true;
            bool bBreak = b['isBreak'] == true;
            if (aBreak && !bBreak) return -1;
            if (!aBreak && bBreak) return 1;

            return aNum.compareTo(bNum);
          });

          if (isLeft) {
            _uldsLeft = mapped;
            _isLoadingUldsLeft = false;
          } else {
            _uldsRight = mapped;
            _isLoadingUldsRight = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() {
          if (isLeft) {
            _isLoadingUldsLeft = false;
          } else {
            _isLoadingUldsRight = false;
          }
        });
      }
    }
  }

  Future<void> _fetchFlights(bool isLeft, DateTime dt) async {
    if (isLeft) {
      setState(() => _isLoadingLeft = true);
    } else {
      setState(() => _isLoadingRight = true);
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(dt);

    try {
      final res = await Supabase.instance.client
          .from('Flight')
          .select()
          .eq('date-arrived', dateStr);

      if (mounted) {
        setState(() {
          final pendingFlights = List<Map<String, dynamic>>.from(res);

          if (isLeft) {
            _flightsLeft = pendingFlights;
            _isLoadingLeft = false;
            _selectedFlightIdLeft = null;
            _uldsLeft.clear();
          } else {
            _flightsRight = pendingFlights;
            _isLoadingRight = false;
            _selectedFlightIdRight = null;
            _uldsRight.clear();
          }
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() {
          if (isLeft) {
            _isLoadingLeft = false;
          } else {
            _isLoadingRight = false;
          }
        });
      }
    }
  }

  Future<void> _pickDate(BuildContext context, bool isLeft) async {
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
      if (isLeft) {
        _dateLeft = dt;
      } else {
        _dateRight = dt;
      }
      _fetchFlights(isLeft, dt);
    }
  }

  Widget _buildPanel(bool isLeft, bool dark) {
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    final dt = isLeft ? _dateLeft : _dateRight;
    final isLoading = isLeft ? _isLoadingLeft : _isLoadingRight;
    final flights = isLeft ? _flightsLeft : _flightsRight;
    final selectedId = isLeft ? _selectedFlightIdLeft : _selectedFlightIdRight;

    bool isFlightReceived = false;
    final match = selectedId != null
        ? flights
              .where((f) => '${f['carrier']}-${f['number']}' == selectedId)
              .toList()
        : [];
    if (match.isNotEmpty) {
      isFlightReceived = match.first['isReceived'] == true;
    }

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.singlePanelMode
                            ? (widget.titleOverride ??
                                  (appLanguage.value == 'es'
                                      ? 'Panel Único'
                                      : 'Single Panel'))
                            : (isLeft
                                  ? (appLanguage.value == 'es'
                                        ? 'Panel Izquierdo'
                                        : 'Left Panel')
                                  : (appLanguage.value == 'es'
                                        ? 'Panel Derecho'
                                        : 'Right Panel')),
                        style: TextStyle(
                          color: textP,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.singlePanelMode
                            ? (appLanguage.value == 'es'
                                  ? 'Módulo central del sistema.'
                                  : 'Central system module.')
                            : (isLeft
                                  ? (appLanguage.value == 'es'
                                        ? 'Cruza operaciones y referencia maestra desde este panel.'
                                        : 'Cross-check operations and master reference from this panel.')
                                  : (appLanguage.value == 'es'
                                        ? 'Compara resultados y auditorías en este panel secundario.'
                                        : 'Compare results and audits in this secondary panel.')),
                        style: TextStyle(
                          color: textS,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickDate(context, isLeft),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      dt == null
                          ? (appLanguage.value == 'es'
                                ? 'Seleccionar Fecha'
                                : 'Select Date')
                          : DateFormat('MM/dd/yyyy').format(dt),
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
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                  ),
                )
              else if (flights.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      dt == null
                          ? (appLanguage.value == 'es'
                                ? 'Selecciona una fecha.'
                                : 'Pick a date to load flights.')
                          : (appLanguage.value == 'es'
                                ? 'No se encontraron vuelos.'
                                : 'No flights found.'),
                      style: TextStyle(color: textS),
                    ),
                  ),
                )
              else ...[
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: flights.map((f) {
                    final chipId = '${f['carrier']}-${f['number']}';
                    final isSel = selectedId == chipId;
                    final isOppositeSel = widget.singlePanelMode
                        ? false
                        : (isLeft
                              ? (_selectedFlightIdRight == chipId)
                              : (_selectedFlightIdLeft == chipId));
                    final isReceived = f['isReceived'] == true;

                    Color textColor = isOppositeSel
                        ? (dark ? Colors.white30 : Colors.black26)
                        : (isSel
                              ? Colors.white
                              : (isReceived ? const Color(0xFF10b981) : textP));
                    Color selColor = isReceived
                        ? const Color(0xFF10b981)
                        : const Color(0xFF6366f1);
                    Color unselBgColor = isOppositeSel
                        ? (dark
                              ? Colors.white.withAlpha(5)
                              : const Color(0xFFF3F4F6))
                        : (isReceived
                              ? const Color(0xFF10b981).withAlpha(15)
                              : bgCard);
                    Color borderColor = isSel || isOppositeSel
                        ? Colors.transparent
                        : (isReceived
                              ? const Color(0xFF10b981).withAlpha(80)
                              : borderC);

                    return ChoiceChip(
                      label: Text(
                        '${f['carrier'] ?? ''} ${f['number'] ?? ''}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: selColor,
                      backgroundColor: unselBgColor,
                      showCheckmark: false,
                      side: BorderSide(color: borderColor),
                      onSelected: isOppositeSel
                          ? null
                          : (v) {
                              setState(() {
                                if (isLeft) {
                                  _selectedFlightIdLeft = v ? chipId : null;
                                  if (v) {
                                    _fetchUldsForFlight(true, f);
                                  } else {
                                    _uldsLeft.clear();
                                  }
                                } else {
                                  _selectedFlightIdRight = v ? chipId : null;
                                  if (v) {
                                    _fetchUldsForFlight(false, f);
                                  } else {
                                    _uldsRight.clear();
                                  }
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
                if (selectedId != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    appLanguage.value == 'es'
                        ? 'ULDs del vuelo'
                        : 'Flight ULDs',
                    style: TextStyle(
                      color: textS,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLeft ? _isLoadingUldsLeft : _isLoadingUldsRight)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366f1),
                        ),
                      ),
                    )
                  else if ((isLeft ? _uldsLeft : _uldsRight).isEmpty)
                    Text(
                      appLanguage.value == 'es'
                          ? 'No hay ULDs registrados para este vuelo.'
                          : 'No ULDs found for this flight.',
                      style: TextStyle(color: textS),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: (isLeft ? _uldsLeft : _uldsRight).length,
                        itemBuilder: (context, index) {
                          final uld = (isLeft ? _uldsLeft : _uldsRight)[index];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: bgCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderC),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              if (uld['awbList'] == null &&
                                                  uld['ULD-number'] != null &&
                                                  match.isNotEmpty) {
                                                setState(() {
                                                  if (isLeft) {
                                                    _activeAwbOverlayLeft = uld;
                                                  } else {
                                                    _activeAwbOverlayRight =
                                                        uld;
                                                  }
                                                  uld['isLoadingAwbs'] = true;
                                                });

                                                try {
                                                  final currentFlight =
                                                      match.first;
                                                  final res = await Supabase
                                                      .instance
                                                      .client
                                                      .from('AWB')
                                                      .select();

                                                  List<Map<String, dynamic>>
                                                  parsedAwbs = [];
                                                  for (var awbRow in res) {
                                                    if (awbRow['data-AWB'] !=
                                                            null &&
                                                        awbRow['data-AWB']
                                                            is List) {
                                                      for (var innerItem
                                                          in (awbRow['data-AWB']
                                                              as List)) {
                                                        if (innerItem['refULD']
                                                                    ?.toString() ==
                                                                uld['ULD-number']
                                                                    ?.toString() &&
                                                            innerItem['refCarrier']
                                                                    ?.toString() ==
                                                                currentFlight['carrier']
                                                                    ?.toString() &&
                                                            innerItem['refNumber']
                                                                    ?.toString() ==
                                                                currentFlight['number']
                                                                    ?.toString() &&
                                                            innerItem['refDate']
                                                                    ?.toString() ==
                                                                currentFlight['date-arrived']
                                                                    ?.toString()) {
                                                          parsedAwbs.add({
                                                            'number':
                                                                awbRow['AWB-number'],
                                                            'pieces':
                                                                innerItem['pieces'],
                                                            'weight':
                                                                innerItem['weight'],
                                                            'remarks':
                                                                innerItem['remarks'],
                                                          });
                                                        }
                                                      }
                                                    }
                                                  }
                                                  uld['awbList'] = parsedAwbs;
                                                } catch (e) {
                                                  debugPrint('Err AWB: $e');
                                                  uld['awbList'] = [];
                                                }

                                                if (mounted) {
                                                  setState(
                                                    () => uld['isLoadingAwbs'] =
                                                        false,
                                                  );
                                                }
                                              } else {
                                                if (mounted) {
                                                  setState(() {
                                                    if (isLeft) {
                                                      _activeAwbOverlayLeft =
                                                          uld;
                                                    } else {
                                                      _activeAwbOverlayRight =
                                                          uld;
                                                    }
                                                  });
                                                }
                                              }
                                            },
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF6366f1,
                                                ).withAlpha(30),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Color(0xFF6366f1),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 105,
                                            child: Text(
                                              '${uld['ULD-number'] ?? '-'}',
                                              style: TextStyle(
                                                color: textP,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            width: 75,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: dark
                                                  ? Colors.white.withAlpha(15)
                                                  : const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'PCs: ${uld['pieces'] ?? '-'}',
                                              style: TextStyle(
                                                color: textS,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            width: 90,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: dark
                                                  ? Colors.white.withAlpha(15)
                                                  : const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${uld['weight'] ?? '-'} kg',
                                              style: TextStyle(
                                                color: textS,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (uld['remarks'] != null &&
                                              uld['remarks']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFf59e0b,
                                                  ).withAlpha(15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFf59e0b,
                                                    ).withAlpha(40),
                                                  ),
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  child: Text(
                                                    '${uld['remarks']}',
                                                    style: const TextStyle(
                                                      color: Color(0xFFd97706),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            const Spacer(),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Row(
                                      children: [
                                        Container(
                                          width: 75,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (uld['isBreak'] == true)
                                                ? const Color(
                                                    0xFF10b981,
                                                  ).withAlpha(30)
                                                : const Color(
                                                    0xFFef4444,
                                                  ).withAlpha(30),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            (uld['isBreak'] == true)
                                                ? 'Break'
                                                : 'No Break',
                                            style: TextStyle(
                                              color: (uld['isBreak'] == true)
                                                  ? const Color(0xFF10b981)
                                                  : const Color(0xFFef4444),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: isFlightReceived
                                                ? true
                                                : uld['selected'] == true,
                                            activeColor: isFlightReceived
                                                ? const Color(0xFF10b981)
                                                : const Color(0xFF6366f1),
                                            side: BorderSide(
                                              color: isFlightReceived
                                                  ? Colors.transparent
                                                  : borderC,
                                              width: 2,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            onChanged: isFlightReceived
                                                ? null
                                                : (v) {
                                                    setState(() {
                                                      uld['selected'] = v;
                                                      if (uld['id'] != null) {
                                                        _savedUldCheckboxState[uld['id']] =
                                                            v ?? false;
                                                      }
                                                      final currentFlightList =
                                                          isLeft
                                                          ? _flightsLeft
                                                          : _flightsRight;
                                                      final idx = currentFlightList
                                                          .indexWhere(
                                                            (f) =>
                                                                '${f['carrier']}-${f['number']}' ==
                                                                selectedId,
                                                          );
                                                      if (idx != -1) {
                                                        if (v == true) {
                                                          if (currentFlightList[idx]['local-first-truck'] ==
                                                              null) {
                                                            currentFlightList[idx]['local-first-truck'] =
                                                                DateTime.now()
                                                                    .toUtc()
                                                                    .toIso8601String();
                                                          }
                                                          currentFlightList[idx]['local-truck-arrived'] ??=
                                                              <
                                                                String,
                                                                dynamic
                                                              >{};
                                                          String uldKey =
                                                              uld['ULD-number']
                                                                  ?.toString() ??
                                                              'Unknown';
                                                          currentFlightList[idx]['local-truck-arrived'][uldKey] =
                                                              DateTime.now()
                                                                  .toUtc()
                                                                  .toIso8601String();
                                                        } else {
                                                          if (currentFlightList[idx]['local-truck-arrived'] !=
                                                              null) {
                                                            String uldKey =
                                                                uld['ULD-number']
                                                                    ?.toString() ??
                                                                'Unknown';
                                                            (currentFlightList[idx]['local-truck-arrived']
                                                                    as Map)
                                                                .remove(uldKey);
                                                          }
                                                        }
                                                      }
                                                    });
                                                  },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (uld['isPriority'] == true)
                                Positioned(
                                  top: -4,
                                  left: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFef4444),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.flash_on,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              Builder(
                                builder: (ctx) {
                                  String? indTime;
                                  if (match.isNotEmpty) {
                                    final f = match.first;
                                    if (f['time-truck-arrived'] != null &&
                                        f['time-truck-arrived'] is Map) {
                                      indTime =
                                          f['time-truck-arrived'][uld['ULD-number']
                                              ?.toString()];
                                    }
                                    if (indTime == null &&
                                        f['local-truck-arrived'] != null &&
                                        f['local-truck-arrived'] is Map) {
                                      indTime =
                                          f['local-truck-arrived'][uld['ULD-number']
                                              ?.toString()];
                                    }
                                  }

                                  if (indTime == null) return const SizedBox();

                                  String toAmPmUld(String t) {
                                    try {
                                      if (t.contains('T')) {
                                        final dt = DateTime.parse(t).toLocal();
                                        int h = dt.hour;
                                        int m = dt.minute;
                                        bool pm = h >= 12;
                                        int h12 = h > 12
                                            ? h - 12
                                            : (h == 0 ? 12 : h);
                                        return '${dt.day}/${dt.month} $h12:${m.toString().padLeft(2, '0')} ${pm ? 'pm' : 'am'}';
                                      }
                                      final pts = t.split(':');
                                      if (pts.length >= 2) {
                                        int h = int.parse(pts[0]);
                                        int m = int.parse(pts[1]);
                                        bool pm = h >= 12;
                                        int h12 = h > 12
                                            ? h - 12
                                            : (h == 0 ? 12 : h);
                                        return '$h12:${m.toString().padLeft(2, '0')} ${pm ? 'pm' : 'am'}';
                                      }
                                    } catch (_) {}
                                    return t;
                                  }

                                  return Positioned(
                                    top: -10,
                                    right: 18,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? const Color(0xFF1e293b)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF10b981,
                                          ).withAlpha(100),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF10b981),
                                            size: 11,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            toAmPmUld(indTime),
                                            style: const TextStyle(
                                              color: Color(0xFF10b981),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  if ((isLeft ? _uldsLeft : _uldsRight).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withAlpha(5)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderC),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildTotalStat(
                                  'Break',
                                  (isLeft ? _uldsLeft : _uldsRight)
                                      .where(
                                        (u) =>
                                            (isFlightReceived
                                                ? true
                                                : u['selected'] == true) &&
                                            u['isBreak'] == true,
                                      )
                                      .length,
                                  (isLeft ? _uldsLeft : _uldsRight)
                                      .where((u) => u['isBreak'] == true)
                                      .length,
                                  const Color(0xFF10b981),
                                ),
                                _buildTotalStat(
                                  'No Break',
                                  (isLeft ? _uldsLeft : _uldsRight)
                                      .where(
                                        (u) =>
                                            (isFlightReceived
                                                ? true
                                                : u['selected'] == true) &&
                                            (u['isBreak'] == false ||
                                                u['isBreak'] == null),
                                      )
                                      .length,
                                  (isLeft ? _uldsLeft : _uldsRight)
                                      .where(
                                        (u) =>
                                            u['isBreak'] == false ||
                                            u['isBreak'] == null,
                                      )
                                      .length,
                                  const Color(0xFFef4444),
                                ),
                                _buildTotalStat(
                                  'Total',
                                  (isLeft ? _uldsLeft : _uldsRight)
                                      .where(
                                        (u) => (isFlightReceived
                                            ? true
                                            : u['selected'] == true),
                                      )
                                      .length,
                                  (isLeft ? _uldsLeft : _uldsRight).length,
                                  const Color(0xFF6366f1),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: borderC,
                          ),
                          Builder(
                            builder: (context) {
                              final currentUlds = isLeft
                                  ? _uldsLeft
                                  : _uldsRight;
                              bool allSelected =
                                  currentUlds.isNotEmpty &&
                                  currentUlds.every(
                                    (u) => u['selected'] == true,
                                  );

                              final flightList = isLeft
                                  ? _flightsLeft
                                  : _flightsRight;
                              final currentFlightIdx = flightList.indexWhere(
                                (f) =>
                                    '${f['carrier']}-${f['number']}' ==
                                    selectedId,
                              );
                              final currentFlight = currentFlightIdx != -1
                                  ? flightList[currentFlightIdx]
                                  : null;

                              Widget actionButton = ElevatedButton.icon(
                                onPressed: isFlightReceived
                                    ? null
                                    : allSelected
                                    ? () async {
                                        try {
                                          // Update ULDs
                                          for (var u in currentUlds) {
                                            if (u['id'] != null) {
                                              await Supabase.instance.client
                                                  .from('ULD')
                                                  .update({
                                                    'status': 'Received',
                                                  })
                                                  .eq('id', u['id']);
                                            }
                                          }

                                          // Update the parent Flight
                                          if (dt != null) {
                                            final parts = selectedId.split('-');
                                            if (parts.length >= 2) {
                                              final dateStr = DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(dt);
                                              try {
                                                final Map<String, dynamic> truckArrivedJson = <String, dynamic>{};
                                                if (currentFlightIdx != -1) {
                                                  if (flightList[currentFlightIdx]['time-truck-arrived'] is Map) {
                                                    truckArrivedJson.addAll(Map<String, dynamic>.from(flightList[currentFlightIdx]['time-truck-arrived']));
                                                  }
                                                  if (flightList[currentFlightIdx]['local-truck-arrived'] is Map) {
                                                    truckArrivedJson.addAll(Map<String, dynamic>.from(flightList[currentFlightIdx]['local-truck-arrived']));
                                                  }
                                                }

                                                String firstTruckTime =
                                                    DateTime.now()
                                                        .toUtc()
                                                        .toIso8601String();
                                                String lastTruckTime =
                                                    firstTruckTime;

                                                if (truckArrivedJson
                                                    .isNotEmpty) {
                                                  List<String> times =
                                                      truckArrivedJson.values
                                                          .map(
                                                            (v) => v.toString(),
                                                          )
                                                          .toList();
                                                  times.sort(
                                                    (a, b) => a.compareTo(b),
                                                  );
                                                  firstTruckTime = times.first;
                                                  lastTruckTime = times.last;
                                                } else if (currentFlightIdx !=
                                                        -1 &&
                                                    flightList[currentFlightIdx]['local-first-truck'] !=
                                                        null) {
                                                  firstTruckTime =
                                                      flightList[currentFlightIdx]['local-first-truck']
                                                          as String;
                                                }

                                                await Supabase.instance.client
                                                    .from('Flight')
                                                    .update({
                                                      'isReceived': true,
                                                      'first-truck':
                                                          firstTruckTime,
                                                      'last-truck':
                                                          lastTruckTime,
                                                      'time-truck-arrived':
                                                          truckArrivedJson,
                                                    })
                                                    .eq('carrier', parts[0])
                                                    .eq('number', parts[1])
                                                    .eq(
                                                      'date-arrived',
                                                      dateStr,
                                                    );

                                                if (currentFlightIdx != -1) {
                                                  flightList[currentFlightIdx]['isReceived'] = true;
                                                  flightList[currentFlightIdx]['first-truck'] =
                                                      firstTruckTime;
                                                  flightList[currentFlightIdx]['last-truck'] =
                                                      lastTruckTime;
                                                  flightList[currentFlightIdx]['time-truck-arrived'] =
                                                      truckArrivedJson;
                                                }
                                              } catch (dbErr) {
                                                debugPrint(
                                                  'Flight update err: $dbErr',
                                                );
                                              }
                                            }
                                          }

                                          setState(() {
                                            for (var u in currentUlds) {
                                              if (u['id'] != null) {
                                                _savedUldCheckboxState.remove(
                                                  u['id'],
                                                );
                                              }
                                            }
                                          });
                                          setState(() {
                                            if (isLeft) {
                                              _showReceivedOverlayLeft = true;
                                            } else {
                                              _showReceivedOverlayRight = true;
                                            }
                                          });
                                          Future.delayed(
                                            const Duration(seconds: 2),
                                            () {
                                              if (mounted) {
                                                setState(() {
                                                  if (isLeft) {
                                                    _showReceivedOverlayLeft =
                                                        false;
                                                  } else {
                                                    _showReceivedOverlayRight =
                                                        false;
                                                  }
                                                });
                                              }
                                            },
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                icon: Icon(
                                  isFlightReceived
                                      ? Icons.verified
                                      : Icons.check_circle_outline,
                                  size: 20,
                                ),
                                label: Text(
                                  isFlightReceived
                                      ? 'Received'
                                      : 'Mark Flight as Received',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFlightReceived
                                      ? Colors.lightBlue.shade100
                                      : const Color(0xFF10b981),
                                  disabledBackgroundColor: isFlightReceived
                                      ? Colors.lightBlue.withAlpha(
                                          dark ? 40 : 100,
                                        )
                                      : const Color(0xFF10b981).withAlpha(60),
                                  disabledForegroundColor: isFlightReceived
                                      ? Colors.lightBlue.shade700
                                      : (dark
                                            ? Colors.white.withAlpha(100)
                                            : Colors.black38),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );

                              if (isFlightReceived &&
                                  currentFlight != null &&
                                  currentFlight['first-truck'] != null) {
                                String toAmPm(String? t) {
                                  if (t == null) return '-';
                                  try {
                                    if (t.contains('T')) {
                                      final dt = DateTime.parse(t).toLocal();
                                      int h = dt.hour;
                                      int m = dt.minute;
                                      bool pm = h >= 12;
                                      int h12 = h > 12
                                          ? h - 12
                                          : (h == 0 ? 12 : h);
                                      return '${dt.day}/${dt.month} $h12:${m.toString().padLeft(2, '0')} ${pm ? 'pm' : 'am'}';
                                    }
                                    final pts = t.split(':');
                                    if (pts.length >= 2) {
                                      int h = int.parse(pts[0]);
                                      int m = int.parse(pts[1]);
                                      bool pm = h >= 12;
                                      int h12 = h > 12
                                          ? h - 12
                                          : (h == 0 ? 12 : h);
                                      return '$h12:${m.toString().padLeft(2, '0')} ${pm ? 'PM' : 'AM'}';
                                    }
                                  } catch (_) {}
                                  return t;
                                }

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 13,
                                              color: Color(0xFF94a3b8),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'First Truck: ${toAmPm(currentFlight['first-truck']?.toString())}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF94a3b8),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.done_all,
                                              size: 13,
                                              color: Color(0xFF10b981),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Last Truck: ${toAmPm(currentFlight['last-truck']?.toString())}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF10b981),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    actionButton,
                                  ],
                                );
                              }

                              return actionButton;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
        if ((isLeft ? _activeAwbOverlayLeft : _activeAwbOverlayRight) !=
            null) ...[
          Positioned.fill(
            child: Container(color: Colors.black.withAlpha(dark ? 120 : 60)),
          ),
          Positioned.fill(
            child: Center(
              child: Builder(
                builder: (ctx) {
                  final activeUld = (isLeft
                      ? _activeAwbOverlayLeft
                      : _activeAwbOverlayRight)!;
                  final list = (activeUld['awbList'] as List?) ?? [];
                  final isLoading = activeUld['isLoadingAwbs'] == true;

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1e293b) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AWBs for ${activeUld['ULD-number'] ?? 'Unknown'}',
                            style: TextStyle(
                              color: textP,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6366f1),
                                ),
                              ),
                            )
                          else if (list.isEmpty)
                            Text(
                              'No AWBs found',
                              style: TextStyle(color: textS),
                            )
                          else
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: list.length,
                                separatorBuilder: (_, _) =>
                                    Divider(color: borderC),
                                itemBuilder: (c, i) {
                                  final awb = list[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.receipt_long,
                                          size: 16,
                                          color: Color(0xFF94a3b8),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${awb['number'] ?? '-'}',
                                            style: TextStyle(
                                              color: textP,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'PCs: ${awb['pieces'] ?? '-'}',
                                          style: TextStyle(
                                            color: textS,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            '${awb['weight'] ?? '-'} kg',
                                            style: TextStyle(
                                              color: textS,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  if (isLeft) {
                                    _activeAwbOverlayLeft = null;
                                  } else {
                                    _activeAwbOverlayRight = null;
                                  }
                                });
                              },
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  color: Color(0xFF6366f1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        if (isLeft ? _showReceivedOverlayLeft : _showReceivedOverlayRight)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1e293b) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
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
                      appLanguage.value == 'es'
                          ? 'Vuelo ${selectedId?.replaceAll('-', ' ') ?? ''} recibido exitosamente'
                          : 'Flight ${selectedId?.replaceAll('-', ' ') ?? ''} received successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textP,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTotalStat(String label, int rem, int total, Color color) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$rem',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' / $total',
                style: const TextStyle(
                  color: Color(0xFF94a3b8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94a3b8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF0f172a).withAlpha(100) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark
                  ? Colors.white.withAlpha(25)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.singlePanelMode
                ? [Expanded(child: _buildPanel(true, dark))]
                : [
                    Expanded(child: _buildPanel(true, dark)),
                    Container(
                      width: 1,
                      color: dark
                          ? Colors.white.withAlpha(25)
                          : const Color(0xFFE5E7EB),
                    ),
                    Expanded(child: _buildPanel(false, dark)),
                  ],
          ),
        );
      },
    );
  }
}
