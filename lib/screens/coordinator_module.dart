import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode;

class CoordinatorModule extends StatefulWidget {
  final bool singlePanelMode;
  final String? titleOverride;
  const CoordinatorModule({
    super.key,
    this.singlePanelMode = false,
    this.titleOverride,
  });

  @override
  State<CoordinatorModule> createState() => _CoordinatorModuleState();
}

class _CoordinatorModuleState extends State<CoordinatorModule> {
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
                            ? 'Coordinador'
                            : 'Coordinator',
                        style: TextStyle(
                          color: textP,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appLanguage.value == 'es'
                            ? 'Módulo para verificación y check-in de vuelos y AWBs'
                            : 'Module for verification and check-in of flights and AWBs',
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
                    final isChecked = f['status'] == 'Checked';

                    Color textColor = isSel ? Colors.white : (isChecked ? const Color(0xFF10b981) : textP);
                    Color selColor = isChecked ? const Color(0xFF10b981) : const Color(0xFF6366f1);
                    Color unselBgColor = isChecked ? const Color(0xFF10b981).withAlpha(15) : bgCard;
                    Color borderColor = isSel ? Colors.transparent : (isChecked ? const Color(0xFF10b981).withAlpha(50) : borderC);


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
                                              bool allAwbChecked = false;
                                              int discrepantAwbCount = 0;
                                              List<Map<String, dynamic>> discrepantAwbsList = [];

                                              if (uld['data-checked'] != null && uld['data-checked']['discrepancies'] != null) {
                                                final discs = uld['data-checked']['discrepancies'] as List;
                                                for (var d in discs) {
                                                  if (d is Map) {
                                                    discrepantAwbsList.add({
                                                      'awb': d['awb']?.toString() ?? 'N/A',
                                                      'label': d['label']?.toString() ?? ''
                                                    });
                                                  }
                                                }
                                                discrepantAwbCount = discrepantAwbsList.length;
                                                allAwbChecked = true;
                                              } else if (uld['awbList'] is List && (uld['awbList'] as List).isNotEmpty) {
                                                final listAwb = uld['awbList'] as List;
                                                int checkedCount = 0;
                                                for (var awbItem in listAwb) {
                                                  bool checked = false;
                                                  bool hasDisc = false;
                                                  List<dynamic> dcList = [];
                                                  if (awbItem['data-coordinator'] is List) {
                                                    dcList = awbItem['data-coordinator'] as List;
                                                  } else if (awbItem['data-coordinator'] is Map) {
                                                    dcList = [awbItem['data-coordinator']];
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
                                                        checked = bd.values.any((val) {
                                                          if (val is List) return val.any((e) => (int.tryParse(e.toString()) ?? 0) > 0);
                                                          if (val is num) return val > 0;
                                                          if (val is String) return (int.tryParse(val) ?? 0) > 0;
                                                          return false;
                                                        });
                                                      }
                                                      if (dc['discrepancy'] != null && dc['discrepancy']['confirmed'] == true) {
                                                        hasDisc = true;
                                                        bool isNotFound = dc['discrepancy']['notFound'] == true;
                                                        if (isNotFound) checked = true;
                                                        int rExp = dc['discrepancy']['expected'] as int? ?? 0;
                                                        int rRev = dc['discrepancy']['received'] as int? ?? 0;
                                                        int diff = (rExp - rRev).abs();
                                                        String tStr = rExp > rRev ? 'SHORT' : 'OVER';
                                                        discrepantAwbsList.add({
                                                          'awb': awbItem['number']?.toString() ?? 'N/A',
                                                          'label': isNotFound ? 'NOT FOUND' : '$diff PCs $tStr'
                                                        });
                                                      }
                                                    }
                                                  }
                                                  
                                                  if (awbItem['isNew'] == true) {
                                                    if (!hasDisc) {
                                                      hasDisc = true;
                                                      discrepantAwbsList.add({
                                                        'awb': awbItem['number']?.toString() ?? 'N/A',
                                                        'label': 'NEW (ADDED)'
                                                      });
                                                    } else {
                                                      int idx = discrepantAwbsList.indexWhere((e) => e['awb'] == awbItem['number']?.toString());
                                                      if (idx != -1) {
                                                        discrepantAwbsList[idx]['label'] = '${discrepantAwbsList[idx]['label']} (NEW)';
                                                      }
                                                    }
                                                  }

                                                  if (checked) checkedCount++;
                                                  if (hasDisc) discrepantAwbCount++;
                                                }
                                                allAwbChecked = checkedCount == listAwb.length;
                                              }
                                              
                                              final isCheckedStatus = uld['status'] == 'Checked';
                                              final canCheck = !isCheckedStatus && allAwbChecked;

                                              return Row(
                                                children: [
                                                  if (discrepantAwbCount > 0) ...[
                                                    GestureDetector(
                                                      onTap: () {
                                                        showDialog(
                                                          context: ctx,
                                                          builder: (dCtx) {
                                                            return AlertDialog(
                                                              backgroundColor: const Color(0xFF1e293b),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                              title: const Text('Discrepancies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                              content: Container(
                                                                width: 320,
                                                                constraints: const BoxConstraints(maxHeight: 400),
                                                                child: ListView.builder(
                                                                  shrinkWrap: true,
                                                                  itemCount: discrepantAwbsList.length,
                                                                  itemBuilder: (context, idx) {
                                                                    final d = discrepantAwbsList[idx];
                                                                    return Padding(
                                                                      padding: const EdgeInsets.only(bottom: 12.0),
                                                                      child: Container(
                                                                        padding: const EdgeInsets.all(12),
                                                                        decoration: BoxDecoration(
                                                                          color: const Color(0xFF0f172a),
                                                                          borderRadius: BorderRadius.circular(8),
                                                                          border: Border.all(color: const Color(0xFF334155)),
                                                                        ),
                                                                        child: Row(
                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Text(d['awb'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                            Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                              decoration: BoxDecoration(
                                                                                color: const Color(0xFFef4444).withAlpha(30),
                                                                                borderRadius: BorderRadius.circular(4),
                                                                                border: Border.all(color: const Color(0xFFef4444).withAlpha(60)),
                                                                              ),
                                                                              child: Text(d['label'], style: const TextStyle(color: Color(0xFFef4444), fontSize: 12, fontWeight: FontWeight.bold)),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(dCtx),
                                                                  style: TextButton.styleFrom(
                                                                    backgroundColor: const Color(0xFF334155),
                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                  ),
                                                                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                                                                )
                                                              ],
                                                            );
                                                          }
                                                        );
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFef4444).withAlpha(30),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: const Color(0xFFef4444).withAlpha(60)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.warning_rounded, size: 12, color: Color(0xFFef4444)),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '$discrepantAwbCount Discrepanc${discrepantAwbCount > 1 ? 'ies' : 'y'}',
                                                              style: const TextStyle(color: Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                  ],
                                                  InkWell(
                                                    onTap: canCheck ? () async {
                                                      try {
                                                        final uUser = Supabase.instance.client.auth.currentUser;
                                                        String nameStr = uUser?.email?.split('@')[0] ?? 'Usuario';
                                                        if (uUser != null) {
                                                          try {
                                                            final userRow = await Supabase.instance.client
                                                                .from('Users')
                                                                .select('full-name')
                                                                .eq('id', uUser.id)
                                                                .maybeSingle();
                                                            if (userRow != null && userRow['full-name'] != null) {
                                                              nameStr = userRow['full-name'];
                                                            }
                                                          } catch (_) {}
                                                        }
                                                        final tStr = DateTime.now().toUtc().toIso8601String();
                                                        final List<Map<String, dynamic>> finalDiscList = discrepantAwbsList.map((e) => {
                                                          'uld': uld['ULD-number']?.toString().toUpperCase(),
                                                          'awb': e['awb'],
                                                          'label': e['label']
                                                        }).toList();
                                                        final cData = {
                                                          'user': nameStr, 
                                                          'time': tStr,
                                                          if (finalDiscList.isNotEmpty) 'discrepancies': finalDiscList
                                                        };

                                                        await Supabase.instance.client
                                                          .from('ULD')
                                                          .update({
                                                            'status': 'Checked',
                                                            'data-checked': cData,
                                                          })
                                                          .eq('ULD-number', uld['ULD-number'])
                                                          .eq('refCarrier', uld['refCarrier'])
                                                          .eq('refNumber', uld['refNumber']);
                                                        if (mounted) {
                                                          setState(() {
                                                            uld['status'] = 'Checked';
                                                            uld['data-checked'] = cData;
                                                            uld['isExpanded'] = false;
                                                          });
                                                        }

                                                        final cFL = match.isNotEmpty ? match.first : null;
                                                        if (cFL != null && cFL['start-break'] == null) {
                                                          final sTime = DateTime.now().toUtc().toIso8601String();
                                                          await Supabase.instance.client
                                                              .from('Flight')
                                                              .update({'start-break': sTime})
                                                              .eq('id', cFL['id']);
                                                          if (mounted) {
                                                            setState(() {
                                                              cFL['start-break'] = sTime;
                                                            });
                                                          }
                                                        }
                                                      } catch (_) {}
                                                    } : null,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: isCheckedStatus ? const Color(0xFF10b981).withAlpha(15) : (canCheck ? const Color(0xFF6366f1) : const Color(0xFFf59e0b).withAlpha(15)),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            if (canCheck) ...[
                                                              const Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                                                              const SizedBox(width: 4),
                                                            ],
                                                            Text(
                                                              isCheckedStatus ? 'Checked' : (canCheck ? 'Mark as Checked' : 'Pending'),
                                                              style: TextStyle(
                                                                color: isCheckedStatus ? const Color(0xFF10b981) : (canCheck ? Colors.white : const Color(0xFFd97706)),
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
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
                                                  Column(
                                                    children: List.generate(
                                                      (uld['awbList'] as List)
                                                          .length,
                                                      (awbIdx) {
                                                        final awb =
                                                            (uld['awbList']
                                                                as List)[awbIdx];
                                                        

                                                        
                                                        bool isChecked = false;
                                                        bool hasDiscrepancy = false;
                                                        String discrepancyBadge = 'Discrepancy';
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
                                                              if (dc['discrepancy'] != null && dc['discrepancy']['confirmed'] == true) {
                                                                hasDiscrepancy = true;
                                                                bool isNotFound = dc['discrepancy']['notFound'] == true;
                                                                if (isNotFound) isChecked = true;
                                                                int exp = dc['discrepancy']['expected'] as int? ?? 0;
                                                                int rec = dc['discrepancy']['received'] as int? ?? 0;
                                                                int diff = (exp - rec).abs();
                                                                String term = exp > rec ? 'SHORT' : 'OVER';
                                                                discrepancyBadge = isNotFound ? 'NOT FOUND' : '$diff PCs $term';
                                                              }
                                                            }
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
                                                                    if (awb['isNew'] == true)
                                                                      Container(
                                                                        margin: const EdgeInsets.only(left: 8),
                                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                                        decoration: BoxDecoration(
                                                                          color: const Color(0xFF10b981).withAlpha(30),
                                                                          borderRadius: BorderRadius.circular(4),
                                                                          border: Border.all(color: const Color(0xFF10b981).withAlpha(100)),
                                                                        ),
                                                                        child: const Text('NEW', style: TextStyle(color: Color(0xFF10b981), fontSize: 9, fontWeight: FontWeight.bold)),
                                                                      ),
                                                                    if (hasDiscrepancy)
                                                                      Container(
                                                                        margin: const EdgeInsets.only(left: 8),
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
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            if (awbIdx <
                                                                (uld['awbList']
                                                                            as List)
                                                                        .length -
                                                                    1)
                                                              Divider(
                                                                color: borderC,
                                                                height: 1,
                                                                thickness: 1,
                                                              ),
                                                          ],
                                                        );
                                                      },
                                                    ),
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
                              if (uld['data-checked'] != null)
                                Positioned(
                                  top: -8,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0xFF1e293b) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF10b981).withAlpha(100)),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, size: 12, color: Color(0xFF10b981)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${uld['data-checked']?['user']?.toString() ?? 'User'} • ${DateFormat('MMM dd, h:mm a').format(DateTime.parse(uld['data-checked']?['time'] ?? DateTime.now().toIso8601String()).toLocal())}',
                                          style: TextStyle(
                                            color: dark ? Colors.white70 : Colors.black87,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildTotalStat(
                                  'Checked',
                                  (isLeft ? _uldsLeft : _uldsRight)
                                      .where((u) => u['status'] == 'Checked')
                                      .length,
                                  (isLeft ? _uldsLeft : _uldsRight).length,
                                  const Color(0xFF10b981),
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

                              Widget discrepanciesButton = ElevatedButton.icon(
                                onPressed: totalFlightDiscrepancies > 0 ? () {
                                  if (hasSentReport) {
                                    showGeneralDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      barrierLabel: '',
                                      transitionDuration: const Duration(milliseconds: 300),
                                      pageBuilder: (context, anim1, anim2) {
                                        final reportData = flightList[currentFlightIdx]['report-final'] as List<dynamic>;
                                        return Align(
                                          alignment: Alignment.centerRight,
                                          child: Material(
                                            color: dark ? const Color(0xFF0f172a) : Colors.white,
                                            elevation: 16,
                                            child: SizedBox(
                                              height: double.infinity,
                                              width: 400,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(20),
                                                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), shape: BoxShape.circle),
                                                          child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10b981), size: 24),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text('Sent Report View', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                                              const SizedBox(height: 4),
                                                              Text('${reportData.length} total items in report', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13)),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(icon: Icon(Icons.close, color: textP), onPressed: () => Navigator.pop(context)),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: ListView.separated(
                                                      padding: const EdgeInsets.all(20),
                                                      itemCount: reportData.length,
                                                      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                                                      itemBuilder: (ctx, idx) {
                                                        final item = reportData[idx];
                                                        bool isGood = item['status'] == 'GOOD';
                                                        return Container(
                                                          padding: const EdgeInsets.all(16),
                                                          decoration: BoxDecoration(
                                                            color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9),
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(color: borderC),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(right: 6), 
                                                                        child: Icon(isGood ? Icons.check_circle : Icons.mark_chat_read_rounded, color: isGood ? const Color(0xFF10b981) : const Color(0xFF38bdf8), size: 16)
                                                                      ),
                                                                      Text('AWB: ${item['awb']}', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                                                                    ],
                                                                  ),
                                                                  if (!isGood)
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                      decoration: BoxDecoration(color: const Color(0xFF38bdf8).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                                                                      child: Text('${item['original_label']}', style: const TextStyle(color: Color(0xFF38bdf8), fontSize: 11, fontWeight: FontWeight.bold)),
                                                                    ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 8),
                                                              Text('ULD: ${item['uld']}', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12, fontWeight: FontWeight.w500)),
                                                              if (item['note'] != null && item['note'].toString().isNotEmpty)
                                                                Padding(
                                                                  padding: const EdgeInsets.only(top: 12),
                                                                  child: Container(
                                                                    width: double.infinity,
                                                                    padding: const EdgeInsets.all(12),
                                                                    decoration: BoxDecoration(color: const Color(0xFF3b82f6).withAlpha(15), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3b82f6).withAlpha(50))),
                                                                    child: Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        const Icon(Icons.format_quote_rounded, color: Color(0xFF3b82f6), size: 16),
                                                                        const SizedBox(width: 8),
                                                                        Expanded(child: Text(item['note'].toString(), style: const TextStyle(color: Color(0xFF3b82f6), fontSize: 13, height: 1.4))),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      transitionBuilder: (context, anim1, anim2, child) {
                                        return SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)), child: child);
                                      },
                                    );
                                    return;
                                  }

                                  showGeneralDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: '',
                                    transitionDuration: const Duration(milliseconds: 300),
                                    pageBuilder: (context, anim1, anim2) {
                                      Map<String, bool?> verificationMap = {};
                                      Map<String, int?> verificationDiffMap = {};
                                      Map<String, bool> showCommentMap = {};
                                      Map<String, TextEditingController> commentControllersMap = {};
                                      bool isVerifying = false;
                                      List<Map<String, dynamic>> localDiscrepancies = List<Map<String, dynamic>>.from(allFlightDiscrepancies);

                                      return StatefulBuilder(
                                        builder: (context, setStateDialog) {
                                          return Align(
                                            alignment: Alignment.centerRight,
                                            child: Material(
                                              color: dark ? const Color(0xFF0f172a) : Colors.white,
                                              elevation: 16,
                                              child: SizedBox(
                                                height: double.infinity,
                                                width: 400,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                Container(
                                                  padding: const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    border: Border(bottom: BorderSide(color: borderC)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFef4444).withAlpha(30),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.warning_rounded, color: Color(0xFFef4444), size: 24),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Flight Discrepancies',
                                                              style: TextStyle(
                                                                color: textP,
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              '${localDiscrepancies.length} discrepancy items total',
                                                              style: const TextStyle(
                                                                color: Color(0xFF94a3b8),
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.close, color: textP),
                                                        onPressed: () => Navigator.pop(context),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: ListView.separated(
                                                    padding: const EdgeInsets.all(20),
                                                    itemCount: localDiscrepancies.length,
                                                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                                                    itemBuilder: (ctx, idx) {
                                                      final d = localDiscrepancies[idx];
                                                      return Container(
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(
                                                          color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: borderC),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    if (verificationMap[d['awb']?.toString()] == true)
                                                                      const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_circle, color: Color(0xFF10b981), size: 16)),
                                                                    if (verificationMap[d['awb']?.toString()] == false)
                                                                      Builder(builder: (ctx) {
                                                                        final awbStr = d['awb']?.toString() ?? '';
                                                                        bool hasNote = localDiscrepancyReports.any((r) => r['awb'] == awbStr);
                                                                        return Padding(
                                                                          padding: const EdgeInsets.only(right: 6), 
                                                                          child: Icon(
                                                                            hasNote ? Icons.error_rounded : Icons.cancel, 
                                                                            color: hasNote ? const Color(0xFF3b82f6) : const Color(0xFFef4444), 
                                                                            size: 16,
                                                                          ),
                                                                        );
                                                                      }),
                                                                    Text(
                                                                      'AWB: ${d['awb']}',
                                                                      style: TextStyle(
                                                                        color: textP,
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 14,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(0xFFef4444).withAlpha(30),
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                  child: Text(
                                                                    '${d['label']}',
                                                                    style: const TextStyle(
                                                                      color: Color(0xFFef4444),
                                                                      fontSize: 11,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Row(
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF94a3b8)),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  'ULD: ${d['uld']}',
                                                                  style: const TextStyle(
                                                                    color: Color(0xFF94a3b8),
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                                if (verificationMap[d['awb']?.toString()] != null) ...[
                                                                  const Spacer(),
                                                                  if (verificationMap[d['awb']?.toString()] == false) ...[
                                                                    Builder(builder: (ctx) {
                                                                      final awbStr = d['awb']?.toString() ?? '';
                                                                      bool hasNote = localDiscrepancyReports.any((r) => r['awb'] == awbStr);
                                                                      return IconButton(
                                                                        padding: EdgeInsets.zero,
                                                                        constraints: const BoxConstraints(),
                                                                        icon: Icon(
                                                                          hasNote ? Icons.mark_chat_read_rounded : Icons.edit_note_rounded,
                                                                          color: hasNote ? const Color(0xFF10b981) : const Color(0xFFf97316),
                                                                          size: 20,
                                                                        ),
                                                                        onPressed: () {
                                                                          setStateDialog(() {
                                                                            showCommentMap[awbStr] = !(showCommentMap[awbStr] ?? false);
                                                                            if (showCommentMap[awbStr] == true && !commentControllersMap.containsKey(awbStr)) {
                                                                              commentControllersMap[awbStr] = TextEditingController();
                                                                              if (hasNote) {
                                                                                 final noteObj = localDiscrepancyReports.firstWhere((r) => r['awb'] == awbStr);
                                                                                 commentControllersMap[awbStr]!.text = noteObj['note'] ?? '';
                                                                              }
                                                                            }
                                                                          });
                                                                        },
                                                                      );
                                                                    }),
                                                                    const SizedBox(width: 8),
                                                                  ],
                                                                  Container(
                                                                    width: 110,
                                                                    alignment: Alignment.center,
                                                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                                                    decoration: BoxDecoration(
                                                                      color: verificationMap[d['awb']?.toString()] == true 
                                                                             ? const Color(0xFF10b981).withAlpha(20) 
                                                                             : const Color(0xFFf97316).withAlpha(20),
                                                                      borderRadius: BorderRadius.circular(6),
                                                                      border: Border.all(
                                                                        color: verificationMap[d['awb']?.toString()] == true 
                                                                               ? const Color(0xFF10b981).withAlpha(60)
                                                                               : const Color(0xFFf97316).withAlpha(60),
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      verificationMap[d['awb']?.toString()] == true 
                                                                        ? 'MATCH (GOOD)' 
                                                                        : verificationDiffMap[d['awb']?.toString()]! > 0 ? '${verificationDiffMap[d['awb']?.toString()]} EXTRA' : '${verificationDiffMap[d['awb']?.toString()]!.abs()} MISSING',
                                                                      style: TextStyle(
                                                                        color: verificationMap[d['awb']?.toString()] == true 
                                                                               ? const Color(0xFF10b981) 
                                                                               : const Color(0xFFf97316),
                                                                        fontSize: 10,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                      textAlign: TextAlign.center,
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                            if (showCommentMap[d['awb']?.toString()] == true) ...[
                                                              const SizedBox(height: 12),
                                                              Row(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Expanded(
                                                                    child: TextField(
                                                                      controller: commentControllersMap[d['awb']?.toString()],
                                                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                                                      decoration: InputDecoration(
                                                                        hintText: 'Add notes about this discrepancy...',
                                                                        hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
                                                                        filled: true,
                                                                        fillColor: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
                                                                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                                                      ),
                                                                      maxLines: 2,
                                                                      minLines: 1,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Container(
                                                                    height: 40,
                                                                    width: 40,
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFF10b981).withAlpha(30),
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      border: Border.all(color: const Color(0xFF10b981).withAlpha(80)),
                                                                    ),
                                                                    child: IconButton(
                                                                      icon: const Icon(Icons.check_rounded, color: Color(0xFF10b981), size: 20),
                                                                      onPressed: () {
                                                                        setStateDialog(() {
                                                                          final awbStr = d['awb']?.toString() ?? '';
                                                                          final noteTxt = commentControllersMap[awbStr]?.text.trim() ?? '';
                                                                          
                                                                          localDiscrepancyReports.removeWhere((r) => r['awb'] == awbStr);
                                                                          if (noteTxt.isNotEmpty) {
                                                                             localDiscrepancyReports.add({
                                                                               'awb': awbStr,
                                                                               'diff': verificationDiffMap[awbStr],
                                                                               'note': noteTxt,
                                                                             });
                                                                          }
                                                                          
                                                                          showCommentMap[awbStr] = false;
                                                                          if (mounted) setState(() {});
                                                                        });
                                                                      },
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Builder(
                                                  builder: (ctx) {
                                                    bool isVerified = verificationMap.isNotEmpty;
                                                    bool hasBadItemsWithoutNote = false;
                                                    if (isVerified) {
                                                      for (var d in localDiscrepancies) {
                                                        String awbStr = d['awb']?.toString() ?? '';
                                                        if (verificationMap[awbStr] == false) {
                                                          if (!localDiscrepancyReports.any((r) => r['awb'] == awbStr)) {
                                                            hasBadItemsWithoutNote = true;
                                                            break;
                                                          }
                                                        }
                                                      }
                                                    }
                                                    bool isReadyToSave = isVerified && !hasBadItemsWithoutNote;

                                                    return Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.all(20),
                                                      decoration: BoxDecoration(
                                                        border: Border(top: BorderSide(color: borderC)),
                                                        color: dark ? const Color(0xFF0f172a) : Colors.white,
                                                      ),
                                                      child: ElevatedButton.icon(
                                                        onPressed: (isVerifying || !allUldsChecked) ? null : () async {
                                                          if (isReadyToSave) {
                                                            setStateDialog(() => isVerifying = true);
                                                            try {
                                                              List<Map<String, dynamic>> finalReport = [];
                                                              for (var d in localDiscrepancies) {
                                                                String awbStr = d['awb']?.toString() ?? '';
                                                                bool isValid = verificationMap[awbStr] == true;
                                                                int diff = verificationDiffMap[awbStr] ?? 0;
                                                                String? note;
                                                                if (!isValid) {
                                                                  try {
                                                                    note = localDiscrepancyReports.firstWhere((r) => r['awb'] == awbStr)['note']?.toString();
                                                                  } catch (_) {}
                                                                }
                                                                
                                                                finalReport.add({
                                                                  'uld': d['uld'],
                                                                  'awb': awbStr,
                                                                  'status': isValid ? 'GOOD' : 'ERROR',
                                                                  'diff': diff,
                                                                  'note': note,
                                                                  'original_label': d['label'],
                                                                });
                                                              }
                                                              
                                                              final parts = selectedId.split('-');
                                                              final dtStr = dt != null ? DateFormat('yyyy-MM-dd').format(dt) : '';
                                                              
                                                              await Supabase.instance.client
                                                                .from('Flight')
                                                                .update({
                                                                  'report-final': finalReport,
                                                                })
                                                                .eq('carrier', parts[0])
                                                                .eq('number', parts[1].split(' -')[0].trim())
                                                                .eq('date-arrived', dtStr);
                                                                
                                                              if (currentFlightIdx != -1) {
                                                                flightList[currentFlightIdx]['report-final'] = finalReport;
                                                                setState(() {});
                                                              }
                                                              
                                                              if (context.mounted) {
                                                                Navigator.pop(context);
                                                                showGeneralDialog(
                                                                  context: context,
                                                                  barrierDismissible: false,
                                                                  barrierColor: Colors.black.withAlpha(20),
                                                                  transitionDuration: const Duration(milliseconds: 300),
                                                                  pageBuilder: (context, anim1, anim2) {
                                                                    Future.delayed(const Duration(milliseconds: 1700), () {
                                                                      if (context.mounted) Navigator.pop(context);
                                                                    });
                                                                    return Dialog(
                                                                      backgroundColor: Colors.transparent,
                                                                      elevation: 0,
                                                                      child: Center(
                                                                        child: Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                                          decoration: BoxDecoration(
                                                                            color: dark ? const Color(0xFF1e293b) : Colors.white,
                                                                            borderRadius: BorderRadius.circular(40),
                                                                            boxShadow: [
                                                                              BoxShadow(
                                                                                color: Colors.black.withAlpha(20),
                                                                                blurRadius: 20,
                                                                                offset: const Offset(0, 10),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                              Container(
                                                                                padding: const EdgeInsets.all(8),
                                                                                decoration: BoxDecoration(
                                                                                  color: const Color(0xFF10b981).withAlpha(30),
                                                                                  shape: BoxShape.circle,
                                                                                ),
                                                                                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 24),
                                                                              ),
                                                                              const SizedBox(width: 12),
                                                                              Text(
                                                                                appLanguage.value == 'es' ? 'Reporte guardado con éxito' : 'Report successful',
                                                                                style: TextStyle(
                                                                                  color: textP,
                                                                                  fontSize: 15,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  transitionBuilder: (context, anim1, anim2, child) {
                                                                    return ScaleTransition(
                                                                      scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
                                                                      child: FadeTransition(opacity: anim1, child: child),
                                                                    );
                                                                  },
                                                                );
                                                              }
                                                            } catch (e) {
                                                              debugPrint('Check error: $e');
                                                              if (context.mounted) {
                                                                setStateDialog(() => isVerifying = false);
                                                              }
                                                            }
                                                            return;
                                                          }
                                                          setStateDialog(() => isVerifying = true);
                                                          
                                                          try {
                                                            final uniqueAwbs = localDiscrepancies.map((e) => e['awb']?.toString()).where((e) => e != null && e != 'N/A').toSet().toList();
                                                            if (uniqueAwbs.isNotEmpty) {
                                                              final awbData = await Supabase.instance.client
                                                                  .from('AWB')
                                                                  .select('AWB-number, total, data-coordinator')
                                                                  .inFilter('AWB-number', uniqueAwbs);
                                                                  
                                                              for (var awbRow in awbData) {
                                                                final awbNum = awbRow['AWB-number']?.toString();
                                                                if (awbNum == null) continue;
                                                                
                                                                int total = int.tryParse(awbRow['total']?.toString() ?? '0') ?? 0;
                                                                int sumBreakdown = 0;
                                                                
                                                                final dcData = awbRow['data-coordinator'];
                                                                List<dynamic> dcList = [];
                                                                if (dcData is List) {
                                                                  dcList = dcData;
                                                                } else if (dcData is Map) {
                                                                  dcList = [dcData];
                                                                }
                                                                
                                                                for (var dc in dcList) {
                                                                  if (dc is Map && dc['breakdown'] is Map) {
                                                                    final bd = dc['breakdown'] as Map;
                                                                    for (var key in bd.keys) {
                                                                      final val = bd[key];
                                                                      if (val is List) {
                                                                        for (var e in val) {
                                                                          sumBreakdown += int.tryParse(e?.toString() ?? '0') ?? 0;
                                                                        }
                                                                      } else if (val is num) {
                                                                        sumBreakdown += val.toInt();
                                                                      } else if (val is String) {
                                                                        sumBreakdown += int.tryParse(val) ?? 0;
                                                                      }
                                                                    }
                                                                  }
                                                                }
                                                                verificationMap[awbNum] = (total == sumBreakdown);
                                                                verificationDiffMap[awbNum] = sumBreakdown - total;
                                                              }
                                                            }
                                                          } catch (e) {
                                                            debugPrint('Verification error: $e');
                                                          }
                                                          
                                                          if (context.mounted) {
                                                            setStateDialog(() {
                                                              isVerifying = false;
                                                              localDiscrepancies.sort((a, b) {
                                                                bool aValid = verificationMap[a['awb']?.toString()] == true;
                                                                bool bValid = verificationMap[b['awb']?.toString()] == true;
                                                                if (aValid && !bValid) return -1;
                                                                if (!aValid && bValid) return 1;
                                                                return 0;
                                                              });
                                                            });
                                                          }
                                                        },
                                                        icon: isVerifying 
                                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                                          : Icon(!allUldsChecked ? Icons.lock_rounded : (isReadyToSave ? Icons.save_rounded : Icons.fact_check_outlined), size: 20),
                                                        label: Text(
                                                          !allUldsChecked ? (appLanguage.value == 'es' ? 'Verifica todos los ULDs primero' : 'Check all ULDs first') : (isVerifying ? 'Verifying...' : (isReadyToSave ? 'Save Report' : 'Verify All Discrepancies')), 
                                                          style: const TextStyle(fontWeight: FontWeight.bold)
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: isReadyToSave ? const Color(0xFF10b981) : const Color(0xFF6366f1),
                                                          foregroundColor: Colors.white,
                                                          disabledBackgroundColor: !allUldsChecked ? (dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)) : (isReadyToSave ? const Color(0xFF10b981) : const Color(0xFF6366f1)).withAlpha(150),
                                                          disabledForegroundColor: !allUldsChecked ? const Color(0xFF94a3b8) : Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                    transitionBuilder: (context, anim1, anim2, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
                                        child: child,
                                      );
                                    },
                                  );
                                } : null,
                                icon: Icon(
                                  hasSentReport ? Icons.mark_email_read_rounded : Icons.warning_amber_rounded,
                                  size: 20
                                ),
                                label: Text(
                                  totalFlightDiscrepancies > 0 
                                      ? (hasSentReport ? 'Sent Report View' : '$totalFlightDiscrepancies Total Discrepanc${totalFlightDiscrepancies == 1 ? 'y' : 'ies'}') 
                                      : 'No Discrepancies',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: totalFlightDiscrepancies > 0 ? (hasSentReport ? const Color(0xFF10b981).withAlpha(100) : const Color(0xFFef4444)) : (dark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9)),
                                  foregroundColor: totalFlightDiscrepancies > 0 ? Colors.white : const Color(0xFF94a3b8),
                                  elevation: hasSentReport ? 0 : null,
                                  disabledBackgroundColor: dark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9),
                                  disabledForegroundColor: const Color(0xFF94a3b8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );

                              Widget actionButton = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  discrepanciesButton,
                                  const SizedBox(width: 12),
                                  baseActionButton,
                                ],
                              );

                              String fmtBreak(String? t) {
                                if (t == null) return '-';
                                try {
                                  final dt = DateTime.parse(t.replaceAll(' ', 'T')).toLocal();
                                  int h = dt.hour;
                                  int m = dt.minute;
                                  bool pm = h >= 12;
                                  int h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
                                  String mm = m < 10 ? '0$m' : '$m';
                                  String suff = pm ? 'pm' : 'am';
                                  return '${dt.day}/${dt.month} $h12:$mm $suff';
                                } catch (_) {
                                  return t;
                                }
                              }

                              if (currentFlightIdx != -1) {
                                final startB = flightList[currentFlightIdx]['start-break']?.toString();
                                final endB = flightList[currentFlightIdx]['end-break']?.toString();
                                
                                if (startB != null || endB != null) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (startB != null)
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
                                                  'Start Break: ${fmtBreak(startB)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF94a3b8),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (endB != null) ...[
                                            if (startB != null) const SizedBox(height: 4),
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
                                                  'End Break: ${fmtBreak(endB)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF10b981),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      actionButton,
                                    ],
                                  );
                                }
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
    List<String> selectedLocations = [];
    final otherLocationCtrl = TextEditingController();
    bool isLoading = true;
    bool isEditMode = true;
    Map<dynamic, dynamic>? initialData;
    bool isNotFound = false;

    final ctrls = {
      'AGI Skid': TextEditingController(),
      'Pre Skid': TextEditingController(),
      'Crate': TextEditingController(),
      'Box': TextEditingController(),
      'Other': TextEditingController(),
    };

    return await showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            if (isLoading) {
              isLoading = false;
              // Fetch from Supabase
              Supabase.instance.client
                  .from('AWB')
                  .select('total, data-coordinator')
                  .eq('AWB-number', awb['number'])
                  .maybeSingle()
                  .then((res) {
                    if (res != null) {
                      if (res['total'] != null) awb['total'] = res['total'];
                      Map<dynamic, dynamic>? data;
                      if (res['data-coordinator'] is List) {
                        final listDc = res['data-coordinator'] as List;
                        final uldNum = uldOverride?['ULD-number']?.toString().toUpperCase();
                        final match = listDc.where((d) => d is Map && d['refULD']?.toString().toUpperCase() == uldNum).toList();
                        if (match.isNotEmpty) data = match.first as Map;
                      } else if (res['data-coordinator'] is Map) {
                        data = res['data-coordinator'];
                      }
                      
                      if (data != null) {
                        initialData = data;
                        bool hasInput = false;
                        if (data['breakdown'] is Map) {
                          final bd = data['breakdown'] as Map;
                          hasInput = bd.values.any((val) {
                            if (val is List) return val.any((e) => (int.tryParse(e.toString()) ?? 0) > 0);
                            if (val is num) return val > 0;
                            if (val is String) return (int.tryParse(val) ?? 0) > 0;
                            return false;
                          });
                        }
                        if (hasInput) isEditMode = false;

                        if (data['discrepancy'] is Map && data['discrepancy']['notFound'] == true) {
                          isNotFound = true;
                          isEditMode = false;
                        }

                        if (data['breakdown'] is Map) {
                        final bd = data['breakdown'] as Map;
                        for (var k in breakdown.keys) {
                          String legacyKey = k;
                          if (k == 'Crate') legacyKey = 'Crate(s)';
                          if (k == 'Box') legacyKey = 'Box(es)';

                          if (bd[k] is List) {
                            breakdown[k] = (bd[k] as List)
                                .map((e) => int.tryParse(e.toString()) ?? 0)
                                .toList();
                          } else if (bd[legacyKey] is List) {
                            breakdown[k] = (bd[legacyKey] as List)
                                .map((e) => int.tryParse(e.toString()) ?? 0)
                                .toList();
                          } else if (bd[k] is num || bd[k] is String) {
                            int val = int.tryParse(bd[k].toString()) ?? 0;
                            breakdown[k] = val > 0 ? [val] : [];
                          } else if (bd[legacyKey] is num || bd[legacyKey] is String) {
                            int val = int.tryParse(bd[legacyKey].toString()) ?? 0;
                            breakdown[k] = val > 0 ? [val] : [];
                          }
                        }
                      }
                      if (data['selectedLocations'] is List) {
                        selectedLocations = List<String>.from(
                          data['selectedLocations'],
                        );
                        if (selectedLocations.isNotEmpty) {
                          String loc = selectedLocations.first;
                          if (!['15-25°C', '2-8°C', 'PSV', 'DG', 'Oversize', 'Small rack', 'Animal Live', 'Other'].contains(loc)) {
                            selectedLocations = ['Other'];
                            otherLocationCtrl.text = loc;
                          }
                        }
                        }
                      }
                    }
                    if (dialogCtx.mounted) setDialogState(() {});
                  });
            }

            int totalChecked = breakdown.values
                .expand((element) => element)
                .fold(0, (a, b) => a + b);

            Widget buildControlRow(String label) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFcbd5e1),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      height: 38,
                      child: TextField(
                        enabled: isEditMode && !isNotFound,
                        controller: ctrls[label],
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(5),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(50),
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha(10),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withAlpha(20),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF8b5cf6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: (isEditMode && !isNotFound) ? () {
                        final val = int.tryParse(ctrls[label]!.text);
                        if (val != null && val > 0) {
                          setDialogState(() {
                            if (label == 'AGI Skid') {
                              breakdown[label]!.add(val);
                            } else {
                              breakdown[label] = [val];
                            }
                            ctrls[label]!.clear();
                          });
                        }
                      } : null,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (isEditMode && !isNotFound) ? const Color(0xFF6366f1) : const Color(0xFF6366f1).withAlpha(100),
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // fully rounded circle like image
                        ),
                        child: Icon(
                          Icons.add,
                          color: (isEditMode && !isNotFound) ? Colors.white : Colors.white.withAlpha(150),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildLocationChip(String label) {
              final isSel = selectedLocations.contains(label);
              return InkWell(
                onTap: (isEditMode && !isNotFound) ? () {
                  setDialogState(() {
                    if (isSel) {
                      selectedLocations.clear();
                      if (label == 'Other') otherLocationCtrl.clear();
                    } else {
                      selectedLocations = [label];
                      if (label != 'Other') otherLocationCtrl.clear();
                    }
                  });
                } : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF6366f1) : Colors.transparent,
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF6366f1)
                          : Colors.white.withAlpha(30),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFFcbd5e1),
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withAlpha(10)),
              ),
              title: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'AWB: ${awb['number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Not Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    selected: isNotFound,
                    onSelected: isEditMode
                        ? (val) {
                            setDialogState(() {
                              isNotFound = val;
                              if (val) {
                                selectedLocations.clear();
                                otherLocationCtrl.clear();
                                for (var k in breakdown.keys) {
                                  breakdown[k]!.clear();
                                }
                                for (var k in ctrls.keys) {
                                  ctrls[k]!.clear();
                                }
                              }
                            });
                          }
                        : null,
                    selectedColor: const Color(0xFFef4444).withAlpha(50),
                    checkmarkColor: const Color(0xFFef4444),
                    labelStyle: TextStyle(
                      color: isNotFound ? const Color(0xFFef4444) : Colors.white,
                    ),
                    backgroundColor: Colors.white.withAlpha(5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isNotFound
                            ? const Color(0xFFef4444).withAlpha(100)
                            : Colors.white.withAlpha(20),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600, // wide dialog to fit both columns
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top summary bar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withAlpha(10)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatMini('PIECES', '${awb['pieces'] ?? '-'}'),
                            _buildStatMini('TOTAL', '${awb['total'] ?? '-'}'),
                            _buildStatMini(
                              'WEIGHT',
                              '${awb['weight'] ?? '-'} kg',
                            ),
                            _buildStatMini(
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
                            _buildStatMini(
                              'REMARKS',
                              (awb['remarks']?.toString().trim().isEmpty ?? true)
                                  ? '-'
                                  : awb['remarks'].toString().trim(),
                            ),
                          ],
                        ),
                      ),
                      if (initialData != null && initialData!['discrepancy'] != null && initialData!['discrepancy']['confirmed'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Builder(
                                    builder: (ctx) {
                                      int exp = initialData!['discrepancy']['expected'] as int? ?? 0;
                                      int rec = initialData!['discrepancy']['received'] as int? ?? 0;
                                      int diff = (exp - rec).abs();
                                      String term = exp > rec ? 'SHORT' : 'OVER';
                                      
                                      return RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Discrepancy Confirmed: Expected $exp PCs, Received $rec PCs.  ',
                                              style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                              text: '$diff PCs $term',
                                              style: const TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.w800),
                                            ),
                                          ]
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
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

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                buildControlRow('AGI Skid'),
                                buildControlRow('Pre Skid'),
                                buildControlRow('Crate'),
                                buildControlRow('Box'),
                                buildControlRow('Other'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right side scrollable list
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 250,
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
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '#${item.key + 1}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF64748b),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withAlpha(5),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${item.value}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (isEditMode && !isNotFound) ...[
                                                    const SizedBox(width: 8),
                                                    InkWell(
                                                      onTap: () {
                                                        setDialogState(() {
                                                          breakdown[entry.key]!
                                                              .removeAt(item.key);
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Colors.red
                                                                .withAlpha(50),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Color(0xFFef4444),
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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
                                          const Spacer(),
                                          if (isEditMode && !isNotFound)
                                            InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  breakdown[entry.key]!.clear();
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.red.withAlpha(50),
                                                  ),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Color(0xFFef4444),
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Location required:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          buildLocationChip('15-25°C'),
                          buildLocationChip('2-8°C'),
                          buildLocationChip('PSV'),
                          buildLocationChip('DG'),
                          buildLocationChip('Oversize'),
                          buildLocationChip('Small rack'),
                          buildLocationChip('Animal Live'),
                          buildLocationChip('Other'),
                          if (selectedLocations.contains('Other'))
                            SizedBox(
                              width: 200,
                              height: 38,
                              child: TextField(
                                enabled: isEditMode && !isNotFound,
                                controller: otherLocationCtrl,
                                style: TextStyle(color: (isEditMode && !isNotFound) ? Colors.white : Colors.white.withAlpha(150), fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Enter custom location...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withAlpha(50),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(5),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.white.withAlpha(20),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8b5cf6),
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
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                if (uldOverride?['status'] != 'Checked')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditMode ? const Color(0xFF6366f1) : Colors.white.withAlpha(10),
                      foregroundColor: isEditMode ? Colors.white : Colors.white.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!isEditMode) {
                              setDialogState(() => isEditMode = true);
                              return;
                            }
                            int expectedPieces = int.tryParse(awb['pieces']?.toString() ?? '0') ?? 0;
                            if (isNotFound) {
                              // By-pass the discrepancy dialog because 'Not Found' is explicitly a discrepancy
                            } else if (totalChecked != expectedPieces &&
                                breakdown.values.any((list) => list.isNotEmpty)) {
                              bool? confirmed = await showDialog<bool>(
                                context: dialogCtx,
                                builder: (ctx) {
                                  int diff = (expectedPieces - totalChecked).abs();
                                  String term = expectedPieces > totalChecked ? 'missing' : 'extra';
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFF1e293b),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Discrepancy Detected', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('You should have received $expectedPieces pieces but you only received $totalChecked.', style: const TextStyle(color: Colors.white70)),
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFef4444).withAlpha(40),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFef4444).withAlpha(100), width: 2),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.error_outline_rounded, color: Color(0xFFef4444), size: 36),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${diff.toString().toUpperCase()} ${term.toUpperCase()}',
                                                style: const TextStyle(
                                                  color: Color(0xFFef4444),
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              const Text('PIECES', style: TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Do you want to confirm this discrepancy?', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6366f1),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                }
                              );
                              if (confirmed != true) return;
                            }

                            setDialogState(() => isSaving = true);
                            try {
                              final existing = await Supabase.instance.client
                                  .from('AWB')
                                  .select('data-coordinator')
                                  .eq('AWB-number', awb['number'])
                                  .maybeSingle();
                              List<dynamic> existingDcList = [];
                              if (existing != null) {
                                if (existing['data-coordinator'] is List) {
                                  existingDcList = List.from(existing['data-coordinator']);
                                } else if (existing['data-coordinator'] is Map) {
                                  existingDcList = [existing['data-coordinator']];
                                }
                              }

                              Map<String, dynamic> coordData = {};
                              
                              final uldNum = uldOverride?['ULD-number']?.toString().toUpperCase() ?? '';
                              final uldCar = uldOverride?['refCarrier']?.toString() ?? '';
                              final uldFlt = uldOverride?['refNumber']?.toString() ?? '';
                              final uldDate = uldOverride?['refDate']?.toString() ?? '';

                              // Find existing map for this ULD if any
                              int matchIndex = existingDcList.indexWhere((d) => d is Map && d['refULD']?.toString().toUpperCase() == uldNum && d['refNumber']?.toString() == uldFlt);
                              if (matchIndex != -1) {
                                coordData = Map<String, dynamic>.from(existingDcList[matchIndex]);
                              }
                              
                              Map<String, dynamic> breakdownToSave = {};
                              breakdown.forEach((key, list) {
                                if (key == 'AGI Skid') {
                                  breakdownToSave[key] = list;
                                } else {
                                  breakdownToSave[key] = list.isNotEmpty ? list.first : 0;
                                }
                              });
                              coordData['breakdown'] = breakdownToSave;
                              
                              if (isNotFound) {
                                coordData['discrepancy'] = {
                                  'confirmed': true,
                                  'expected': expectedPieces,
                                  'received': 0,
                                  'notFound': true,
                                };
                              } else if (totalChecked != expectedPieces && breakdown.values.any((list) => list.isNotEmpty)) {
                                coordData['discrepancy'] = {
                                  'confirmed': true,
                                  'expected': expectedPieces,
                                  'received': totalChecked
                                };
                              } else {
                                coordData.remove('discrepancy');
                              }
                              
                              coordData['selectedLocations'] = selectedLocations.map((loc) {
                                if (loc == 'Other' && otherLocationCtrl.text.trim().isNotEmpty) {
                                  return otherLocationCtrl.text.trim();
                                }
                                return loc;
                              }).toList();
                              
                              coordData['refULD'] = uldNum;
                              coordData['refCarrier'] = uldCar;
                              coordData['refNumber'] = uldFlt;
                              coordData['refDate'] = uldDate;

                              if (matchIndex != -1) {
                                existingDcList[matchIndex] = coordData;
                              } else {
                                existingDcList.add(coordData);
                              }

                              await Supabase.instance.client
                                  .from('AWB')
                                  .update({'data-coordinator': existingDcList})
                                  .eq('AWB-number', awb['number']);

                              awb['data-coordinator'] = existingDcList;
                              if (mounted) setState(() {});
                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx, awb);
                              }
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                              setDialogState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEditMode ? 'Save' : 'Edit',
                            style: TextStyle(
                              color: isEditMode ? Colors.white : Colors.white.withAlpha(100),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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