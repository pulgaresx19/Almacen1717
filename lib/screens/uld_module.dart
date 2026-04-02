import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage, isDarkMode;
import 'add_uld_screen.dart';

class UldModule extends StatefulWidget {
  final bool isActive;
  const UldModule({super.key, this.isActive = true});

  @override
  State<UldModule> createState() => _UldModuleState();
}

class _UldModuleState extends State<UldModule> {
  final _searchController = TextEditingController();
  final GlobalKey<AddUldScreenState> _addUldKey = GlobalKey<AddUldScreenState>();

  @override
  void didUpdateWidget(covariant UldModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_showAddForm && _addUldKey.currentState != null) {
        if (!_addUldKey.currentState!.hasDataSync) {
          setState(() => _showAddForm = false);
        }
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MM/dd/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
  bool _showAddForm = false;
  final Set<String> _selectedReadyUlds = {};
  late Stream<List<Map<String, dynamic>>> _uldsStream;

  @override
  void initState() {
    super.initState();
    _loadUlds();
  }

  void _loadUlds() {
    setState(() {
      _uldsStream = Supabase.instance.client
          .from('ULD')
          .stream(primaryKey: ['id'])
          .order('ULD-number', ascending: true);
    });
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
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (_addUldKey.currentState != null) {
                                final canPop = await _addUldKey.currentState!.handleBackRequest();
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
                          Text(appLanguage.value == 'es' ? 'Añadir Nuevo ULD' : 'Add New ULD', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text(appLanguage.value == 'es' ? 'Contenedores' : 'Unit Load Devices (ULD)', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(appLanguage.value == 'es' ? 'Registra y asigna ULDs individualmente.' : 'Create and assign ULDs individually.', style: TextStyle(color: textS, fontSize: 13))
                    else
                      Text(appLanguage.value == 'es' ? 'Administración de contenedores y pallets de carga.' : 'Administration of Unit Load Devices.', style: TextStyle(color: textS, fontSize: 13)),
              ],
            ),
            const Spacer(),
            
            // Search Box
            if (!_showAddForm)
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
            
            // Add ULD Button
            if (!_showAddForm)
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddForm = true),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(appLanguage.value == 'es' ? 'Añadir ULD' : 'Add ULD', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
            if (!_showAddForm)
              IconButton(
                onPressed: _loadUlds,
                icon: Icon(Icons.refresh_rounded, color: iconColor, size: 18),
                tooltip: appLanguage.value == 'es' ? 'Refrescar' : 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: dark ? Colors.white.withAlpha(25) : const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.all(12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
        
        if (_showAddForm)
          Expanded(
            child: AddUldScreen(
              key: _addUldKey,
              isInline: true,
              onPop: (didAdd) {
                setState(() => _showAddForm = false);
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
                  stream: _uldsStream,
                      builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                  }

                  var ulds = List<Map<String, dynamic>>.from(snapshot.data ?? []);
                  
                  if (_searchController.text.isNotEmpty) {
                    final term = _searchController.text.toLowerCase();
                    ulds = ulds.where((u) => u['ULD-number']?.toString().toLowerCase().contains(term) ?? false).toList();
                  }

                  ulds.sort((a, b) {
                    final bool breakA = a['isBreak'] == true || a['isBreak']?.toString().toLowerCase() == 'true';
                    final bool breakB = b['isBreak'] == true || b['isBreak']?.toString().toLowerCase() == 'true';

                    if (breakA && !breakB) return -1;
                    if (!breakA && breakB) return 1;

                    final uldA = a['ULD-number']?.toString().toUpperCase() ?? '';
                    final uldB = b['ULD-number']?.toString().toUpperCase() ?? '';
                    
                    if (uldA == 'BULK' && uldB != 'BULK') return -1;
                    if (uldB == 'BULK' && uldA != 'BULK') return 1;
                    
                    return uldA.compareTo(uldB);
                  });

                  if (ulds.isEmpty) return const Center(child: Text('No ULDs found.', style: TextStyle(color: Color(0xFF94a3b8))));

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
                          const DataColumn(label: Text('ULD Number')),
                          const DataColumn(label: Text('Ref. Flight')),
                          const DataColumn(label: Text('Pcs')),
                          const DataColumn(label: Text('Weight')),
                          const DataColumn(label: Text('Priority')),
                          const DataColumn(label: Text('Break')),
                          const DataColumn(label: SizedBox(width: 250, child: Text('Remarks'))),
                          const DataColumn(numeric: true, label: SizedBox(width: 100, child: Text('Status', textAlign: TextAlign.center))),
                          DataColumn(
                            numeric: true,
                            label: Builder(
                              builder: (context) {
                                int countReady = ulds.where((x) {
                                  final s = x['status']?.toString().toLowerCase().trim() ?? '';
                                  return s == 'ready' || s == 'saved';
                                }).length;
                                bool allSel = countReady > 0 && _selectedReadyUlds.length == countReady;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_selectedReadyUlds.isNotEmpty) ...[
                                      InkWell(
                                        onTap: () async {
                                          bool? confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(0xFF1E293B),
                                              title: const Text('Delete ULDs', style: TextStyle(color: Colors.white)),
                                              content: Text('Are you sure you want to delete ${_selectedReadyUlds.length} ULD(s)?', style: const TextStyle(color: Colors.white70)),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                )
                                              ],
                                            )
                                          );
                                          if (confirm != true) return;
                                          try {
                                            await Future.wait(_selectedReadyUlds.map((uldNumber) => 
                                              Supabase.instance.client.from('ULD').delete().eq('ULD-number', uldNumber)
                                            ));
                                            if (context.mounted) {
                                              showDialog(
                                                context: context,
                                                barrierColor: Colors.transparent,
                                                builder: (BuildContext ctx) {
                                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                                  });
                                                  return Dialog(
                                                    backgroundColor: Colors.transparent,
                                                    elevation: 0,
                                                    child: Center(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                        decoration: BoxDecoration(color: const Color(0xFF10b981), borderRadius: BorderRadius.circular(12)),
                                                        child: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                                                            SizedBox(width: 12),
                                                            Text('Deleted successfully', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                            setState(() => _selectedReadyUlds.clear());
                                          } catch (e) {
                                            if (context.mounted) {
                                              showDialog(
                                                context: context,
                                                barrierColor: Colors.transparent,
                                                builder: (BuildContext ctx) {
                                                  Future.delayed(const Duration(milliseconds: 2000), () {
                                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                                  });
                                                  return Dialog(
                                                    backgroundColor: Colors.transparent,
                                                    elevation: 0,
                                                    child: Center(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.error_outline, color: Colors.white, size: 28),
                                                            const SizedBox(width: 12),
                                                            Flexible(child: Text('Error: $e', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                          }
                                        },
                                        customBorder: const CircleBorder(),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF6366f1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${_selectedReadyUlds.length}',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1),
                                        ),
                                      ),
                                    ],
                                    Checkbox(
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      value: countReady == 0 ? false : (allSel ? true : (_selectedReadyUlds.isNotEmpty ? null : false)),
                                      tristate: true,
                                      onChanged: countReady == 0 ? null : (val) {
                                        setState(() {
                                          if (allSel) {
                                            _selectedReadyUlds.clear();
                                          } else {
                                            for (var x in ulds) {
                                              final s = x['status']?.toString().toLowerCase().trim() ?? '';
                                              if (s == 'ready' || s == 'saved') {
                                                _selectedReadyUlds.add(x['ULD-number']?.toString() ?? '');
                                              }
                                            }
                                          }
                                        });
                                      }
                                    ),
                                  ],
                                );
                              }
                            )
                          ),
                        ],
                        rows: List.generate(ulds.length, (index) {
                          final u = ulds[index];
                          final status = u['status']?.toString().toLowerCase().trim() ?? '';
                          final isReady = status == 'ready' || status == 'saved';
                          return DataRow(
                            onSelectChanged: (_) => _showUldDrawer(context, u, dark),
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(u['ULD-number']?.toString() ?? '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                              DataCell(Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u['refCarrier'] == null ? 'Standalone ULD' : '${u['refCarrier']} ${u['refNumber'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    u['refCarrier'] == null && u['created_at'] != null ? _formatDate(u['created_at'].toString()) : _formatDate(u['refDate']?.toString()),
                                    style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11),
                                  ),
                                ],
                              )),
                              DataCell(Text(u['pieces']?.toString() ?? '0')),
                              DataCell(Text('${u['weight']?.toString() ?? '0'} kg')),
                              DataCell(u['isPriority'] == true ? const Icon(Icons.star_rounded, color: Colors.orange, size: 20) : const Icon(Icons.star_border_rounded, color: Colors.grey, size: 20)),
                              DataCell(Text(u['isBreak'] == true ? 'BREAK' : 'NO BREAK', style: TextStyle(color: u['isBreak'] == true ? const Color(0xFF10b981) : const Color(0xFFef4444), fontWeight: FontWeight.bold))),
                              DataCell(SizedBox(
                                width: 250,
                                child: Text(u['remarks']?.toString() ?? '-', overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(_buildStatusBadge(u['status']?.toString() ?? 'Received')),
                              DataCell(
                                isReady 
                                ? Checkbox(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    value: _selectedReadyUlds.contains(u['ULD-number']?.toString()),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedReadyUlds.add(u['ULD-number']?.toString() ?? '');
                                        } else {
                                          _selectedReadyUlds.remove(u['ULD-number']?.toString());
                                        }
                                      });
                                    },
                                  )
                                : const SizedBox.shrink(),
                              ),
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

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    switch (status.toLowerCase()) {
      case 'waiting':
        bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
        break;
      case 'received':
        bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
        break;
      case 'checked':
        bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
        break;
      case 'ready':
        bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
        break;
      case 'pending':
        bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
        break;
      default:
        bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
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

  void _showUldDrawer(BuildContext context, Map<String, dynamic> u, bool dark) {
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

        List dataUld = [];
        if (u['data-ULD'] is List) dataUld = u['data-ULD'];

        Set<String> editingKeys = {};
        Map<String, dynamic> tempValues = {};

        return StatefulBuilder(
          builder: (ctxModal, setModalState) {

            Widget buildEditable(String label, String key, {bool isBool = false, String trueText = '', String falseText = '', bool isNum = false, List<String>? options}) {
               dynamic val = u[key];
               final bool isEditing = editingKeys.contains(key);

               if (!isEditing) {
                  String displayStr = '';
                  Color valColor = textP;

                  if (isBool) {
                     displayStr = val == true ? trueText : falseText;
                     if (key == 'isBreak') {
                        valColor = val == true ? const Color(0xFF10b981) : const Color(0xFFef4444);
                     } else if (key == 'isPriority') {
                        valColor = val == true ? Colors.redAccent : textP;
                     }
                  } else {
                     displayStr = '${val ?? '0'}';
                     if (key == 'weight') displayStr += ' kg';
                  }

                  return Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                 Text(label, style: TextStyle(color: textS, fontSize: 11)),
                                 InkWell(
                                    onTap: () => setModalState(() {
                                       editingKeys.add(key);
                                       tempValues[key] = val;
                                    }),
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.edit_rounded, color: Color(0xFF94a3b8), size: 12),
                                    ),
                                 )
                              ],
                           ),
                           const SizedBox(height: 6),
                           Text(displayStr, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ]
                     )
                  );
               }

               final inputBorderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
               Widget editor;
               final ctrl = TextEditingController(text: val?.toString() ?? '')..selection = TextSelection.collapsed(offset: (val?.toString() ?? '').length);

               if (isBool) {
                  editor = Container(
                     height: 32,
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(horizontal: 8),
                     decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
                     child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                           value: val == true,
                           dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
                           isExpanded: true,
                           style: TextStyle(color: textP, fontSize: 12),
                           items: [
                              DropdownMenuItem(value: true, child: Text(trueText)),
                              DropdownMenuItem(value: false, child: Text(falseText)),
                           ],
                           onChanged: (v) async {
                              if (v != null) {
                                  try {
                                     await Supabase.instance.client.from('ULD').update({key: v}).eq('id', u['id']);
                                     setModalState(() {
                                        u[key] = v;
                                        editingKeys.remove(key);
                                     });
                                     if (mounted) setState(() {});
                                  } catch (e) {
                                     debugPrint('Error updating bool $key: $e');
                                  }
                              }
                           },
                        ),
                     ),
                  );
               } else if (options != null) {
                  editor = Container(
                     height: 32,
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(horizontal: 8),
                     decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
                     child: DropdownButtonHideUnderline(
                        child: Builder(
                           builder: (context) {
                              final currentVal = tempValues[key]?.toString() ?? val?.toString() ?? options.first;
                              final safeOptions = options.contains(currentVal) ? options : [...options, currentVal];
                              return DropdownButton<String>(
                                 value: currentVal,
                                 dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                 isExpanded: true,
                                 style: TextStyle(color: textP, fontSize: 12),
                                 items: safeOptions.map((String o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                 onChanged: (v) {
                                    if (v != null) {
                                       setModalState(() {
                                          tempValues[key] = v;
                                       });
                                    }
                                 },
                              );
                           }
                        ),
                     ),
                  );
               } else {
                  editor = SizedBox(
                     height: 32,
                     child: TextField(
                        controller: ctrl,
                        keyboardType: isNum ? TextInputType.number : TextInputType.text,
                        style: TextStyle(color: textP, fontSize: 12),
                        decoration: InputDecoration(
                           contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                           fillColor: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                           filled: true,
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
                           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
                        ),
                     ),
                  );
               }

               return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(label, style: TextStyle(color: textS, fontSize: 11)),
                        const SizedBox(height: 8),
                        editor,
                        if (!isBool) ...[
                           const SizedBox(height: 8),
                           Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                 InkWell(
                                    onTap: () => setModalState(() => editingKeys.remove(key)),
                                    child: Container(
                                       padding: const EdgeInsets.all(4),
                                       decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                                       child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                                    )
                                 ),
                                 const SizedBox(width: 8),
                                 InkWell(
                                    onTap: () async {
                                       try {
                                          dynamic parsedVal;
                                          if (options != null) {
                                             parsedVal = tempValues[key] ?? val;
                                          } else {
                                             parsedVal = ctrl.text;
                                             if (isNum) parsedVal = int.tryParse(ctrl.text) ?? 0;
                                          }
                                          await Supabase.instance.client.from('ULD').update({key: parsedVal}).eq('id', u['id']);
                                          setModalState(() {
                                             u[key] = parsedVal;
                                             editingKeys.remove(key);
                                          });
                                          if (mounted) setState(() {});
                                       } catch (e) {
                                          debugPrint('Error: $e');
                                       }
                                    },
                                    child: Container(
                                       padding: const EdgeInsets.all(4),
                                       decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(20), borderRadius: BorderRadius.circular(6)),
                                       child: const Icon(Icons.check_rounded, color: Color(0xFF6366f1), size: 16),
                                    )
                                 ),
                              ]
                           )
                        ]
                     ]
                  )
               );
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
                                 Text('ULD Details', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                                 const SizedBox(height: 4),
                                 Row(
                                   children: [
                                     Icon(Icons.inventory_2_rounded, color: textP, size: 24),
                                     const SizedBox(width: 8),
                                     Text('${u['ULD-number'] ?? '-'}', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                                   ]
                                 )
                               ],
                             ),
                             Row(
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: textP)),
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
                                         children: [
                                            Icon(Icons.flight_takeoff, size: 16, color: textP),
                                            const SizedBox(width: 8),
                                            Text('Flight Information', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                         ]
                                       ),
                                       const SizedBox(height: 12),
                                       Row(children: [
                                         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                           Text('Ref. Flight', style: TextStyle(color: textS, fontSize: 12)),
                                           Text(u['refCarrier'] == null ? 'Standalone ULD' : '${u['refCarrier']} ${u['refNumber'] ?? ''}', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                         ])),
                                         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                           Text('Date', style: TextStyle(color: textS, fontSize: 12)),
                                           Text(u['refCarrier'] == null ? (u['created_at'] != null ? _formatDate(u['created_at'].toString()) : '-') : _formatDate(u['refDate']?.toString()), style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                         ])),
                                       ]),
                                       const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                       Row(children: [
                                         Expanded(child: buildEditable('Pieces', 'pieces', isNum: true)),
                                         Expanded(child: buildEditable('Weight', 'weight', isNum: true)),
                                       ]),
                                       const SizedBox(height: 12),
                                       Row(children: [
                                         Expanded(child: buildEditable('Type', 'isBreak', isBool: true, trueText: 'BREAK', falseText: 'NO BREAK')),
                                         Expanded(child: buildEditable('Priority', 'isPriority', isBool: true, trueText: 'Priority', falseText: 'Normal')),
                                       ]),
                                       const SizedBox(height: 12),
                                       Row(children: [
                                         Expanded(flex: 2, child: buildEditable('Status', 'status', options: (u['isBreak'] == true || u['isBreak']?.toString().toLowerCase() == 'true') ? ['Waiting', 'Received', 'Checked', 'Ready'] : ['Waiting', 'Received', 'Delivered'])),
                                         const SizedBox(width: 12),
                                         Expanded(flex: 3, child: buildEditable('Remarks', 'remarks')),
                                       ])
                                    ]
                                  )
                                ),

                                if (dataUld.isNotEmpty) ...[
                                   const SizedBox(height: 24),
                                   Text('Assigned AWBs', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                                   const SizedBox(height: 12),
                                   ...dataUld.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final awb = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
                                        child: Row(
                                          children: [
                                             Container(
                                               width: 20, height: 20,
                                               alignment: Alignment.center,
                                               decoration: const BoxDecoration(color: Color(0x326366f1), shape: BoxShape.circle),
                                               child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                                             ),
                                             const SizedBox(width: 8),
                                             const Icon(Icons.description_rounded, color: Color(0xFF6366f1), size: 14),
                                             const SizedBox(width: 8),
                                             Expanded(
                                               child: Row(
                                                  children: [
                                                     SizedBox(width: 120, child: Text(awb['awb_number']?.toString() ?? '', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w500))),
                                                     const SizedBox(width: 8),
                                                     Expanded(child: Text('Pieces: ${awb['pieces'] ?? 0}', style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                     Expanded(child: Text('Weight: ${awb['weight'] ?? 0} kg', style: TextStyle(color: textS, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                  ],
                                               )
                                             ),
                                             InkWell(
                                               onTap: () {
                                                 showDialog(
                                                   context: ctxModal,
                                                   builder: (ctxD) => AlertDialog(
                                                     backgroundColor: bg,
                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                     title: Text('AWB Information', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                                     content: Builder(
                                                       builder: (ctx) {
                                                         Widget buildInfoCard(String title, String value, IconData icon) {
                                                           return Container(
                                                             padding: const EdgeInsets.all(12),
                                                             decoration: BoxDecoration(
                                                               color: dark ? Colors.white.withAlpha(10) : Colors.white,
                                                               borderRadius: BorderRadius.circular(8),
                                                               border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                                                             ),
                                                             child: Row(
                                                               children: [
                                                                 Icon(icon, size: 16, color: textS),
                                                                 const SizedBox(width: 8),
                                                                 Expanded(
                                                                   child: Column(
                                                                     crossAxisAlignment: CrossAxisAlignment.start,
                                                                     children: [
                                                                       Text(title, style: TextStyle(color: textS, fontSize: 11)),
                                                                       Text(value, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                                                     ]
                                                                   )
                                                                 ),
                                                               ]
                                                             )
                                                           );
                                                         }

                                                         final String remarks = awb['remarks']?.toString() ?? '';
                                                         
                                                         List<String> finalHawbs = [];
                                                         final hRaw = awb['house_number'] ?? awb['house'];
                                                         if (hRaw != null) {
                                                            if (hRaw is List) {
                                                              finalHawbs = hRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
                                                            } else if (hRaw is String) {
                                                              finalHawbs = hRaw.toString().split(RegExp(r'[,\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                                            }
                                                         }

                                                         return SizedBox(
                                                           width: 450,
                                                           child: SingleChildScrollView(
                                                             child: Column(
                                                               mainAxisSize: MainAxisSize.min,
                                                               crossAxisAlignment: CrossAxisAlignment.start,
                                                               children: [
                                                                 Container(
                                                                   padding: const EdgeInsets.all(12),
                                                                   decoration: BoxDecoration(
                                                                     color: dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
                                                                     borderRadius: BorderRadius.circular(10),
                                                                     border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                                                   ),
                                                                   child: Row(
                                                                     children: [
                                                                       const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF6366f1), size: 20),
                                                                       const SizedBox(width: 12),
                                                                       Column(
                                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                                         children: [
                                                                           Text('AWB Number', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.w600)),
                                                                           Text(awb['awb_number']?.toString() ?? '-', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                         ]
                                                                       ),
                                                                     ]
                                                                   )
                                                                 ),
                                                                 const SizedBox(height: 16),
                                                                 Row(
                                                                   children: [
                                                                      Expanded(child: buildInfoCard('Pieces', '${awb['pieces'] ?? 0}', Icons.extension_outlined)),
                                                                      const SizedBox(width: 12),
                                                                      Expanded(child: buildInfoCard('Total Pcs', '${awb['total'] ?? 0}', Icons.all_inbox_outlined)),
                                                                      const SizedBox(width: 12),
                                                                      Expanded(child: buildInfoCard('Weight', '${awb['weight'] ?? 0} kg', Icons.scale_outlined)),
                                                                   ]
                                                                 ),
                                                                 if (finalHawbs.isNotEmpty) ...[
                                                                   const SizedBox(height: 20),
                                                                   Text('House AWBs (HAWBs)', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                                                   const SizedBox(height: 8),
                                                                   Container(
                                                                     padding: const EdgeInsets.all(12),
                                                                     decoration: BoxDecoration(color: dark ? Colors.black.withAlpha(30) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))),
                                                                     child: Column(
                                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                                       children: finalHawbs.map((h) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.layers_outlined, size: 14, color: textS), const SizedBox(width: 8), Expanded(child: SelectableText(h, style: TextStyle(color: textP, fontSize: 13)))]))).toList(),
                                                                     ),
                                                                   ),
                                                                 ],
                                                                 if (remarks.trim().isNotEmpty) ...[
                                                                   const SizedBox(height: 20),
                                                                   Text('Remarks', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                                                                   const SizedBox(height: 8),
                                                                   Container(
                                                                     padding: const EdgeInsets.all(12),
                                                                     decoration: BoxDecoration(color: dark ? const Color(0xFFfef3c7).withAlpha(20) : const Color(0xFFfef3c7).withAlpha(120), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFf59e0b).withAlpha(50))),
                                                                     child: Row(
                                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                                       children: [
                                                                         const Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFf59e0b)),
                                                                         const SizedBox(width: 8),
                                                                         Expanded(child: SelectableText(remarks, style: TextStyle(color: textP, fontSize: 13))),
                                                                       ]
                                                                     )
                                                                   ),
                                                                 ],
                                                               ]
                                                             ),
                                                           ),
                                                         );
                                                       }
                                                     ),
                                                     actions: [
                                                       TextButton(
                                                         onPressed: () => Navigator.pop(ctxD),
                                                         child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
                                                       )
                                                     ]
                                                   )
                                                 );
                                               },
                                               child: Padding(
                                                 padding: const EdgeInsets.all(4.0),
                                                 child: Icon(Icons.info_outline_rounded, color: textS, size: 18),
                                               )
                                             ),
                                          ]
                                        )
                                      );
                                   }),
                                ],

                                if ((u['data-received'] != null && (u['data-received'] as Map).isNotEmpty) || 
                                    (u['data-checked'] != null && (u['data-checked'] as Map).isNotEmpty) || 
                                    (u['data-saved'] != null && (u['data-saved'] as Map).isNotEmpty) || 
                                    (u['data-delivery'] != null && (u['data-delivery'] as Map).isNotEmpty)) ...[
                                   const SizedBox(height: 24),
                                   Text('Audit Trail', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                                   const SizedBox(height: 12),
                                   _buildAuditItem('Received', u['data-received'], textP, textS, bgCard, borderC),
                                   _buildAuditItem('Checked', u['data-checked'], textP, textS, bgCard, borderC),
                                   _buildAuditItem('Saved', u['data-saved'], textP, textS, bgCard, borderC),
                                   _buildAuditItem('Delivered', u['data-delivery'], textP, textS, bgCard, borderC),
                                ],
                             ]
                           )
                         )
                       )
                    ]
                  )
                )
              )
            );
          }
        );
      },
      transitionBuilder: (context, a1, a2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: a1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Widget _buildAuditItem(String title, dynamic data, Color textP, Color textS, Color bgCard, Color borderC) {
    if (data == null || data is! Map || data.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderC)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Icon(
                 title == 'Received' ? Icons.download_done : 
                 title == 'Checked' ? Icons.fact_check_outlined : 
                 title == 'Saved' ? Icons.save_outlined : 
                 Icons.local_shipping_outlined, 
                 size: 16, color: const Color(0xFF10b981)
               ),
               const SizedBox(width: 8),
               Text(title, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
             ]
           ),
           const SizedBox(height: 8),
           Row(
             children: [
               Icon(Icons.person_outline, size: 14, color: textS),
               const SizedBox(width: 6),
               Text(data['user']?.toString() ?? 'System', style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 13)),
               const Spacer(),
               Icon(Icons.access_time, size: 14, color: textS),
               const SizedBox(width: 6),
               Text(data['time'] != null ? DateFormat('hh:mm a • MM/dd/yyyy').format(DateTime.parse(data['time']).toLocal()) : '-', style: TextStyle(color: textS, fontSize: 12)),
             ]
           )
        ]
      )
    );
  }
}
