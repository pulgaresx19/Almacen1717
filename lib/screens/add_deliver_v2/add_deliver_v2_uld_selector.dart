// ignore_for_file: invalid_use_of_protected_member
part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2UldSelectorExt on AddDeliverV2ScreenState {
  Widget _buildUldSelector(bool dark) {
    if (_isLoadingUlds) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
    }
    
    var filteredUlds = _allUlds.where((uld) {
      final status = uld['status']?.toString() ?? 'Received';
      if (status == 'Delivered' || status == 'Canceled') return false;
      if (uld['is_break'] == true) return false;
      
      if (_searchAwbCtrl.text.isNotEmpty) {
        final term = _searchAwbCtrl.text.toLowerCase();
        final uNum = (uld['uld_number']?.toString() ?? uld['ULD-number']?.toString() ?? '').toLowerCase();
        if (!uNum.contains(term)) return false;
      }
      return true;
    }).toList();

    filteredUlds.sort((a, b) {
      int getPriority(Map<String, dynamic> u) {
        final s = u['status']?.toString() ?? 'Received';
        if (u['in_process'] == true) return 2;
        if (s == 'Received') return 1;
        if (s == 'Waiting') return 3;
        return 4;
      }
      return getPriority(a).compareTo(getPriority(b));
    });

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
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('ULD Number')),
                      DataColumn(label: Text('Total Pieces')),
                      DataColumn(label: Text('Total Weight')),
                      DataColumn(label: Text('Flight')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('')),
                    ],
                    rows: List.generate(filteredUlds.length, (index) {
                      final uld = filteredUlds[index];
                      final String uldNum = uld['uld_number']?.toString() ?? uld['ULD-number']?.toString() ?? 'Unknown';
                      final bool isSelected = _selectedUlds.any((item) => (item['uld_number']?.toString() ?? item['ULD-number']?.toString()) == uldNum);

                      int totalPieces = 0;
                      if (uld['pieces_total'] != null) {
                        totalPieces = int.tryParse(uld['pieces_total'].toString()) ?? 0;
                      } else if (uld['data-ULD'] is List) {
                         for (var d in (uld['data-ULD'] as List)) {
                            if (d is Map) {
                               totalPieces += int.tryParse(d['pieces']?.toString() ?? '0') ?? 0;
                            }
                         }
                      }

                      String flightStr = '-';
                      if (uld['flights'] != null && uld['flights'] is Map) {
                         final f = uld['flights'];
                         final carrier = f['carrier']?.toString() ?? '';
                         final flightNum = f['number']?.toString() ?? '';
                         final flightDateStr = f['date']?.toString() ?? '';
                         if (carrier.isNotEmpty || flightNum.isNotEmpty) {
                            flightStr = '$carrier$flightNum';
                            if (flightDateStr.isNotEmpty) {
                                try {
                                  final d = DateTime.parse(flightDateStr);
                                  flightStr += ' ${DateFormat('MMM dd').format(d)}';
                                } catch (_) {}
                            }
                         }
                      } else {
                        final carrier = uld['refCarrier']?.toString() ?? '';
                        final flightNum = uld['refNumber']?.toString() ?? '';
                        final flightDateStr = uld['refDate']?.toString() ?? '';
                        
                        if (carrier.isNotEmpty || flightNum.isNotEmpty) {
                           flightStr = '$carrier$flightNum';
                           if (flightDateStr.isNotEmpty) {
                               try {
                                 final d = DateTime.parse(flightDateStr);
                                 flightStr += ' ${DateFormat('MMM dd').format(d)}';
                               } catch (_) {}
                           }
                        }
                      }


                      final String rawStatus = uld['status']?.toString() ?? 'Received';
                      final bool isInProcess = uld['in_process'] == true;
                      final String displayStatus = isInProcess ? 'In Process' : rawStatus;
                      final bool isSelectable = !isInProcess && rawStatus != 'Waiting';

                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: isSelectable ? (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUlds.add(uld);
                              if (!_deliveryPcsControllers.containsKey(uldNum)) {
                                _deliveryPcsControllers[uldNum] = TextEditingController(text: totalPieces.toString());
                                _deliveryRemarkControllers[uldNum] = TextEditingController();
                              }
                            } else {
                              _selectedUlds.removeWhere((item) => (item['uld_number']?.toString() ?? item['ULD-number']?.toString()) == uldNum);
                              _deliveryPcsControllers.remove(uldNum)?.dispose();
                              _deliveryRemarkControllers.remove(uldNum)?.dispose();
                            }
                          });
                        } : null,
                        cells: [
                          DataCell(Text('${index + 1}', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontWeight: FontWeight.w600))),
                          DataCell(Text(uldNum, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold))),
                          DataCell(Text('$totalPieces pcs')),
                          DataCell(Text('${uld['weight_total']?.toString() ?? uld['weight']?.toString() ?? '0'} kg', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366f1)))),
                          DataCell(Text(flightStr.trim() == '' ? '-' : flightStr, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(_buildStatusBadge(displayStatus)),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(Icons.info_outline_rounded, color: dark ? const Color(0xFF64748b) : const Color(0xFF9ca3af), size: 16),
                                onPressed: () => _showUldDrawer(context, uld, dark),
                                tooltip: 'View Info',
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
