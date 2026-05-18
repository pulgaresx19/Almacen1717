// ignore_for_file: invalid_use_of_protected_member
part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2AwbSelectorExt on AddDeliverV2ScreenState {
  Widget _buildAwbSelector(bool dark) {
    if (_isLoadingAwbs) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
    }
    if (_allAwbs.isEmpty) {
      return Center(
        child: Text(
          appLanguage.value == 'es' ? 'No hay AWBs disponibles' : 'No AWBs available',
          style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
        ),
      );
    }
    
    var filteredAwbs = _allAwbs.where((awb) {
      int deliveredPieces = 0;
      if (awb['pieces_delivered'] != null) {
        deliveredPieces = int.tryParse(awb['pieces_delivered'].toString()) ?? 0;
      } else if (awb['data-deliver'] != null) {
        if (awb['data-deliver'] is List) {
          for (var item in awb['data-deliver']) {
            if (item is Map && item.containsKey('found')) {
              deliveredPieces += int.tryParse(item['found']?.toString() ?? '0') ?? 0;
            }
          }
        } else if (awb['data-deliver'] is Map) {
          deliveredPieces = int.tryParse(awb['data-deliver']['found']?.toString() ?? '0') ?? 0;
        }
      }
      
      final int expectedPieces = int.tryParse(awb['total_espected']?.toString() ?? awb['total']?.toString() ?? '0') ?? 0;
      
      if (deliveredPieces >= expectedPieces && expectedPieces > 0) {
        return false;
      }
      
      if (_searchAwbCtrl.text.isNotEmpty) {
        final term = _searchAwbCtrl.text.toLowerCase();
        final awbNumber = (awb['awb_number']?.toString() ?? awb['AWB-number']?.toString() ?? '').toLowerCase();
        if (!awbNumber.contains(term)) return false;
      }
      
      return true;
    }).toList();
    
    Map<String, int> getAwbCounts(Map<String, dynamic> awb) {
      return DeliveryMathLogic.calculateAwbMetrics(awb);
    }

    String getAwbStatus(Map<String, dynamic> awb, Map<String, int> counts) {
      String status = awb['status']?.toString() ?? '';
      if (status.isNotEmpty) return status;
      int receivedPieces = counts['checked']!;
      int deliveredPieces = counts['delivered']!;
      final int totalValInt = counts['expected']!;
      if (deliveredPieces >= totalValInt && totalValInt > 0) return 'Delivered';
      if (deliveredPieces > 0) return 'In Process';
      if (receivedPieces > 0) return 'Received';
      return 'Waiting';
    }

    int getStatusPriority(String status) {
      final s = status.toLowerCase();
      if (s.contains('deliver') || s.contains('ready') || s.contains('saved')) return 1;
      if (s.contains('process') || s.contains('progress')) return 2;
      if (s == 'checked') return 3;
      if (s == 'checking') return 4;
      if (s == 'received') return 5;
      if (s == 'receiving') return 6;
      if (s.contains('waiting') || s.contains('pending')) return 7;
      return 8;
    }

    filteredAwbs.sort((a, b) {
      final countsA = getAwbCounts(a);
      final countsB = getAwbCounts(b);
      
      int rA = countsA['remaining']!;
      int rB = countsB['remaining']!;
      
      if (rA == 0 && rB > 0) return 1;
      if (rA > 0 && rB == 0) return -1;
      
      String statusA = getAwbStatus(a, countsA);
      String statusB = getAwbStatus(b, countsB);
      
      int pA = getStatusPriority(statusA);
      int pB = getStatusPriority(statusB);
      
      if (pA != pB) return pA.compareTo(pB);
      
      String numA = (a['awb_number']?.toString() ?? a['AWB-number']?.toString() ?? '').toLowerCase();
      String numB = (b['awb_number']?.toString() ?? b['AWB-number']?.toString() ?? '').toLowerCase();
      return numA.compareTo(numB);
    });
    
    final isImport = _typeCtrl.text == 'Import';

    return Container(
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: DataTable(
                    showCheckboxColumn: false,
                    checkboxHorizontalMargin: 12,
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 44,
                    headingRowHeight: 40,
                    headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                       if (states.contains(WidgetState.disabled)) return dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5);
                       if (states.contains(WidgetState.selected)) return const Color(0xFF6366f1).withAlpha(40);
                       if (states.contains(WidgetState.hovered)) return dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6);
                       return Colors.transparent;
                    }),
                    dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12),
                    headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 11),
                    columns: [
                      const DataColumn(label: Text('#')),
                      const DataColumn(label: Text('AWB Number')),
                      const DataColumn(label: Text('Remaining Pcs')),
                      const DataColumn(label: Text('Total Pieces')),
                      const DataColumn(label: Text('Total Weight')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('')),
                    ],
                    rows: List.generate(filteredAwbs.length, (index) {
                      final awb = filteredAwbs[index];
                      final String awbNumber = awb['awb_number']?.toString() ?? awb['AWB-number']?.toString() ?? 'Unknown';
                      final bool isSelected = _selectedAwbs.any((item) => (item['awb_number']?.toString() ?? item['AWB-number']?.toString()) == awbNumber);

                      int expectedPieces = 0;
                      double totalWeight = 0.0;
                      
                      if (awb['total_espected'] != null) {
                         expectedPieces = int.tryParse(awb['total_espected'].toString()) ?? 0;
                         totalWeight = double.tryParse(awb['total_weight']?.toString() ?? '0') ?? 0.0;
                      } else {
                         // Fallback for legacy
                        if (awb['data-AWB'] is List) {
                          for (var item in awb['data-AWB']) {
                             expectedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
                             totalWeight += double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
                          }
                        } else if (awb['data-AWB'] is Map) {
                             expectedPieces += int.tryParse(awb['data-AWB']['pieces']?.toString() ?? '0') ?? 0;
                             totalWeight += double.tryParse(awb['data-AWB']['weight']?.toString() ?? '0') ?? 0.0;
                        }
                      }

                      final counts = getAwbCounts(awb);
                      int receivedPieces = counts['checked']!;
                      int deliveredPieces = counts['delivered']!;
                      int inProcess = counts['in_process']!;
                      int remainingPieces = counts['remaining']!;
                      
                      final int totalValInt = counts['expected']!;
                      
                      String status = awb['status']?.toString() ?? '';
                      if (status.isEmpty) {
                        status = 'Waiting';
                        if (deliveredPieces >= totalValInt && totalValInt > 0) {
                           status = 'Delivered';
                        } else if (deliveredPieces > 0) {
                           status = 'In Process';
                        } else if (receivedPieces > 0) {
                           status = 'Received';
                        }
                      }

                      return DataRow(
                        selected: !isImport && isSelected,
                        onSelectChanged: (isImport || remainingPieces == 0 || status.toLowerCase() == 'waiting' || status.toLowerCase() == 'pending') ? null : (val) {
                          if (val == true) {
                            List<Map<String, dynamic>> noBreakUlds = [];
                            int noBreakPieces = 0;
                            
                            if (awb['awb_splits'] != null) {
                              for (var split in awb['awb_splits']) {
                                if (split['ulds'] != null && (split['ulds']['is_break'] == false || split['ulds']['is_break'] == 0 || split['ulds']['is_break'] == 'false')) {
                                  if (split['ulds']['time_received'] != null) {
                                    int p = 0;
                                    if (split['total_checked'] != null && (int.tryParse(split['total_checked'].toString()) ?? 0) > 0) {
                                      p = int.tryParse(split['total_checked'].toString()) ?? 0;
                                    } else {
                                      p = int.tryParse(split['pieces']?.toString() ?? '0') ?? 0;
                                    }
                                    if (p > 0) {
                                      noBreakPieces += p;
                                      if (!noBreakUlds.any((u) => u['id_uld'] == (split['uld_id'] ?? split['id_uld']))) {
                                        final fullUld = _allUlds.firstWhere(
                                          (u) => u['id_uld'] == (split['uld_id'] ?? split['id_uld']), 
                                          orElse: () => Map<String, dynamic>.from(split['ulds'])
                                        );
                                        noBreakUlds.add(fullUld);
                                      }
                                    }
                                  }
                                }
                              }
                            }
                            
                            if (noBreakPieces > 0) {
                              int loosePieces = remainingPieces - noBreakPieces;
                              if (loosePieces < 0) loosePieces = 0;
                              
                              String title = 'NO BREAK ULD Detected';
                              String msg = '';
                              if (loosePieces == 0) {
                                msg = 'This AWB is fully consolidated inside NO BREAK ULDs. To process the delivery, the ULDs will be added automatically instead of the loose pieces.';
                              } else {
                                msg = 'This AWB has $noBreakPieces pieces inside NO BREAK ULDs and $loosePieces loose pieces. The NO BREAK ULDs will be added to the delivery list, and this AWB will remain enabled for the $loosePieces loose pieces only.';
                              }
                              
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    width: 320,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0xFF1e293b) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.amber.withAlpha(200), width: 2),
                                      boxShadow: [
                                        BoxShadow(color: Colors.amber.withAlpha(80), blurRadius: 20, spreadRadius: 2),
                                      ]
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: Colors.amber.withAlpha(20), shape: BoxShape.circle),
                                          child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(title, textAlign: TextAlign.center, style: TextStyle(color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                                        const SizedBox(height: 12),
                                        Text(msg, textAlign: TextAlign.center, style: TextStyle(color: dark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.4)),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: Text('Cancel', style: TextStyle(color: dark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.amber,
                                                foregroundColor: Colors.black87,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                setState(() {
                                                  for (var u in noBreakUlds) {
                                                    if (!_selectedUlds.any((sel) => sel['id_uld'] == u['id_uld'])) {
                                                      _selectedUlds.add(u);
                                                    }
                                                  }
                                                  if (loosePieces > 0) {
                                                    _selectedAwbs.add(awb);
                                                  }
                                                });
                                              },
                                              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _selectedAwbs.add(awb);
                            });
                          } else {
                            setState(() {
                              _selectedAwbs.removeWhere((item) => (item['awb_number']?.toString() ?? item['AWB-number']?.toString()) == awbNumber);
                              _deliveryPcsControllers[awbNumber]?.dispose();
                              _deliveryPcsControllers.remove(awbNumber);
                              _deliveryRemarkControllers[awbNumber]?.dispose();
                              _deliveryRemarkControllers.remove(awbNumber);
                            });
                          }
                        },
                        cells: [
                          DataCell(Text('${index + 1}', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600))),
                          DataCell(Text(awbNumber, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text('$remainingPieces pcs', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366f1))),
                          )),
                          DataCell(Text('${totalValInt > 0 ? totalValInt : expectedPieces} pcs')),
                          DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\.$|\.0$'), '')} kg')),
                          DataCell(_buildStatusBadge(status)),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(Icons.info_outline_rounded, color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), size: 16),
                                onPressed: () => _showAwbDrawer(context, awb, dark, receivedPieces, counts['expected']!, deliveredPieces, inProcess, remainingPieces, totalValInt, status, counts['on_hold']!),
                                tooltip: 'Ver Info',
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
