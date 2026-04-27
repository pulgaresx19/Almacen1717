import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'delivers_v2_logic.dart';
import 'delivers_v2_dialogs.dart';

class DeliversV2History extends StatefulWidget {
  final DeliversV2Logic logic;
  final VoidCallback onBackToMain;
  const DeliversV2History({super.key, required this.logic, required this.onBackToMain});

  @override
  State<DeliversV2History> createState() => _DeliversV2HistoryState();
}

class _DeliversV2HistoryState extends State<DeliversV2History> {
  String? _selectedDate; // The date folder currently opened

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        return Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_selectedDate != null) {
                          setState(() {
                            _selectedDate = null;
                          });
                        } else {
                          widget.onBackToMain();
                        }
                      },
                      icon: Icon(Icons.arrow_back_rounded, color: textP),
                      tooltip: appLanguage.value == 'es' ? 'Atrás' : 'Back',
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _selectedDate == null ? Icons.folder_special_rounded : Icons.folder_open_rounded,
                      color: const Color(0xFF6366f1),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? (appLanguage.value == 'es' ? 'Historial de Entregas' : 'Deliveries History')
                          : (appLanguage.value == 'es' ? 'Entregas del $_selectedDate' : 'Deliveries on $_selectedDate'),
                      style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.transparent), // just a separator visually

              // Content
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.logic,
                  builder: (context, _) {
                    final allItems = widget.logic.allDelivers;

                    // Group by Date (YYYY-MM-DD)
                    final Map<String, List<Map<String, dynamic>>> grouped = {};
                    for (var item in allItems) {
                      final taStr = item['time']?.toString() ?? '';
                      final dt = DateTime.tryParse(taStr);
                      if (dt != null) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(dt);
                        grouped.putIfAbsent(dateKey, () => []).add(item);
                      } else {
                        grouped.putIfAbsent('Unknown Date', () => []).add(item);
                      }
                    }

                    // Sort date keys descending
                    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                    if (_selectedDate == null) {
                      // Show Grid of Folders
                      if (sortedKeys.isEmpty) {
                        return Center(
                          child: Text(
                            appLanguage.value == 'es' ? 'No hay historial disponible.' : 'No history available.',
                            style: TextStyle(color: textS),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedKeys[index];
                          final count = grouped[dateKey]!.length;
                          
                          // Format date nicely
                          String niceDate = dateKey;
                          if (dateKey != 'Unknown Date') {
                            try {
                              final d = DateTime.parse(dateKey);
                              niceDate = DateFormat('MMM dd, yyyy').format(d);
                            } catch (_) {}
                          }

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDate = dateKey;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderCard),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.folder_rounded,
                                    color: Color(0xFFeab308), // Folder yellow color
                                    size: 64,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    niceDate,
                                    style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count ${appLanguage.value == 'es' ? 'entregas' : 'delivers'}',
                                    style: TextStyle(color: textS, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // Show list of deliveries for the selected date
                      final itemsForDate = grouped[_selectedDate] ?? [];
                      
                      if (itemsForDate.isEmpty) {
                         return Center(child: Text('No items', style: TextStyle(color: textS)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: itemsForDate.length,
                        itemBuilder: (context, index) {
                          final item = itemsForDate[index];
                          final company = item['company']?.toString() ?? '-';
                          final driver = item['driver_name']?.toString() ?? '-';
                          final door = item['door']?.toString() ?? '-';
                          final time = item['time']?.toString() ?? '';
                          
                          String niceTime = time;
                          if (time.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(time);
                              niceTime = DateFormat('HH:mm').format(dt);
                            } catch (_) {}
                          }

                          return Card(
                            color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: borderCard),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF6366f1),
                                child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                              ),
                              title: Text(company, style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                              subtitle: Text('$driver • Door $door', style: TextStyle(color: textS)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(niceTime, style: TextStyle(color: textS, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right, color: textS),
                                ],
                              ),
                              onTap: () {
                                DeliversV2Dialogs.showDeliverDetails(context, item, dark);
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
