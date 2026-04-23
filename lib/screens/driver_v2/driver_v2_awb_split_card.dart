import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'driver_v2_dialogs.dart';

class DriverV2AwbSplitCard extends StatefulWidget {
  final dynamic split;
  final String awbNumber;
  final bool dark;
  final int index;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Set<String> checkedItems;
  final Set<String> selectedLocations;
  final ValueNotifier<int> foundNotifier;

  const DriverV2AwbSplitCard({
    super.key,
    required this.split,
    required this.awbNumber,
    required this.dark,
    required this.index,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.checkedItems,
    required this.selectedLocations,
    required this.foundNotifier,
  });

  @override
  State<DriverV2AwbSplitCard> createState() => _DriverV2AwbSplitCardState();
}

class _DriverV2AwbSplitCardState extends State<DriverV2AwbSplitCard> {
  bool _localChecked = false;

  @override
  Widget build(BuildContext context) {
    final split = widget.split;
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    String uldName = 'N/A';
    String flightName = 'N/A';
    String itemPieces = split['pieces']?.toString() ?? split['pieces_total']?.toString() ?? '0';
    
    List locList = [];
    if (split['data_location'] is List) {
      locList = split['data_location'] as List;
    } else if (split['data_location'] is Map && (split['data_location'] as Map).isNotEmpty) {
      locList = [split['data_location']];
    }

    List coordList = [];
    if (split['data_coordinator'] is List) {
      coordList = split['data_coordinator'] as List;
    } else if (split['data_coordinator'] is Map && (split['data_coordinator'] as Map).isNotEmpty) {
      coordList = [split['data_coordinator']];
    }
    
    bool hasDriverPickUp = coordList.any((c) => c is Map && c['check_source'] == 'Driver Pick Up');
    
    Map uldData = {};
    if (split.containsKey('id_uld') && !split.containsKey('awb_id')) {
       uldName = split['uld_number']?.toString() ?? 'N/A';
       uldData = Map.from(split);
    } else {
       if (split['ulds'] is Map) {
          uldName = split['ulds']['uld_number']?.toString() ?? 'N/A';
          uldData = Map.from(split['ulds']);
       }
    }
    
    String statusText = '';
    Color statusColor = Colors.transparent;
    
    if (uldData['time_saved'] != null || uldData['time-saved'] != null) {
      statusText = appLanguage.value == 'es' ? 'Guardado' : 'Saved';
      statusColor = const Color(0xFF10b981); // Green
    } else if (uldData['time_checked'] != null || uldData['time-checked'] != null) {
      statusText = appLanguage.value == 'es' ? 'Chequeado' : 'Checked';
      statusColor = const Color(0xFFf59e0b); // Orange
    } else if (uldData['time_received'] != null || uldData['time-received'] != null) {
      statusText = appLanguage.value == 'es' ? 'Recibido' : 'Received';
      statusColor = const Color(0xFF3b82f6); // Blue
    }
    
    if (split['flights'] is Map) {
       final fMap = split['flights'] as Map;
       final carrier = fMap['carrier']?.toString() ?? '';
       final number = fMap['number']?.toString() ?? '';
       
       final rawDate = fMap['date']?.toString() ?? fMap['date_arrived']?.toString() ?? fMap['date-arrived']?.toString() ?? fMap['created_at']?.toString();
       String dateStr = '';
       if (rawDate != null) {
         final d = DateTime.tryParse(rawDate)?.toLocal();
         if (d != null) {
           final esMonths = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
           final enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
           final m = appLanguage.value == 'es' ? esMonths[d.month - 1] : enMonths[d.month - 1];
           final day = d.day.toString().padLeft(2, '0');
           dateStr = ' - $m $day';
         }
       }
       
       final combined = '$carrier $number'.trim();
       if (combined.isNotEmpty) {
         flightName = '$combined$dateStr';
       }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: Color(0xFF10b981), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ULD: $uldName', 
                  style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$itemPieces pcs', 
                  style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              if (statusText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        statusText == 'Guardado' || statusText == 'Saved' ? Icons.check_circle_rounded :
                        statusText == 'Chequeado' || statusText == 'Checked' ? Icons.fact_check_rounded :
                        Icons.move_to_inbox_rounded,
                        color: statusColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (statusText == 'Recibido' || statusText == 'Received') ...[
                      if (uldData['is_break'] == true || uldData['isbrey'] == true) ...[
                        if (!hasDriverPickUp)
                          InkWell(
                            onTap: () => DriverV2Dialogs.showCheckItemDialog(
                              context: context, 
                              split: split, 
                              awbNumber: widget.awbNumber,
                              dark: widget.dark,
                              onUpdate: () => setState(() {}),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.playlist_add_check_rounded, 
                                color: Color(0xFF3b82f6), 
                                size: 20
                              ),
                            ),
                          )
                      ] else
                        InkWell(
                          onTap: () => DriverV2Dialogs.showNoBreakInfoDialog(
                            context: context, 
                            uldData: uldData, 
                            uldName: uldName, 
                            dark: widget.dark
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.info_outline_rounded, 
                              color: Color(0xFF94a3b8), 
                              size: 20
                            ),
                          ),
                        ),
                    ],
                    if (locList.isNotEmpty || coordList.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: widget.onToggleCollapse,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            widget.isCollapsed ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                            color: widget.isCollapsed ? textS : const Color(0xFF3b82f6), 
                            size: 20
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flight_land_rounded, color: textS, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Flight Ref: $flightName', 
                  style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

              Container(
                width: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (uldData['is_break'] == true || uldData['isbrey'] == true) ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  (uldData['is_break'] == true || uldData['isbrey'] == true) ? 'BREAK' : 'NO BREAK',
                  style: TextStyle(
                    color: (uldData['is_break'] == true || uldData['isbrey'] == true) ? const Color(0xFF10b981) : const Color(0xFFef4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!(uldData['is_break'] == true || uldData['isbrey'] == true) || !split.containsKey('awb_id')) ...[
                      Container(
                        width: 28,
                        height: 24,
                        alignment: Alignment.center,
                        child: uldData['time_deliver'] != null
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 22)
                            : SizedBox(
                                height: 24,
                                child: Theme(
                                  data: ThemeData(
                                    unselectedWidgetColor: widget.dark ? Colors.white70 : Colors.black54,
                                  ),
                                  child: Checkbox(
                                    value: _localChecked,
                                    activeColor: const Color(0xFF10b981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _localChecked = value ?? false;
                                      });
                                      final pieces = int.tryParse(itemPieces) ?? 0;
                                      if (_localChecked) {
                                        widget.foundNotifier.value += pieces;
                                      } else {
                                        widget.foundNotifier.value -= pieces;
                                      }
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                      ),
                    ]
                  ],
                ),
              )
            ],
          ),
          if (split.containsKey('awb_id')) ...[
            if ((locList.isNotEmpty || coordList.isNotEmpty) && !widget.isCollapsed) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderC),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: textS, size: 14),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Items List', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold))),
                              if (split['total_checked'] != null && split['total_checked'].toString() != '0')
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10b981).withAlpha(20),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF10b981).withAlpha(50)),
                                  ),
                                  child: Text(
                                    '${split['total_checked']}',
                                    style: const TextStyle(color: Color(0xFF10b981), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (coordList.isEmpty)
                            Text('No data', style: TextStyle(color: textS, fontSize: 12))
                          else
                            ...coordList.map((item) {
                              final map = Map.from(item as Map);
                              final by = map.remove('processed_by') ?? map.remove('user') ?? 'Unknown';
                              final timeRaw = map.remove('processed_at') ?? map.remove('time');
                              
                              String timeStr = '';
                              if (timeRaw != null) {
                                final time = DateTime.tryParse(timeRaw.toString())?.toLocal();
                                if (time != null) {
                                  final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
                                  final ampm = time.hour >= 12 ? 'PM' : 'AM';
                                  final minute = time.minute.toString().padLeft(2, '0');
                                  final esMonths = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                                  final enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                  final monthStr = appLanguage.value == 'es' ? esMonths[time.month - 1] : enMonths[time.month - 1];
                                  final dayStr = time.day.toString().padLeft(2, '0');
                                  timeStr = ' [$dayStr $monthStr, $hour:$minute $ampm]';
                                }
                              }
                              
                              Map bd = {};
                              if (map['breakdown'] is Map) {
                                bd = Map.from(map['breakdown'] as Map);
                              } else {
                                bd = Map.from(map);
                              }
                              
                              bd.remove('remark');
                              bd.remove('remarks');
                              bd.remove('Remarks');
                              bd.remove('discrepancy_check');
                              bd.remove('discrepancy check');
                              bd.remove('discrepancy_checked');
                              bd.remove('discrepancy checked');
                              bd.remove('discrepancy_expected');
                              bd.remove('discrepancy expected');
                              bd.remove('check_source');
                              
                              final discAmount = bd.remove('discrepancy_amount') ?? bd.remove('discrepancy amount');
                              final discType = bd.remove('discrepancy_type') ?? bd.remove('discrepancy type');
                              String discrepancyStr = '';
                              if (discAmount != null && discAmount.toString().isNotEmpty && discAmount.toString() != '0') {
                                discrepancyStr = '${discAmount.toString()} ${discType?.toString() ?? ''}'.trim().toUpperCase();
                              }
                              
                              final locReq1 = bd.remove('location_required');
                              final locReq2 = bd.remove('required_location');
                              final locReq3 = bd.remove('location required');
                              final locReq4 = bd.remove('Location requerida');
                              final locReq5 = bd.remove('location requerida');
                              String locReqStr = (locReq1 ?? locReq2 ?? locReq3 ?? locReq4 ?? locReq5 ?? '').toString();
                              if (locReqStr.toLowerCase() == 'null') locReqStr = '';
                              
                              bd.removeWhere((k, v) => const ['processed_by', 'processed_at', 'user', 'time', 'refULD', 'manual_entry', 'breakdown'].contains(k));
                              
                              List<Map<String, dynamic>> thisGroupItems = [];
                              bd.forEach((key, value) {
                                if (value is List && value.isEmpty) return;
                                if (value == null || value.toString().isEmpty || value.toString() == '0') return;
                                final itemName = key;
                                final itemPieces = int.tryParse(value.toString()) ?? 0;
                                final uniqueKey = '${split['id']}-$itemName';
                                thisGroupItems.add({'name': itemName, 'pieces': itemPieces, 'key': uniqueKey});
                              });

                              Widget? discWidget;
                              if (discrepancyStr.isNotEmpty) {
                                discWidget = Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.redAccent.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text(discrepancyStr, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                );
                              }
                              
                              Widget? locWidget;
                              if (locReqStr.isNotEmpty && locReqStr.toLowerCase() != 'false' && locReqStr != '0') {
                                locWidget = Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text(locReqStr, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                );
                              }
                              
                              bool allSelected = thisGroupItems.isNotEmpty && thisGroupItems.every((item) => widget.checkedItems.contains(item['key']));
                              
                              List<Widget> itemRows = thisGroupItems.map((item) {
                                final isChecked = widget.checkedItems.contains(item['key']);
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isChecked) {
                                        widget.checkedItems.remove(item['key']);
                                        widget.foundNotifier.value -= (item['pieces'] as int);
                                      } else {
                                        widget.checkedItems.add(item['key']);
                                        widget.foundNotifier.value += (item['pieces'] as int);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: isChecked ? const Color(0xFF10b981).withAlpha(15) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: isChecked,
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  widget.checkedItems.add(item['key']);
                                                  widget.foundNotifier.value += (item['pieces'] as int);
                                                } else {
                                                  widget.checkedItems.remove(item['key']);
                                                  widget.foundNotifier.value -= (item['pieces'] as int);
                                                }
                                              });
                                            },
                                            activeColor: const Color(0xFF10b981),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            side: BorderSide(color: textS.withAlpha(150)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text(item['name'], style: TextStyle(color: isChecked ? const Color(0xFF10b981) : textP, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('${item['pieces']} pcs', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (thisGroupItems.isNotEmpty)
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: allSelected,
                                              onChanged: (v) {
                                                setState(() {
                                                  if (v == true) {
                                                    for (var item in thisGroupItems) {
                                                      if (!widget.checkedItems.contains(item['key'])) {
                                                        widget.checkedItems.add(item['key']);
                                                        widget.foundNotifier.value += (item['pieces'] as int);
                                                      }
                                                    }
                                                  } else {
                                                    for (var item in thisGroupItems) {
                                                      if (widget.checkedItems.contains(item['key'])) {
                                                        widget.checkedItems.remove(item['key']);
                                                        widget.foundNotifier.value -= (item['pieces'] as int);
                                                      }
                                                    }
                                                  }
                                                });
                                              },
                                              activeColor: const Color(0xFF6366f1),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              side: BorderSide(color: textS.withAlpha(150)),
                                            ),
                                          ),
                                        if (thisGroupItems.isNotEmpty)
                                          const SizedBox(width: 8),
                                        Expanded(child: Text('By: $by$timeStr', style: TextStyle(color: textP, fontSize: 11, fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (itemRows.isNotEmpty)
                                      Column(
                                        children: itemRows,
                                      )
                                    else if (discWidget == null && locWidget == null)
                                      Text('No details', style: TextStyle(color: textS, fontSize: 10)),
                                    if (discWidget != null || locWidget != null) ...[
                                      if (itemRows.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Divider(height: 1, color: borderC),
                                        ),
                                      Row(
                                        children: [
                                          if (locWidget != null) Expanded(child: locWidget),
                                          if (discWidget != null && locWidget != null) ...[
                                            const SizedBox(width: 8),
                                            Container(width: 1, height: 20, color: borderC),
                                            const SizedBox(width: 8),
                                          ],
                                          if (discWidget != null) Expanded(child: discWidget),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderC),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.place_rounded, color: textS, size: 14),
                              const SizedBox(width: 6),
                              Text('Locations', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Builder(
                            builder: (context) {
                              if (locList.isEmpty && !hasDriverPickUp) {
                                return Text('No locations', style: TextStyle(color: textS, fontSize: 12));
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasDriverPickUp)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3b82f6).withAlpha(20),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF3b82f6).withAlpha(50)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.local_shipping_rounded, size: 14, color: Color(0xFF3b82f6)),
                                            SizedBox(width: 6),
                                            Text(
                                              'Driver Pick Up',
                                              style: TextStyle(
                                                color: Color(0xFF3b82f6),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (locList.isNotEmpty)
                                    ...locList.map((item) {
                                      final map = Map.from(item as Map);
                                      final List<Widget> locChips = [];
                                      
                                      void extractLocs(Map m) {
                                        m.forEach((key, value) {
                                          if (['updated_by', 'processed_by', 'user', 'updated_at', 'processed_at', 'time'].contains(key)) return;
                                          if (value == null || value.toString().isEmpty || value.toString() == '0') return;
                                          
                                          final locValue = value.toString();
                                          final uniqueKey = '${widget.index}-$locValue';
                                          final isSelected = widget.selectedLocations.contains(uniqueKey);
                                          
                                          locChips.add(
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (isSelected) {
                                                      widget.selectedLocations.remove(uniqueKey);
                                                    } else {
                                                      widget.selectedLocations.add(uniqueKey);
                                                    }
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? const Color(0xFF10b981) : const Color(0xFF10b981).withAlpha(20),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: isSelected ? const Color(0xFF10b981) : (widget.dark ? Colors.white.withAlpha(30) : const Color(0xFFE5E7EB))),
                                                  ),
                                                  child: Text(
                                                    locValue, 
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : const Color(0xFF10b981), 
                                                      fontSize: 12, 
                                                      fontWeight: FontWeight.bold
                                                    )
                                                  ),
                                                ),
                                              ),
                                            )
                                          );
                                        });
                                      }

                                      if (map.containsKey('locations') && map['locations'] is List) {
                                        for (var locItem in map['locations']) {
                                          if (locItem is Map) extractLocs(locItem);
                                        }
                                      } else {
                                        extractLocs(map);
                                      }
                                      
                                      if (locChips.isEmpty) return const SizedBox.shrink();
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: locChips,
                                        ),
                                      );
                                    }),
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
