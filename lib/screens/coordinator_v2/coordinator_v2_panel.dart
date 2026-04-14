import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'coordinator_v2_logic.dart';

class CoordinatorV2Panel extends StatelessWidget {
  final CoordinatorV2Logic logic;

  const CoordinatorV2Panel({super.key, required this.logic});

  Future<void> _pickDate(BuildContext context) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: logic.selectedDate ?? DateTime.now(),
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
      logic.setDate(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([logic, isDarkMode]),
      builder: (context, child) {
        final dark = isDarkMode.value;
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff);
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Container(
          padding: const EdgeInsets.all(32),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: (!logic.isLoadingFlights && logic.flights.isNotEmpty)
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!logic.isLoadingFlights && logic.flights.isNotEmpty)
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
                  ElevatedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      logic.selectedDate == null
                          ? (appLanguage.value == 'es'
                              ? 'Seleccionar Fecha'
                              : 'Select Date')
                          : DateFormat('MM/dd/yyyy').format(logic.selectedDate!),
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
              if (logic.isLoadingFlights)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                  ),
                )
              else if (logic.flights.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      logic.selectedDate == null
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: logic.flights.map((f) {
                    final chipId = f['id_flight']?.toString() ?? '';
                    final isSel = logic.selectedFlightId == chipId && chipId.isNotEmpty;
                    final isChecked = f['isChecked'] == true;

                    Color textColor = isSel
                        ? Colors.white
                        : (isChecked ? const Color(0xFF10b981) : textP);
                    Color selColor = isChecked
                        ? const Color(0xFF10b981)
                        : const Color(0xFF6366f1);
                    Color unselBgColor = isChecked
                        ? const Color(0xFF10b981).withAlpha(15)
                        : bgCard;
                    Color borderColor = isSel
                        ? Colors.transparent
                        : (isChecked
                            ? const Color(0xFF10b981).withAlpha(50)
                            : borderC);

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
                          logic.selectFlight(chipId);
                        }
                      },
                    );
                  }).toList(),
                ),
                if (logic.selectedFlightId != null) ...[
                  const SizedBox(height: 16),
                  if (logic.isLoadingUlds)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF6366f1))))
                  else if (logic.ulds.isEmpty)
                    Text(
                      appLanguage.value == 'es'
                          ? 'No hay ULDs encontrados para este vuelo.'
                          : 'No ULDs found for this flight.',
                      style: TextStyle(color: textS),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: logic.ulds.length,
                        itemBuilder: (context, index) {
                          final uld = logic.ulds[index];
                          final int pieces = uld['pieces_total'] ?? 0;
                          final num weight = uld['weight_total'] ?? 0;
                          final String remarks = uld['remarks']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderC),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366f1).withAlpha(30),
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
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 105,
                                        child: Text(
                                          '${uld['uld_number'] ?? '-'}',
                                          style: TextStyle(
                                            color: textP,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 75,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'PCs: $pieces',
                                          style: TextStyle(color: textS, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 90,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$weight kg',
                                          style: TextStyle(color: textS, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (remarks.trim().isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFf59e0b).withAlpha(15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFf59e0b).withAlpha(40)),
                                            ),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics: const BouncingScrollPhysics(),
                                              child: Text(
                                                remarks,
                                                style: const TextStyle(
                                                  color: Color(0xFFd97706),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
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
                                // Pending indicators implementation if needed
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ]
              ],
            ],
          ),
        );
      },
    );
  }
}
