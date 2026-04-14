import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
  Widget _buildStatMini(String label, String value, {VoidCallback? onTap}) {
  Widget content = Column(
    children: [
      Text(label, style: const TextStyle(color: Color(0xFF64748b), fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ],
  );
  if (onTap != null) {
    return GestureDetector(onTap: onTap, child: content);
  }
  return content;
}

Future<dynamic> showCoordinatorV2AwbDetails(
    BuildContext context,
    Map<String, dynamic> awb,
    bool dark, [
    Map<String, dynamic>? uldOverride,
  ]) async {
    Map<String, List<int>> breakdown = {
      'AGI Skid': [],
      'Pre Skid': [],
      'Crate': [],
      'Box': [],
      'Other': [],
    };
    List<String> selectedLocations = [];
    final otherLocationCtrl = TextEditingController();
    final bool isUldChecked =
        (uldOverride?['data-checked'] as Map?)?.isNotEmpty == true;
    bool isLoading = true;
    bool isEditMode = !isUldChecked;
    Map<dynamic, dynamic>? initialData;
    bool isNotFound = false;

    final ctrls = {
      'AGI Skid': TextEditingController(),
      'Pre Skid': TextEditingController(),
      'Crate': TextEditingController(),
      'Box': TextEditingController(),
      'Other': TextEditingController(),
    };

    return await showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            if (isLoading) {
              isLoading = false;
              // Fetch from Supabase
              Supabase.instance.client
                      .from('awb_splits')
                      .select('data_coordinator, awbs!inner(total_pieces)')
                      .eq('id', awb['id_split'])
                      .maybeSingle()
                      .then((res) {
                    if (res != null) {
                      if (res['awbs'] != null && res['awbs']['total_pieces'] != null) {
                        awb['total'] = res['awbs']['total_pieces'];
                      }
                      Map<dynamic, dynamic>? data;
                      if (res['data_coordinator'] is Map) {
                        data = res['data_coordinator'] as Map<dynamic, dynamic>;
                      }

                      if (data != null) {
                        initialData = data;
                        bool hasInput = false;
                        if (data['breakdown'] is Map) {
                          final bd = data['breakdown'] as Map;
                          hasInput = bd.values.any((val) {
                            if (val is List) {
                              return val.any(
                                (e) => (int.tryParse(e.toString()) ?? 0) > 0,
                              );
                            }
                            if (val is num) {
                              return val > 0;
                            }
                            if (val is String) {
                              return (int.tryParse(val) ?? 0) > 0;
                            }
                            return false;
                          });
                        }
                        if (hasInput) isEditMode = false;

                        if (data['discrepancy'] is Map &&
                            data['discrepancy']['notFound'] == true) {
                          isNotFound = true;
                          isEditMode = false;
                        }

                        if (data['breakdown'] is Map) {
                          final bd = data['breakdown'] as Map;
                          for (var k in breakdown.keys) {
                            String legacyKey = k;
                            if (k == 'Crate') legacyKey = 'Crate(s)';
                            if (k == 'Box') legacyKey = 'Box(es)';

                            if (bd[k] is List) {
                              breakdown[k] = (bd[k] as List)
                                  .map((e) => int.tryParse(e.toString()) ?? 0)
                                  .toList();
                            } else if (bd[legacyKey] is List) {
                              breakdown[k] = (bd[legacyKey] as List)
                                  .map((e) => int.tryParse(e.toString()) ?? 0)
                                  .toList();
                            } else if (bd[k] is num || bd[k] is String) {
                              int val = int.tryParse(bd[k].toString()) ?? 0;
                              breakdown[k] = val > 0 ? [val] : [];
                            } else if (bd[legacyKey] is num ||
                                bd[legacyKey] is String) {
                              int val =
                                  int.tryParse(bd[legacyKey].toString()) ?? 0;
                              breakdown[k] = val > 0 ? [val] : [];
                            }
                          }
                        }
                        if (data['selectedLocations'] is List) {
                          selectedLocations = List<String>.from(
                            data['selectedLocations'],
                          );
                          if (selectedLocations.isNotEmpty) {
                            String loc = selectedLocations.first;
                            if (![
                              '15-25°C',
                              '2-8°C',
                              'PSV',
                              'DG',
                              'Oversize',
                              'Small rack',
                              'Animal Live',
                              'Other',
                            ].contains(loc)) {
                              selectedLocations = ['Other'];
                              otherLocationCtrl.text = loc;
                            }
                          }
                        }
                      }
                    }
                    if (dialogCtx.mounted) setDialogState(() {});
                  });
            }

            int totalChecked = breakdown.values
                .expand((element) => element)
                .fold(0, (a, b) => a + b);

            Widget buildControlRow(String label) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFcbd5e1),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      height: 38,
                      child: TextField(
                        enabled: isEditMode && !isNotFound,
                        controller: ctrls[label],
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(5),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(50),
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha(10),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withAlpha(20),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF8b5cf6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: (isEditMode && !isNotFound)
                          ? () {
                              final val = int.tryParse(ctrls[label]!.text);
                              if (val != null && val > 0) {
                                setDialogState(() {
                                  if (label == 'AGI Skid') {
                                    breakdown[label]!.add(val);
                                  } else {
                                    breakdown[label] = [val];
                                  }
                                  ctrls[label]!.clear();
                                });
                              }
                            }
                          : null,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (isEditMode && !isNotFound)
                              ? const Color(0xFF6366f1)
                              : const Color(0xFF6366f1).withAlpha(100),
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // fully rounded circle like image
                        ),
                        child: Icon(
                          Icons.add,
                          color: (isEditMode && !isNotFound)
                              ? Colors.white
                              : Colors.white.withAlpha(150),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildLocationChip(String label) {
              final isSel = selectedLocations.contains(label);
              return InkWell(
                onTap: (isEditMode && !isNotFound)
                    ? () {
                        setDialogState(() {
                          if (isSel) {
                            selectedLocations.clear();
                            if (label == 'Other') otherLocationCtrl.clear();
                          } else {
                            selectedLocations = [label];
                            if (label != 'Other') otherLocationCtrl.clear();
                          }
                        });
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF6366f1) : Colors.transparent,
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF6366f1)
                          : Colors.white.withAlpha(30),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFFcbd5e1),
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withAlpha(10)),
              ),
              title: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'AWB: ${awb['number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  FilterChip(
                    label: const Text(
                      'Not Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    selected: isNotFound,
                    onSelected: isEditMode
                        ? (val) {
                            setDialogState(() {
                              isNotFound = val;
                              if (val) {
                                selectedLocations.clear();
                                otherLocationCtrl.clear();
                                for (var k in breakdown.keys) {
                                  breakdown[k]!.clear();
                                }
                                for (var k in ctrls.keys) {
                                  ctrls[k]!.clear();
                                }
                              }
                            });
                          }
                        : null,
                    selectedColor: const Color(0xFFef4444).withAlpha(50),
                    checkmarkColor: const Color(0xFFef4444),
                    labelStyle: TextStyle(
                      color: isNotFound
                          ? const Color(0xFFef4444)
                          : Colors.white,
                    ),
                    backgroundColor: Colors.white.withAlpha(5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isNotFound
                            ? const Color(0xFFef4444).withAlpha(100)
                            : Colors.white.withAlpha(20),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600, // wide dialog to fit both columns
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top summary bar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withAlpha(10)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatMini('PIECES', '${awb['pieces'] ?? '-'}'),
                            _buildStatMini('TOTAL', '${awb['total'] ?? '-'}'),
                            _buildStatMini(
                              'WEIGHT',
                              '${awb['weight'] ?? '-'} kg',
                            ),
                            _buildStatMini(
                              'HOUSES',
                              '${(awb['hawbs'] as List?)?.length ?? '0'}',
                              onTap: () {
                                final hList = (awb['hawbs'] as List?) ?? [];
                                if (hList.isEmpty) return;
                                showDialog(
                                  context: dialogCtx,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1e293b),
                                    elevation: 8,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    titlePadding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Row(
                                      children: const [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          color: Color(0xFF6366f1),
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'House Numbers',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Container(
                                      width: 250,
                                      constraints: const BoxConstraints(
                                        maxHeight: 250,
                                      ),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: hList.length,
                                        separatorBuilder: (_, _) =>
                                            const Divider(
                                              color: Color(0xFF334155),
                                            ),
                                        itemBuilder: (c, i) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              hList[i].toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(
                                            color: Color(0xFF94a3b8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            _buildStatMini(
                              'REMARKS',
                              (awb['remarks']?.toString().trim().isEmpty ??
                                      true)
                                  ? '-'
                                  : awb['remarks'].toString().trim(),
                            ),
                          ],
                        ),
                      ),
                      if (initialData != null &&
                          initialData!['discrepancy'] != null &&
                          initialData!['discrepancy']['confirmed'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withAlpha(50),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Builder(
                                    builder: (ctx) {
                                      int exp =
                                          initialData!['discrepancy']['expected']
                                              as int? ??
                                          0;
                                      int rec =
                                          initialData!['discrepancy']['received']
                                              as int? ??
                                          0;
                                      int diff = (exp - rec).abs();
                                      String term = exp > rec
                                          ? 'SHORT'
                                          : 'OVER';

                                      return RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  'Discrepancy Confirmed: Expected $exp PCs, Received $rec PCs.  ',
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '$diff PCs $term',
                                              style: const TextStyle(
                                                color: Color(0xFFef4444),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AWB BREAK DOWN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Total Checked: ',
                                style: TextStyle(
                                  color: Color(0xFF94a3b8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3b82f6).withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalChecked',
                                  style: const TextStyle(
                                    color: Color(0xFF60a5fa),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                buildControlRow('AGI Skid'),
                                buildControlRow('Pre Skid'),
                                buildControlRow('Crate'),
                                buildControlRow('Box'),
                                buildControlRow('Other'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right side scrollable list
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withAlpha(10),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView(
                                padding: const EdgeInsets.all(12),
                                children: breakdown.entries.where((e) => e.value.isNotEmpty).map((
                                  entry,
                                ) {
                                  int itemCount = entry.value.length;
                                  int totalPcs = entry.value.fold<int>(
                                    0,
                                    (a, b) => a + b,
                                  );

                                  String getDisplayName(String key, int count) {
                                    if (count <= 1) return key.toUpperCase();
                                    if (key == 'Box') return 'BOXES';
                                    return '${key.toUpperCase()}S';
                                  }

                                  if (entry.key == 'AGI Skid') {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(10),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(
                                                    25,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '$itemCount',
                                                  style: const TextStyle(
                                                    color: Color(0xFFcbd5e1),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                getDisplayName(
                                                  entry.key,
                                                  itemCount,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '$totalPcs pcs',
                                                style: const TextStyle(
                                                  color: Color(0xFF94a3b8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ...entry.value.asMap().entries.map((
                                            item,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '#${item.key + 1}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF64748b),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withAlpha(5),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${item.value}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (isEditMode &&
                                                      !isNotFound) ...[
                                                    const SizedBox(width: 8),
                                                    InkWell(
                                                      onTap: () {
                                                        setDialogState(() {
                                                          breakdown[entry.key]!
                                                              .removeAt(
                                                                item.key,
                                                              );
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Colors.red
                                                                .withAlpha(50),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Color(
                                                            0xFFef4444,
                                                          ),
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(10),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$totalPcs',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            getDisplayName(entry.key, totalPcs),
                                            style: const TextStyle(
                                              color: Color(0xFF94a3b8),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isEditMode && !isNotFound)
                                            InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  breakdown[entry.key]!.clear();
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.red.withAlpha(
                                                      50,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Color(0xFFef4444),
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Location required:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          buildLocationChip('15-25°C'),
                          buildLocationChip('2-8°C'),
                          buildLocationChip('PSV'),
                          buildLocationChip('DG'),
                          buildLocationChip('Oversize'),
                          buildLocationChip('Small rack'),
                          buildLocationChip('Animal Live'),
                          buildLocationChip('Other'),
                          if (selectedLocations.contains('Other'))
                            SizedBox(
                              width: 200,
                              height: 38,
                              child: TextField(
                                enabled: isEditMode && !isNotFound,
                                controller: otherLocationCtrl,
                                style: TextStyle(
                                  color: (isEditMode && !isNotFound)
                                      ? Colors.white
                                      : Colors.white.withAlpha(150),
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter custom location...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withAlpha(50),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(5),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.white.withAlpha(20),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF8b5cf6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                if (!isUldChecked)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditMode
                            ? const Color(0xFF6366f1)
                            : Colors.white.withAlpha(10),
                        foregroundColor: isEditMode
                            ? Colors.white
                            : Colors.white.withAlpha(100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!isEditMode) {
                                setDialogState(() => isEditMode = true);
                                return;
                              }
                              int expectedPieces =
                                  int.tryParse(
                                    awb['pieces']?.toString() ?? '0',
                                  ) ??
                                  0;
                              if (isNotFound) {
                                // By-pass the discrepancy dialog because 'Not Found' is explicitly a discrepancy
                              } else if (totalChecked != expectedPieces &&
                                  breakdown.values.any(
                                    (list) => list.isNotEmpty,
                                  )) {
                                bool? confirmed = await showDialog<bool>(
                                  context: dialogCtx,
                                  builder: (ctx) {
                                    int diff = (expectedPieces - totalChecked)
                                        .abs();
                                    String term = expectedPieces > totalChecked
                                        ? 'missing'
                                        : 'extra';
                                    return AlertDialog(
                                      backgroundColor: const Color(0xFF1e293b),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Discrepancy Detected',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'You should have received $expectedPieces pieces but you only received $totalChecked.',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 20,
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFef4444,
                                              ).withAlpha(40),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFef4444,
                                                ).withAlpha(100),
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Color(0xFFef4444),
                                                  size: 36,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${diff.toString().toUpperCase()} ${term.toUpperCase()}',
                                                  style: const TextStyle(
                                                    color: Color(0xFFef4444),
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.5,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'PIECES',
                                                  style: TextStyle(
                                                    color: Color(0xFFef4444),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Do you want to confirm this discrepancy?',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF6366f1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Confirm',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirmed != true) return;
                              }

                              setDialogState(() => isSaving = true);
                              try {
                                String userFullName = 'Unknown User';
                                final uUser =
                                    Supabase.instance.client.auth.currentUser;
                                if (uUser != null) {
                                  userFullName =
                                      uUser.email?.split('@')[0] ??
                                      'Unknown User';
                                  try {
                                    final userRow = await Supabase
                                        .instance
                                        .client
                                        .from('users')
                                        .select('full-name')
                                        .eq('id', uUser.id)
                                        .maybeSingle();
                                    if (userRow != null &&
                                        userRow['full-name'] != null) {
                                      userFullName = userRow['full-name'];
                                    }
                                  } catch (_) {}
                                }
                                final timeStr = DateTime.now()
                                    .toUtc()
                                    .toIso8601String();

                                  Map<String, dynamic> coordData = {};
                                  coordData['refULD'] = uldOverride?['ULD-number']?.toString().toUpperCase() ?? '';
                                  coordData['user'] = userFullName;
                                  coordData['time'] = timeStr;

                                  await Supabase.instance.client
                                      .from('awb_splits')
                                      .update({'data_coordinator': coordData})
                                      .eq('id', awb['id_split']);
                                  
                                  awb['data-coordinator'] = coordData;
                                  if (dialogCtx.mounted) {

                                  Navigator.pop(dialogCtx, awb);
                                }
                              } catch (e) {
                                if (dialogCtx.mounted) {
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                                setDialogState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditMode ? 'Save' : 'Edit',
                              style: TextStyle(
                                color: isEditMode
                                    ? Colors.white
                                    : Colors.white.withAlpha(100),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

