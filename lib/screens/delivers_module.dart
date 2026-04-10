import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;
import 'add_deliver_screen.dart';
import '_deliver_print_preview.dart';
import '_deliver_pdf_exporter.dart';

class DeliversModule extends StatefulWidget {
  final bool isActive;
  const DeliversModule({super.key, this.isActive = true});

  @override
  State<DeliversModule> createState() => _DeliversModuleState();
}

class _DeliversModuleState extends State<DeliversModule> {
  final ScrollController _horizontalScrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddDeliverScreenState> _addDeliverKey = GlobalKey<AddDeliverScreenState>();
  late Stream<List<Map<String, dynamic>>> _deliversStream;
  final Set<String> _selectedDeliverIds = {};

  @override
  void initState() {
    super.initState();
    _deliversStream = Supabase.instance.client.from('Delivers').stream(primaryKey: ['id']).order('time-deliver', ascending: true);
  }

  @override
  void didUpdateWidget(covariant DeliversModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_showAddForm && _addDeliverKey.currentState != null) {
        if (!_addDeliverKey.currentState!.hasDataSync) {
          setState(() => _showAddForm = false);
        }
      }
    }
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
                              if (_addDeliverKey.currentState != null) {
                                final canPop = await _addDeliverKey.currentState!.handleBackRequest();
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
                          Text(appLanguage.value == 'es' ? 'Añadir Nueva Entrega' : 'Add New Deliver', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text('Delivers / Transfers', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(
                        appLanguage.value == 'es' ? 'Registra una nueva entrega en el sistema.' : 'Register a new delivery in the system.',
                        style: TextStyle(color: textS, fontSize: 13)
                      )
                    else
                      Text(
                        appLanguage.value == 'es' 
                          ? 'Administración de entregas.' 
                          : 'Management of deliveries.', 
                        style: TextStyle(color: textS, fontSize: 13)
                      ),
                  ],
                ),
                const Spacer(),
                
                // Search Box
                if (!_showAddForm) ...[
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
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))],
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
                ],
                
                if (!_showAddForm && currentUserData.value?['position'] != 'Supervisor')
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddForm = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(appLanguage.value == 'es' ? 'Añadir Entrega' : 'Add Deliver', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
            ),
            const SizedBox(height: 30),
            
            if (_showAddForm)
              Expanded(
                child: AddDeliverScreen(
                  key: _addDeliverKey,
                  onPop: (didAdd) {
                    setState(() {
                      _showAddForm = false;
                      // stream autoupdates
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
                      stream: _deliversStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                        }
                        
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                        }
  
                        var items = snapshot.data ?? [];
                      
                        items.sort((a, b) {
                          const statusOrder = ['Waiting', 'In process', 'Ready', 'Canceled'];
                          final statusA = a['status']?.toString() ?? 'Waiting';
                          final statusB = b['status']?.toString() ?? 'Waiting';
                          
                          int indexA = statusOrder.indexOf(statusA);
                          int indexB = statusOrder.indexOf(statusB);
                          if (indexA == -1) indexA = 999;
                          if (indexB == -1) indexB = 999;
                          
                          int statusComp = indexA.compareTo(indexB);
                          if (statusComp != 0) return statusComp;

                          final taStr = a['time-deliver']?.toString() ?? '';
                          final tbStr = b['time-deliver']?.toString() ?? '';
                          if (taStr.isEmpty && tbStr.isNotEmpty) return 1;
                          if (taStr.isNotEmpty && tbStr.isEmpty) return -1;
                          if (taStr.isEmpty && tbStr.isEmpty) return 0;
                          
                          final da = DateTime.tryParse(taStr) ?? DateTime(1970);
                          final db = DateTime.tryParse(tbStr) ?? DateTime(1970);
                          return da.compareTo(db);
                        });

                      if (_searchController.text.isNotEmpty) {
                        final terms = _searchController.text.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
                        items = items.where((u) {
                           final comp = (u['truck-company']?.toString() ?? '').toLowerCase();
                           final dr = (u['driver']?.toString() ?? '').toLowerCase();
                           final door = (u['door']?.toString() ?? '').toLowerCase();
                           final pId = (u['id-pickup']?.toString() ?? '').toLowerCase();
                           final status = (u['status']?.toString() ?? 'waiting').toLowerCase();
                           
                           final combinedString = '$comp $dr $door $pId $status';
                           
                           return terms.every((term) => combinedString.contains(term));
                        }).toList();
                      }

                      if (items.isEmpty) return Center(child: Text(appLanguage.value == 'es' ? 'No se encontraron registros.' : 'No records found.', style: const TextStyle(color: Color(0xFF94a3b8))));

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
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Compañía' : 'Company')),
                                    const DataColumn(label: Text('Driver')),
                                    const DataColumn(label: Text('Door')),
                                    const DataColumn(label: Text('Type')),
                                    const DataColumn(label: Text('ID Pickup')),
                                    const DataColumn(label: Text('Time')),
                                    const DataColumn(label: Text('Priority')),
                                    const DataColumn(label: Text('AWBs')),
                                    const DataColumn(label: Text('No Show')),
                                    const DataColumn(label: Text('Agent')),
                                    const DataColumn(label: Text('Remarks')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
                                    DataColumn(
                                      label: Checkbox(
                                        value: _selectedDeliverIds.isNotEmpty && items.isNotEmpty && _selectedDeliverIds.length == items.length,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedDeliverIds.addAll(items.map((e) => e['id'].toString()));
                                            } else {
                                              _selectedDeliverIds.clear();
                                            }
                                          });
                                        },
                                        activeColor: const Color(0xFF6366f1),
                                        side: BorderSide(color: dark ? Colors.white54 : Colors.black54),
                                      ),
                                    ),
                                  ],
                                  rows: List.generate(items.length, (index) {
                                    final u = items[index];
                                    final dId = u['id']?.toString() ?? '';
                                    
                                    String timeStr = '-';
                                    if (u['time-deliver'] != null) {
                                      final tdt = DateTime.tryParse(u['time-deliver'].toString())?.toLocal();
                                      if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
                                    }

                                    String awbsStr = '0';
                                    if (u['list-pickup'] != null) {
                                      if (u['list-pickup'] is List) {
                                        awbsStr = (u['list-pickup'] as List).length.toString();
                                      } else {
                                        awbsStr = '1';
                                      }
                                    }
                                    
                                    bool isPriority = u['isPriority'] == true;
                                    
                                    int noShowCount = 0;
                                    if (u['no-show'] != null) {
                                      if (u['no-show'] is List) {
                                        noShowCount = (u['no-show'] as List).length;
                                      } else if (u['no-show'] is Map && (u['no-show'] as Map).isNotEmpty) {
                                        noShowCount = 1;
                                      }
                                    }

                                    return DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected == true) {
                                          _showDeliverDetails(context, u, dark);
                                        }
                                      },
                                      cells: [
                                        DataCell(Text('${index + 1}')),
                                        DataCell(Text(u['truck-company']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                                        DataCell(Text(u['driver']?.toString() ?? '-')),
                                        DataCell(Text(u['door']?.toString() ?? '-')),
                                        DataCell(Text(u['type']?.toString() ?? '-')),
                                        DataCell(Text(u['id-pickup']?.toString() ?? '-')),
                                        DataCell(Text(timeStr)),
                                        DataCell(isPriority ? const Icon(Icons.star_rounded, color: Colors.orange, size: 20) : const Icon(Icons.star_border_rounded, color: Colors.grey, size: 20)),
                                        DataCell(
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) {
                                                  List<Map<String, dynamic>> awbItems = [];
                                                  if (u['list-pickup'] is List) {
                                                    awbItems = (u['list-pickup'] as List).map((e) {
                                                       if (e is Map) return Map<String, dynamic>.from(e);
                                                       final str = e.toString();
                                                       final parts = str.split(' - ');
                                                       return {
                                                          'AWB-number': parts.isNotEmpty ? parts[0].trim() : '-',
                                                          'pieces': parts.length > 1 ? parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '') : '-',
                                                          'weight': '',
                                                          'remarks': parts.length > 2 ? parts[2].trim() : '',
                                                       };
                                                    }).toList();
                                                  } else if (u['list-pickup'] != null) {
                                                    final str = u['list-pickup'].toString();
                                                    final parts = str.split(' - ');
                                                    awbItems = [{
                                                       'AWB-number': parts.isNotEmpty ? parts[0].trim() : '-',
                                                       'pieces': parts.length > 1 ? parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '') : '-',
                                                       'weight': '',
                                                       'remarks': parts.length > 2 ? parts[2].trim() : '',
                                                    }];
                                                  }
                                                  return AlertDialog(
                                                    backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                                    title: Row(
                                                      children: [
                                                        const Icon(Icons.inventory_2_rounded, color: Color(0xFF6366f1)),
                                                        const SizedBox(width: 8),
                                                        Text(appLanguage.value == 'es' ? 'Detalles de Entrega' : 'Delivery Details', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold)),
                                                      ]
                                                    ),
                                                    content: SizedBox(
                                                      width: 400,
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: awbItems.length,
                                                        itemBuilder: (ctx, i) {
                                                          final item = awbItems[i];
                                                          final awbN = item['ULD-number']?.toString() ?? item['AWB-number']?.toString() ?? '-';
                                                          final pcs = item['pieces']?.toString() ?? '-';
                                                          final weight = item['weight']?.toString() ?? '';
                                                          final rmks = item['remarks']?.toString() ?? '';
                                                          return Container(
                                                            margin: const EdgeInsets.only(bottom: 8),
                                                            padding: const EdgeInsets.all(12),
                                                            decoration: BoxDecoration(
                                                              color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Expanded(child: Text(awbN, style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold))),
                                                                    SizedBox(
                                                                      width: 70,
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                        children: [
                                                                          Flexible(child: Text('$pcs pcs', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    if (weight.isNotEmpty && weight != '0.00' && weight != '0')
                                                                      SizedBox(
                                                                        width: 80,
                                                                        child: Row(
                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                          children: [
                                                                            Flexible(child: Text('${weight}kg', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    if (weight.isEmpty || weight == '0.00' || weight == '0')
                                                                      const SizedBox(width: 80),
                                                                  ]
                                                                ),
                                                                if (rmks.isNotEmpty) ...[
                                                                  const SizedBox(height: 4),
                                                                  Text('Remarks: $rmks', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 12)),
                                                                ]
                                                              ]
                                                            )
                                                          );
                                                        }
                                                      )
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx),
                                                        child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold))
                                                      )
                                                    ]
                                                  );
                                                }
                                              );
                                            },
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366f1).withAlpha(25),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(awbsStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366f1), fontSize: 13)),
                                            )
                                          )
                                        ),
                                        DataCell(
                                          noShowCount > 0 
                                              ? InkWell(
                                                  onTap: () {
                                                    _showNoShowDetails(context, u['no-show'], dark, dark ? Colors.white : const Color(0xFF111827));
                                                  },
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(color: Colors.redAccent.withAlpha(30), shape: BoxShape.circle),
                                                    child: Text('$noShowCount', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                                  ),
                                                )
                                              : const Text('-', style: TextStyle(color: Colors.grey))
                                        ),
                                        DataCell(
                                          Builder(builder: (ctx) {
                                            if (u['ref-userDrive'] == null) return const Text('-', style: TextStyle(color: Colors.grey));
                                            if (u['ref-userDrive'] is Map) {
                                              final userMap = u['ref-userDrive'] as Map;
                                              final userName = userMap['user']?.toString() ?? '-';
                                              String dtStr = '';
                                              if (userMap['time'] != null) {
                                                final dt = DateTime.tryParse(userMap['time'].toString())?.toLocal();
                                                if (dt != null) dtStr = DateFormat('MMM dd, hh:mm a').format(dt);
                                              }
                                              final avatarStr = userMap['avatar']?.toString();
                                              return Tooltip(
                                                message: 'Agent: $userName',
                                                child: InkWell(
                                                  onTap: () => _showAgentProfile(context, userName, avatarStr, dtStr, dark),
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: const Color(0xFF6366f1).withAlpha(50),
                                                    backgroundImage: avatarStr != null && avatarStr.isNotEmpty ? NetworkImage(avatarStr) : null,
                                                    child: avatarStr == null || avatarStr.isEmpty ? Text(
                                                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366f1), fontSize: 13),
                                                    ) : null,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('-', style: TextStyle(color: Colors.grey));
                                          })
                                        ),
                                        DataCell(Tooltip(message: u['remarks']?.toString() ?? '', child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(u['remarks']?.toString() ?? '-', overflow: TextOverflow.ellipsis)))),
                                        DataCell(_buildStatusBadge(u['status']?.toString() ?? 'Waiting', itemData: u)),
                                        DataCell(
                                          Checkbox(
                                            value: _selectedDeliverIds.contains(dId),
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedDeliverIds.add(dId);
                                                } else {
                                                  _selectedDeliverIds.remove(dId);
                                                }
                                              });
                                            },
                                            activeColor: const Color(0xFF6366f1),
                                            side: BorderSide(color: dark ? Colors.white54 : Colors.black54),
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
            if (_selectedDeliverIds.isNotEmpty)
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
                            '${_selectedDeliverIds.length} Selected',
                            style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(height: 24, width: 1, color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () async {
                              final res = await Supabase.instance.client.from('Delivers').select().inFilter('id', _selectedDeliverIds.toList());
                              final selected = List<Map<String, dynamic>>.from(res);
                              if (selected.isNotEmpty) {
                                DeliverPdfExporter.printDelivers(selected);
                              }
                          }, 
                          icon: const Icon(Icons.print_rounded, color: Color(0xFF6366f1)), 
                          tooltip: 'Print Selected', 
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                              final res = await Supabase.instance.client.from('Delivers').select().inFilter('id', _selectedDeliverIds.toList());
                              final selected = List<Map<String, dynamic>>.from(res);
                              if (selected.isNotEmpty) {
                                DeliverPdfExporter.downloadPdf(selected);
                              }
                          }, 
                          icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF6366f1)), 
                          tooltip: 'Download PDF', 
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete Delivers'),
                                  content: Text('Are you sure you want to delete ${_selectedDeliverIds.length} Deliver(s)?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete'),
                                    )
                                  ],
                                )
                              );
                              if (confirm == true) {
                                for (var id in _selectedDeliverIds) {
                                  await Supabase.instance.client.from('Delivers').delete().eq('id', id);
                                }
                                setState(() => _selectedDeliverIds.clear());
                              }
                          }, 
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), 
                          tooltip: 'Delete Selected', 
                          style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withAlpha(15))
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
        );
      }
    );
  }

  void _showNoShowDetails(BuildContext context, dynamic noShowData, bool dark, Color textP) {
    List<Map<String, dynamic>> items = [];
    if (noShowData is List) {
      items = noShowData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (noShowData is Map) {
      items = [Map<String, dynamic>.from(noShowData)];
    }

    showDialog(context: context, builder: (ctx) {
      return Dialog(
        backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No Show Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...items.map((i) {
                String tStr = i['time']?.toString() ?? '-';
                if (tStr != '-') {
                  final parsed = DateTime.tryParse(tStr)?.toLocal();
                  if (parsed != null) {
                    tStr = DateFormat('MMM dd, hh:mm a').format(parsed);
                  }
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark ? Colors.white.withAlpha(20) : Colors.grey.shade300)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(i['user']?.toString() ?? 'Unknown User', style: TextStyle(color: textP, fontWeight: FontWeight.w600))),
                        ]
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tStr, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                        ]
                      )
                    ]
                  )
                );
              }),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        )
      );
    });
  }

  void _showDeliverDetails(BuildContext context, Map<String, dynamic> u, bool dark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        bool isEditing = false;
        bool isEditingAwbs = false;
        List<Map<String, dynamic>> tempAwbsList = [];
        final Map<String, dynamic> tempU = Map.from(u);
        return StatefulBuilder(
          builder: (context, setDrawerState) {
            final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
            final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        List<Map<String, dynamic>> awbs = [];
        if (u['list-pickup'] != null) {
          if (u['list-pickup'] is List) {
            awbs = (u['list-pickup'] as List).map((e) {
              if (e is Map) return Map<String, dynamic>.from(e);
              final str = e.toString();
              final parts = str.split(' - ');
              return {
                'AWB-number': parts.isNotEmpty ? parts[0].trim() : '-',
                'pieces': parts.length > 1 ? parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '') : '-',
                'weight': '',
                'remarks': parts.length > 2 ? parts[2].trim() : '',
              };
            }).toList();
          } else {
            final str = u['list-pickup'].toString();
            if (str.isNotEmpty) {
              final parts = str.split(' - ');
              awbs = [{
                'AWB-number': parts.isNotEmpty ? parts[0].trim() : '-',
                'pieces': parts.length > 1 ? parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '') : '-',
                'weight': '',
                'remarks': parts.length > 2 ? parts[2].trim() : '',
              }];
            }
          }
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: bg,
            elevation: 16,
            child: SizedBox(
              width: 520,
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
                            Text('Deliver Details', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, color: textP, size: 24),
                                const SizedBox(width: 8),
                                Text(u['truck-company']?.toString() ?? 'Unknown Company', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                              ]
                            )
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => showDeliverPrintPreviewDialog(context, u),
                              icon: Icon(Icons.print_rounded, color: textP, size: 20),
                              tooltip: 'Print Deliver Manifest',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(Icons.close_rounded, color: textP, size: 20),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [Icon(Icons.badge_outlined, size: 16, color: textP), const SizedBox(width: 8), Text('Driver Information', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold))]),
                                      if (!isEditing)
                                        IconButton(
                                          onPressed: () {
                                            setDrawerState(() {
                                              isEditing = true;
                                              tempU.clear();
                                              tempU.addAll(u);
                                            });
                                          },
                                          tooltip: appLanguage.value == 'es' ? 'Editar' : 'Edit',
                                          icon: Icon(Icons.edit_rounded, color: textP, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      else
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () => setDrawerState(() => isEditing = false),
                                              tooltip: appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                                              icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              onPressed: () async {
                                                try {
                                                  await Supabase.instance.client.from('Delivers').update(tempU).eq('id', u['id']);
                                                  u.addAll(tempU);
                                                  setDrawerState(() => isEditing = false);
                                                  if (mounted) setState(() {});
                                                } catch (_) {}
                                              },
                                              tooltip: appLanguage.value == 'es' ? 'Guardar Cambios' : 'Save Changes',
                                              icon: const Icon(Icons.check_rounded, color: Color(0xFF22c55e), size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        )
                                    ]
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _buildDeliverEditableCard(context, 'Driver Name', 'driver', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.person_outline)),
                                      Expanded(child: _buildDeliverEditableCard(context, 'ID Pickup', 'id-pickup', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.badge_outlined)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildDeliverEditableCard(context, 'Type', 'type', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.local_shipping_outlined, isTypeDropdown: true)),
                                      Expanded(child: _buildDeliverEditableCard(context, 'Status', 'status', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.info_outline, isStatusDropdown: true)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildDeliverEditableCard(context, 'Priority', 'isPriority', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.star_outline, isPriority: true)),
                                      Expanded(child: _buildDeliverEditableCard(context, 'Time', 'time-deliver', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.access_time_rounded, isTime: true)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 1, child: _buildDeliverEditableCard(context, 'Door', 'door', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.door_front_door_outlined)),
                                      const SizedBox(width: 16),
                                      Expanded(flex: 2, child: _buildDeliverEditableCard(context, 'Remarks', 'remarks', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.notes, isRemarks: true)),
                                    ],
                                  ),
                               ]
                             )
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(appLanguage.value == 'es' ? 'Lista de Entregas' : 'List of Delivery', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                                    child: Text('${(isEditingAwbs ? tempAwbsList : awbs).length}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              if (!isEditingAwbs)
                                IconButton(
                                  onPressed: () {
                                    setDrawerState(() {
                                      isEditingAwbs = true;
                                      tempAwbsList = List<Map<String, dynamic>>.from(awbs);
                                    });
                                  },
                                  tooltip: appLanguage.value == 'es' ? 'Editar lista' : 'Edit list',
                                  icon: Icon(Icons.edit_rounded, color: textP, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              else
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => setDrawerState(() => isEditingAwbs = false),
                                      tooltip: appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      onPressed: () async {
                                        try {
                                          await Supabase.instance.client.from('Delivers').update({
                                            'list-pickup': tempAwbsList
                                          }).eq('id', u['id']);
                                          u['list-pickup'] = tempAwbsList;
                                          setDrawerState(() => isEditingAwbs = false);
                                          if (mounted) setState(() {});
                                        } catch (_) {}
                                      },
                                      tooltip: appLanguage.value == 'es' ? 'Guardar Cambios' : 'Save Changes',
                                      icon: const Icon(Icons.check_rounded, color: Color(0xFF22c55e), size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Builder(builder: (ctx) {
                            final currentList = isEditingAwbs ? tempAwbsList : awbs;
                            if (currentList.isEmpty) {
                              return Text(appLanguage.value == 'es' ? 'No hay items asignados.' : 'No items assigned.', style: TextStyle(color: textS));
                            }
                            return Column(
                              children: currentList.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              final awbN = item['ULD-number']?.toString() ?? item['AWB-number']?.toString() ?? '-';
                              final pcs = item['pieces']?.toString() ?? '-';
                              final weight = item['weight']?.toString() ?? '';
                              final rem = item['remarks']?.toString() ?? '';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), shape: BoxShape.circle),
                                      child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: Text(awbN, style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined, color: textS, size: 14),
                                          const SizedBox(width: 6),
                                          Flexible(child: Text('$pcs pcs', style: TextStyle(color: textS, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ),
                                    if (weight.isNotEmpty && weight != '0.00' && weight != '0')
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Icon(Icons.scale_rounded, color: textS, size: 14),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text('${weight}kg', style: TextStyle(color: textS, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                          ]
                                        ),
                                      ),
                                    Expanded(
                                      flex: 4,
                                      child: rem.isNotEmpty ? Row(
                                        children: [
                                          Icon(Icons.notes_rounded, color: textS, size: 14),
                                          const SizedBox(width: 6),
                                          Flexible(child: Text(rem, style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                        ]
                                      ) : const SizedBox(),
                                    ),
                                    if (isEditingAwbs) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          setDrawerState(() {
                                            tempAwbsList.removeAt(idx);
                                          });
                                        },
                                        tooltip: appLanguage.value == 'es' ? 'Eliminar' : 'Remove',
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                           );
                          }),
                        ],
                      ),
                    ),
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
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }


  Widget _buildDeliverEditableCard(
    BuildContext context, 
    String label, 
    String key, 
    Map<String, dynamic> u, 
    bool isEditing, 
    Map<String, dynamic> tempU,
    StateSetter setDrawerState, 
    bool dark, 
    Color colorL, 
    Color colorP, 
    {IconData? icon, bool isTime = false, bool isRemarks = false, bool isPriority = false, bool isTypeDropdown = false, bool isStatusDropdown = false}
  ) {
    if (!isEditing) {
      String displayValue = '${u[key] ?? '-'}';
      

      
      if (isTime) {
         displayValue = '-';
         if (u['time-deliver'] != null) {
           final tdt = DateTime.tryParse(u['time-deliver'].toString())?.toLocal();
           if (tdt != null) displayValue = DateFormat('hh:mm a').format(tdt);
         }
      } else if (isPriority) {
         displayValue = (u[key] == true) ? 'High Priority' : 'Normal';
      } else if (isRemarks) {
         displayValue = (u['remarks']?.toString() ?? '').isEmpty ? 'No remarks' : u['remarks'].toString();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colorL, size: 14),
                  const SizedBox(width: 4),
                ],
                Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            Text(displayValue, style: TextStyle(color: colorP, fontSize: 13, fontWeight: FontWeight.bold), overflow: isRemarks ? null : TextOverflow.ellipsis),
          ],
        ),
      );
    }
    
    final inputBorderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    Widget editor;

    if (isTime) {
      String tStr = '-';
      if (tempU['time-deliver'] != null) {
        final tdt = DateTime.tryParse(tempU['time-deliver'].toString())?.toLocal();
        if (tdt != null) tStr = DateFormat('hh:mm a').format(tdt);
      }
      editor = InkWell(
        onTap: () async {
          final tdt = DateTime.tryParse(tempU['time-deliver']?.toString() ?? '')?.toLocal() ?? DateTime.now();
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: tdt.hour, minute: tdt.minute),
            builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b)),
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                ),
            )
          );
          if (picked != null) {
             final now = DateTime.now();
             final newDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute).toUtc();
             setDrawerState(() => tempU[key] = newDate.toIso8601String());
          }
        },
        child: Container(
          width: double.infinity,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
          child: Text(tStr, style: TextStyle(color: colorP, fontSize: 12), textAlign: TextAlign.center),
        ),
      );
    } else if (isTypeDropdown) {
      String currentType = tempU[key]?.toString() ?? 'Walk-in';
      if (!['Walk-in', 'Transfer', 'Priority Load'].contains(currentType)) currentType = 'Walk-in';
      editor = Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentType,
            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 12),
            items: const [
              DropdownMenuItem(value: 'Walk-in', child: Text('Walk-in')),
              DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
              DropdownMenuItem(value: 'Priority Load', child: Text('Priority Load')),
            ],
            onChanged: (v) {
              if (v != null) {
                setDrawerState(() => tempU[key] = v);
              }
            },
          ),
        ),
      );
    } else if (isPriority) {
      editor = Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<bool>(
            value: tempU[key] == true,
            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 12),
            items: const [
              DropdownMenuItem(value: true, child: Text('High Priority')),
              DropdownMenuItem(value: false, child: Text('Normal')),
            ],
            onChanged: (v) {
              if (v != null) {
                setDrawerState(() => tempU[key] = v);
              }
            },
          ),
        ),
      );
    } else if (isStatusDropdown) {
      String currentStatus = tempU[key]?.toString() ?? 'Waiting';
      final statuses = ['Waiting', 'In process', 'Ready', 'Canceled'];
      if (!statuses.contains(currentStatus)) {
        statuses.add(currentStatus);
      }
      editor = Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentStatus,
            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 12),
            items: statuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null) {
                setDrawerState(() => tempU[key] = v);
              }
            },
          ),
        ),
      );
    } else {
      final ctrl = TextEditingController(text: tempU[key]?.toString() ?? '')..selection = TextSelection.collapsed(offset: (tempU[key]?.toString() ?? '').length);
      editor = TextField(
        controller: ctrl,
        style: TextStyle(color: colorP, fontSize: 12),
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))],
        maxLines: isRemarks ? 3 : 1,
        minLines: isRemarks ? 2 : 1,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          fillColor: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
        ),
        onChanged: (v) => tempU[key] = v,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colorL, size: 14),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          editor,
        ],
      ),
    );
  }

  void _showAgentProfile(BuildContext context, String userName, String? avatarStr, String timeStr, bool dark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(50),
      builder: (BuildContext modalContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10))
                ],
                border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF4f46e5),
                    backgroundImage: avatarStr != null && avatarStr.isNotEmpty ? NetworkImage(avatarStr) : null,
                    child: avatarStr == null || avatarStr.isEmpty ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                    ) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF6366f1).withAlpha(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(modalContext),
                      child: Text('Close', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatusBadge(String status, {Map<String, dynamic>? itemData}) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('pending')) {
      bg = const Color(0xFFca8a04).withAlpha(51); fg = const Color(0xFFfef08a);
    } else if (s.contains('in process') || s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('ready')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('canceled')) {
      bg = const Color(0xFF7f1d1d).withAlpha(51); fg = const Color(0xFFfca5a5);
    }

    Widget badgeContainer = Container(
      width: 100,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );

    if (itemData != null && itemData['report-pending'] != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badgeContainer,
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              bool dark = isDarkMode.value;
              final reportField = itemData['report-pending'];
              List<dynamic> reports = [];
              if (reportField is List) {
                reports = reportField;
              } else if (reportField is Map) {
                reports = [reportField];
              }
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFca8a04).withAlpha(51), shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline_rounded, color: Color(0xFFfef08a), size: 24)
                      ),
                      const SizedBox(width: 12),
                      Text(appLanguage.value == 'es' ? 'Detalles de postergación' : 'Pending Context', style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: SizedBox(
                    width: 400,
                    height: reports.length > 2 ? 300 : null,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: reports.map((report) => Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               _buildReportRow(Icons.access_time_rounded, appLanguage.value == 'es' ? 'Hora' : 'Time', report['time'] ?? 'Unknown', dark),
                               const SizedBox(height: 16),
                               _buildReportRow(Icons.person_rounded, appLanguage.value == 'es' ? 'Usuario' : 'User', report['user'] ?? 'Unknown', dark),
                               const SizedBox(height: 16),
                               _buildReportRow(Icons.comment_rounded, appLanguage.value == 'es' ? 'Razón' : 'Reason', report['reason'] ?? 'No reason provided', dark),
                               if (report != reports.last) ...[
                                 const SizedBox(height: 12),
                                 Divider(color: dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                               ]
                             ]
                          )
                        )).toList(),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(appLanguage.value == 'es' ? 'Cerrar' : 'Close', style: TextStyle(color: dark ? const Color(0xFFfcd34d) : const Color(0xFFb45309), fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                )
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode.value ? const Color(0xFFca8a04).withAlpha(40) : const Color(0xFFfef08a).withAlpha(150),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline_rounded, color: isDarkMode.value ? const Color(0xFFfde047) : const Color(0xFFb45309), size: 18),
            ),
          )
        ],
      );
    }

    return badgeContainer;
  }

  Widget _buildReportRow(IconData icon, String label, String value, bool dark) {
    if ((label == 'Time' || label == 'Hora') && value != 'Unknown') {
      try {
        final d = DateTime.parse(value).toLocal();
        value = DateFormat('MMM dd, yyyy - hh:mm a').format(d);
      } catch (_) {}
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: dark ? Colors.white54 : Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: dark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: dark ? Colors.white : Colors.black, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}


