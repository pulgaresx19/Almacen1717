import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;

class LocationV2Screen extends StatefulWidget {
  final bool isActive;
  const LocationV2Screen({super.key, required this.isActive});

  @override
  State<LocationV2Screen> createState() => _LocationV2ScreenState();
}

class _LocationV2ScreenState extends State<LocationV2Screen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
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
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(color: textP, fontSize: 13),
                          onChanged: (v) => setState(() {}),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              // Perform search later
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
                            // Perform search later
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // DATE PICKER
                        ElevatedButton.icon(
                          onPressed: () => _pickDate(context),
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(
                            _selectedDate == null
                                ? (appLanguage.value == 'es'
                                      ? 'Seleccionar Fecha'
                                      : 'Select Date')
                                : DateFormat('MM/dd/yyyy').format(_selectedDate!),
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
                    
                    // PLACEHOLDER FOR CONTENT
                    Expanded(
                      child: Center(
                        child: Text(
                          _selectedDate == null
                              ? (appLanguage.value == 'es'
                                    ? 'Selecciona una fecha.'
                                    : 'Pick a date to load flights.')
                              : (appLanguage.value == 'es'
                                    ? 'No se encontraron vuelos para esta fecha.'
                                    : 'No flights found for this date.'),
                          style: TextStyle(color: textS),
                        ),
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
