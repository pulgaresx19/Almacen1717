import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;

import 'flights_v2_status_logic.dart';
import 'flights_v2_service.dart';
import 'flights_v2_drawer_uld_details.dart';
import 'flights_v2_uld_print_preview.dart';

class FlightsV2UldList extends StatefulWidget {
  final List<Map<String, dynamic>> ulds;
  final Map<String, dynamic> flight;
  final bool isLoading;
  final bool dark;
  final VoidCallback? onRefresh;

  const FlightsV2UldList({
    super.key,
    required this.ulds,
    required this.flight,
    required this.isLoading,
    required this.dark,
    this.onRefresh,
  });

  @override
  State<FlightsV2UldList> createState() => _FlightsV2UldListState();
}

class _FlightsV2UldListState extends State<FlightsV2UldList> {
  final Set<String> _selectedUlds = {};

  void _openUldDrawer(Map<String, dynamic> uld) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withAlpha(150),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: FlightsV2UldDetailsDrawer(
              uld: uld,
              flight: widget.flight,
              dark: widget.dark,
              ulds: widget.ulds,
              onRefresh: widget.onRefresh,
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, Color textP, Color textS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildStatusMetric(String label, String value, Color textS) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = value.toLowerCase();
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('process') || s.contains('progress')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('checked')) {
      bg = const Color(0xFF0284c7).withAlpha(51); fg = const Color(0xFF7dd3fc);
    } else if (s.contains('received')) {
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
    } else if (s.contains('ready') || s.contains('saved') || s.contains('delivered') || s.contains('stored')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('pending')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 10)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUldCard(int index, Map<String, dynamic> uld, Color textP, Color textS, Color bgCard) {
    final uldId = uld['id_uld']?.toString() ?? '';
    final isSelected = _selectedUlds.contains(uldId);
    final borderColor = isSelected 
        ? const Color(0xFF6366f1) 
        : (widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB));
    final bgColor = isSelected ? const Color(0xFF6366f1).withAlpha(20) : bgCard;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              InkWell(
                onTap: () => _openUldDrawer(uld),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 135,
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                shape: BoxShape.circle,
                                border: Border.all(color: widget.dark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(15)),
                              ),
                              alignment: Alignment.center,
                              child: Text('${index + 1}', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(uld['uld_number']?.toString() ?? '', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Pcs' : 'Pieces', uld['pieces_total']?.toString() ?? uld['pieces']?.toString() ?? '0', textP, textS))),
                      Expanded(child: Center(child: _buildMetric(appLanguage.value == 'es' ? 'Wgt' : 'Weight', '${uld['weight_total']?.toString() ?? uld['weight']?.toString() ?? '0'} kg', textP, textS))),
                      Expanded(child: Center(child: _buildMetric('Priority', uld['is_priority'] == true ? 'Yes' : 'No', uld['is_priority'] == true ? const Color(0xFFeab308) : textP, textS))),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Break', style: TextStyle(color: textS, fontSize: 10)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (uld['is_break'] == true) ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: (uld['is_break'] == true) ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50)),
                                ),
                                child: Text(
                                  (uld['is_break'] == true) ? 'BREAK' : 'NO BRK',
                                  style: TextStyle(
                                    color: (uld['is_break'] == true) ? Colors.green : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: Center(child: _buildMetric('Remarks', (uld['remarks']?.toString().trim().isNotEmpty == true && uld['remarks']?.toString().trim().toLowerCase() != 'null') ? uld['remarks'].toString() : '-', textP, textS))),
                      Expanded(child: Center(child: _buildStatusMetric('Status', FlightsV2StatusLogic.getUldStatus(uld), textS))),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF6366f1),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUlds.add(uldId);
                            } else {
                              _selectedUlds.remove(uldId);
                            }
                          });
                        },
                      ),

                ],
              ),
            ),
          ),
        ],
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Row(
          children: [
            if (FlightsV2StatusLogic.getUldStatus(uld).toLowerCase().contains('waiting'))
              InkWell(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                      title: Text(appLanguage.value == 'es' ? 'Eliminar ULD' : 'Delete ULD', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                      content: Text(
                        appLanguage.value == 'es' 
                            ? '¿Estás seguro de que deseas eliminar este ULD y todas sus guías asociadas? Esta acción no se puede deshacer.'
                            : 'Are you sure you want to delete this ULD and all its associated AWBs? This action cannot be undone.',
                        style: TextStyle(color: textS),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Color(0xFF94a3b8))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(appLanguage.value == 'es' ? 'Eliminar' : 'Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!mounted) return;
                    
                    showDialog(
                      context: context, 
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    
                    try {
                      await FlightsV2Service().deleteUld(uldId);
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Close loading
                      if (widget.onRefresh != null) widget.onRefresh!();
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                    }
                  }
                },
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.dark ? Colors.redAccent.withAlpha(40) : Colors.redAccent.withAlpha(20),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.delete_outline_rounded, color: widget.dark ? const Color(0xFFfca5a5) : Colors.red, size: 13),
                ),
              ),
          ],
        ),
      ),
    ],
  ),
);
}

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6);

    final sortedUlds = List<Map<String, dynamic>>.from(widget.ulds);
    sortedUlds.sort((a, b) {
      final aBreak = a['is_break'] == true;
      final bBreak = b['is_break'] == true;
      if (aBreak && !bBreak) return -1;
      if (!aBreak && bBreak) return 1;

      final aUldNum = (a['uld_number']?.toString() ?? '').toLowerCase();
      final bUldNum = (b['uld_number']?.toString() ?? '').toLowerCase();
      
      final aIsBulk = aUldNum == 'bulk';
      final bIsBulk = bUldNum == 'bulk';
      if (aIsBulk && !bIsBulk) return -1;
      if (!aIsBulk && bIsBulk) return 1;

      return aUldNum.compareTo(bUldNum);
    });

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : sortedUlds.isEmpty
                      ? Center(
                          child: Text(
                            appLanguage.value == 'es' ? 'No se encontraron ULDs.' : 'No ULDs found.',
                            style: TextStyle(color: textS),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100), // Space for floating bar
                            itemCount: sortedUlds.length,
                            itemBuilder: (context, index) {
                              return _buildUldCard(index, sortedUlds[index], textP, textS, bgCard);
                            },
                          ),
                        ),
            ),
          ],
        ),
        if (_selectedUlds.isNotEmpty)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: widget.dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedUlds.length} Selected',
                        style: const TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        final selectedData = sortedUlds.where((u) => _selectedUlds.contains(u['id_uld']?.toString())).toList();
                        showUldPrintPreviewDialog(context, widget.flight, selectedData, widget.dark);
                      },
                      icon: const Icon(Icons.print_rounded, size: 20),
                      color: const Color(0xFF818cf8),
                      tooltip: appLanguage.value == 'es' ? 'Previsualizar / Imprimir' : 'Preview / Print',
                    ),
                    Container(width: 1, height: 24, color: widget.dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), margin: const EdgeInsets.symmetric(horizontal: 4)),
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
                            title: Text(appLanguage.value == 'es' ? 'Eliminar Múltiples ULDs' : 'Delete Multiple ULDs', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                            content: Text(
                              appLanguage.value == 'es' 
                                  ? '¿Estás seguro de que deseas eliminar los ${_selectedUlds.length} ULDs seleccionados y sus guías?'
                                  : 'Are you sure you want to delete the ${_selectedUlds.length} selected ULDs and their AWBs?',
                              style: TextStyle(color: textS),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(appLanguage.value == 'es' ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Color(0xFF94a3b8))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(appLanguage.value == 'es' ? 'Eliminar' : 'Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          if (!context.mounted) return;
                          
                          showDialog(
                            context: context, 
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );
                          
                          try {
                            for (var id in _selectedUlds) {
                               await FlightsV2Service().deleteUld(id);
                            }
                            if (!context.mounted) return;
                            Navigator.of(context).pop(); // Close loading
                            setState(() {
                              _selectedUlds.clear();
                            });
                            if (widget.onRefresh != null) widget.onRefresh!();
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.of(context).pop(); // Close loading
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.redAccent,
                      tooltip: 'Delete Selected',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
