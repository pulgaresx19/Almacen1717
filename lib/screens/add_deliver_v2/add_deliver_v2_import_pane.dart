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
                                             child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
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
                                             child: Text('Tot: ${awb['total']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
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
                                                  Text('House Number', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text((awb['house'] as List).isEmpty ? 'N/A' : (awb['house'] as List).join('\n'), style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 12)),
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
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     SizedBox(width: 150, child: _buildTextField('AWB Number', _importAwbNumberCtrl, dark, null, hint: '123-4567 8910', onChanged: (val) {
                       var pureDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
                       if (pureDigits.length == 11) {
                         final text = val.trim().toUpperCase();
                         () async {
                           try {
                             final res = await Supabase.instance.client.from('AWB').select('total').eq('AWB-number', text).maybeSingle();
                             if (res != null && res['total'] != null && _importAwbNumberCtrl.text.toUpperCase() == text) {
                               if (mounted) {
                                  setState(() {
                                     _importTotalLocked = true;
                                     _importTotalCtrl.text = res['total'].toString();
                                  });
                               }
                             }
                           } catch (_) {}
                         }();
                       } else {
                         if (_importTotalLocked) {
                           setState(() {
                             _importTotalLocked = false;
                             _importTotalCtrl.clear();
                           });
                         }
                       }
                     })),
                     const SizedBox(width: 8),
                     SizedBox(width: 80, child: _buildTextField('Pieces', _importPiecesCtrl, dark, null, hint: '0')),
                     const SizedBox(width: 8),
                     SizedBox(width: 80, child: _buildTextField('Total', _importTotalCtrl, dark, null, hint: '0', readOnly: _importTotalLocked)),
                     const SizedBox(width: 8),
                     SizedBox(width: 80, child: _buildTextField('Weight', _importWeightCtrl, dark, null, hint: '0')),
                     const SizedBox(width: 8),
                     Expanded(child: _buildTextField('House No.', _importHouseCtrl, dark, null, hint: 'HAWB', maxLines: 3, minLines: 1, uppercase: true)),
                   ]
                ),
                const SizedBox(height: 12),
                Row(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Expanded(child: _buildTextField('Remarks', _importRemarksCtrl, dark, null, hint: 'Remarks of the AWB', capitalizeFirst: true)),
                     const SizedBox(width: 16),
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
                          label: const Text('Add AWB', style: TextStyle(fontWeight: FontWeight.bold)),
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
