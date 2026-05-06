// ignore_for_file: invalid_use_of_protected_member
part of 'add_deliver_v2_screen.dart';

extension AddDeliverV2ImportPaneExt on AddDeliverV2ScreenState {
  Widget _buildImportAwbRightPane(bool dark, Color textP, Color textS, Color borderC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
             decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
             ),
             child: _importAwbs.isEmpty
                ? Center(child: Text(appLanguage.value == 'es' ? 'NingÃºn AWB de importaciÃ³n aÃ±adido' : 'No imported AWBs added', style: TextStyle(color: textS)))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF6366f1), size: 18),
                            const SizedBox(width: 8),
                            Text('${_importAwbs.length} ${appLanguage.value == 'es' ? 'AÃ±adidos' : 'Added'}', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB)),
                      Expanded(
                        child: ListView.builder(
                           padding: const EdgeInsets.all(8),
                           itemCount: _importAwbs.length,
                           itemBuilder: (ctx, idx) {
                               final awb = _importAwbs[idx];
                               final String awbNum = awb['awbNumber'];
                               final bool isExpanded = _expandedImports.contains(awbNum);
                               final isUld = awb['type'] == 'ULD';

                               return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                           Container(
                                             width: 20, height: 20,
                                             margin: const EdgeInsets.only(right: 8),
                                             alignment: Alignment.center,
                                             decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(40), shape: BoxShape.circle),
                                             child: Icon(isUld ? Icons.pallet : Icons.airplanemode_active, color: const Color(0xFF818cf8), size: 12),
                                           ),
                                           Expanded(
                                             flex: 5,
                                             child: Text(awb['awbNumber'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 13)),
                                           ),
                                           Expanded(
                                             flex: 3,
                                             child: Text('Pcs: ${awb['pieces']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                                           ),
                                           Expanded(
                                             flex: 3,
                                             child: Text(isUld ? 'ULD' : 'Tot: ${awb['total']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                                           ),
                                           Expanded(
                                             flex: 4,
                                             child: Text('Wgt: ${awb['weight'].toString().replaceAll(RegExp(r'\.$|\.0$'), '')}kg', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
                                           ),
                                           const SizedBox(width: 4),
                                           IconButton(
                                             constraints: const BoxConstraints(),
                                             padding: EdgeInsets.zero,
                                             icon: Icon(isExpanded ? Icons.visibility_off : Icons.visibility, size: 18, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280)),
                                             onPressed: () {
                                               setState(() {
                                                 if (isExpanded) {
                                                   _expandedImports.remove(awbNum);
                                                 } else {
                                                   _expandedImports.add(awbNum);
                                                 }
                                               });
                                             },
                                           ),
                                           const SizedBox(width: 8),
                                           IconButton(
                                             constraints: const BoxConstraints(),
                                             padding: EdgeInsets.zero,
                                             icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                                             onPressed: () => setState(() => _importAwbs.removeAt(idx)),
                                           ),
                                        ]
                                      ),
                                      if (isExpanded) ...[
                                        const SizedBox(height: 8),
                                        Divider(height: 1, color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(isUld ? 'Is Break?' : 'House Number', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text(isUld 
                                                    ? (awb['is_break'] == true ? 'Yes' : 'No') 
                                                    : ((awb['house'] as List?)?.isEmpty ?? true ? 'N/A' : (awb['house'] as List).join('\n')), 
                                                    style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 12)
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Remarks', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text(awb['remarks'] ?? 'N/A', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  )
                               );
                            }
                        )
                      )
                    ]
                  )
          )
        ),
        const SizedBox(height: 16),
        Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(color: dark ? const Color(0xFF1e293b) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB))),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
                Row(
                  children: [
                     GestureDetector(
                       onTap: () {
                         setState(() {
                           _isImportUld = false;
                           _importAwbNumberCtrl.clear();
                           _importPiecesCtrl.clear();
                           _importTotalCtrl.clear();
                           _importWeightCtrl.clear();
                           _importHouseCtrl.clear();
                           _importRemarksCtrl.clear();
                           _importTotalLocked = false;
                           _importAwbError = false;
                           _importPiecesError = false;
                           _importTotalError = false;
                           _importUldExistsError = false;
                           _importExceedsRemainingError = false;
                           _importAwbRemainingPieces = null;
                           _importTotalLessThanPiecesError = false;
                           _importExistsInListError = false;
                         });
                       },
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                         decoration: BoxDecoration(
                            color: !_isImportUld ? const Color(0xFF6366f1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text('AWB', style: TextStyle(color: !_isImportUld ? Colors.white : textS, fontWeight: FontWeight.bold, fontSize: 12)),
                       ),
                     ),
                     const SizedBox(width: 8),
                     GestureDetector(
                       onTap: () {
                         setState(() {
                           _isImportUld = true;
                           _importAwbNumberCtrl.clear();
                           _importPiecesCtrl.clear();
                           _importTotalCtrl.clear();
                           _importWeightCtrl.clear();
                           _importHouseCtrl.clear();
                           _importRemarksCtrl.clear();
                           _importTotalLocked = false;
                           _importAwbError = false;
                           _importPiecesError = false;
                           _importTotalError = false;
                           _importUldExistsError = false;
                           _importExceedsRemainingError = false;
                           _importAwbRemainingPieces = null;
                           _importTotalLessThanPiecesError = false;
                           _importExistsInListError = false;
                         });
                       },
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                         decoration: BoxDecoration(
                            color: _isImportUld ? const Color(0xFF6366f1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text('ULD', style: TextStyle(color: _isImportUld ? Colors.white : textS, fontWeight: FontWeight.bold, fontSize: 12)),
                       ),
                     ),
                     const Spacer(),
                     if (_importUldExistsError)
                       Text(
                         appLanguage.value == 'es' ? 'El ULD ya existe' : 'ULD already exists',
                         style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                       )
                     else if (_importAwbRemainingPieces != null)
                       Text(
                         appLanguage.value == 'es' ? 'Restantes: $_importAwbRemainingPieces' : 'Remaining: $_importAwbRemainingPieces',
                         style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold),
                       )
                     else if (_importExceedsRemainingError)
                       Text(
                         appLanguage.value == 'es' ? 'El AWB ya existe' : 'AWB already exists',
                         style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                       )
                     else if (_importExistsInListError)
                       Text(
                         appLanguage.value == 'es' ? 'Ya añadido en la lista local' : 'Already in local list',
                         style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                       )
                     else if (_importTotalLessThanPiecesError)
                       Text(
                         appLanguage.value == 'es' ? 'Total no puede ser menor a Pieces' : 'Total cannot be less than Pieces',
                         style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                       ),
                  ]
                ),
                const SizedBox(height: 16),
                Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     if (!_isImportUld)
                       SizedBox(width: 150, child: _buildTextField('AWB Number', _importAwbNumberCtrl, dark, null, hint: '123-4567 8910', forceError: _importAwbError || _importExceedsRemainingError || _importExistsInListError, onChanged: (val) {
                         if (_importAwbError && val.trim().isNotEmpty) setState(() => _importAwbError = false);
                         if (_importExceedsRemainingError) setState(() => _importExceedsRemainingError = false);
                         if (_importExistsInListError) setState(() => _importExistsInListError = false);
                         
                         var pureDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
                         if (pureDigits.length == 11) {
                           final text = val.trim().toUpperCase();
                           
                           // Check if it already exists in the local list
                           if (_importAwbs.any((e) => e['type'] == 'AWB' && e['awbNumber'] == text)) {
                             setState(() {
                               _importExistsInListError = true;
                               _importAwbRemainingPieces = null;
                             });
                             return;
                           }

                           () async {
                             try {
                               final res = await Supabase.instance.client.from('awbs').select('*').eq('awb_number', text).maybeSingle();
                               if (res != null && _importAwbNumberCtrl.text.toUpperCase() == text) {
                                 final int totalPieces = int.tryParse(res['total_pieces']?.toString() ?? '0') ?? 0;
                                 final int totalExpected = int.tryParse(res['total_expected']?.toString() ?? res['total_espected']?.toString() ?? '0') ?? 0;
                                 int remaining = totalPieces - totalExpected;
                                 if (remaining < 0) remaining = 0;

                                 if (mounted) {
                                    setState(() {
                                       if (res['total_pieces'] != null) {
                                         _importTotalLocked = true;
                                         _importTotalCtrl.text = res['total_pieces'].toString();
                                         _importTotalError = false;
                                       }
                                       if (remaining == 0) {
                                         _importExceedsRemainingError = true;
                                         _importAwbRemainingPieces = null;
                                       } else {
                                         _importAwbRemainingPieces = remaining;
                                         _importExceedsRemainingError = false;
                                         
                                         // Update pieces if it exceeds remaining
                                         final int currentPcs = int.tryParse(_importPiecesCtrl.text) ?? 0;
                                         if (currentPcs > remaining) {
                                           _importPiecesCtrl.text = remaining.toString();
                                         }
                                       }
                                    });
                                 }
                               } else {
                                 if (mounted) {
                                   setState(() {
                                     _importAwbRemainingPieces = null;
                                   });
                                 }
                               }
                             } catch (_) {
                               if (mounted) {
                                 setState(() {
                                   _importAwbRemainingPieces = null;
                                 });
                               }
                             }
                           }();
                         } else {
                           if (_importTotalLocked || _importAwbRemainingPieces != null || _importExceedsRemainingError || _importExistsInListError) {
                             setState(() {
                               _importTotalLocked = false;
                               _importTotalCtrl.clear();
                               _importAwbRemainingPieces = null;
                               _importExceedsRemainingError = false;
                               _importExistsInListError = false;
                             });
                           }
                         }
                       }))
                     else
                       SizedBox(width: 150, child: _buildTextField('ULD Number', _importAwbNumberCtrl, dark, null, hint: 'PMC12345BA', uppercase: true, maxLen: 10, forceError: _importAwbError || _importUldExistsError || _importExistsInListError, onChanged: (val) {
                         if (_importAwbError && val.trim().isNotEmpty) setState(() => _importAwbError = false);
                         if (_importExistsInListError) setState(() => _importExistsInListError = false);
                         
                         final text = val.trim().toUpperCase();
                         if (text.length == 10) {
                           // Check if it already exists in the local list
                           if (_importAwbs.any((e) => e['type'] == 'ULD' && e['awbNumber'] == text)) {
                             setState(() {
                               _importExistsInListError = true;
                             });
                             return;
                           }

                           () async {
                             try {
                               final existingUld = await Supabase.instance.client.from('ulds').select('uld_number').eq('uld_number', text).maybeSingle();
                               if (existingUld != null && _importAwbNumberCtrl.text.trim().toUpperCase() == text) {
                                 if (mounted) {
                                   setState(() {
                                     _importUldExistsError = true;
                                   });
                                 }
                               } else {
                                 if (_importUldExistsError && mounted) setState(() => _importUldExistsError = false);
                               }
                             } catch (_) {}
                           }();
                         } else {
                           if (_importUldExistsError) setState(() => _importUldExistsError = false);
                           if (_importExistsInListError) setState(() => _importExistsInListError = false);
                         }
                       })),
                     
                     const SizedBox(width: 8),
                     SizedBox(width: 80, child: _buildTextField('Pieces', _importPiecesCtrl, dark, null, hint: '0', forceError: _importPiecesError || _importTotalLessThanPiecesError, onChanged: (val) {
                       if (_importPiecesError && val.trim().isNotEmpty) setState(() => _importPiecesError = false);
                       if (_importTotalLessThanPiecesError) setState(() => _importTotalLessThanPiecesError = false);
                       
                       // Check if it exceeds remaining pieces
                       if (_importAwbRemainingPieces != null) {
                         final int currentPcs = int.tryParse(val) ?? 0;
                         if (currentPcs > _importAwbRemainingPieces!) {
                           setState(() {
                             _importExceedsRemainingError = true;
                           });
                         } else {
                           if (_importExceedsRemainingError) setState(() => _importExceedsRemainingError = false);
                         }
                       }
                     })),
                     const SizedBox(width: 8),
                     if (!_isImportUld) ...[
                       SizedBox(width: 80, child: _buildTextField('Total', _importTotalCtrl, dark, null, hint: '0', readOnly: _importTotalLocked, forceError: _importTotalError || _importTotalLessThanPiecesError, onChanged: (val) {
                         if (_importTotalError && val.trim().isNotEmpty) setState(() => _importTotalError = false);
                         if (_importTotalLessThanPiecesError) setState(() => _importTotalLessThanPiecesError = false);
                       })),
                       const SizedBox(width: 8),
                     ],
                     SizedBox(width: 80, child: _buildTextField('Weight', _importWeightCtrl, dark, null, hint: '0')),
                     const SizedBox(width: 8),
                     
                     if (!_isImportUld)
                        Expanded(child: _buildTextField('House No.', _importHouseCtrl, dark, null, hint: 'HAWB', maxLines: 3, minLines: 1, uppercase: true))
                      else
                        Expanded(child: _buildTextField('Remarks', _importRemarksCtrl, dark, null, hint: 'Remarks', capitalizeFirst: true)),
                   ]
                ),
                const SizedBox(height: 12),
                Row(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     if (!_isImportUld)
                       Expanded(child: _buildTextField('Remarks', _importRemarksCtrl, dark, null, hint: 'Remarks', capitalizeFirst: true))
                     else
                       SizedBox(
                         width: 150,
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Is Break?', style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 4),
                             Container(
                               height: 48,
                               decoration: BoxDecoration(
                                 color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB))
                               ),
                               child: Row(
                                 children: [
                                   Expanded(
                                     child: GestureDetector(
                                       onTap: () => setState(() => _importIsBreak = false),
                                       child: Container(
                                         color: Colors.transparent,
                                         child: Row(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                             Icon(!_importIsBreak ? Icons.radio_button_checked : Icons.radio_button_off, color: !_importIsBreak ? const Color(0xFF6366f1) : textS, size: 16),
                                             const SizedBox(width: 4),
                                             Text('No', style: TextStyle(color: !_importIsBreak ? textP : textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                           ]
                                         )
                                       )
                                     )
                                   ),
                                   Expanded(
                                     child: GestureDetector(
                                       onTap: () => setState(() => _importIsBreak = true),
                                       child: Container(
                                         color: Colors.transparent,
                                         child: Row(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                             Icon(_importIsBreak ? Icons.radio_button_checked : Icons.radio_button_off, color: _importIsBreak ? const Color(0xFF6366f1) : textS, size: 16),
                                             const SizedBox(width: 4),
                                             Text('Yes', style: TextStyle(color: _importIsBreak ? textP : textS, fontSize: 12, fontWeight: FontWeight.bold)),
                                           ]
                                         )
                                       )
                                     )
                                   )
                                 ]
                               )
                             )
                           ]
                         )
                       ),
                     if (!_isImportUld) const SizedBox(width: 16) else const Spacer(),
                     SizedBox(
                       height: 48,
                       width: 140,
                       child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15),
                            foregroundColor: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5),
                            elevation: 0,
                            side: BorderSide(color: dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: _addImportAwb,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: Text(_isImportUld ? 'Add ULD' : 'Add AWB', style: const TextStyle(fontWeight: FontWeight.bold)),
                       ),
                     ),
                   ]
                ),
             ]
           )
        )
      ]
    );
  }

  
}
