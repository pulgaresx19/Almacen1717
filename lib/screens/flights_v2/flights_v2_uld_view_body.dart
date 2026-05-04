import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'package:intl/intl.dart';
import 'flights_v2_status_logic.dart';

class FlightsV2UldViewBody extends StatefulWidget {
  final Map<String, dynamic> uld;
  final bool dark;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onClose;

  const FlightsV2UldViewBody({
    super.key,
    required this.uld,
    required this.dark,
    required this.onEdit,
    required this.onPrint,
    required this.onClose,
  });

  @override
  State<FlightsV2UldViewBody> createState() => _FlightsV2UldViewBodyState();
}

class _FlightsV2UldViewBodyState extends State<FlightsV2UldViewBody> {
  final Set<int> _expandedItems = {};

  void _showHouseList(BuildContext context, String awb, List<String> houses) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          title: Text('House Numbers - $awb', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 16)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
            child: SizedBox(
              width: 350,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: houses.length,
                itemBuilder: (c, i) => ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                    child: Text('${i + 1}', style: TextStyle(fontSize: 10, color: widget.dark ? Colors.white : Colors.black)),
                  ),
                  title: Text(houses[i], style: TextStyle(color: widget.dark ? Colors.white : Colors.black)),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: TextStyle(color: widget.dark ? Colors.white70 : Colors.black87)),
            ),
          ],
        );
      },
    );
  }


  String _formatLogTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty || timeStr.toLowerCase() == 'null') return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return DateFormat('MM/dd/yy hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  Widget _buildTraceStep(String title, IconData icon, String? user, String? time, Color accentColor, Color textP, Color textS) {
    final t = _formatLogTime(time);
    if (t.isEmpty) return const SizedBox.shrink();

    final u = (user == null || user.trim().isEmpty || user.toLowerCase() == 'null') ? 'System' : user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withAlpha(50)),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        u,
                        style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      t,
                      style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCoordinatorLog(Map<String, dynamic> split, Color textP, Color textS) {
    final dc = split['data_coordinator'] as Map<String, dynamic>?;
    
    if (dc == null || dc.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Coordinator', style: TextStyle(color: textS, fontSize: 11)),
          const SizedBox(height: 4),
          Text(split['user_checked']?.toString().trim().isNotEmpty == true ? split['user_checked'].toString() : 'Pending', style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
          if (split['time_checked']?.toString().trim().isNotEmpty == true)
            Text(_formatLogTime(split['time_checked'].toString()), style: TextStyle(color: textS, fontSize: 11)),
        ],
      );
    }

    final user = dc['processed_by']?.toString() ?? split['user_checked']?.toString() ?? 'Unknown';
    final time = dc['processed_at']?.toString() ?? split['time_checked']?.toString() ?? '';
    final dType = dc['discrepancy_type']?.toString();
    final dAmount = dc['discrepancy_amount']?.toString();
    
    // Check various possible keys
    final locReq = dc['Location requerida']?.toString() ?? dc['location_required']?.toString() ?? dc['location requerida']?.toString();
    final newAmt = dc['new_amount']?.toString();
    final remarks = dc['Remarks']?.toString() ?? dc['remarks']?.toString();

    List<Widget> items = [];
    dc.forEach((key, value) {
      final keyLower = key.toLowerCase();
      if (keyLower != 'processed_at' && 
          keyLower != 'processed_by' && 
          !keyLower.startsWith('discrepancy_') && 
          keyLower != 'location_required' && 
          keyLower != 'location requerida' && 
          keyLower != 'new_amount' &&
          keyLower != 'remarks') {
        int val = int.tryParse(value.toString()) ?? 0;
        if (val > 0) {
          items.add(Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text('• $key: $val', style: TextStyle(color: textP, fontSize: 12)),
          ));
        }
      }
    });

    List<Widget> tags = [];
    
    // Discrepancy Tag
    if (dType != null && dType.trim().isNotEmpty && dType != 'NONE') {
      tags.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.redAccent.withAlpha(50)),
        ),
        child: Text(
          '$dAmount $dType',
          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ));
    }

    // Not Found Tag
    if (split['not_found'] == true) {
      tags.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF991b1b).withAlpha(20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF991b1b).withAlpha(50)),
        ),
        child: const Text(
          'NOT FOUND',
          style: TextStyle(color: Color(0xFF991b1b), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ));
    }

    // Location Required Tag
    if (locReq != null && locReq.trim().isNotEmpty) {
      tags.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blueAccent.withAlpha(50)),
        ),
        child: Text(
          locReq,
          style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ));
    }

    // New Amount Tag
    if (newAmt != null && newAmt.trim().isNotEmpty && newAmt != '0') {
      tags.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.withAlpha(50)),
        ),
        child: Text(
          'NEW: $newAmt',
          style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ));
    }

    // Remarks Tag
    if (remarks != null && remarks.trim().isNotEmpty) {
      tags.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.orange, size: 10),
            const SizedBox(width: 4),
            Text(
              remarks,
              style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Coordinator', style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        Text(user, style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
        if (time.isNotEmpty)
          Text(_formatLogTime(time), style: TextStyle(color: textS, fontSize: 11)),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...items,
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags,
          ),
        ]
      ],
    );
  }

  Widget _buildDataLocationLog(Map<String, dynamic> split, Color textP, Color textS) {
    final locs = split['data_location'] ?? split['locations'];
    List<Widget> locationItems = [];
    
    if (locs is List) {
      for (var item in locs) {
        if (item is Map) {
          final loc = item['location']?.toString() ?? 'Unknown';
          final user = item['updated_by']?.toString() ?? 'System';
          final time = _formatLogTime(item['updated_at']?.toString());
          
          locationItems.add(Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                  ),
                  child: Text(loc, style: TextStyle(color: textP, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                if (user.isNotEmpty || time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('$user • $time', style: TextStyle(color: textS, fontSize: 10)),
                ]
              ],
            ),
          ));
        } else {
          locationItems.add(Text('• ${item.toString()}', style: TextStyle(color: textP, fontSize: 11)));
        }
      }
    } else if (locs != null && locs.toString().trim().isNotEmpty) {
      final locList = locs.toString().split(RegExp(r'[,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (var loc in locList) {
        locationItems.add(Text('• $loc', style: TextStyle(color: textP, fontSize: 11)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Location', style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        if (split['user_saved']?.toString().trim().isNotEmpty == true) ...[
          Text(split['user_saved'].toString(), style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
          if (split['time_saved']?.toString().trim().isNotEmpty == true)
            Text(_formatLogTime(split['time_saved'].toString()), style: TextStyle(color: textS, fontSize: 11)),
        ] else if (locationItems.isEmpty) ...[
          Text('Pending', style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
        if (locationItems.isNotEmpty) ...[
          if (split['user_saved']?.toString().trim().isNotEmpty == true)
            const SizedBox(height: 8),
          ...locationItems,
        ],
      ],
    );
  }

  Widget _buildMetric(String label, String value, Color textP, Color textS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(color: textS, fontSize: 11)),
          const SizedBox(height: 2),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    final uldNumber = widget.uld['uld_number']?.toString() ?? '';
    final awbSplits = List<Map<String, dynamic>>.from(widget.uld['awb_splits'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textS),
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ULD Details', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(uldNumber, style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.dark ? const Color(0xFF1e293b) : const Color(0xFFF3F4F6),
                      foregroundColor: textP,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderC),
                      ),
                    ),
                    onPressed: widget.onPrint,
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: Text(appLanguage.value == 'es' ? 'Imprimir' : 'Print'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1).withAlpha(20),
                      foregroundColor: const Color(0xFF818cf8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(appLanguage.value == 'es' ? 'Editar' : 'Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // ULD Info
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetric('Pcs', widget.uld['pieces_total']?.toString() ?? widget.uld['pieces']?.toString() ?? '0', textP, textS)),
                  Expanded(child: _buildMetric('Weight', '${widget.uld['weight_total']?.toString() ?? widget.uld['weight']?.toString() ?? '0'} kg', textP, textS)),
                  Expanded(child: _buildMetric('Priority', widget.uld['is_priority'] == true ? 'Yes' : 'No', widget.uld['is_priority'] == true ? const Color(0xFFeab308) : textP, textS)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Break', style: TextStyle(color: textS, fontSize: 11)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (widget.uld['is_break'] == true) ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: (widget.uld['is_break'] == true) ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50)),
                          ),
                          child: Text(
                            (widget.uld['is_break'] == true) ? 'BREAK' : 'NO BRK',
                            style: TextStyle(
                              color: (widget.uld['is_break'] == true) ? Colors.green : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildStatusMetric('Status', FlightsV2StatusLogic.getUldStatus(widget.uld), textS)),
                  Expanded(child: _buildMetric('Remarks', (widget.uld['remarks']?.toString().trim().isNotEmpty == true && widget.uld['remarks']?.toString().trim().toLowerCase() != 'null') ? widget.uld['remarks'].toString() : '-', textP, textS)),
                ],
              ),
            ],
          ),
        ),

        // AWBs List Header
        Container(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
          child: Text(appLanguage.value == 'es' ? 'AWBs Asociados' : 'Associated AWBs', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
        ),

        // AWBs List
        Expanded(
          child: Container(
            color: widget.dark ? const Color(0xFF1e293b).withAlpha(50) : const Color(0xFFF9FAFB),
            child: awbSplits.isEmpty
                ? Center(child: Text(appLanguage.value == 'es' ? 'No hay AWBs.' : 'No AWBs.', style: TextStyle(color: textS)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: awbSplits.length,
                    itemBuilder: (context, index) {
                      final split = awbSplits[index];
                      final master = split['awbs'] ?? {};
                      final combined = {...master, ...split};
                      final awbNumber = master['awb_number']?.toString() ?? 'Desconocida';
                      final splitPieces = split['pieces']?.toString() ?? split['pieces_split']?.toString() ?? '0';
                      final masterPieces = master['total_pieces']?.toString() ?? master['pieces']?.toString() ?? '0';
                      final splitWeight = split['weight']?.toString() ?? split['weight_split']?.toString() ?? '0';
                      
                      List<String> houseList = [];
                      if (combined['house_number'] != null) {
                        if (combined['house_number'] is List) {
                          houseList = List<String>.from(combined['house_number']).where((e) => e.trim().isNotEmpty).toList();
                        } else if (combined['house_number'].toString().trim().isNotEmpty) {
                          houseList = [combined['house_number'].toString().trim()];
                        }
                      }
                      
                      final isExpanded = _expandedItems.contains(index);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedItems.remove(index);
                              } else {
                                _expandedItems.add(index);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Linear Row
                                Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: widget.dark ? const Color(0xFFf472b6).withAlpha(30) : const Color(0xFFdb2777).withAlpha(20),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: widget.dark ? const Color(0xFFf472b6).withAlpha(80) : const Color(0xFFdb2777).withAlpha(60)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('${index + 1}', style: TextStyle(color: widget.dark ? const Color(0xFFf472b6) : const Color(0xFFdb2777), fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('P: $splitPieces/$masterPieces', style: TextStyle(color: textS, fontSize: 12)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('W: ${splitWeight}kg', style: TextStyle(color: textS, fontSize: 12)),
                                    ),
                                    _buildStatusMetric('', FlightsV2StatusLogic.getAwbStatus(split), textS),
                                    const SizedBox(width: 8),
                                    Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: textS, size: 16),
                                  ],
                                ),
                                
                                // Expanded Area
                                if (isExpanded) ...[
                                  const SizedBox(height: 16),
                                  Divider(color: borderC, height: 1),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left Column: House
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('House Numbers', style: TextStyle(color: textS, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            if (houseList.isEmpty)
                                              Text('-', style: TextStyle(color: textP, fontSize: 13))
                                            else
                                              InkWell(
                                                onTap: () => _showHouseList(context, awbNumber, houseList),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF6366f1).withAlpha(20),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFF6366f1).withAlpha(50)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.list_alt_rounded, size: 12, color: Color(0xFF818cf8)),
                                                      const SizedBox(width: 6),
                                                      Text('${houseList.length} items', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Right Column: Remarks
                                      Expanded(
                                        child: _buildMetric(
                                          'Remarks',
                                          (combined['remarks']?.toString().trim().isNotEmpty == true && combined['remarks']?.toString().trim().toLowerCase() != 'null')
                                              ? combined['remarks'].toString()
                                              : '-',
                                          textP,
                                          textS,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(color: borderC, height: 1),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Data Coordinator
                                      Expanded(
                                        child: _buildDataCoordinatorLog(split, textP, textS),
                                      ),
                                      const SizedBox(width: 16),
                                      // Data Location
                                      Expanded(
                                        child: _buildDataLocationLog(split, textP, textS),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Traceability Log
        if ((widget.uld['time_received']?.toString().isNotEmpty == true && widget.uld['time_received'].toString() != 'null') ||
            (widget.uld['time_checked']?.toString().isNotEmpty == true && widget.uld['time_checked'].toString() != 'null') ||
            (widget.uld['time_saved']?.toString().isNotEmpty == true && widget.uld['time_saved'].toString() != 'null') ||
            (widget.uld['time_delivery']?.toString().isNotEmpty == true && widget.uld['time_delivery'].toString() != 'null') ||
            (widget.uld['time_deliver']?.toString().isNotEmpty == true && widget.uld['time_deliver'].toString() != 'null'))
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.dark ? const Color(0xFF1e293b) : Colors.white,
              border: Border(top: BorderSide(color: borderC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appLanguage.value == 'es' ? 'Historial de Eventos' : 'Event History', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTraceStep('RECEIVED', Icons.download_rounded, widget.uld['user_received']?.toString(), widget.uld['time_received']?.toString(), const Color(0xFFa855f7), textP, textS),
                _buildTraceStep('CHECKED', Icons.inventory_rounded, widget.uld['user_checked']?.toString(), widget.uld['time_checked']?.toString(), const Color(0xFF0ea5e9), textP, textS),
                _buildTraceStep('SAVED', Icons.save_rounded, widget.uld['user_saved']?.toString(), widget.uld['time_saved']?.toString(), const Color(0xFF22c55e), textP, textS),
                _buildTraceStep('DELIVERED', Icons.local_shipping_rounded, widget.uld['user_delivery']?.toString() ?? widget.uld['user_deliver']?.toString(), widget.uld['time_delivery']?.toString() ?? widget.uld['time_deliver']?.toString() ?? widget.uld['time-deliver']?.toString(), const Color(0xFFf59e0b), textP, textS),
              ],
            ),
          ),
      ],
    );
  }
}
