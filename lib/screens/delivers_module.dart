import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;
import 'add_deliver_screen.dart';

class DeliversModule extends StatefulWidget {
  final bool isActive;
  const DeliversModule({super.key, this.isActive = true});

  @override
  State<DeliversModule> createState() => _DeliversModuleState();
}

class _DeliversModuleState extends State<DeliversModule> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddDeliverScreenState> _addDeliverKey = GlobalKey<AddDeliverScreenState>();
  late Stream<List<Map<String, dynamic>>> _deliversStream;

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
                      Text('Delivers', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
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
                
                if (!_showAddForm)
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
                        final term = _searchController.text.toLowerCase();
                        items = items.where((u) {
                           final comp = (u['truck-company']?.toString() ?? '').toLowerCase();
                           final dr = (u['driver']?.toString() ?? '').toLowerCase();
                           final dr2 = (u['door']?.toString() ?? '').toLowerCase();
                           final pId = (u['id-pickup']?.toString() ?? '').toLowerCase();
                           return comp.contains(term) || dr.contains(term) || dr2.contains(term) || pId.contains(term);
                        }).toList();
                      }

                      if (items.isEmpty) return Center(child: Text(appLanguage.value == 'es' ? 'No se encontraron registros.' : 'No records found.', style: const TextStyle(color: Color(0xFF94a3b8))));

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
                                  columns: [
                                    const DataColumn(label: Text('#')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Compañía' : 'Truck Co.')),
                                    const DataColumn(label: Text('Driver')),
                                    const DataColumn(label: Text('Door')),
                                    const DataColumn(label: Text('Type')),
                                    const DataColumn(label: Text('ID Pickup')),
                                    const DataColumn(label: Text('Time')),
                                    const DataColumn(label: Text('Priority')),
                                    const DataColumn(label: Text('Remarks')),
                                    const DataColumn(label: Text('AWBs')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
                                  ],
                                  rows: List.generate(items.length, (index) {
                                    final u = items[index];
                                    

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
                                        DataCell(Tooltip(message: u['remarks']?.toString() ?? '', child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(u['remarks']?.toString() ?? '-', overflow: TextOverflow.ellipsis)))),
                                        DataCell(Text(awbsStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366f1)))),
                                        DataCell(_buildStatusBadge(u['status']?.toString() ?? 'Waiting')),
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

  void _showDeliverDetails(BuildContext context, Map<String, dynamic> u, bool dark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        bool isEditing = false;
        final Map<String, dynamic> tempU = Map.from(u);
        return StatefulBuilder(
          builder: (context, setDrawerState) {
            final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
            final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        List<dynamic> awbs = [];
        if (u['list-pickup'] != null && u['list-pickup'] is List) {
          awbs = u['list-pickup'] as List;
        } else if (u['list-pickup'] != null && u['list-pickup'].toString().isNotEmpty) {
          awbs = [u['list-pickup'].toString()];
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
                            _buildStatusBadge(u['status']?.toString() ?? 'Waiting'),
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
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildDeliverEditableCard(context, 'Type', 'type', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.local_shipping_outlined, isTypeDropdown: true)),
                                      Expanded(child: _buildDeliverEditableCard(context, 'Door', 'door', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.door_front_door_outlined)),
                                      Expanded(child: _buildDeliverEditableCard(context, 'Priority', 'isPriority', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.star_outline, isPriority: true)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 1, child: _buildDeliverEditableCard(context, 'Time', 'time-deliver', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.access_time_rounded, isTime: true)),
                                      const SizedBox(width: 16),
                                      Expanded(flex: 2, child: _buildDeliverEditableCard(context, 'Remarks', 'remarks', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.notes, isRemarks: true)),
                                    ],
                                  ),
                               ]
                             )
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Row(
                            children: [
                              Text('List of AWBs', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                                child: Text('${awbs.length}', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (awbs.isEmpty)
                            Text('No AWBs assigned.', style: TextStyle(color: textS))
                          else
                            ...awbs.map((awb) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: textS, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(awb.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 14))),
                                ],
                              ),
                            )),
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
    {IconData? icon, bool isTime = false, bool isRemarks = false, bool isPriority = false, bool isTypeDropdown = false}
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

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting') || s.contains('espera')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('pending') || s.contains('pendiente')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (s.contains('completed') || s.contains('completado') || s.contains('ready') || s.contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('received') || s.contains('recibido') || s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('checked')){
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
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
        status.toUpperCase(), 
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}


