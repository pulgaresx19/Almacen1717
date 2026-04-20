import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage;
import 'delivers_v2_logic.dart';
import 'delivers_v2_dialogs.dart';

class DeliversV2Table extends StatefulWidget {
  final DeliversV2Logic logic;
  final bool dark;

  const DeliversV2Table({super.key, required this.logic, required this.dark});

  @override
  State<DeliversV2Table> createState() => _DeliversV2TableState();
}

class _DeliversV2TableState extends State<DeliversV2Table> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logic.allDelivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_rounded, size: 64, color: widget.dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
            const SizedBox(height: 16),
            Text(appLanguage.value == 'es' ? 'No hay Entregas' : 'No Deliveries', style: TextStyle(color: widget.dark ? Colors.white : const Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(appLanguage.value == 'es' ? 'Aún no hay entregas registradas.' : 'There are no registered deliveries yet.', style: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563))),
          ],
        )
      );
    }

    if (widget.logic.displayedDelivers.isEmpty) {
      return Center(child: Text(appLanguage.value == 'es' ? 'No se encontraron entregas con esa búsqueda.' : 'No deliveries found matching the search.', style: const TextStyle(color: Colors.grey)));
    }

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
                                  columnSpacing: 28,
                                  showCheckboxColumn: false,
                                  headingRowColor: WidgetStateProperty.all(widget.dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                                  dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? (widget.dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6)) : Colors.transparent),
                                  dataTextStyle: TextStyle(color: widget.dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                                  headingTextStyle: TextStyle(color: widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 12),                                  columns: [
                                    const DataColumn(label: Text('#')),
                                    DataColumn(label: Text(appLanguage.value == 'es' ? 'Compañía' : 'Company')),
                                    const DataColumn(label: Text('Driver')),
                                    const DataColumn(label: Text('Door')),
                                    const DataColumn(label: Text('Type')),
                                    const DataColumn(label: Text('ID Pickup')),
                                    const DataColumn(label: Text('Time')),
                                    const DataColumn(label: Text('Priority')),
                                    const DataColumn(label: Text('Pieces')),
                                    const DataColumn(label: Text('Weight')),
                                    const DataColumn(label: Text('Remarks')),
                                    DataColumn(
                                      label: Checkbox(
                                        visualDensity: VisualDensity.compact,
                                        value: widget.logic.selectedDeliverIds.isNotEmpty && widget.logic.displayedDelivers.isNotEmpty && widget.logic.selectedDeliverIds.length == widget.logic.displayedDelivers.length,
                                        onChanged: (val) {
                                          widget.logic.toggleAll(val == true);
                                        },
                                        activeColor: const Color(0xFF6366f1),
                                        side: const BorderSide(color: Color(0xFF94a3b8)),
                                      ),
                                    ),
                                  ],
                                  rows: List.generate(widget.logic.displayedDelivers.length, (index) {
                                    final u = widget.logic.displayedDelivers[index];
                                    final dId = u['id_delivery']?.toString() ?? '';
                                    
                                    String timeStr = '-';
                                    if (u['time'] != null) {
                                      final tdt = DateTime.tryParse(u['time'].toString())?.toLocal();
                                      if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
                                    }

                                    bool isPriority = u['is_priority'] == true;

                                    return DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected == true) {
                                          DeliversV2Dialogs.showDeliverDetails(context, u, widget.dark);
                                        }
                                      },
                                      cells: [
                                        DataCell(Text('${index + 1}')),
                                        DataCell(Text(u['company']?.toString() ?? '-', style: TextStyle(color: widget.dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                                        DataCell(Text(u['driver_name']?.toString() ?? '-')),
                                        DataCell(Text(u['door']?.toString() ?? '-')),
                                        DataCell(Text(u['type']?.toString() ?? '-')),
                                        DataCell(Text(u['id_pickup']?.toString() ?? '-')),
                                        DataCell(Text(timeStr)),
                                        DataCell(isPriority ? const Icon(Icons.star_rounded, color: Colors.orange, size: 20) : const Icon(Icons.star_border_rounded, color: Colors.grey, size: 20)),
                                        DataCell(Text(u['total_pieces']?.toString() ?? '0')),
                                        DataCell(Text(u['total_weight'] != null ? '${u['total_weight']} kg' : '0 kg')),
                                        DataCell(Tooltip(message: u['remarks']?.toString() ?? '', child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(u['remarks']?.toString() ?? '-', overflow: TextOverflow.ellipsis)))),
                                        DataCell(
                                          Checkbox(
                                            visualDensity: VisualDensity.compact,
                                            value: widget.logic.selectedDeliverIds.contains(dId),
                                            onChanged: (val) {
                                              widget.logic.toggleSelection(dId, val == true);
                                            },
                                            activeColor: const Color(0xFF6366f1),
                                            side: const BorderSide(color: Color(0xFF94a3b8)),
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
  }
}
