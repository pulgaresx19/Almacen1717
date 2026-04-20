import 'package:flutter/material.dart';

class LocalAwbsTable extends StatelessWidget {
  final bool dark;
  final Color textP;
  final Color textS;
  final Color borderC;
  final List<Map<String, dynamic>> localAwbs;
  final TextEditingController searchCtrl;
  final Set<String> collapsedGroups;
  final Function(String) onToggleGroup;
  final Function(int) onRemoveAwb;
  final Function(String, List<String>) onShowListDialog;
  final Function(Map<String, dynamic>) onShowCoordinatorPreview;
  final Function(Map<String, dynamic>) onShowLocationPreview;

  const LocalAwbsTable({
    super.key,
    required this.dark,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.localAwbs,
    required this.searchCtrl,
    required this.collapsedGroups,
    required this.onToggleGroup,
    required this.onRemoveAwb,
    required this.onShowListDialog,
    required this.onShowCoordinatorPreview,
    required this.onShowLocationPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (localAwbs.isEmpty) {
      return Center(
        child: Text(
          'No AWBs added yet',
          style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedAwbs = {};
    for (int i = 0; i < localAwbs.length; i++) {
      final a = localAwbs[i];
      if (searchCtrl.text.isNotEmpty) {
        final term = searchCtrl.text.toLowerCase();
        final number = (a['awbNumber'] ?? '').toString().toLowerCase();
        if (!number.contains(term)) continue;
      }
      final groupKey = a['flightLabel'] ?? 'Standalone AWBs';
      groupedAwbs.putIfAbsent(groupKey, () => []);
      groupedAwbs[groupKey]!.add({'index': i, 'awb': a});
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedAwbs.entries.map((group) {
          final groupName = group.key;
          final groupItems = group.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                  border: Border(bottom: BorderSide(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Icon(
                      groupName == 'Standalone AWBs' ? Icons.inventory_2_outlined : Icons.flight_takeoff_rounded,
                      color: textS,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      groupName,
                      style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${groupItems.length} items',
                        style: const TextStyle(color: Color(0xFF818cf8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        collapsedGroups.contains(groupName) ? Icons.visibility_off : Icons.visibility,
                        color: textS,
                        size: 20,
                      ),
                      onPressed: () => onToggleGroup(groupName),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              if (!collapsedGroups.contains(groupName))
                Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: IntrinsicColumnWidth(),
                    2: IntrinsicColumnWidth(),
                    3: IntrinsicColumnWidth(),
                    4: IntrinsicColumnWidth(),
                    5: FlexColumnWidth(),
                    6: IntrinsicColumnWidth(),
                    7: IntrinsicColumnWidth(),
                    8: IntrinsicColumnWidth(),
                  },
                  children: groupItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final int realIndex = item['index'];
                    final a = item['awb'];
                    final awbNum = a['awbNumber'];
                    return TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12, top: 12, bottom: 12),
                          child: Container(
                            width: 24, height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                            child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 24, top: 12, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(awbNum, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                              if (a['refUld'] != '' && a['refUld'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 12, color: textS),
                                      const SizedBox(width: 4),
                                      Text(a['refUld'], style: TextStyle(color: textS, fontSize: 12)),
                                      if (a['isBreak'] != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (a['isBreak'] == true) ? const Color(0xFF22c55e).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            (a['isBreak'] == true) ? 'BREAK' : 'NO BREAK',
                                            style: TextStyle(
                                              color: (a['isBreak'] == true) ? const Color(0xFF22c55e) : const Color(0xFFef4444),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                          child: RichText(text: TextSpan(children: [
                            TextSpan(text: 'PIECES: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                            TextSpan(text: '${a['pieces']}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                          ])),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                          child: RichText(text: TextSpan(children: [
                            TextSpan(text: 'TOTAL: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                            TextSpan(text: '${a['total']}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                          ])),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                          child: RichText(text: TextSpan(children: [
                            TextSpan(text: 'WEIGHT: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                            TextSpan(text: '${a['weight']}', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                          ])),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(children: [
                              TextSpan(text: 'REMARKS: ', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                              TextSpan(
                                text: (a['remarks'] != null && a['remarks'].toString().isNotEmpty) ? a['remarks'].toString() : '-',
                                style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                              ),
                            ]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                          child: Builder(
                            builder: (ctx) {
                              List<String> houses = (a['house'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                              if (houses.isEmpty) return const SizedBox.shrink();
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => onShowListDialog('House Numbers', houses),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: dark ? const Color(0xFF1e293b) : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.maps_home_work_outlined, size: 12, color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)),
                                        const SizedBox(width: 4),
                                        Text('${houses.length} HAWB', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
                          child: Builder(
                            builder: (context) {
                              bool hasCoordinatorData = (a['coordinator'] != null && (a['coordinator'] is List ? (a['coordinator'] as List).isNotEmpty : a['coordinator'].toString().isNotEmpty)) || (a['coordinatorCounts'] != null && (a['coordinatorCounts'] as Map).isNotEmpty);
                              bool hasLocationData = (a['location'] != null && (a['location'] is List ? (a['location'] as List).isNotEmpty : a['location'].toString().isNotEmpty)) || (a['itemLocations'] != null && (a['itemLocations'] as Map).isNotEmpty);
                              
                              int discrepancy = 0;
                              String discType = '';
                              if (a['coordinatorCounts'] != null && (a['coordinatorCounts'] as Map).isNotEmpty) {
                                int totalChecked = 0;
                                Map counts = a['coordinatorCounts'];
                                if (counts['AGI Skid'] != null) {
                                  final parts = counts['AGI Skid'].toString().split(RegExp(r'[,\s-]+'));
                                  for (var p in parts) { totalChecked += int.tryParse(p) ?? 0; }
                                }
                                for (String k in ['Pre Skid', 'Crate', 'Box', 'Other']) {
                                  totalChecked += int.tryParse(counts[k]?.toString() ?? '') ?? 0;
                                }
                                int expected = int.tryParse(a['pieces']?.toString() ?? '0') ?? 0;
                                if (totalChecked != expected && totalChecked > 0) {
                                  discrepancy = (totalChecked - expected).abs();
                                  discType = totalChecked > expected ? 'OVER' : 'SHORT';
                                }
                              }
                              
                              if (!hasCoordinatorData && !hasLocationData && discrepancy == 0) return const SizedBox.shrink();
                              
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (discrepancy > 0)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFEF4444).withAlpha(100)),
                                      ),
                                      child: Text(
                                        '$discrepancy $discType',
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (hasCoordinatorData)
                                    InkWell(
                                      onTap: () {
                                        if (a['coordinatorCounts'] != null && (a['coordinatorCounts'] as Map).isNotEmpty) {
                                          onShowCoordinatorPreview(a);
                                        } else {
                                          List<String> dcList = a['coordinator'] is List ? (a['coordinator'] as List).map((e) => e.toString()).toList() : a['coordinator'].toString().split('\n').where((e) => e.trim().isNotEmpty).toList();
                                          onShowListDialog('Data Coordinator', dcList);
                                        }
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), shape: BoxShape.circle),
                                        child: const Icon(Icons.assignment_add, size: 14, color: Color(0xFF6366f1)),
                                      ),
                                    ),
                                  if (hasLocationData)
                                    InkWell(
                                      onTap: () {
                                        if (a['itemLocations'] != null && (a['itemLocations'] as Map).isNotEmpty) {
                                          onShowLocationPreview(a);
                                        } else {
                                          List<String> locList = a['location'] is List ? (a['location'] as List).map((e) => e.toString()).toList() : a['location'].toString().split('\n').where((e) => e.trim().isNotEmpty).toList();
                                          onShowListDialog('Data Location', locList);
                                        }
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.green.withAlpha(30), shape: BoxShape.circle),
                                        child: const Icon(Icons.location_on_outlined, size: 14, color: Colors.green),
                                      ),
                                    ),
                                ],
                              );
                            }
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFFef4444), size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => onRemoveAwb(realIndex),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
