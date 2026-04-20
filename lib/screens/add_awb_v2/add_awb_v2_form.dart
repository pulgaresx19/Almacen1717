part of 'add_awb_v2_screen.dart';

extension AddAwbV2FormUI on AddAwbV2ScreenState {
  Widget _buildFormContent(bool dark) {
    final Color textP = dark ? Colors.white : const Color(0xFF111827);
    final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final Color bgCard = dark ? const Color(0xFF1e293b) : const Color(0xFFffffff);
    final Color borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upper Form Container
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderC),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, color: textP, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    appLanguage.value == 'es' ? 'Detalles de AWB y Asignación' : 'AWB Details & Assignment',
                    style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  double baseWidth = 1187;
                  double rWidth = constraints.maxWidth - baseWidth - 1;
                  if (rWidth < 70) rWidth = 70;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: 135,
                        child: buildAwbTextField('AWB Number', _awbNumberCtrl, '123-1234 5678', dark: dark, textP: textP, maxLen: 13, inputFormatters: [AwbNumberFormatter()]),
                      ),
                      SizedBox(width: 170, child: buildFlightDropdownWidget(
                        dark, textP, borderC,
                        titleTrailing: SizedBox(
                          width: 20, height: 20,
                          child: Checkbox(
                            value: _refFlightCheck,
                            activeColor: const Color(0xFF6366f1),
                            side: const BorderSide(color: Color(0xFF94a3b8)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => updateUI(() => _refFlightCheck = v ?? true),
                          ),
                        ),
                        selectedFlight: _selectedFlight,
                        flights: _flights,
                        onChanged: (v) {
                          updateUI(() => _selectedFlight = v);
                          _checkUldBreakStatus();
                        },
                      )),
                      SizedBox(
                        width: 135,
                        child: buildAwbTextField(
                          'Ref ULD', _refUldCtrl, 'AKE12345AA',
                          dark: dark, textP: textP, maxLen: 10,
                          inputFormatters: [UpperCaseTextFormatter()],
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (v) {
                             updateUI(() => _refUld = v);
                             _checkUldBreakStatus();
                          },
                          titleTrailing: _refUld.trim().isNotEmpty ? SizedBox(
                            width: 20, height: 20,
                            child: Checkbox(
                              value: _refUldCheck,
                              activeColor: const Color(0xFF6366f1),
                              side: const BorderSide(color: Color(0xFF94a3b8)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) => updateUI(() => _refUldCheck = v ?? false),
                            )
                          ) : null,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Break?', style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF), size: 18),
                                  Switch(
                                    value: _isBreak,
                                    onChanged: (v) => updateUI(() => _isBreak = v),
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF22c55e),
                                    inactiveThumbColor: dark ? const Color(0xFFbdc3c7) : const Color(0xFF9CA3AF),
                                    inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                                    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) return Colors.transparent;
                                      return const Color(0xFFef4444).withAlpha(180);
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 75,
                        child: buildAwbTextField('Pieces', _piecesCtrl, '0', isNum: true, dark: dark, textP: textP, inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) return newValue;
                            final p = int.tryParse(newValue.text) ?? 0;
                            final t = int.tryParse(_totalCtrl.text) ?? 0;
                            if (_totalCtrl.text.isNotEmpty && t > 0 && p > t) return oldValue;
                            return newValue;
                          })
                        ], onChanged: (_) => updateUI(() {})),
                      ),
                      SizedBox(
                        width: 75,
                        child: buildAwbTextField('Total', _totalCtrl, '0', isNum: true, dark: dark, textP: textP, inputFormatters: [FilteringTextInputFormatter.digitsOnly], readOnly: _totalLocked),
                      ),
                      SizedBox(
                        width: 75,
                        child: buildAwbTextField('Weight', _weightCtrl, '0.0', isNum: true, dark: dark, textP: textP, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
                      ),
                      SizedBox(
                        width: rWidth,
                        child: buildAwbTextField('Remarks', _remarksCtrl, 'Additional remarks...', dark: dark, textP: textP, textCapitalization: TextCapitalization.sentences, inputFormatters: [SentenceCaseTextFormatter()]),
                      ),
                      SizedBox(
                        width: 140,
                        child: buildAwbTextField('House Number', _houseCtrl, 'HAWB', dark: dark, textP: textP, maxLines: 3, inputFormatters: [UpperCaseTextFormatter()], textCapitalization: TextCapitalization.characters),
                      ),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderC),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.assignment_add, 
                                color: _piecesCtrl.text.isEmpty 
                                    ? (dark ? const Color(0xFF475569) : const Color(0xFF9CA3AF))
                                    : (_coordinatorCounts.isNotEmpty ? const Color(0xFF6366f1) : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563))), 
                                size: 20
                              ),
                              onPressed: _piecesCtrl.text.isNotEmpty ? () => showCoordinatorDataDialog(
                                context: context,
                                dark: dark,
                                textP: textP,
                                textS: textS,
                                expectedPieces: int.tryParse(_piecesCtrl.text) ?? 0,
                                coordinatorCounts: _coordinatorCounts,
                                onSave: () => updateUI(() {}),
                              ) : null,
                              tooltip: 'Data Coordinator',
                            ),
                            Container(width: 1, height: 24, color: borderC),
                            IconButton(
                              icon: Icon(
                                Icons.location_on_outlined, 
                                color: _coordinatorCounts.isEmpty 
                                    ? (dark ? const Color(0xFF475569) : const Color(0xFF9CA3AF)) 
                                    : (_itemLocations.isNotEmpty ? const Color(0xFF10b981) : (dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563))), 
                                size: 20
                              ),
                              onPressed: _coordinatorCounts.isEmpty ? null : () => showItemLocationEntryDialog(
                                context: context,
                                expectedPieces: int.tryParse(_piecesCtrl.text) ?? 0,
                                coordinatorCounts: _coordinatorCounts,
                                itemLocations: _itemLocations,
                                onSave: () => updateUI(() {}),
                              ),
                              tooltip: 'Data Location',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _addLocalAwb,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFF6366f1).withAlpha(15),
                            foregroundColor: dark ? const Color(0xFF818cf8) : const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                            side: BorderSide(color: dark ? const Color(0xFF6366f1).withAlpha(60) : const Color(0xFF6366f1).withAlpha(40)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('+ Add AWB', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ),

        // Persistent Form Container Gap
        const SizedBox(height: 16),

        // Persistent Container for Native table of added AWBs
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderC),
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt_rounded, color: textP, size: 20),
                            const SizedBox(width: 8),
                            Text('Added AWBs', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                               width: 300,
                               height: 40,
                               decoration: BoxDecoration(
                                  color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderC),
                               ),
                               child: TextField(
                                  controller: _searchAwbCtrl,
                                  style: TextStyle(color: textP, fontSize: 13),
                                  onChanged: (v) => updateUI(() {}),
                                  decoration: InputDecoration(
                                     hintText: appLanguage.value == 'es' ? 'Buscar AWB...' : 'Search AWB...',
                                     hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                                     prefixIcon: Icon(Icons.search_rounded, color: textP.withAlpha(76), size: 16),
                                     border: InputBorder.none,
                                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                               ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appLanguage.value == 'es' ? 'Vea y gestione todos los AWBs que serán guardados.' : 'View and manage all AWBs pending to be saved.', 
                          style: TextStyle(color: textS, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderC),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _localAwbs.isNotEmpty
                              ? LocalAwbsTable(
                                  dark: dark,
                                  textP: textP,
                                  textS: textS,
                                  borderC: borderC,
                                  localAwbs: _localAwbs,
                                  searchCtrl: _searchAwbCtrl,
                                  collapsedGroups: _collapsedGroups,
                                  onToggleGroup: (groupName) {
                                    updateUI(() {
                                      if (_collapsedGroups.contains(groupName)) {
                                        _collapsedGroups.remove(groupName);
                                      } else {
                                        _collapsedGroups.add(groupName);
                                      }
                                    });
                                  },
                                  onRemoveAwb: (index) {
                                    updateUI(() => _localAwbs.removeAt(index));
                                  },
                                  onShowListDialog: _showCustomListDialog,
                                  onShowCoordinatorPreview: (awb) => showCoordinatorDataPreviewDialog(context, awb),
                                  onShowLocationPreview: (awb) => showItemLocationPreviewDialog(context, awb),
                                )
                              : Center(
                                  child: Text(
                                    'No AWBs added yet',
                                    style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom Action Bar
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSavingAll ? null : _saveAllAwbs,
                  icon: _isSavingAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    appLanguage.value == 'es' ? 'Guardar AWBs' : 'Save AWBs',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  
}
}
