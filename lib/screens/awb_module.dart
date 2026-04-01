import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;
import 'add_awb_screen.dart';

class AwbModule extends StatefulWidget {
  final bool isActive;
  const AwbModule({super.key, this.isActive = true});

  @override
  State<AwbModule> createState() => _AwbModuleState();
}

class _AwbModuleState extends State<AwbModule> {
  final _searchController = TextEditingController();
  final GlobalKey<AddAwbScreenState> _addAwbKey = GlobalKey<AddAwbScreenState>();
  bool _showAddForm = false;

  @override
  void didUpdateWidget(AwbModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      if (_showAddForm && _addAwbKey.currentState != null) {
        if (!_addAwbKey.currentState!.hasDataSync) {
          setState(() {
            _showAddForm = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff);
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final Color iconColor = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Header Row (Title, Search, Buttons)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showAddForm)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                            child: IconButton(
                              onPressed: () async {
                                if (_addAwbKey.currentState != null) {
                                  final canPop = await _addAwbKey.currentState!.handleBackRequest();
                                  if (canPop) {
                                    setState(() => _showAddForm = false);
                                  }
                                } else {
                                  setState(() => _showAddForm = false);
                                }
                              },
                              icon: const Icon(Icons.arrow_back_rounded, size: 24),
                              tooltip: appLanguage.value == 'es' ? 'Volver' : 'Back',
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appLanguage.value == 'es' ? 'Añadir Nuevo Aerobill' : 'Add New Air Waybill', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(appLanguage.value == 'es' ? 'Crea y registra detalles de los aerobills.' : 'Create and register Air Waybill details.', style: TextStyle(color: textS, fontSize: 13)),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appLanguage.value == 'es' ? 'Guías Aéreas' : 'Air Waybills (AWB)', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(appLanguage.value == 'es' ? 'Administración y desglose de guías aéreas.' : 'Management and breakdown of Air Waybills.', style: TextStyle(color: textS, fontSize: 13)),
                        ],
                      ),
                  ],
                ),
                const Spacer(),
                
                if (!_showAddForm) ...[
                  // Search Box
                  Container(
                    width: 300,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderCard),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textP, fontSize: 13),
                      onChanged: (v) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                        hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Add AWB Button
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddForm = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(appLanguage.value == 'es' ? 'Añadir AWB' : 'Add AWB', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF6366f1).withAlpha(100),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Refresh Button
                  IconButton(
                    onPressed: () => setState(() {}),
                    icon: Icon(Icons.refresh_rounded, color: iconColor, size: 18),
                    tooltip: appLanguage.value == 'es' ? 'Refrescar' : 'Refresh',
                    style: IconButton.styleFrom(
                      backgroundColor: dark ? Colors.white.withAlpha(25) : const Color(0xFFF3F4F6),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 30),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCard),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _showAddForm
                      ? AddAwbScreen(
                          key: _addAwbKey,
                          onPop: (didAdd) {
                            setState(() {
                              _showAddForm = false;
                            });
                          },
                        )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                          future: Supabase.instance.client.from('AWB').select().order('AWB-number', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  var awbs = snapshot.data ?? [];
                  
                  if (_searchController.text.isNotEmpty) {
                    final term = _searchController.text.toLowerCase();
                    awbs = awbs.where((u) => u['AWB-number']?.toString().toLowerCase().contains(term) ?? false).toList();
                  }

                  if (awbs.isEmpty) return const Center(child: Text('No AWBs found.', style: TextStyle(color: Color(0xFF94a3b8))));

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                        dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                        headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('AWB Number')),
                          DataColumn(label: Text('Pieces Received')),
                          DataColumn(label: Text('Pieces Expected')),
                          DataColumn(label: Text('Total Pieces')),
                          DataColumn(label: Text('Delivered Pieces')),
                          DataColumn(label: Text('Remaining Pieces')),
                          DataColumn(label: Text('Total Weight')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: List.generate(awbs.length, (index) {
                          final u = awbs[index];
                          
                          int expectedPieces = 0;
                          double totalWeight = 0.0;
                          if (u['data-AWB'] is List) {
                            for (var item in u['data-AWB']) {
                               expectedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
                               totalWeight += double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
                            }
                          } else if (u['data-AWB'] is Map) {
                               expectedPieces += int.tryParse(u['data-AWB']['pieces']?.toString() ?? '0') ?? 0;
                               totalWeight += double.tryParse(u['data-AWB']['weight']?.toString() ?? '0') ?? 0.0;
                          }

                          int receivedPieces = 0;
                          if (u['data-coordinator'] != null) {
                            List dcList = [];
                            if (u['data-coordinator'] is List) {
                              dcList = u['data-coordinator'] as List;
                            } else if (u['data-coordinator'] is Map && u['data-coordinator'].isNotEmpty) {
                              dcList = [u['data-coordinator']];
                            }
                            
                            for (var item in dcList) {
                               if (item is Map) {
                                  if (item.containsKey('breakdown') && item['breakdown'] is Map) {
                                     Map breakdown = item['breakdown'];
                                     if (breakdown['AGI Skid'] is List) {
                                        for (var val in breakdown['AGI Skid']) {
                                           receivedPieces += int.tryParse(val.toString()) ?? 0;
                                        }
                                     }
                                     for (String k in ['Pre Skid', 'Crate', 'Box', 'Other']) {
                                        receivedPieces += int.tryParse(breakdown[k]?.toString() ?? '0') ?? 0;
                                     }
                                  } else {
                                     receivedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
                                  }
                               }
                            }
                          }
                          
                          String status = 'Pending';
                          if (receivedPieces > 0 && receivedPieces < expectedPieces) {
                            status = 'In Progress';
                          } else if (receivedPieces >= expectedPieces && expectedPieces > 0) {
                            status = 'Ready';
                          }

                          return DataRow(
                            onSelectChanged: (_) => _showAwbDrawer(context, u, dark, receivedPieces, expectedPieces, status),
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(u['AWB-number']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                              DataCell(Text(receivedPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(expectedPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(u['total']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366f1)))),
                              const DataCell(Text('-')), // To update with Pieces Delivered
                              const DataCell(Text('-')), // To update with Remaining Pieces
                              DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\\.$|\\.0$'), '')} kg', style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(_buildStatusBadge(status)),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
            ),
          ),
        ),
      ],
    );
     }
    );
  }

  void _showAwbDrawer(BuildContext context, Map<String, dynamic> u, bool dark, int receivedPieces, int expectedPieces, String status) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        final Set<int> expandedCards = {};

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBuilder) {
            String formatChicagoTime(String? timeStr) {
               if (timeStr == null) return '-';
               final dt = DateTime.tryParse(timeStr);
               if (dt == null) return '-';
               final utc = dt.isUtc ? dt : dt.toUtc();
               final chicago = utc.subtract(const Duration(hours: 5));
               int h = chicago.hour;
               String amPm = h >= 12 ? 'PM' : 'AM';
               if (h == 0) { h = 12; }
               else if (h > 12) { h -= 12; }
               String hh = h.toString().padLeft(2, '0');
               String mm = chicago.minute.toString().padLeft(2, '0');
               String mth = chicago.month.toString().padLeft(2, '0');
               String dd = chicago.day.toString().padLeft(2, '0');
               String yy = chicago.year.toString();
               return '$hh:$mm $amPm $mth/$dd/$yy';
            }

            List<Widget> buildCombinedAuditItems() {
              List awbList = [];
              if (u['data-AWB'] is List) {
                awbList = u['data-AWB'];
              } else if (u['data-AWB'] is Map) {
                awbList = [u['data-AWB']];
              }

              List dcList = [];
              if (u['data-coordinator'] is List) {
                dcList = u['data-coordinator'];
              } else if (u['data-coordinator'] is Map && (u['data-coordinator'] as Map).isNotEmpty) {
                dcList = [u['data-coordinator']];
              }

              List locList = [];
              if (u['data-location'] is List) {
                locList = u['data-location'];
              } else if (u['data-location'] is Map && (u['data-location'] as Map).isNotEmpty) {
                locList = [u['data-location']];
              }

              if (awbList.isEmpty) return [Text('No flight data available.', style: TextStyle(color: textS))];
              
              return awbList.asMap().entries.map((entry) {
                final int idx = entry.key;
                final e = entry.value;
                final isBreak = e['isBreak'] == true;
                final uldNum = e['refULD']?.toString() ?? '';
                final uldDcData = dcList.where((dc) => dc['refULD']?.toString() == uldNum || dcList.length == 1).toList();
                final isExpanded = expandedCards.contains(idx);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Collapsible Header Area
                      InkWell(
                        onTap: () {
                           setStateBuilder(() {
                              if (isExpanded) {
                                expandedCards.remove(idx);
                              } else {
                                expandedCards.add(idx);
                              }
                           });
                        },
                        borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text('ULD: ${e['refULD'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBreak ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isBreak ? const Color(0xFF10b981).withAlpha(50) : const Color(0xFFef4444).withAlpha(50)),
                                ),
                                child: Text(isBreak ? 'BREAK' : 'NO BREAK', style: TextStyle(color: isBreak ? const Color(0xFF10b981) : const Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: textS),
                            ]
                          )
                        )
                      ),
                      
                      // Expanded Content Area
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(padding: EdgeInsets.only(bottom: 12), child: Divider(height: 1)),
                              // --- FLIGHT INFO ---
                              Row(
                                children: [
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Flight', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['refCarrier'] ?? ''} ${e['refNumber'] ?? ''}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Date', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['refDate'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                ]
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Pieces', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['pieces'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Weight', style: TextStyle(color: textS, fontSize: 12)),
                                      Text('${e['weight'] ?? '-'} kg', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                   ])),
                                ]
                              ),
                              if (e['remarks'] != null && e['remarks'].toString().isNotEmpty) ...[
                                 const SizedBox(height: 12),
                                 Text('Remarks: ${e['remarks']}', style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic)),
                              ],

                              // --- NO BREAK MAPPED AWBs ---
                              if (!isBreak && uldNum.isNotEmpty)
                                FutureBuilder<List<dynamic>>(
                                  future: Supabase.instance.client.from('ULD').select('data-ULD').eq('ULD-number', uldNum).maybeSingle().then((res) => (res?['data-ULD'] as List<dynamic>?) ?? []),
                                  builder: (ctx, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                                    }
                                    final listData = snapshot.data ?? [];
                                    if (listData.isEmpty) return const SizedBox.shrink();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                        Row(children: [
                                          Icon(Icons.inventory_2_outlined, size: 16, color: textP),
                                          const SizedBox(width: 8),
                                          Text('Mapped AWBs in ULD', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ]),
                                        const SizedBox(height: 12),
                                        ...listData.map((d) {
                                           return Container(
                                             margin: const EdgeInsets.only(bottom: 6),
                                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                             decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(6)),
                                             child: Row(
                                               children: [
                                                 Expanded(flex: 2, child: Text(d['awb_number']?.toString() ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13))),
                                                 Expanded(flex: 1, child: Text('Pieces: ${d['pieces'] ?? '-'}', style: TextStyle(color: textS, fontSize: 12))),
                                                 Expanded(flex: 1, child: Text('Total: ${d['total'] ?? '-'}', style: TextStyle(color: textS, fontSize: 12))),
                                               ]
                                             )
                                           );
                                        }),
                                      ]
                                    );
                                  }
                                ),

                              // --- COORDINATOR AUDIT ---
                              if (uldDcData.isNotEmpty) ...[
                                 const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                 Row(children: [
                                    Icon(Icons.assignment_turned_in_outlined, size: 16, color: textP),
                                    const SizedBox(width: 8),
                                    Text('Coordinator Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]),
                                 const SizedBox(height: 12),
                                 ...uldDcData.map((dc) {
                                    Map bd = (dc['breakdown'] is Map) ? dc['breakdown'] as Map : {};
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                             children: [
                                                Icon(Icons.person_outline, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(dc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                const Spacer(),
                                                Icon(Icons.access_time, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(formatChicagoTime(dc['time']), style: TextStyle(color: textS, fontSize: 12)),
                                             ]
                                          ),
                                          if (bd.isNotEmpty) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               children: bd.entries.map((entry) {
                                                 if (entry.value is List && (entry.value as List).isEmpty) return const SizedBox.shrink();
                                                 if (entry.value is num && entry.value == 0) return const SizedBox.shrink();
                                                 return Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                   decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF6366f1).withAlpha(50))),
                                                   child: Text('${entry.key}: ${entry.value is List ? entry.value.join(', ') : entry.value}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                                 );
                                               }).toList(),
                                             ),
                                          ],
                                          if (dc['manual_entry'] != null) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               crossAxisAlignment: WrapCrossAlignment.center,
                                               children: [
                                                 Text('Manual Entry:', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                 ...(dc['manual_entry'] is List ? dc['manual_entry'] as List : [dc['manual_entry']]).map((entry) {
                                                   return Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                     decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF6366f1).withAlpha(50))),
                                                     child: Text(entry.toString(), style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                                   );
                                                 }),
                                               ],
                                             ),
                                          ]
                                        ]
                                      )
                                    );
                                 }),
                              ],

                              // --- LOCATION AUDIT ---
                              if (locList.isNotEmpty && awbList.last == e) ...[
                                 const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                 Row(children: [
                                    Icon(Icons.location_on_outlined, size: 16, color: textP),
                                    const SizedBox(width: 8),
                                    Text('Location Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]),
                                 const SizedBox(height: 12),
                                 ...locList.map((loc) {
                                    Map itemLocs = (loc['itemLocations'] is Map) ? loc['itemLocations'] as Map : {};
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                             children: [
                                                Icon(Icons.person_outline, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(loc['user']?.toString() ?? 'Unknown', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
                                                const Spacer(),
                                                Icon(Icons.access_time, size: 14, color: textS),
                                                const SizedBox(width: 6),
                                                Text(formatChicagoTime(loc['time']), style: TextStyle(color: textS, fontSize: 12)),
                                             ]
                                          ),
                                          if (itemLocs.isNotEmpty) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               children: itemLocs.entries.map((entry) {
                                                 if (entry.value == null || entry.value.toString().isEmpty) return const SizedBox.shrink();
                                                 return Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                   decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(50))),
                                                   child: Text('${entry.key} ➔ ${entry.value}', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
                                                 );
                                               }).toList(),
                                             ),
                                          ],
                                          if (loc['manual_entry'] != null) ...[
                                             const SizedBox(height: 10),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 6,
                                               crossAxisAlignment: WrapCrossAlignment.center,
                                               children: [
                                                 Text('Manual Entry:', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                                                 ...(loc['manual_entry'] is List ? loc['manual_entry'] as List : [loc['manual_entry']]).map((entry) {
                                                   return Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                     decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(50))),
                                                     child: Text(entry.toString(), style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
                                                   );
                                                 }),
                                               ],
                                             ),
                                          ]
                                        ]
                                      )
                                    );
                                 }),
                              ]
                            ]
                          )
                        )
                    ]
                  )
                );
              }).toList();
            }

            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: bg,
                elevation: 16,
                child: SizedBox(
                  width: 520, // slightly wider to fit everything beautifully
                  height: double.infinity,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AWB Traceability', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(u['AWB-number']?.toString() ?? 'N/A', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: textP),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            // Totals Summary
                            Text('Pieces Summary', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                              child: Column(
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Root Total:', style: TextStyle(color: textS)), Text(u['total']?.toString() ?? '-', style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Expected (Manifest):', style: TextStyle(color: textS)), Text(expectedPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Received (Coordinator):', style: TextStyle(color: textS)), Text(receivedPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Calculated Status:', style: TextStyle(color: textS)), _buildStatusBadge(status)]),
                                ]
                              )
                            ),
                            const SizedBox(height: 32),
                            
                            Text('ULD Traceability Flow', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...buildCombinedAuditItems(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            );
          }
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      }
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('received')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('checked')) {
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
    } else if (s.contains('ready') || s.contains('saved')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('pending')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    }

    return Container(
      width: 100,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status, 
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
