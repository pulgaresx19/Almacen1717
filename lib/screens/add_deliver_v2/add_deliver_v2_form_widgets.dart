// ignore_for_file: invalid_use_of_protected_member
part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2FormWidgetsExt on AddDeliverV2ScreenState {
  Widget _buildTextField(String label, TextEditingController controller, bool dark, IconData? icon, {String hint = '', int? maxLen, bool uppercase = false, bool capitalizeWords = false, bool capitalizeFirst = false, Widget? suffixIcon, int? maxLines = 1, int? minLines, Function(String)? onChanged, bool readOnly = false}) {
    List<TextInputFormatter> formatters = [];
    if (maxLen != null) formatters.add(LengthLimitingTextInputFormatter(maxLen));
    if (uppercase) formatters.add(TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase())));
    if (capitalizeFirst) {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        var t = newValue.text;
        var res = t.substring(0, 1).toUpperCase() + (t.length > 1 ? t.substring(1).toLowerCase() : '');
        return newValue.copyWith(text: res);
      }));
    }
    if (capitalizeWords) {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        String t = newValue.text;
        String res = '';
        bool capNext = true;
        for (int i = 0; i < t.length; i++) {
          if (t[i] == ' ') {
            res += ' ';
            capNext = true;
          } else {
            res += capNext ? t[i].toUpperCase() : t[i].toLowerCase();
            capNext = false;
          }
        }
        return newValue.copyWith(text: res);
      }));
    }
    
    if (label == 'Pieces' || label == 'Total') {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }

    if (controller == _importPiecesCtrl) {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        final pcs = int.tryParse(newValue.text) ?? 0;
        final tot = int.tryParse(_importTotalCtrl.text) ?? 0;
        if (tot > 0 && pcs > tot) return oldValue;
        return newValue;
      }));
    }
    if (label == 'Weight') {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')));
    }
    
    if (label == 'AWB Number') {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        var text = newValue.text;
        text = text.replaceAll(RegExp(r'[^0-9]'), '');
        if (text.length > 11) text = text.substring(0, 11);

        var formatted = '';
        for (int i = 0; i < text.length; i++) {
          if (i == 3) formatted += '-';
          if (i == 7) formatted += ' ';
          formatted += text[i];
        }

        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }));
    }
    if (label == 'Time') {
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
        var oldText = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (text.length > 4) text = text.substring(0, 4);

        if (text.length > oldText.length) { // user is adding chars
          if (text.isNotEmpty) {
            int h1 = int.parse(text[0]);
            if (h1 > 2) {
              text = '0$text';
              if (text.length > 4) text = text.substring(0, 4);
            }
          }
          if (text.length >= 2) {
            int h = int.parse(text.substring(0, 2));
            if (h > 23) return oldValue;
          }
          if (text.length >= 3) {
            int m1 = int.parse(text[2]);
            if (m1 > 5) {
              text = '${text.substring(0, 2)}0${text[2]}';
              if (text.length > 4) text = text.substring(0, 4);
            }
          }
          if (text.length >= 4) {
            int m = int.parse(text.substring(2, 4));
            if (m > 59) return oldValue;
          }
        }

        var formatted = '';
        for (int i = 0; i < text.length; i++) {
          if (i == 2) formatted += ':';
          formatted += text[i];
        }

        int offset = formatted.length;
        if (newValue.selection.end < formatted.length && newValue.selection.end >= 0) {
          offset = newValue.selection.end;
          // Jump over colon if necessary
          if (offset == 2 && formatted.length > 2) offset = 3;
        }

        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: offset),
        );
      }));
    }

    bool isError = _missingField == label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isError ? Colors.redAccent : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563)), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: (val) {
            if (isError && val.trim().isNotEmpty) setState(() => _missingField = null);
            if (onChanged != null) onChanged(val);
          },
          readOnly: readOnly,
          keyboardType: label == 'Time' 
              ? TextInputType.datetime 
              : (label == 'Pieces' || label == 'Total' || label == 'Weight' 
                  ? TextInputType.number 
                  : (maxLines == null || maxLines > 1 ? TextInputType.multiline : TextInputType.text)),
          style: TextStyle(color: readOnly ? (dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)) : (dark ? Colors.white : const Color(0xFF111827)), fontSize: 13),
          inputFormatters: formatters.isNotEmpty ? formatters : null,
          textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: dark ? Colors.white.withAlpha(76) : Colors.black.withAlpha(76), fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, color: isError ? Colors.redAccent : (dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF)), size: 18) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isError ? Colors.redAccent.withAlpha(10) : (dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isError ? Colors.redAccent.withAlpha(150) : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)))),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isError ? Colors.redAccent.withAlpha(150) : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isError ? Colors.redAccent : (dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5)), width: 1.5),
            ),
          ),
        ),
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              appLanguage.value == 'es' ? 'Requerido' : 'Required',
              style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeDropdown(bool dark) {
    const types = ['Walk-in', 'Appointment', 'Transfer', 'Import', 'Priority Load'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _typeCtrl.text.isNotEmpty ? _typeCtrl.text : 'Walk-in',
          dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
          style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF)),
          decoration: InputDecoration(
            filled: true,
            fillColor: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dark ? const Color(0xFF6366f1) : const Color(0xFF4F46E5), width: 1.5),
            ),
          ),
          items: types.map((String val) {
            IconData iconData;
            switch (val) {
              case 'Walk-in': iconData = Icons.directions_walk_rounded; break;
              case 'Appointment': iconData = Icons.calendar_month_rounded; break;
              case 'Transfer': iconData = Icons.swap_horiz_rounded; break;
              case 'Import': iconData = Icons.move_to_inbox_rounded; break;
              case 'Priority Load': iconData = Icons.bolt_rounded; break;
              default: iconData = Icons.circle;
            }
            return DropdownMenuItem(
              value: val,
              child: Row(
                children: [
                  Icon(iconData, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), size: 16),
                  const SizedBox(width: 8),
                  Text(val),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                 _typeCtrl.text = val;
                 if (val == 'Appointment') {
                   if (_timeCtrl.text == 'NOW') _timeCtrl.clear();
                 } else {
                   if (_timeCtrl.text.isEmpty) _timeCtrl.text = 'NOW';
                 }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSelectedItemsSummary(bool dark) {
    final int selectedCount = _selectedAwbs.length + _selectedUlds.length;
    if (selectedCount == 0) {
      return Container(
         decoration: BoxDecoration(
           color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF3F4F6),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
         ),
         child: Center(
           child: Text(
             appLanguage.value == 'es' ? 'NingÃƒÂºn elemento seleccionado' : 'No items selected',
             style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
           )
         ),
       );
    }

    final List<Map<String, dynamic>> combinedList = [
       ..._selectedAwbs.map((e) => {'type': 'AWB', 'data': e}),
       ..._selectedUlds.map((e) => {'type': 'ULD', 'data': e}),
    ];

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1e293b) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366f1).withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF6366f1), size: 18),
                const SizedBox(width: 8),
                Text('$selectedCount ${appLanguage.value == 'es' ? 'Seleccionados' : 'Selected'}', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: combinedList.length,
              itemBuilder: (context, index) {
                final item = combinedList[index];
                final bool isAwb = item['type'] == 'AWB';
                final data = item['data'];
                final String itemNumber = isAwb ? (data['awb_number']?.toString() ?? data['AWB-number']?.toString() ?? 'Unknown') : (data['uld_number']?.toString() ?? data['ULD-number']?.toString() ?? 'Unknown');
                
                int remainingPieces = 0;
                if (isAwb) {
                   int receivedPieces = 0;
                   if (data['pieces_received'] != null) {
                      receivedPieces = int.tryParse(data['pieces_received'].toString()) ?? 0;
                   } else if (data['data-coordinator'] != null) {
                      List dcList = [];
                      if (data['data-coordinator'] is List) {
                        dcList = data['data-coordinator'] as List;
                      } else if (data['data-coordinator'] is Map && (data['data-coordinator'] as Map).isNotEmpty) {
                        dcList = [data['data-coordinator']];
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
                   if (data['pieces_delivered'] != null) {
                      deliveredPieces = int.tryParse(data['pieces_delivered'].toString()) ?? 0;
                   } else if (data['data-deliver'] != null) {
                      if (data['data-deliver'] is List) {
                         for (var d in data['data-deliver']) {
                            if (d is Map && d.containsKey('found')) {
                               deliveredPieces += int.tryParse(d['found']?.toString() ?? '0') ?? 0;
                            }
                         }
                      } else if (data['data-deliver'] is Map) {
                         deliveredPieces = int.tryParse(data['data-deliver']['found']?.toString() ?? '0') ?? 0;
                      }
                   }

                   int inProcessPieces = int.tryParse(data['pieces_in_process']?.toString() ?? '0') ?? 0;
                   remainingPieces = receivedPieces - deliveredPieces - inProcessPieces;
                   if (remainingPieces < 0) remainingPieces = 0;
                } else {
                   if (data['pieces_total'] != null) {
                      remainingPieces = int.tryParse(data['pieces_total'].toString()) ?? 0;
                   } else if (data['data-ULD'] is List) {
                      for (var d in (data['data-ULD'] as List)) {
                         if (d is Map) {
                            remainingPieces += int.tryParse(d['pieces']?.toString() ?? '0') ?? 0;
                         }
                      }
                   }
                }

                if (!_deliveryPcsControllers.containsKey(itemNumber)) {
                  _deliveryPcsControllers[itemNumber] = TextEditingController(text: remainingPieces.toString());
                }
                if (!_deliveryRemarkControllers.containsKey(itemNumber)) {
                  _deliveryRemarkControllers[itemNumber] = TextEditingController();
                }
                final pcsCtrl = _deliveryPcsControllers[itemNumber]!;
                final remCtrl = _deliveryRemarkControllers[itemNumber]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(10) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        margin: const EdgeInsets.only(right: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(6)),
                        child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(itemNumber, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      () {
                          bool isOverLimit = _overLimitErrors[itemNumber] == true;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 85,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: dark ? Colors.black26 : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isOverLimit 
                                        ? Colors.redAccent 
                                        : (dark ? Colors.white.withAlpha(30) : const Color(0xFFD1D5DB)),
                                    width: isOverLimit ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: isOverLimit ? Colors.redAccent.withAlpha(20) : (dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6)),
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                                        border: Border(right: BorderSide(color: isOverLimit ? Colors.redAccent.withAlpha(50) : (dark ? Colors.white.withAlpha(30) : const Color(0xFFD1D5DB)))),
                                      ),
                                      child: Tooltip(
                                        message: appLanguage.value == 'es' ? 'Piezas a entregar' : 'Pieces to deliver',
                                        child: Icon(Icons.local_shipping_rounded, size: 14, color: isOverLimit ? Colors.redAccent : (dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)))
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: pcsCtrl,
                                        readOnly: !isAwb,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val) ?? 0;
                                          setState(() {
                                            if (isAwb && parsed > remainingPieces) {
                                              _overLimitErrors[itemNumber] = true;
                                            } else {
                                              _overLimitErrors[itemNumber] = false;
                                            }
                                          });
                                        },
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: isOverLimit ? Colors.redAccent : (dark ? Colors.white : const Color(0xFF111827)), fontSize: 12, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOverLimit)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('Max: $remainingPieces', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          );
                        }(),
                      Expanded(
                        flex: 9,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: dark ? Colors.black26 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: dark ? Colors.white.withAlpha(30) : const Color(0xFFD1D5DB)),
                            ),
                            child: TextField(
                              controller: remCtrl,
                              style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Remarks...',
                                hintStyle: TextStyle(color: dark ? Colors.white.withAlpha(90) : const Color(0xFF9CA3AF), fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        tooltip: 'Remove',
                        onPressed: () {
                          setState(() {
                             if (isAwb) {
                               _selectedAwbs.removeWhere((e) => (e['awb_number']?.toString() ?? e['AWB-number']?.toString()) == itemNumber);
                             } else {
                               _selectedUlds.removeWhere((e) => (e['uld_number']?.toString() ?? e['ULD-number']?.toString()) == itemNumber);
                             }
                             _deliveryPcsControllers.remove(itemNumber)?.dispose();
                             _deliveryRemarkControllers.remove(itemNumber)?.dispose();
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('pending') || s.contains('pendiente')) {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (s.contains('in progress') || s.contains('proceso') || s.contains('process') || s.contains('received')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('ready') || s.contains('listo') || s.contains('completed')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('checked')){
      bg = const Color(0xFF4c1d95).withAlpha(51); fg = const Color(0xFFc4b5fd);
    }

    return Container(
      width: 80,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status, 
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
