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
                       if (states.contains(WidgetState.selected)) return const Color(0xFF6366f1).withAlpha(40);
                       if (states.contains(WidgetState.hovered)) return dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6);
                       return Colors.transparent;
                    }),
                    dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12),
                    headingTextStyle: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 11),
                    columns: [
                      const DataColumn(label: Text('#')),
                      const DataColumn(label: Text('AWB Number')),
                      const DataColumn(label: Text('Expected')),
                      const DataColumn(label: Text('Received')),
                      const DataColumn(label: Text('Delivered')),
                      const DataColumn(label: Text('Remaining')),
                      const DataColumn(label: Text('Total')),
                      const DataColumn(label: Text('Weight')),
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

                      int receivedPieces = 0;
                      if (awb['pieces_received'] != null) {
                        receivedPieces = int.tryParse(awb['pieces_received'].toString()) ?? 0;
                      } else if (awb['data-coordinator'] != null) {
                        List dcList = [];
                        if (awb['data-coordinator'] is List) {
                          dcList = awb['data-coordinator'] as List;
                        } else if (awb['data-coordinator'] is Map && (awb['data-coordinator'] as Map).isNotEmpty) {
                          dcList = [awb['data-coordinator']];
                        }
                        
                        for (var item in dcList) {
                           if (item is Map) {
                              if (item.containsKey('breakdown') && item['breakdown'] is Map) {
                                 Map breakdown = item['breakdown'];
                                 if (breakdown['AGI Skid'] is List) {
                                    for (var val in breakdown['AGI Skid']) {
                                       receivedPieces += int.tryParse(val.toString()) ?? 0;
                                    }
                                 }
                                 for (String k in ['Pre Skid', 'Crate', 'Box', 'Other']) {
                                    receivedPieces += int.tryParse(breakdown[k]?.toString() ?? '0') ?? 0;
                                 }
                              } else {
                                 receivedPieces += int.tryParse(item['pieces']?.toString() ?? '0') ?? 0;
                              }
                           }
                        }
                      }

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

                      int remainingPieces = 0;
                      if (awb['pieces_remaining'] != null) {
                        remainingPieces = int.tryParse(awb['pieces_remaining'].toString()) ?? 0;
                      } else {
                        remainingPieces = expectedPieces - deliveredPieces;
                        if (remainingPieces < 0) remainingPieces = 0;
                      }
                      
                      final int totalValInt = int.tryParse(awb['total_pieces']?.toString() ?? awb['total']?.toString() ?? '0') ?? 0;
                      
                      String status = 'Waiting';
                      if (deliveredPieces >= totalValInt && totalValInt > 0) {
                         status = 'Delivered';
                      } else if (deliveredPieces > 0) {
                         status = 'In Process';
                      } else if (receivedPieces > 0) {
                         status = 'Received';
                      }

                      return DataRow(
                        selected: !isImport && isSelected,
                        onSelectChanged: isImport ? null : (val) {
                          setState(() {
                            if (val == true) {
                              _selectedAwbs.add(awb);
                            } else {
                              _selectedAwbs.removeWhere((item) => (item['awb_number']?.toString() ?? item['AWB-number']?.toString()) == awbNumber);
                              _deliveryPcsControllers[awbNumber]?.dispose();
                              _deliveryPcsControllers.remove(awbNumber);
                              _deliveryRemarkControllers[awbNumber]?.dispose();
                              _deliveryRemarkControllers.remove(awbNumber);
                            }
                          });
                        },
                        cells: [
                          DataCell(Text('${index + 1}', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600))),
                          DataCell(Text(awbNumber, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                          DataCell(Text('$expectedPieces pcs')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text('$receivedPieces pcs', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.amber)),
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text('$deliveredPieces pcs', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10b981))),
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text('$remainingPieces pcs', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366f1))),
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text('$totalValInt pcs', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                          )),
                          DataCell(Text('${totalWeight.toString().replaceAll(RegExp(r'\.$|\.0$'), '')} kg')),
                          DataCell(_buildStatusBadge(status)),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(Icons.info_outline_rounded, color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), size: 16),
                                onPressed: () => _showAwbDrawer(context, awb, dark, receivedPieces, expectedPieces, status),
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
