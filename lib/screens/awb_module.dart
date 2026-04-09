import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;
import 'add_awb_screen.dart';
import 'package:intl/intl.dart';
import '_print_preview.dart';

class AwbModule extends StatefulWidget {
  final bool isActive;
  const AwbModule({super.key, this.isActive = true});

  @override
  State<AwbModule> createState() => _AwbModuleState();
}

class _AwbModuleState extends State<AwbModule> {
  final ScrollController _horizontalScrollController = ScrollController();
  final _searchController = TextEditingController();
  final GlobalKey<AddAwbScreenState> _addAwbKey = GlobalKey<AddAwbScreenState>();
  final Set<String> _selectedAwbIds = {};
  bool _showAddForm = false;
  late Stream<List<Map<String, dynamic>>> _awbStream;

  @override
  void initState() {
    super.initState();
    _awbStream = Supabase.instance.client.from('AWB').stream(primaryKey: ['id']).order('AWB-number', ascending: true);
  }

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

  String _computeAwbStatus(Map<String, dynamic> u) {
    int deliveredPieces = 0;
    if (u['data-deliver'] != null) {
      if (u['data-deliver'] is List) {
        for (var item in u['data-deliver']) {
          if (item is Map && item.containsKey('found')) {
            deliveredPieces += int.tryParse(item['found']?.toString() ?? '0') ?? 0;
          }
        }
      } else if (u['data-deliver'] is Map) {
        deliveredPieces = int.tryParse(u['data-deliver']['found']?.toString() ?? '0') ?? 0;
      }
    }
    
    final int totalValInt = int.tryParse(u['total']?.toString() ?? '0') ?? 0;
    if (deliveredPieces == totalValInt && totalValInt > 0) {
       return 'Ready';
    } else if (deliveredPieces > 0) {
       return 'In Process';
    }
    return 'Waiting';
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
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
                ValueListenableBuilder<bool>(
                  valueListenable: isSidebarExpandedNotifier,
                  builder: (context, expanded, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: expanded ? 0 : 44,
                    );
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showAddForm)
                      Row(
                        children: [
                          IconButton(
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
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            tooltip: appLanguage.value == 'es' ? 'Volver' : 'Back',
                          ),
                          const SizedBox(width: 8),
                          Text(appLanguage.value == 'es' ? 'Añadir Nuevo Aerobill' : 'Add New Air Waybill', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text(appLanguage.value == 'es' ? 'Guías Aéreas' : 'Air Waybills (AWB)', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(appLanguage.value == 'es' ? 'Crea y registra detalles de los aerobills.' : 'Create and register Air Waybill details.', style: TextStyle(color: textS, fontSize: 13))
                    else
                      Text(appLanguage.value == 'es' ? 'Administración y desglose de guías aéreas.' : 'Management and breakdown of Air Waybills.', style: TextStyle(color: textS, fontSize: 13)),
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
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          var text = newValue.text;
                          
                          if (text.contains(RegExp(r'[a-zA-Z]'))) {
                             final updatedText = text.toUpperCase();
                             return TextEditingValue(
                               text: updatedText,
                               selection: newValue.selection,
                             );
                          }
                          
                          text = text.replaceAll(RegExp(r'[^0-9]'), '');
                          if (text.length > 11) text = text.substring(0, 11);

                          var formatted = '';
                          for (int i = 0; i < text.length; i++) {
                            if (i == 3) formatted += '-';
                            if (i == 7) formatted += ' ';
                            formatted += text[i];
                          }

                          return TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        })
                      ],
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
                  if (currentUserData.value?['position'] != 'Supervisor')
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
                ],
              ],
            ),
            const SizedBox(height: 30),
            
            if (_showAddForm)
              Expanded(
                child: AddAwbScreen(
                  key: _addAwbKey,
                  onPop: (didAdd) {
                    setState(() {
                      _showAddForm = false;
                    });
                  },
                ),
              )
            else
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCard),
                        ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _awbStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  var awbs = snapshot.data ?? [];
                  
                  if (_searchController.text.isNotEmpty) {
                    final terms = _searchController.text.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
                    awbs = awbs.where((u) {
                      final awbSearch = u['AWB-number']?.toString().toLowerCase() ?? '';
                      final statusSearch = _computeAwbStatus(u).toLowerCase();
                      
                      final combinedString = '$awbSearch $statusSearch';
                      
                      return terms.every((term) => combinedString.contains(term));
                    }).toList();
                  }

                  if (awbs.isEmpty) return const Center(child: Text('No AWBs found.', style: TextStyle(color: Color(0xFF94a3b8))));

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            thickness: 8,
                            radius: const Radius.circular(8),
                            interactive: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
                          child: SingleChildScrollView(
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                        dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                        headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),
                        columns: [
                          const DataColumn(label: Text('#')),
                          const DataColumn(label: Text('AWB Number')),
                          const DataColumn(label: Text('Pieces Expected')),
                          const DataColumn(label: Text('Pieces Received')),
                          const DataColumn(label: Text('Delivered Pieces')),
                          const DataColumn(label: Text('Remaining Pieces')),
                          const DataColumn(label: Text('Reject')),
                          const DataColumn(label: Text('Total Pieces')),
                          const DataColumn(label: Text('Total Weight')),
                          const DataColumn(label: Text('Status')),
                          DataColumn(
                            label: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: _selectedAwbIds.length == awbs.length && awbs.isNotEmpty,
                              onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedAwbIds.addAll(awbs.map((e) => e['id'].toString()));
                                    } else {
                                      _selectedAwbIds.clear();
                                    }
                                  });
                              },
                            ),
                          ),
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

                          int deliveredPieces = 0;
                          if (u['data-deliver'] != null) {
                            if (u['data-deliver'] is List) {
                              for (var item in u['data-deliver']) {
                                if (item is Map && item.containsKey('found')) {
                                  deliveredPieces += int.tryParse(item['found']?.toString() ?? '0') ?? 0;
                                }
                              }
                            } else if (u['data-deliver'] is Map) {
                              deliveredPieces = int.tryParse(u['data-deliver']['found']?.toString() ?? '0') ?? 0;
                            }
                          }
                          
                          int remainingPieces = expectedPieces - deliveredPieces;
                          if (remainingPieces < 0) remainingPieces = 0;

                          List<Map<String, dynamic>> rejectDataList = [];
                          
                          if (u['data-deliver'] != null) {
                             if (u['data-deliver'] is List) {
                                for (var del in u['data-deliver']) {
                                   if (del is Map && del.containsKey('rejection') && del['rejection'] != null) {
                                      Map<String, dynamic> r = del['rejection'] as Map<String, dynamic>;
                                      rejectDataList.add(r);
                                   }
                                }
                             } else if (u['data-deliver'] is Map && u['data-deliver']['rejection'] != null) {
                                Map<String, dynamic> r = u['data-deliver']['rejection'] as Map<String, dynamic>;
                                rejectDataList.add(r);
                             }
                          }
                          
                          if (rejectDataList.isEmpty && u['data-reject'] != null) {
                             if (u['data-reject'] is List) {
                                for (var r in u['data-reject']) {
                                   if (r is Map) {
                                      rejectDataList.add(r as Map<String, dynamic>);
                                   }
                                }
                             } else if (u['data-reject'] is Map) {
                                Map<String, dynamic> r = u['data-reject'] as Map<String, dynamic>;
                                rejectDataList.add(r);
                             }
                          }

                          String status = _computeAwbStatus(u);

                          return DataRow(
                            onSelectChanged: (_) => _showAwbDrawer(context, u, dark, receivedPieces, expectedPieces, status),
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(u['AWB-number']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                              DataCell(Text(expectedPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(receivedPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(deliveredPieces > 0 ? deliveredPieces.toString() : '-', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10b981)))),
                              DataCell(Text(remainingPieces.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange))),
                              DataCell(
                                rejectDataList.isNotEmpty 
                                ? InkWell(
                                    onTap: () {
                                       showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: Text('Reject Details', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold)),
                                            content: SizedBox(
                                              width: 350, // standard constrained width
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                itemCount: rejectDataList.length,
                                                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                                                itemBuilder: (ctx, i) {
                                                  final rData = rejectDataList[i];
                                                  final pcs = int.tryParse(rData['pieces']?.toString() ?? rData['qty']?.toString() ?? '0') ?? 0;
                                                  return Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))
                                                    ),
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Text('Rejection ${i + 1}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                                            const SizedBox(height: 8),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                                    Text('Pieces', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold)),
                                                                    const SizedBox(height: 2),
                                                                    Text(pcs.toString(), style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 13, fontWeight: FontWeight.bold)),
                                                                 ]),
                                                                 Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                                                    Text('Location', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold)),
                                                                    const SizedBox(height: 2),
                                                                    Text(rData['location']?.toString() ?? 'Unknown', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 13)),
                                                                 ]),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Text('Reason', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold)),
                                                            const SizedBox(height: 2),
                                                            Text(rData['reason']?.toString() ?? 'No reason provided', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 13)),
                                                            const SizedBox(height: 8),
                                                            Row(
                                                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                               children: [
                                                                  Row(
                                                                    children: [
                                                                      Icon(Icons.person_outline, size: 14, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
                                                                      const SizedBox(width: 4),
                                                                      Text(rData['user']?.toString() ?? 'Unknown', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 12)),
                                                                    ],
                                                                  ),
                                                                  Text(rData['time'] != null ? DateFormat('hh:mm a').format(DateTime.parse(rData['time'].toString()).toLocal()) : '', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 12)),
                                                               ]
                                                            ),
                                                        ]
                                                    )
                                                  );
                                                }
                                              )
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx), 
                                                child: Text('Close', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)))
                                              )
                                            ],
                                          )
                                       );
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withAlpha(25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(rejectDataList.length.toString(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                    )
                                ) 
                                : const Text('-', style: TextStyle(fontWeight: FontWeight.w500))
                              ),
                              DataCell(Text(u['total']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366f1)))),
                              DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\\.$|\\.0$'), '')} kg', style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(_buildStatusBadge(status)),
                              DataCell(
                                Checkbox(
                                  visualDensity: VisualDensity.compact,
                                  value: _selectedAwbIds.contains(u['id']?.toString()),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedAwbIds.add(u['id'].toString());
                                      } else {
                                        _selectedAwbIds.remove(u['id'].toString());
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ));
              },
            );
          },
        ),
                  ),
                ),
              ),
              if (_selectedAwbIds.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1e293b) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
                        border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366f1).withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_selectedAwbIds.length} Selected',
                              style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(height: 24, width: 1, color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                          const SizedBox(width: 16),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.print_rounded, color: Color(0xFF6366f1)), tooltip: 'Print Selected', style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))),
                          const SizedBox(width: 8),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF6366f1)), tooltip: 'Download PDF', style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))),
                          const SizedBox(width: 8),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), tooltip: 'Delete Selected', style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withAlpha(15))),
                        ],
                      ),
                    ),
                  ),
                )
            ],
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

            List<Widget> buildDeliveryItems() {
               List delList = [];
               if (u['data-deliver'] is List) {
                 delList = u['data-deliver'];
               } else if (u['data-deliver'] is Map && (u['data-deliver'] as Map).isNotEmpty) {
                 delList = [u['data-deliver']];
               }
               
               if (delList.isEmpty) return [];

               return delList.map((del) {
                 final isRejected = del.containsKey('rejection');
                 final rej = isRejected ? (del['rejection'] as Map) : null;
                 
                 return Container(
                   margin: const EdgeInsets.only(bottom: 16),
                   decoration: BoxDecoration(
                     color: bgCard,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                             color: const Color(0xFF10b981).withAlpha(15),
                             borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                             border: Border(bottom: BorderSide(color: const Color(0xFF10b981).withAlpha(30))),
                          ),
                          child: Row(
                            children: [
                               const Icon(Icons.outbox_rounded, color: Color(0xFF10b981), size: 20),
                               const SizedBox(width: 8),
                               const Text('Delivered to Driver', style: TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 15)),
                               const Spacer(),
                               Icon(Icons.access_time, size: 14, color: textS),
                               const SizedBox(width: 6),
                               Text(formatChicagoTime(del['time']), style: TextStyle(color: textS, fontSize: 12)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Row(
                                 children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Company', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('${del['company'] ?? '-'}', style: TextStyle(color: textP, fontSize: 15, fontWeight: FontWeight.bold)),
                                    ])),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Driver', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('${del['driver'] ?? '-'}', style: TextStyle(color: textP, fontSize: 15, fontWeight: FontWeight.bold)),
                                    ])),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Door', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('${del['door'] ?? '-'}', style: TextStyle(color: textP, fontSize: 15, fontWeight: FontWeight.bold)),
                                    ])),
                                 ],
                               ),
                               const SizedBox(height: 16),
                               Row(
                                 children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Status', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('${del['status'] ?? '-'}', style: TextStyle(color: textP, fontSize: 14)),
                                    ])),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Type', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('${del['type'] ?? '-'}', style: TextStyle(color: textP, fontSize: 14)),
                                    ])),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Pickup ID', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('${del['pickup_id'] ?? '-'}', style: TextStyle(color: textP, fontSize: 14)),
                                    ])),
                                 ],
                               ),
                               const SizedBox(height: 16),
                               Row(
                                 children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Pieces Handed Over (Expected / Found)', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('${del['delivery'] ?? 0} / ${del['found'] ?? 0} (Total ${del['total'] ?? 0})', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 14, fontWeight: FontWeight.bold)),
                                    ])),
                                 ]
                               ),
                               if (del['remark'] != null && del['remark'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text('Remark: ${del['remark']}', style: TextStyle(color: textS, fontSize: 13, fontStyle: FontStyle.italic)),
                               ],
                               
                               if (isRejected && rej != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFef4444).withAlpha(15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFef4444).withAlpha(30)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                         Row(
                                           children: [
                                             const Icon(Icons.warning_amber_rounded, color: Color(0xFFef4444), size: 18),
                                             const SizedBox(width: 6),
                                             const Text('REJECTION RECORDED', style: TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.bold)),
                                             const Spacer(),
                                             Text(formatChicagoTime(rej['time']), style: const TextStyle(color: Color(0xFFef4444), fontSize: 11)),
                                           ],
                                         ),
                                         const SizedBox(height: 10),
                                         Row(
                                           children: [
                                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                const Text('Rejected Qty', style: TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.w600)),
                                                Text('${rej['qty'] ?? 0}', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                              ])),
                                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                const Text('New Location', style: TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.w600)),
                                                Text('${rej['location'] ?? '-'}', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                              ])),
                                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                const Text('Recorded By', style: TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.w600)),
                                                Text('${rej['user'] ?? '-'}', style: TextStyle(color: textP, fontSize: 14)),
                                              ])),
                                           ]
                                         ),
                                         const SizedBox(height: 8),
                                         const Text('Reason', style: TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.w600)),
                                         Text('${rej['reason'] ?? '-'}', style: TextStyle(color: textP, fontSize: 13, fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                               ],
                            ],
                          ),
                        ),
                     ],
                   ),
                 );
               }).toList();
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
                final uldDcData = dcList.where((dc) => dc['refULD']?.toString() == uldNum).toList();
                final uldLocData = locList.where((loc) => loc['refULD']?.toString() == uldNum).toList();
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
                                                   child: Text(
                                                     entry.value is List 
                                                        ? '${(entry.value as List).length} ${entry.key}: ${(entry.value as List).join(', ')}' 
                                                        : '${entry.key}: ${entry.value}', 
                                                     style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)
                                                   ),
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
                              if (uldLocData.isNotEmpty) ...[
                                 const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                 Row(children: [
                                    Icon(Icons.location_on_outlined, size: 16, color: textP),
                                    const SizedBox(width: 8),
                                    Text('Location Audit', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]),
                                 const SizedBox(height: 12),
                                 ...uldLocData.map((loc) {
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
                                                 
                                                 String formattedKey = entry.key;
                                                 final RegExp exp = RegExp(r'^(.*?)[\-_](\d+)$');
                                                 final match = exp.firstMatch(formattedKey);
                                                 if (match != null) {
                                                     final prefix = match.group(1)?.trim() ?? '';
                                                     final numStr = match.group(2) ?? '0';
                                                     final numValue = int.tryParse(numStr) ?? 0;
                                                     formattedKey = '${numValue + 1} $prefix';
                                                 }

                                                 return Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                   decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF10b981).withAlpha(50))),
                                                   child: Text('$formattedKey ➔ ${entry.value}', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.w600)),
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
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.print_rounded, color: textP),
                                  onPressed: () {
                                     showPrintPreviewDialog(context, u);
                                  },
                                  tooltip: 'Print Preview',
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: textP),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text('ULD Traceability Flow', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...buildCombinedAuditItems(),
                            const SizedBox(height: 32),

                            if (u['data-deliver'] != null) ...[
                               Text('Delivery Execution', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                               const SizedBox(height: 12),
                               ...buildDeliveryItems(),
                               const SizedBox(height: 24),
                            ],
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
    } else if (s.contains('process') || s.contains('progress') || s.contains('received')) {
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


