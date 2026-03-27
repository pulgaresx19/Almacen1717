import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode;

class LocationModule extends StatefulWidget {
  final bool singlePanelMode;
  final String? titleOverride;
  const LocationModule({
    super.key,
    this.singlePanelMode = false,
    this.titleOverride,
  });

  @override
  State<LocationModule> createState() => _LocationModuleState();
}

class _LocationModuleState extends State<LocationModule> {
  // Local storage for discrepancy reports, saving AWB, ULD, diff and notes.
  List<Map<String, dynamic>> localDiscrepancyReports = [];

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
          .eq('refDate', flight['date-arrived'])
          .eq('isBreak', true);

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

    final match = selectedId != null
        ? flights
              .where((f) => '${f['carrier']}-${f['number']}' == selectedId)
              .toList()
        : [];

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
                        appLanguage.value == 'es'
                            ? 'Localización'
                            : 'Location',
                        style: TextStyle(
                          color: textP,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appLanguage.value == 'es'
                            ? 'Módulo para añadir ubicación a los AWBs correspondientes'
                            : 'Module for adding locations to the corresponding AWBs',
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
                    Color textColor = isSel ? Colors.white : textP;
                    Color selColor = const Color(0xFF6366f1);
                    Color unselBgColor = bgCard;
                    Color borderColor = isSel ? Colors.transparent : borderC;


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
                      onSelected: (v) {
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      setState(() {
                                        uld['isExpanded'] =
                                            !(uld['isExpanded'] == true);
                                      });
                                      if (uld['isExpanded'] == true &&
                                          uld['awbList'] == null &&
                                          uld['ULD-number'] != null &&
                                          match.isNotEmpty) {
                                        setState(
                                          () => uld['isLoadingAwbs'] = true,
                                        );
                                        try {
                                          final currentFlight = match.first;
                                          final res = await Supabase
                                              .instance
                                              .client
                                              .from('AWB')
                                              .select();

                                          List<Map<String, dynamic>>
                                          parsedAwbs = [];
                                          for (var awbRow in res) {
                                            if (awbRow['data-AWB'] != null &&
                                                awbRow['data-AWB'] is List) {
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
                                                  List<String> validHawbs = [];
                                                  if (innerItem['house_number'] !=
                                                      null) {
                                                    if (innerItem['house_number']
                                                        is List) {
                                                      validHawbs =
                                                          (innerItem['house_number']
                                                                  as List)
                                                              .map(
                                                                (e) => e
                                                                    .toString()
                                                                    .trim(),
                                                              )
                                                              .where(
                                                                (e) => e
                                                                    .isNotEmpty,
                                                              )
                                                              .toList();
                                                    } else if (innerItem['house_number']
                                                        is String) {
                                                      validHawbs =
                                                          innerItem['house_number']
                                                              .toString()
                                                              .split(
                                                                RegExp(
                                                                  r'[,\n]+',
                                                                ),
                                                              )
                                                              .map(
                                                                (e) => e.trim(),
                                                              )
                                                              .where(
                                                                (e) => e
                                                                    .isNotEmpty,
                                                              )
                                                              .toList();
                                                    }
                                                  } else if (innerItem['house'] !=
                                                      null) {
                                                    validHawbs =
                                                        innerItem['house']
                                                            .toString()
                                                            .split(
                                                              RegExp(r'[,\n]+'),
                                                            )
                                                            .map(
                                                              (e) => e.trim(),
                                                            )
                                                            .where(
                                                              (e) =>
                                                                  e.isNotEmpty,
                                                            )
                                                            .toList();
                                                  }

                                                  parsedAwbs.add({
                                                    'number':
                                                        awbRow['AWB-number'],
                                                    'total':
                                                        awbRow['total'],
                                                    'data-coordinator':
                                                        awbRow['data-coordinator'],
                                                    'data-location':
                                                        awbRow['data-location'],
                                                    'pieces':
                                                        innerItem['pieces'],
                                                    'weight':
                                                        innerItem['weight'],
                                                    'remarks':
                                                        innerItem['remarks'],
                                                    'hawbs': validHawbs,
                                                    'isNew': innerItem['isNew'] == true,
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
                                            () => uld['isLoadingAwbs'] = false,
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
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
                                                Container(
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  width: 75,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: dark
                                                        ? Colors.white
                                                              .withAlpha(15)
                                                        : const Color(
                                                            0xFFF3F4F6,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'PCs: ${uld['pieces'] ?? '-'}',
                                                    style: TextStyle(
                                                      color: textS,
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  width: 90,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: dark
                                                        ? Colors.white
                                                              .withAlpha(15)
                                                        : const Color(
                                                            0xFFF3F4F6,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${uld['weight'] ?? '-'} kg',
                                                    style: TextStyle(
                                                      color: textS,
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
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
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFFd97706,
                                                                ),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
                                          Builder(
                                            builder: (ctx) {
                                              return Row(
                                                children: [

                                                  Builder(
                                                    builder: (context) {
                                                      final bool isSaved = _isUldSaved(uld);
                                                      final bool isChecked = uld['status'] == 'Checked';

                                                      if (!isChecked && !isSaved) return const SizedBox.shrink();

                                                      if (isSaved) {
                                                        return Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF10b981).withAlpha(15),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: const Text('Saved', style: TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold)),
                                                        );
                                                      }

                                                      final bool allAwbsLocated = _areAllAwbsLocated(uld);

                                                      if (allAwbsLocated) {
                                                        return TextButton(
                                                          style: TextButton.styleFrom(
                                                            backgroundColor: const Color(0xFF6366f1),
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                          ),
                                                          onPressed: () async {
                                                            setState(() => uld['isSaving'] = true);
                                                            try {
                                                              await Supabase.instance.client.from('ULD').update({
                                                                'isSaved': true
                                                              }).eq('id', uld['id']);

                                                              if (mounted) {
                                                                setState(() {
                                                                  uld['isSaved'] = true;
                                                                  uld['isSaving'] = false;
                                                                  uld['isExpanded'] = false;
                                                                });
                                                              }
                                                            } catch(e) {
                                                              debugPrint('Error saving ULD: $e');
                                                              if (mounted) {
                                                                setState(() => uld['isSaving'] = false);
                                                              }
                                                            }
                                                          },
                                                          child: uld['isSaving'] == true
                                                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                                              : const Text('Mark ULD as Ready', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                                                        );
                                                      }

                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF3b82f6).withAlpha(15),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'ULD ready to save',
                                                          style: TextStyle(
                                                            color: Color(0xFF3b82f6),
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    uld['isExpanded'] == true
                                                        ? Icons.keyboard_arrow_up
                                                        : Icons.keyboard_arrow_down,
                                                    color: textS,
                                                    size: 20,
                                                  ),
                                                ],
                                              );
                                            }
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (uld['isExpanded'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? const Color(
                                                0xFF1e293b,
                                              ).withAlpha(150)
                                            : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF6366f1,
                                          ).withAlpha(50),
                                        ),
                                      ),
                                      child: uld['isLoadingAwbs'] == true
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF6366f1),
                                                    ),
                                              ),
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      appLanguage.value == 'es'
                                                          ? 'Facturas vinculadas al ULD'
                                                          : 'AWBs assigned to ULD',
                                                      style: TextStyle(
                                                        color: textS,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (uld['status'] != 'Checked')
                                                      InkWell(
                                                        onTap: () async {
                                                          final f = match.isNotEmpty ? match.first : null;
                                                          if (f != null) {
                                                            final res =
                                                                await _showAddAwbOverlay(
                                                                context,
                                                                uld,
                                                                f,
                                                              );
                                                          if (res is Map &&
                                                              mounted) {
                                                            setState(() {
                                                              if (uld['awbList'] ==
                                                                  null) {
                                                                uld['awbList'] =
                                                                    [];
                                                              }
                                                              (uld['awbList']
                                                                      as List)
                                                                  .add(res);
                                                            });
                                                          } else if (res ==
                                                                  true &&
                                                              mounted) {
                                                            setState(() {
                                                              uld['isExpanded'] =
                                                                  false;
                                                            });
                                                          }
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Wait for flight data loaded.',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: dark
                                                              ? Colors.white
                                                                    .withAlpha(
                                                                      15,
                                                                    )
                                                              : const Color(
                                                                  0xFFF3F4F6,
                                                                ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.add,
                                                              size: 11,
                                                              color: textS,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Add AWB',
                                                              style: TextStyle(
                                                                color: textS,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                if (uld['awbList'] == null ||
                                                    (uld['awbList'] as List)
                                                        .isEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                          bottom: 8.0,
                                                        ),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        appLanguage.value ==
                                                                'es'
                                                            ? 'No se encontraron facturas AWB.'
                                                            : 'No AWBs found.',
                                                        style: TextStyle(
                                                          color: textS,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Builder(
                                                      builder: (context) {
                                                        final filteredAwbs = (uld['awbList'] as List).where((awb) {
                                                          List<dynamic> dcList = [];
                                                          if (awb['data-coordinator'] is List) {
                                                            dcList = awb['data-coordinator'] as List;
                                                          } else if (awb['data-coordinator'] is Map) {
                                                            dcList = [awb['data-coordinator']];
                                                          }
                                                          
                                                          final uldNum = uld['ULD-number']?.toString().toUpperCase();
                                                          final uldCarrier = uld['refCarrier']?.toString();
                                                          final uldFlight = uld['refNumber']?.toString();
                                                          
                                                          for (var dc in dcList) {
                                                            if (dc is Map && dc['refULD']?.toString().toUpperCase() == uldNum &&
                                                                dc['refCarrier']?.toString() == uldCarrier &&
                                                                dc['refNumber']?.toString() == uldFlight) {
                                                              if (dc['discrepancy'] != null && dc['discrepancy']['notFound'] == true) {
                                                                return false;
                                                              }
                                                            }
                                                          }
                                                          return true;
                                                        }).toList();

                                                        return Column(
                                                          children: List.generate(
                                                            filteredAwbs.length,
                                                            (awbIdx) {
                                                              final awb = filteredAwbs[awbIdx];
                                                        

                                                        
                                                        bool isChecked = false;
                                                        List<dynamic> dcList = [];
                                                        if (awb['data-coordinator'] is List) {
                                                          dcList = awb['data-coordinator'] as List;
                                                        } else if (awb['data-coordinator'] is Map) {
                                                          dcList = [awb['data-coordinator']];
                                                        }
                                                        
                                                        final uldNum = uld['ULD-number']?.toString().toUpperCase();
                                                        final uldCarrier = uld['refCarrier']?.toString();
                                                        final uldFlight = uld['refNumber']?.toString();
                                                        
                                                        for (var dc in dcList) {
                                                          if (dc is Map && dc['refULD']?.toString().toUpperCase() == uldNum &&
                                                              dc['refCarrier']?.toString() == uldCarrier &&
                                                              dc['refNumber']?.toString() == uldFlight) {
                                                            final bd = dc['breakdown'];
                                                            if (bd is Map && bd.isNotEmpty) {
                                                              bool hasInput = bd.values.any((val) {
                                                                if (val is List) {
                                                                  return val.any((e) => (int.tryParse(e.toString()) ?? 0) > 0);
                                                                }
                                                                if (val is num) return val > 0;
                                                                if (val is String) return (int.tryParse(val) ?? 0) > 0;
                                                                return false;
                                                              });
                                                              if (hasInput) isChecked = true;
                                                            }
                                                          }
                                                        }

                                                        bool isSaved = false;
                                                        List<dynamic> dlList = [];
                                                        if (awb['data-location'] is List) {
                                                          dlList = awb['data-location'] as List;
                                                        } else if (awb['data-location'] is Map) {
                                                          dlList = [awb['data-location']];
                                                        }
                                                        for (var dl in dlList) {
                                                          if (dl is Map && dl['refULD']?.toString().toUpperCase() == uldNum &&
                                                              dl['refCarrier']?.toString() == uldCarrier &&
                                                              dl['refNumber']?.toString() == uldFlight) {
                                                            isSaved = true;
                                                          }
                                                        }

                                                        return Column(
                                                          children: [
                                                            InkWell(
                                                              onTap: () async {
                                                                final res = await _showAwbDetailsOverlay(
                                                                  context,
                                                                  awb,
                                                                  dark,
                                                                  uld,
                                                                );
                                                                if (res != null && mounted) {
                                                                  setState(() {});
                                                                }
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          8.0,
                                                                      horizontal:
                                                                          4.0,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      width: 24,
                                                                      child: Text(
                                                                        '${awbIdx + 1}.',
                                                                        style: TextStyle(
                                                                          color: const Color(
                                                                            0xFF6366f1,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          120,
                                                                      child: Text(
                                                                        '${awb['number']}',
                                                                        style: TextStyle(
                                                                          color:
                                                                              textP,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      width: 70,
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(
                                                                          0xFFf59e0b,
                                                                        ).withAlpha(20),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              4,
                                                                            ),
                                                                      ),
                                                                      child: Text(
                                                                        'PCs: ${awb['pieces'] ?? '-'}',
                                                                        style: const TextStyle(
                                                                          color: Color(
                                                                            0xFFd97706,
                                                                          ),
                                                                          fontSize:
                                                                              11,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Container(
                                                                      width: 80,
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(
                                                                          0xFFf59e0b,
                                                                        ).withAlpha(20),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              4,
                                                                            ),
                                                                      ),
                                                                      child: Text(
                                                                        '${awb['weight'] ?? '-'} kg',
                                                                        style: const TextStyle(
                                                                          color: Color(
                                                                            0xFFd97706,
                                                                          ),
                                                                          fontSize:
                                                                              11,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    if (awb['hawbs'] !=
                                                                            null &&
                                                                        (awb['hawbs']
                                                                                as List)
                                                                            .isNotEmpty) ...[
                                                                      const SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      InkWell(
                                                                        onTap: () {
                                                                          final hList =
                                                                              awb['hawbs']
                                                                                  as List;
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (
                                                                                  ctx,
                                                                                ) => AlertDialog(
                                                                                  backgroundColor: dark
                                                                                      ? const Color(
                                                                                          0xFF1e293b,
                                                                                        )
                                                                                      : Colors.white,
                                                                                  elevation: 8,
                                                                                  contentPadding: const EdgeInsets.symmetric(
                                                                                    horizontal: 16,
                                                                                    vertical: 8,
                                                                                  ),
                                                                                  titlePadding: const EdgeInsets.fromLTRB(
                                                                                    16,
                                                                                    16,
                                                                                    16,
                                                                                    8,
                                                                                  ),
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(
                                                                                      12,
                                                                                    ),
                                                                                  ),
                                                                                  title: Row(
                                                                                    children: [
                                                                                      const Icon(
                                                                                        Icons.inventory_2_outlined,
                                                                                        color: Color(
                                                                                          0xFF6366f1,
                                                                                        ),
                                                                                        size: 18,
                                                                                      ),
                                                                                      const SizedBox(
                                                                                        width: 8,
                                                                                      ),
                                                                                      Text(
                                                                                        'House Numbers',
                                                                                        style: TextStyle(
                                                                                          color: textP,
                                                                                          fontSize: 14,
                                                                                          fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  content: Container(
                                                                                    width: 250,
                                                                                    constraints: const BoxConstraints(
                                                                                      maxHeight: 250,
                                                                                    ),
                                                                                    child: ListView.separated(
                                                                                      shrinkWrap: true,
                                                                                      itemCount: hList.length,
                                                                                      separatorBuilder:
                                                                                          (
                                                                                            _,
                                                                                            _,
                                                                                          ) => Divider(
                                                                                            color: borderC,
                                                                                            height: 1,
                                                                                          ),
                                                                                      itemBuilder:
                                                                                          (
                                                                                            ctx,
                                                                                            i,
                                                                                          ) => Padding(
                                                                                            padding: const EdgeInsets.symmetric(
                                                                                              vertical: 6,
                                                                                            ),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                SizedBox(
                                                                                                  width: 16,
                                                                                                  child: Text(
                                                                                                    '${i + 1}.',
                                                                                                    style: const TextStyle(
                                                                                                      color: Color(
                                                                                                        0xFF6366f1,
                                                                                                      ),
                                                                                                      fontSize: 12,
                                                                                                      fontWeight: FontWeight.bold,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                const SizedBox(
                                                                                                  width: 8,
                                                                                                ),
                                                                                                Expanded(
                                                                                                  child: Text(
                                                                                                    '${hList[i]}',
                                                                                                    style: TextStyle(
                                                                                                      color: textP,
                                                                                                      fontSize: 12,
                                                                                                      fontWeight: FontWeight.w600,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      onPressed: () => Navigator.pop(
                                                                                        ctx,
                                                                                      ),
                                                                                      child: Text(
                                                                                        appLanguage.value ==
                                                                                                'es'
                                                                                            ? 'Cerrar'
                                                                                            : 'Close',
                                                                                        style: const TextStyle(
                                                                                          color: Color(
                                                                                            0xFF6366f1,
                                                                                          ),
                                                                                          fontSize: 12,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                          );
                                                                        },
                                                                        child: Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                8,
                                                                            vertical:
                                                                                2,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                            color:
                                                                                const Color(
                                                                                  0xFF6366f1,
                                                                                ).withAlpha(
                                                                                  20,
                                                                                ),
                                                                            borderRadius: BorderRadius.circular(
                                                                              4,
                                                                            ),
                                                                            border: Border.all(
                                                                              color:
                                                                                  const Color(
                                                                                    0xFF6366f1,
                                                                                  ).withAlpha(
                                                                                    50,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Text(
                                                                                '${(awb['hawbs'] as List).length} ',
                                                                                style: const TextStyle(
                                                                                  color: Color(
                                                                                    0xFF6366f1,
                                                                                  ),
                                                                                  fontSize: 11,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              const Icon(
                                                                                Icons.layers,
                                                                                size: 12,
                                                                                color: Color(
                                                                                  0xFF6366f1,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                    if (awb['remarks'] !=
                                                                            null &&
                                                                        awb['remarks']
                                                                            .toString()
                                                                            .trim()
                                                                            .isNotEmpty) ...[
                                                                      const SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                          '${awb['remarks']}',
                                                                          style: TextStyle(
                                                                            color:
                                                                                textS,
                                                                            fontSize:
                                                                                11,
                                                                            fontStyle:
                                                                                FontStyle.italic,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ] else ...[
                                                                      const Spacer(),
                                                                    ],


                                                                    if (isChecked)
                                                                      GestureDetector(
                                                                        onTap: () {
                                                                          showDialog(
                                                                            context: context,
                                                                            builder: (ctx) => AlertDialog(
                                                                              backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                                                              content: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Container(
                                                                                    padding: const EdgeInsets.all(8),
                                                                                    decoration: BoxDecoration(
                                                                                      color: const Color(0xFF10b981).withAlpha(30),
                                                                                      shape: BoxShape.circle,
                                                                                    ),
                                                                                    child: const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 28),
                                                                                  ),
                                                                                  const SizedBox(height: 12),
                                                                                  Text(
                                                                                    uld['data-checked']?['user']?.toString() ?? 'System',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                      color: dark ? Colors.white : Colors.black87,
                                                                                      fontSize: 16,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 4),
                                                                                  Text(
                                                                                    uld['data-checked']?['time'] != null 
                                                                                        ? DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.parse(uld['data-checked']['time']).toLocal())
                                                                                        : '-',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                      color: textS,
                                                                                      fontSize: 12,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                        child: Container(
                                                                          margin: const EdgeInsets.only(left: 8),
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                          decoration: BoxDecoration(
                                                                            color: const Color(0xFF6366f1).withAlpha(30),
                                                                            borderRadius: BorderRadius.circular(4),
                                                                            border: Border.all(
                                                                              color: const Color(0xFF6366f1).withAlpha(50),
                                                                            ),
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: const [
                                                                              Icon(Icons.check_circle, size: 10, color: Color(0xFF6366f1)),
                                                                              SizedBox(width: 4),
                                                                              Text('Checked', style: TextStyle(color: Color(0xFF6366f1), fontSize: 10, fontWeight: FontWeight.bold)),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      if (isSaved)
                                                                        Container(
                                                                          margin: const EdgeInsets.only(left: 8),
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                          decoration: BoxDecoration(
                                                                            color: const Color(0xFF3b82f6).withAlpha(30),
                                                                            borderRadius: BorderRadius.circular(4),
                                                                            border: Border.all(
                                                                              color: const Color(0xFF3b82f6).withAlpha(50),
                                                                            ),
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: const [
                                                                              Icon(Icons.save, size: 10, color: Color(0xFF3b82f6)),
                                                                              SizedBox(width: 4),
                                                                              Text('Saved', style: TextStyle(color: Color(0xFF3b82f6), fontSize: 10, fontWeight: FontWeight.bold)),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            if (awbIdx <
                                                                filteredAwbs.length - 1)
                                                              Divider(
                                                                color: borderC,
                                                                height: 1,
                                                                thickness: 1,
                                                              ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                            ),
                                    ),
                                ],
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

                              const SizedBox(),
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
                            child: Wrap(
                              alignment: WrapAlignment.spaceEvenly,
                              spacing: 32,
                              runSpacing: 16,
                              children: [
                                _buildTotalStat(
                                  'Saved',
                                  (isLeft ? _uldsLeft : _uldsRight)
                                      .where((u) => _isUldSaved(u))
                                      .length,
                                  (isLeft ? _uldsLeft : _uldsRight).length,
                                  const Color(0xFF10b981),
                                ),
                                  _buildTotalStat(
                                    'Priority',
                                    (isLeft ? _uldsLeft : _uldsRight)
                                        .where((u) => u['isPriority'] == true && _isUldSaved(u))
                                        .length,
                                    (isLeft ? _uldsLeft : _uldsRight)
                                        .where((u) => u['isPriority'] == true)
                                        .length,
                                    const Color(0xFFef4444),
                                  ),
                                Builder(builder: (ctx) {
                                  final awbsWithLocs = _getAwbsWithLocations(isLeft ? _uldsLeft : _uldsRight);
                                  return _buildTotalStat(
                                    'Req. Locations',
                                    awbsWithLocs.length,
                                    -1,
                                    const Color(0xFF8b5cf6),
                                    onTap: () => _showAllLocationsModal(context, awbsWithLocs),
                                  );
                                }),
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
                              bool allUldsChecked =
                                  currentUlds.isNotEmpty &&
                                  currentUlds.every(
                                    (u) => u['status'] == 'Checked',
                                  );

                              final flightList = isLeft
                                  ? _flightsLeft
                                  : _flightsRight;
                              final currentFlightIdx = flightList.indexWhere(
                                (f) =>
                                    '${f['carrier']}-${f['number']}' ==
                                    selectedId,
                              );
                              final bool isFlightChecked = currentFlightIdx != -1 && flightList[currentFlightIdx]['status'] == 'Checked';

                              int totalFlightDiscrepancies = 0;
                              List<Map<String, dynamic>> allFlightDiscrepancies = [];

                              for (var u in currentUlds) {
                                if (u['data-checked'] != null && u['data-checked']['discrepancies'] != null) {
                                  final discs = u['data-checked']['discrepancies'] as List;
                                  for (var d in discs) {
                                    if (d is Map) {
                                      allFlightDiscrepancies.add({
                                        'uld': d['uld']?.toString() ?? 'N/A',
                                        'awb': d['awb']?.toString() ?? 'N/A',
                                        'label': d['label']?.toString() ?? ''
                                      });
                                    }
                                  }
                                  totalFlightDiscrepancies += discs.length;
                                } else if (u['awbList'] is List) {
                                  for (var awbItem in u['awbList']) {
                                    bool hasDisc = false;
                                    List<dynamic> dcList = [];
                                    if (awbItem['data-coordinator'] is List) {
                                      dcList = awbItem['data-coordinator'] as List;
                                    } else if (awbItem['data-coordinator'] is Map) {
                                      dcList = [awbItem['data-coordinator']];
                                    }
                                    
                                    final uldNum = u['ULD-number']?.toString().toUpperCase();
                                    final uCarrier = u['refCarrier']?.toString();
                                    final uFlight = u['refNumber']?.toString();
                                    
                                    for (var dc in dcList) {
                                      if (dc is Map && dc['refULD']?.toString().toUpperCase() == uldNum &&
                                          dc['refCarrier']?.toString() == uCarrier &&
                                          dc['refNumber']?.toString() == uFlight) {
                                        
                                        if (dc['discrepancy'] != null && dc['discrepancy']['confirmed'] == true) {
                                          hasDisc = true;
                                          bool isNotFound = dc['discrepancy']['notFound'] == true;
                                          int rExp = dc['discrepancy']['expected'] as int? ?? 0;
                                          int rRev = dc['discrepancy']['received'] as int? ?? 0;
                                          int diff = (rExp - rRev).abs();
                                          String tStr = rExp > rRev ? 'SHORT' : 'OVER';
                                          allFlightDiscrepancies.add({
                                            'uld': uldNum ?? 'Unknown ULD',
                                            'awb': awbItem['number']?.toString() ?? 'N/A',
                                            'label': isNotFound ? 'NOT FOUND' : '$diff PCs $tStr'
                                          });
                                          break;
                                        }
                                      }
                                    }
                                    
                                    if (awbItem['isNew'] == true) {
                                      if (!hasDisc) {
                                        hasDisc = true;
                                        allFlightDiscrepancies.add({
                                          'uld': u['ULD-number']?.toString().toUpperCase() ?? 'N/A',
                                          'awb': awbItem['number']?.toString() ?? 'N/A',
                                          'label': 'NEW (ADDED)'
                                        });
                                      } else {
                                        int idx = allFlightDiscrepancies.indexWhere((e) => e['awb'] == awbItem['number']?.toString());
                                        if (idx != -1) {
                                          allFlightDiscrepancies[idx]['label'] = '${allFlightDiscrepancies[idx]['label']} (NEW)';
                                        }
                                      }
                                    }
                                    if (hasDisc) totalFlightDiscrepancies++;
                                  }
                                }
                              }

                              bool hasSentReport = currentFlightIdx != -1 && flightList[currentFlightIdx]['report-final'] != null;

                              Widget baseActionButton = ElevatedButton.icon(
                                onPressed: isFlightChecked
                                    ? null
                                    : allUldsChecked
                                    ? () async {
                                        if (totalFlightDiscrepancies > 0 && !hasSentReport) {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Row(
                                                children: [
                                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 28),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    appLanguage.value == 'es' ? 'Acción Requerida' : 'Action Required',
                                                    style: TextStyle(color: textP, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                appLanguage.value == 'es' 
                                                  ? 'Debes verificar y enviar el reporte de discrepancias antes de poder marcar este vuelo como finalizado.' 
                                                  : 'You must verify and submit the discrepancies report before you can mark this flight as completed.',
                                                style: TextStyle(color: textP, fontSize: 15, height: 1.5),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: Text(appLanguage.value == 'es' ? 'Entendido' : 'Understood', style: const TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }

                                        try {
                                          // Update the parent Flight
                                          if (dt != null) {
                                            final parts = selectedId.split('-');
                                            if (parts.length >= 2) {
                                              final dateStr = DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(dt);
                                              try {
                                                final Map<String, dynamic>
                                                truckArrivedJson =
                                                    (currentFlightIdx != -1 &&
                                                        flightList[currentFlightIdx]['local-truck-arrived'] !=
                                                            null)
                                                    ? Map<String, dynamic>.from(
                                                        flightList[currentFlightIdx]['local-truck-arrived'],
                                                      )
                                                    : <String, dynamic>{};

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

                                                final eBreakTime =
                                                    DateTime.now().toUtc().toIso8601String();
                                                await Supabase.instance.client
                                                    .from('Flight')
                                                    .update({
                                                      'status': 'Checked',
                                                      'end-break': eBreakTime,
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
                                                  flightList[currentFlightIdx]['status'] =
                                                      'Checked';
                                                  flightList[currentFlightIdx]['end-break'] =
                                                      eBreakTime;
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

                                          setState(() {});
                                          if (!context.mounted) return;
                                          showDialog(
                                            context: context,
                                            barrierColor: Colors.transparent,
                                            builder: (ctx) => Center(
                                              child: Material(
                                                color: Colors.transparent,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                  decoration: BoxDecoration(
                                                    color: dark ? const Color(0xFF1e293b) : Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black26,
                                                        blurRadius: 10,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 28),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        appLanguage.value == 'es' ? 'Vuelo actualizado correctamente' : 'Flight checked successfully',
                                                        style: TextStyle(
                                                          color: dark ? Colors.white : const Color(0xFF111827),
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                          Future.delayed(const Duration(milliseconds: 1500), () {
                                            if (!context.mounted) return;
                                            if (Navigator.canPop(context)) {
                                              Navigator.pop(context);
                                            }
                                          });
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
                                  isFlightChecked
                                      ? Icons.verified
                                      : Icons.check_circle_outline,
                                  size: 20,
                                ),
                                label: Text(
                                  isFlightChecked ? 'Checked' : 'Mark Flight as Checked',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFlightChecked 
                                    ? const Color(0xFF38bdf8) 
                                    : (allUldsChecked && (totalFlightDiscrepancies == 0 || hasSentReport) 
                                      ? const Color(0xFF10b981) 
                                      : const Color(0xFF10b981).withAlpha(100)),
                                  disabledBackgroundColor: isFlightChecked ? const Color(0xFF38bdf8) : const Color(0xFF10b981).withAlpha(100),
                                  disabledForegroundColor: Colors.white,
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
                              return baseActionButton;
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
                                  bool isChecked = false;
                                  bool hasDiscrepancy = false;
                                  String discrepancyBadge = 'Discrepancy';
                                  List<dynamic> dcList = [];
                                  if (awb['data-coordinator'] is List) {
                                    dcList = awb['data-coordinator'] as List;
                                  } else if (awb['data-coordinator'] is Map) {
                                    dcList = [awb['data-coordinator']];
                                  }
                                  
                                  final uldNum = activeUld['ULD-number']?.toString().toUpperCase();
                                  final uldCarrier = activeUld['refCarrier']?.toString();
                                  final uldFlight = activeUld['refNumber']?.toString();
                                  
                                  for (var dc in dcList) {
                                    if (dc is Map && dc['refULD']?.toString().toUpperCase() == uldNum &&
                                        dc['refCarrier']?.toString() == uldCarrier &&
                                        dc['refNumber']?.toString() == uldFlight) {
                                      final bd = dc['breakdown'];
                                      if (bd is Map && bd.isNotEmpty) {
                                        bool hasInput = bd.values.any((val) {
                                          if (val is List) {
                                            return val.any((e) => (int.tryParse(e.toString()) ?? 0) > 0);
                                          }
                                          if (val is num) return val > 0;
                                          if (val is String) return (int.tryParse(val) ?? 0) > 0;
                                          return false;
                                        });
                                        if (hasInput) isChecked = true;
                                        if (dc['discrepancy'] != null && dc['discrepancy']['confirmed'] == true) {
                                          hasDiscrepancy = true;
                                          int exp = dc['discrepancy']['expected'] as int? ?? 0;
                                          int rec = dc['discrepancy']['received'] as int? ?? 0;
                                          int diff = (exp - rec).abs();
                                          String term = exp > rec ? 'SHORT' : 'OVER';
                                          discrepancyBadge = '$diff PCs $term';
                                        }
                                      }
                                    }
                                  }

                                  bool isSaved = false;
                                  List<dynamic> dlList = [];
                                  if (awb['data-location'] is List) {
                                    dlList = awb['data-location'] as List;
                                  } else if (awb['data-location'] is Map) {
                                    dlList = [awb['data-location']];
                                  }
                                  for (var dl in dlList) {
                                    if (dl is Map && dl['refULD']?.toString().toUpperCase() == uldNum &&
                                        dl['refCarrier']?.toString() == uldCarrier &&
                                        dl['refNumber']?.toString() == uldFlight) {
                                      isSaved = true;
                                    }
                                  }

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
                                        if (hasDiscrepancy)
                                          Container(
                                            margin: const EdgeInsets.only(left: 12),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFef4444).withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFef4444).withAlpha(60)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.warning_rounded, size: 10, color: Color(0xFFef4444)),
                                                const SizedBox(width: 4),
                                                Text(discrepancyBadge, style: const TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        if (isChecked)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366f1).withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFF6366f1).withAlpha(50),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.check_circle, size: 10, color: Color(0xFF6366f1)),
                                                SizedBox(width: 4),
                                                Text('Checked', style: TextStyle(color: Color(0xFF6366f1), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                        ),
                                        if (isSaved)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3b82f6).withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFF3b82f6).withAlpha(50),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.save, size: 10, color: Color(0xFF3b82f6)),
                                                SizedBox(width: 4),
                                                Text('Saved', style: TextStyle(color: Color(0xFF3b82f6), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
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
      ],
    );
  }

  Widget _buildTotalStat(String label, int rem, int total, Color color, {VoidCallback? onTap}) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
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
              if (total != -1)
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: content,
    );
  }

  void _showAllLocationsModal(BuildContext context, List<Map<String, dynamic>> matchingAwbs) {
    final dark = isDarkMode.value;
    final bgC = dark ? const Color(0xFF1e293b) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);
    final borderC = dark ? Colors.white.withAlpha(20) : const Color(0xFFe2e8f0);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: bgC,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF6366f1)),
              const SizedBox(width: 8),
              Text(
                'Required Locations',
                style: TextStyle(color: textP, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: matchingAwbs.isEmpty
                ? Text('No AWBs found.', style: TextStyle(color: textS))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: matchingAwbs.length,
                    separatorBuilder: (_, _) => Divider(color: borderC),
                    itemBuilder: (context, index) {
                      final item = matchingAwbs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['awb']}', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366f1).withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('ULD: ${item['uld']}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dark ? Colors.white.withAlpha(10) : const Color(0xFFf1f5f9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('PCs: ${item['pieces']}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF475569), fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dark ? Colors.white.withAlpha(10) : const Color(0xFFf1f5f9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${item['weight']} kg', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF475569), fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF8b5cf6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    (item['locations'] as List).join(', '),
                                    style: const TextStyle(color: Color(0xFF8b5cf6), fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (item['remarks'] != null && item['remarks'].toString().trim().isNotEmpty && item['remarks'].toString().trim() != '-')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Remarks: ${item['remarks']}', style: TextStyle(color: const Color(0xFFd97706), fontSize: 13, fontStyle: FontStyle.italic)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
            ),
          ],
        );
      },
    );
  }

  bool _isUldSaved(Map<String, dynamic> uld) {
    return uld['isSaved'] == true;
  }

  bool _areAllAwbsLocated(Map<String, dynamic> uld) {
    if (uld['awbList'] is! List) return false;
    final awbList = uld['awbList'] as List;
    if (awbList.isEmpty) return false;
    
    int bCount = 0;
    int sCount = 0;
    final uldNum = uld['ULD-number']?.toString().toUpperCase();
    final uCarrier = uld['refCarrier']?.toString();
    final uFlight = uld['refNumber']?.toString();
    
    for (var awb in awbList) {
      bool isBreak = false;
      bool isSaved = false;
      List<dynamic> dcList = [];
      if (awb['data-coordinator'] is List) {
        dcList = awb['data-coordinator'] as List;
      } else if (awb['data-coordinator'] is Map) {
        dcList = [awb['data-coordinator']];
      }
      for (var dc in dcList) {
        if (dc is Map && dc['refULD']?.toString().toUpperCase() == uldNum &&
            dc['refCarrier']?.toString() == uCarrier &&
            dc['refNumber']?.toString() == uFlight) {
          final bd = dc['breakdown'];
          if (bd is Map && bd.isNotEmpty) {
            isBreak = bd.values.any((val) {
              if (val is List) return val.any((e) => (int.tryParse(e.toString()) ?? 0) > 0);
              if (val is num) return val > 0;
              if (val is String) return (int.tryParse(val) ?? 0) > 0;
              return false;
            });
          }
          if (dc['discrepancy'] != null && dc['discrepancy']['notFound'] == true) {
            isBreak = true;
          }
        }
      }
      
      List<dynamic> locList = [];
      if (awb['data-location'] is List) {
        locList = awb['data-location'] as List;
      } else if (awb['data-location'] is Map) {
        locList = [awb['data-location']];
      }
      for (var loc in locList) {
        if (loc is Map && loc['refULD']?.toString().toUpperCase() == uldNum &&
            loc['refCarrier']?.toString() == uCarrier &&
            loc['refNumber']?.toString() == uFlight) {
          isSaved = true;
        }
      }

      if (isBreak) bCount++;
      if (isSaved) sCount++;
    }
    return bCount > 0 && sCount >= bCount;
  }

  List<Map<String, dynamic>> _getAwbsWithLocations(List<Map<String, dynamic>> ulds) {
    List<Map<String, dynamic>> matchingAwbs = [];
    for (var u in ulds) {
      if (u['inf-location-requerid'] != null && u['inf-location-requerid'] is List) {
        for (var item in u['inf-location-requerid']) {
          if (item is Map<String, dynamic>) {
            matchingAwbs.add(item);
          } else if (item is Map) {
            matchingAwbs.add(Map<String, dynamic>.from(item));
          }
        }
      } else if (u['awbList'] is List) {
        for (var awbItem in u['awbList']) {
          List<dynamic> dcList = [];
          if (awbItem['data-coordinator'] is List) {
            dcList = awbItem['data-coordinator'] as List;
          } else if (awbItem['data-coordinator'] is Map) {
            dcList = [awbItem['data-coordinator']];
          }
          final uldNum = u['ULD-number']?.toString().toUpperCase();
          final uCarrier = u['refCarrier']?.toString();
          final uFlight = u['refNumber']?.toString();
          
          List<String> assignedLocs = [];
          for (var dc in dcList) {
            if (dc is Map && dc['refULD']?.toString().toUpperCase() == uldNum &&
                dc['refCarrier']?.toString() == uCarrier &&
                dc['refNumber']?.toString() == uFlight) {
              if (dc['selectedLocations'] is List) {
                for (var loc in dc['selectedLocations']) {
                  String locStr = loc.toString().trim().toUpperCase();
                  if (locStr.isNotEmpty) {
                    assignedLocs.add(locStr);
                  }
                }
              }
            }
          }
          if (assignedLocs.isNotEmpty) {
            matchingAwbs.add({
              'awb': awbItem['number']?.toString() ?? 'N/A',
              'uld': uldNum ?? 'Unknown',
              'pieces': awbItem['pieces']?.toString() ?? '-',
              'weight': awbItem['weight']?.toString() ?? '-',
              'remarks': awbItem['remarks']?.toString() ?? '-',
              'locations': assignedLocs,
            });
          }
        }
      }
    }
    return matchingAwbs;
  }

  Future<dynamic> _showAwbDetailsOverlay(
    BuildContext context,
    Map<String, dynamic> awb,
    bool dark,
    [Map<String, dynamic>? uldOverride]
  ) async {
    Map<String, List<int>> breakdown = {
      'AGI Skid': [],
      'Pre Skid': [],
      'Crate': [],
      'Box': [],
      'Other': [],
    };
    Map<String, TextEditingController> itemLocationCtrls = {};
    Set<String> confirmedLocations = {};
    String? requiredGlobalLoc;
    bool isLoading = true;

    return await showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        bool isViewMode = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {

            Widget buildLocationEditor(String locKey) {
              if (requiredGlobalLoc != null && !itemLocationCtrls.containsKey(locKey) && !confirmedLocations.contains(locKey)) {
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.withAlpha(30))),
                        child: Text(
                          '$requiredGlobalLoc',
                          style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(15), shape: BoxShape.circle),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10b981), size: 18),
                        tooltip: 'Confirm Required Location',
                        onPressed: () {
                          setDialogState(() {
                            itemLocationCtrls[locKey] = TextEditingController(text: requiredGlobalLoc);
                            confirmedLocations.add(locKey);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withAlpha(5), shape: BoxShape.circle),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.edit_outlined, color: Colors.white60, size: 18),
                        tooltip: 'Override Location',
                        onPressed: () {
                          setDialogState(() {
                            itemLocationCtrls[locKey] = TextEditingController();
                          });
                        },
                      ),
                    ),
                  ],
                );
              }

              if (confirmedLocations.contains(locKey)) {
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(10), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(30))),
                        child: Text(
                          itemLocationCtrls[locKey]?.text ?? '',
                          style: const TextStyle(color: Color(0xFF10b981), fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!isViewMode) ...[
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withAlpha(5), shape: BoxShape.circle),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.edit_outlined, color: Colors.white60, size: 18),
                          tooltip: 'Edit Location',
                          onPressed: () {
                            setDialogState(() {
                              confirmedLocations.remove(locKey);
                              if (requiredGlobalLoc != null && itemLocationCtrls[locKey]?.text == requiredGlobalLoc) {
                                itemLocationCtrls.remove(locKey);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                );
              }

              if (!itemLocationCtrls.containsKey(locKey)) {
                itemLocationCtrls[locKey] = TextEditingController();
              }
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: itemLocationCtrls[locKey],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(text: newValue.text.toUpperCase());
                        }),
                      ],
                      onChanged: (val) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Location...',
                        hintStyle: TextStyle(color: Colors.white.withAlpha(50), fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withAlpha(5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  if (itemLocationCtrls[locKey]?.text.trim().isNotEmpty == true) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10b981)),
                      iconSize: 20,
                      tooltip: 'Confirm Location',
                      onPressed: () {
                        setDialogState(() {
                          confirmedLocations.add(locKey);
                        });
                      },
                    ),
                  ],
                  if (requiredGlobalLoc != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(color: Colors.red.withAlpha(20), shape: BoxShape.circle),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 14),
                        tooltip: 'Cancel Edit',
                        onPressed: () {
                          setDialogState(() {
                            itemLocationCtrls.remove(locKey);
                          });
                        },
                      ),
                    ),
                  ],
                ],
              );
            }

            if (isLoading) {
              isLoading = false;
              // Fetch from Supabase
              Supabase.instance.client
                  .from('AWB')
                  .select('total, data-coordinator, data-location')
                  .eq('AWB-number', awb['number'])
                  .maybeSingle()
                  .then((res) {
                    if (res != null) {
                      if (res['total'] != null) awb['total'] = res['total'];
                      
                      Map<dynamic, dynamic>? dataDc;
                      if (res['data-coordinator'] is List) {
                        final listDc = res['data-coordinator'] as List;
                        final uldNum = uldOverride?['ULD-number']?.toString().toUpperCase();
                        final match = listDc.where((d) => d is Map && d['refULD']?.toString().toUpperCase() == uldNum).toList();
                        if (match.isNotEmpty) dataDc = match.first as Map;
                      } else if (res['data-coordinator'] is Map) {
                        dataDc = res['data-coordinator'];
                      }
                      
                      Map<dynamic, dynamic>? dataLoc;
                      if (res['data-location'] is List) {
                        final listLoc = res['data-location'] as List;
                        final uldNum = uldOverride?['ULD-number']?.toString().toUpperCase() ?? '';
                        final uldFlt = uldOverride?['refNumber']?.toString() ?? '';
                        final match = listLoc.where((d) => d is Map && d['refULD']?.toString().toUpperCase() == uldNum && d['refNumber']?.toString() == uldFlt).toList();
                        if (match.isNotEmpty) dataLoc = match.first as Map;
                      } else if (res['data-location'] is Map) {
                        dataLoc = res['data-location'];
                      }
                      
                      if (dataDc != null) {
                        if (dataDc['breakdown'] is Map) {
                          final bd = dataDc['breakdown'] as Map;
                          for (var k in breakdown.keys) {
                            String legacyKey = k;
                            if (k == 'Crate') legacyKey = 'Crate(s)';
                            if (k == 'Box') legacyKey = 'Box(es)';

                            if (bd[k] is List) {
                              breakdown[k] = (bd[k] as List).map((e) => int.tryParse(e.toString()) ?? 0).toList();
                            } else if (bd[legacyKey] is List) {
                              breakdown[k] = (bd[legacyKey] as List).map((e) => int.tryParse(e.toString()) ?? 0).toList();
                            } else if (bd[k] is num || bd[k] is String) {
                              int val = int.tryParse(bd[k].toString()) ?? 0;
                              breakdown[k] = val > 0 ? [val] : [];
                            } else if (bd[legacyKey] is num || bd[legacyKey] is String) {
                              int val = int.tryParse(bd[legacyKey].toString()) ?? 0;
                              breakdown[k] = val > 0 ? [val] : [];
                            }
                          }
                        }
                        if (dataDc['selectedLocations'] is List && (dataDc['selectedLocations'] as List).isNotEmpty) {
                          requiredGlobalLoc = (dataDc['selectedLocations'] as List).where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
                          if (requiredGlobalLoc!.isEmpty) requiredGlobalLoc = null;
                        }

                        // Fallback to legacy location tracking if new one is missing
                        if (dataLoc == null && dataDc['itemLocations'] is Map) {
                          dataLoc = {'itemLocations': dataDc['itemLocations']};
                        }
                      }
                      
                      if (dataLoc != null) {
                        if (dataLoc['itemLocations'] is Map) {
                          final locMap = dataLoc['itemLocations'] as Map;
                          if (locMap.isNotEmpty) {
                            isViewMode = true;
                          }
                          locMap.forEach((k, v) {
                            itemLocationCtrls[k.toString()] = TextEditingController(text: v.toString());
                            confirmedLocations.add(k.toString());
                          });
                        }
                      }
                    }
                    if (dialogCtx.mounted) setDialogState(() {});
                  });
            }

            int totalChecked = breakdown.values
                .expand((element) => element)
                .fold(0, (a, b) => a + b);

            bool allSet = totalChecked > 0;
            Map<String, dynamic> locationData = {};
            breakdown.forEach((k, list) {
              if (k == 'AGI Skid') {
                for (int i = 0; i < list.length; i++) {
                  String key = '${k}_$i';
                  if (!itemLocationCtrls.containsKey(key) || itemLocationCtrls[key]!.text.trim().isEmpty) {
                    allSet = false;
                  } else {
                    locationData[key] = itemLocationCtrls[key]!.text.trim();
                  }
                }
              } else {
                int totalPcs = list.isNotEmpty ? list.fold(0, (a, b) => a + b) : 0;
                if (totalPcs > 0) {
                  if (!itemLocationCtrls.containsKey(k) || itemLocationCtrls[k]!.text.trim().isEmpty) {
                    allSet = false;
                  } else {
                    locationData[k] = itemLocationCtrls[k]!.text.trim();
                  }
                }
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withAlpha(10)),
              ),
              title: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    icon: Icon(Icons.close_rounded, color: Colors.white.withAlpha(80), size: 16),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                  Expanded(
                    child: Text(
                      'AWB: ${awb['number']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top summary bar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withAlpha(10)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatMini('PIECES', '${awb['pieces'] ?? '-'}'),
                                _buildStatMini('TOTAL', '${awb['total'] ?? '-'}'),
                                _buildStatMini(
                                  'WEIGHT',
                                  '${awb['weight'] ?? '-'} kg',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildStatMini(
                                    'HOUSES',
                                    '${(awb['hawbs'] as List?)?.length ?? '0'}',
                                    onTap: () {
                                      final hList = (awb['hawbs'] as List?) ?? [];
                                      if (hList.isEmpty) return;
                                      showDialog(
                                        context: dialogCtx,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1e293b),
                                          elevation: 8,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          titlePadding: const EdgeInsets.fromLTRB(
                                            16,
                                            16,
                                            16,
                                            8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          title: Row(
                                            children: const [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                color: Color(0xFF6366f1),
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'House Numbers',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Container(
                                            width: 250,
                                            constraints: const BoxConstraints(
                                              maxHeight: 250,
                                            ),
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: hList.length,
                                              separatorBuilder:
                                                  (_, _) => const Divider(
                                                    color: Color(0xFF334155),
                                                  ),
                                              itemBuilder: (c, i) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                                  child: Text(
                                                    hList[i].toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Close', style: TextStyle(color: Color(0xFF94a3b8))),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatMini(
                                    'REMARKS',
                                    (awb['remarks']?.toString().trim().isEmpty ?? true)
                                        ? '-'
                                        : awb['remarks'].toString().trim(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AWB BREAK DOWN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Total Checked: ',
                                style: TextStyle(
                                  color: Color(0xFF94a3b8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3b82f6).withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalChecked',
                                  style: const TextStyle(
                                    color: Color(0xFF60a5fa),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      Container(
                        height: 250,
                        width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withAlpha(10),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView(
                                padding: const EdgeInsets.all(12),
                                children: breakdown.entries.where((e) => e.value.isNotEmpty).map((
                                  entry,
                                ) {
                                  int itemCount = entry.value.length;
                                  int totalPcs = entry.value.fold<int>(0, (a, b) => a + b);

                                  String getDisplayName(String key, int count) {
                                    if (count <= 1) return key.toUpperCase();
                                    if (key == 'Box') return 'BOXES';
                                    return '${key.toUpperCase()}S';
                                  }

                                  if (entry.key == 'AGI Skid') {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(10),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(25),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '$itemCount',
                                                  style: const TextStyle(
                                                    color: Color(0xFFcbd5e1),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                getDisplayName(entry.key, itemCount),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '$totalPcs pcs',
                                                style: const TextStyle(
                                                  color: Color(0xFF94a3b8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ...entry.value.asMap().entries.map((
                                            item,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '#${item.key + 1}',
                                                    style: const TextStyle(color: Color(0xFF64748b), fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                    decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(4)),
                                                    child: Text('${item.value}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: (() {
                                                      String locKey = '${entry.key}_${item.key}';
                                                      return buildLocationEditor(locKey);
                                                    })(),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(10),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$totalPcs',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            getDisplayName(entry.key, totalPcs),
                                            style: const TextStyle(
                                              color: Color(0xFF94a3b8),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: (() {
                                              String locKey = entry.key;
                                              return buildLocationEditor(locKey);
                                            })(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }).toList(),
                              ),
                            ),

                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                if (uldOverride?['isSaved'] != true)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isViewMode ? const Color(0xFF3b82f6) : (allSet ? const Color(0xFF6366f1) : Colors.white.withAlpha(10)),
                      foregroundColor: (allSet || isViewMode) ? Colors.white : Colors.white.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: isViewMode
                        ? () {
                            setDialogState(() {
                              isViewMode = false;
                            });
                          }
                        : (!allSet || isSaving)
                            ? null
                            : () async {
                            setDialogState(() => isSaving = true);
                            try {
                              final existing = await Supabase.instance.client
                                  .from('AWB')
                                  .select('data-location')
                                  .eq('AWB-number', awb['number'])
                                  .maybeSingle();
                              
                              List<dynamic> dlList = [];
                              if (existing != null) {
                                if (existing['data-location'] is List) {
                                  dlList = List.from(existing['data-location']);
                                } else if (existing['data-location'] is Map) {
                                  dlList = [existing['data-location']];
                                }
                              }

                              Map<String, dynamic> locData = {};
                              
                              final uldNum = uldOverride?['ULD-number']?.toString().toUpperCase() ?? '';
                              final uldCar = uldOverride?['refCarrier']?.toString() ?? '';
                              final uldFlt = uldOverride?['refNumber']?.toString() ?? '';
                              final uldDate = uldOverride?['refDate']?.toString() ?? '';

                              int matchIndex = dlList.indexWhere((d) => d is Map && d['refULD']?.toString().toUpperCase() == uldNum && d['refNumber']?.toString() == uldFlt);
                              if (matchIndex != -1) {
                                locData = Map<String, dynamic>.from(dlList[matchIndex]);
                              }
                              
                              locData['itemLocations'] = locationData;
                              locData['refULD'] = uldNum;
                              locData['refCarrier'] = uldCar;
                              locData['refNumber'] = uldFlt;
                              locData['refDate'] = uldDate;
                              locData['updatedAt'] = DateTime.now().toIso8601String();

                              if (matchIndex != -1) {
                                dlList[matchIndex] = locData;
                              } else {
                                dlList.add(locData);
                              }

                              await Supabase.instance.client
                                  .from('AWB')
                                  .update({'data-location': dlList})
                                  .eq('AWB-number', awb['number']);

                              awb['data-location'] = dlList;

                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx, awb);
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  barrierColor: Colors.black45,
                                  transitionDuration: const Duration(milliseconds: 200),
                                  pageBuilder: (ctx, anim1, anim2) {
                                    Future.delayed(const Duration(milliseconds: 1500), () {
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    });
                                    return Center(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          decoration: BoxDecoration(color: const Color(0xFF10b981), borderRadius: BorderRadius.circular(8)),
                                          child: const Text('Locations saved correctly', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                      ),
                                    );
                                  },
                                  transitionBuilder: (ctx, anim1, anim2, child) {
                                    return FadeTransition(opacity: anim1, child: child);
                                  },
                                );
                              }
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving location data: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (dialogCtx.mounted) setDialogState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isViewMode ? 'Edit Location' : 'Save All Locations',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatMini(String label, String value, {VoidCallback? onTap}) {
    Widget content = Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748b),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: content,
        ),
      );
    }
    return content;
  }

  Future<dynamic> _showAddAwbOverlay(
    BuildContext context,
    Map<String, dynamic> uld,
    Map<String, dynamic> currentFlight,
  ) async {
    final awbNumCtrl = TextEditingController();
    final piecesCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final remCtrl = TextEditingController();
    final totalLocked = ValueNotifier<bool>(false);

    awbNumCtrl.addListener(() {
      final text = awbNumCtrl.text.toUpperCase();
      if (text.length == 13) {
        () async {
          try {
            final res = await Supabase.instance.client
                .from('AWB')
                .select('total')
                .eq('AWB-number', text)
                .maybeSingle();
            if (res != null &&
                res['total'] != null &&
                awbNumCtrl.text.toUpperCase() == text) {
              totalLocked.value = true;
              totalCtrl.text = res['total'].toString();
            }
          } catch (_) {}
        }();
      } else {
        if (totalLocked.value) {
          totalLocked.value = false;
          totalCtrl.text = '0';
        }
      }
    });

    return await showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        double houseHeight = 120.0;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            Widget buildTextField(
              String label,
              TextEditingController ctrl,
              String hint, {
              bool isUpperCase = false,
              bool isNum = false,
              bool allowDecimal = false,
              bool digitsOnly = false,
              bool disabled = false,
              bool isAwb = false,
              bool expands = false,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFcbd5e1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  expands
                      ? Expanded(
                          child: TextField(
                            controller: ctrl,
                            enabled: !disabled,
                            keyboardType: isNum
                                ? (allowDecimal
                                      ? const TextInputType.numberWithOptions(
                                          decimal: true,
                                        )
                                      : TextInputType.number)
                                : TextInputType.text,
                            maxLines: expands ? null : 1,
                            minLines: expands ? null : null,
                            expands: true,
                            inputFormatters: [
                              if (isUpperCase)
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) => newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                  ),
                                ),
                              if (digitsOnly)
                                FilteringTextInputFormatter.digitsOnly,
                              if (isNum && !digitsOnly)
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              if (isAwb)
                                TextInputFormatter.withFunction((
                                  oldValue,
                                  newValue,
                                ) {
                                  if (newValue.text.isEmpty) return newValue;
                                  String raw = newValue.text.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );
                                  if (raw.length > 11) {
                                    raw = raw.substring(0, 11);
                                  }
                                  String formatted = '';
                                  for (int i = 0; i < raw.length; i++) {
                                    if (i == 3) formatted += '-';
                                    if (i == 7) formatted += ' ';
                                    formatted += raw[i];
                                  }
                                  return TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                                }),
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: hint,
                              hintStyle: TextStyle(
                                color: Colors.white.withAlpha(76),
                              ),
                              filled: true,
                              fillColor: disabled
                                  ? Colors.white.withAlpha(5)
                                  : Colors.white.withAlpha(13),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(25),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8b5cf6),
                                  width: 1.5,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(10),
                                ),
                              ),
                            ),
                          ),
                        )
                      : TextField(
                          controller: ctrl,
                          enabled: !disabled,
                          keyboardType: isNum
                              ? (allowDecimal
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true,
                                      )
                                    : TextInputType.number)
                              : TextInputType.text,
                          maxLines: 1,
                          inputFormatters: [
                            if (isUpperCase)
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) => newValue.copyWith(
                                  text: newValue.text.toUpperCase(),
                                ),
                              ),
                            if (digitsOnly)
                              FilteringTextInputFormatter.digitsOnly,
                            if (isNum && !digitsOnly)
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            if (isAwb)
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                if (newValue.text.isEmpty) return newValue;
                                String raw = newValue.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                if (raw.length > 11) raw = raw.substring(0, 11);
                                String formatted = '';
                                for (int i = 0; i < raw.length; i++) {
                                  if (i == 3) formatted += '-';
                                  if (i == 7) formatted += ' ';
                                  formatted += raw[i];
                                }
                                return TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              }),
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(
                              color: Colors.white.withAlpha(76),
                            ),
                            filled: true,
                            fillColor: disabled
                                ? Colors.white.withAlpha(5)
                                : Colors.white.withAlpha(13),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.white.withAlpha(25),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF8b5cf6),
                                width: 1.5,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.white.withAlpha(10),
                              ),
                            ),
                          ),
                        ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              title: Text(
                'Add AWB to ${uld['ULD-number'] ?? ''}',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3b82f6).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF3b82f6).withAlpha(50),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF60a5fa),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Flight and ULD references are detected automatically and linked safely to this AWB document.',
                                style: TextStyle(
                                  color: Color(0xFF93c5fd),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 145,
                            child: buildTextField(
                              'AWB Number',
                              awbNumCtrl,
                              '123-1234 5678',
                              isAwb: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: buildTextField(
                              'Pieces',
                              piecesCtrl,
                              '0',
                              isNum: true,
                              digitsOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: totalLocked,
                              builder: (ctx, locked, _) => buildTextField(
                                'Total',
                                totalCtrl,
                                '0',
                                isNum: true,
                                digitsOnly: true,
                                disabled: locked,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: buildTextField(
                              'Weight',
                              weightCtrl,
                              '0.0',
                              isNum: true,
                              allowDecimal: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      buildTextField('Remarks', remCtrl, 'Notas...'),
                      const SizedBox(height: 12),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          SizedBox(
                            height: houseHeight,
                            child: buildTextField(
                              'House Number',
                              houseCtrl,
                              'HAWB1, HAWB2...',
                              expands: true,
                              isUpperCase: true,
                            ),
                          ),
                          GestureDetector(
                            onPanUpdate: (details) {
                              setDialogState(() {
                                houseHeight = (houseHeight + details.delta.dy)
                                    .clamp(80.0, 500.0);
                              });
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CustomPaint(
                                    painter: _SharedResizePainter(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF94a3b8)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newAwb = awbNumCtrl.text.trim().toUpperCase();
                          if (newAwb.isEmpty || totalCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'AWB Number y Total obligatorios',
                                ),
                              ),
                            );
                            return;
                          }

                          void showDuplicateAlert() {
                            showDialog(
                              context: dialogCtx,
                              builder: (alertCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF1e293b),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.orange.withAlpha(50),
                                  ),
                                ),
                                title: Row(
                                  children: const [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orangeAccent,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Duplicate Entry',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  'This AWB document is already registered under the selected ULD and Flight references. Please verify the AWB number.',
                                  style: TextStyle(
                                    color: Color(0xFF94a3b8),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(alertCtx),
                                    child: const Text(
                                      'Understood',
                                      style: TextStyle(
                                        color: Color(0xFF8b5cf6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Local instant check
                          final localAwbList = (uld['awbList'] as List?) ?? [];
                          final existsLocally = localAwbList.any(
                            (a) => a is Map && a['number'] == newAwb,
                          );
                          if (existsLocally) {
                            showDuplicateAlert();
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final houseStr = houseCtrl.text.trim();
                            final houseArr = houseStr.isEmpty
                                ? []
                                : houseStr
                                      .split(RegExp(r'[,\s]+'))
                                      .where((s) => s.isNotEmpty)
                                      .map((e) => e.toUpperCase())
                                      .toList();

                            final dataAwb = {
                              'pieces': int.tryParse(piecesCtrl.text) ?? 1,
                              'refULD':
                                  uld['ULD-number']?.toString().toUpperCase() ??
                                  '',
                              'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                              'isBreak': uld['isBreak'] == true,
                              'refDate':
                                  currentFlight['date-arrived']?.toString() ??
                                  '',
                              'remarks': remCtrl.text,
                              'refNumber':
                                  currentFlight['number']?.toString() ?? '',
                              'refCarrier':
                                  currentFlight['carrier']?.toString() ?? '',
                              'house_number': houseArr,
                              'isNew': true,
                            };

                            final existingAwb = await Supabase.instance.client
                                .from('AWB')
                                .select()
                                .eq('AWB-number', newAwb)
                                .maybeSingle();

                            if (existingAwb != null) {
                              List<dynamic> existingDataAwb =
                                  existingAwb['data-AWB'] ?? [];

                              // Database remote check
                              bool alreadyExists = existingDataAwb.any(
                                (e) =>
                                    e is Map &&
                                    e['refULD'] == dataAwb['refULD'] &&
                                    e['refDate'] == dataAwb['refDate'] &&
                                    e['refNumber'] == dataAwb['refNumber'] &&
                                    e['refCarrier'] == dataAwb['refCarrier'],
                              );

                              if (alreadyExists) {
                                if (!dialogCtx.mounted) return;
                                showDuplicateAlert();
                                setDialogState(() => isSaving = false);
                                return; // Do NOT insert
                              }

                              existingDataAwb.add(dataAwb);
                              await Supabase.instance.client
                                  .from('AWB')
                                  .update({'data-AWB': existingDataAwb})
                                  .eq('AWB-number', newAwb);
                            } else {
                              final payload = {
                                'AWB-number': newAwb,
                                'total': int.tryParse(totalCtrl.text) ?? 1,
                                'data-AWB': [dataAwb],
                                'data-coordinator': {},
                                'data-location': {},
                                'created_at': DateTime.now()
                                    .toUtc()
                                    .toIso8601String(),
                              };
                              await Supabase.instance.client
                                  .from('AWB')
                                  .insert(payload);
                            }
                            if (!dialogCtx.mounted) return;

                            final fullCreatedAwbObject = {
                              'number': newAwb,
                              'pieces': int.tryParse(piecesCtrl.text) ?? 1,
                              'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                              'total': int.tryParse(totalCtrl.text) ?? 1,
                              'hawbs': houseArr,
                              'data-AWB': [dataAwb],
                              'isNew': true,
                            };
                            Navigator.of(dialogCtx).pop(fullCreatedAwbObject);
                          } catch (e) {
                            if (!dialogCtx.mounted) return;
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add AWB',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
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
            children: [Expanded(child: _buildPanel(true, dark))],
          ),
        );
      },
    );
  }
}


class _SharedResizePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94a3b8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height),
      Offset(size.width, size.height * 0.45),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.9, size.height),
      Offset(size.width, size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}