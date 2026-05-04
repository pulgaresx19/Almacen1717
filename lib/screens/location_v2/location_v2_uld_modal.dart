import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'location_v2_logic.dart';
import 'location_v2_awb_assign_modal.dart';

class LocationV2UldModal extends StatefulWidget {
  final Map<String, dynamic> uld;
  final LocationV2Logic logic;

  const LocationV2UldModal({
    super.key,
    required this.uld,
    required this.logic,
  });

  @override
  State<LocationV2UldModal> createState() => _LocationV2UldModalState();
}

class _LocationV2UldModalState extends State<LocationV2UldModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isRelocating = false;
  bool _searchError = false;

  @override
  void initState() {
    super.initState();
    // Pre-fetch the AWBs for this ULD if not already loaded
    final idUld = widget.uld['id_uld']?.toString();
    if (idUld != null) {
      widget.logic.fetchAwbsForUld(idUld);
    }
    
    // Auto focus the search field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onAwbScanned(String query) {
    if (query.isEmpty) return;

    final awbMatch = widget.logic.uldAwbs.firstWhere(
      (awb) {
        final awbObj = awb['awbs'] ?? {};
        final String awbNumber = awbObj['awb_number']?.toString() ?? awb['awb_number']?.toString() ?? '';
        final String awbFull = awbObj['awb_full']?.toString() ?? awb['awb_full']?.toString() ?? '';
        return awbNumber == query || awbFull == query;
      },
      orElse: () => <String, dynamic>{},
    );

    if (awbMatch.isNotEmpty) {
      setState(() { _searchError = false; });
      _searchController.clear();
      _openAssignModal(awbMatch);
    } else {
      setState(() { _searchError = true; });
    }
    _searchController.clear();
    _searchFocus.requestFocus();
  }
  bool _isUldCompleted() {
    final currentUld = widget.logic.ulds.firstWhere(
      (u) => u['id_uld'].toString() == widget.uld['id_uld'].toString(),
      orElse: () => widget.uld,
    );
    return currentUld['time_saved'] != null;
  }

  void _openAssignModal(Map<String, dynamic> awb) {
    if (_isUldCompleted() && !_isRelocating) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LocationV2AwbAssignModal(
        awb: awb,
        logic: widget.logic,
        onSave: (locations, isConfirmed) async {
          List<Map<String, dynamic>> parsedLocations = [];
          if (awb['data_location'] != null) {
            if (awb['data_location'] is List) {
              for (var item in awb['data_location']) {
                if (item is Map) parsedLocations.add(Map<String, dynamic>.from(item));
              }
            } else if (awb['data_location'] is Map) {
              final locData = awb['data_location'] as Map;
              if (locData['locations'] != null && locData['locations'] is List) {
                for (var item in locData['locations']) {
                  if (item is Map) parsedLocations.add(Map<String, dynamic>.from(item));
                }
              } else if (locData['location'] != null) {
                parsedLocations.add({
                  'location': locData['location'].toString(),
                  'updated_by': locData['updated_by'],
                  'updated_at': locData['updated_at'] ?? locData['time_saved'],
                });
              }
            }
          }

          final user = widget.logic.supabase.auth.currentUser;
          String byName = user?.email ?? 'Unknown';
          if (user != null) {
            if (user.userMetadata?['full_name'] != null) {
              byName = user.userMetadata!['full_name'].toString();
            }
            try {
              final profile = await widget.logic.supabase.from('users').select('full_name').eq('id', user.id).maybeSingle();
              if (profile != null && profile['full_name'] != null && profile['full_name'].toString().trim().isNotEmpty) {
                byName = profile['full_name'].toString().trim();
              }
            } catch (_) {}
          }

          for (var location in locations) {
            bool exists = parsedLocations.any((p) => p['location'].toString().toUpperCase() == location);
            if (!exists) {
              parsedLocations.add({
                'location': location,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
                'updated_by': byName,
              });
            }
          }

          try {
            await widget.logic.supabase.from('awb_splits').update({
              'data_location': parsedLocations,
              'is_location_confirmed': isConfirmed,
            }).eq('id', awb['id']);
            
            // Refetch to update the list
            widget.logic.fetchAwbsForUld(widget.uld['id_uld'].toString());
            
            if (mounted) {
              bool dialogOpen = true;
              showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (context, anim1, anim2) {
                  final dark = isDarkMode.value;
                  return Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1e293b) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10b981).withAlpha(40),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981).withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              appLanguage.value == 'es' ? '¡Locación Guardada!' : 'Location Saved!',
                              style: TextStyle(
                                color: dark ? Colors.white : const Color(0xFF111827),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                transitionBuilder: (context, anim1, anim2, child) {
                  return Transform.scale(
                    scale: Curves.easeOutBack.transform(anim1.value),
                    child: FadeTransition(
                      opacity: anim1,
                      child: child,
                    ),
                  );
                },
              ).then((_) => dialogOpen = false);

              Future.delayed(const Duration(milliseconds: 1500), () {
                if (dialogOpen && mounted) {
                  Navigator.of(context).pop();
                }
              });

              // Focus back to search field
              _searchFocus.requestFocus();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uldNumber = widget.uld['uld_number']?.toString() ?? '-';
    final String pieces = widget.uld['pieces_total']?.toString() ?? '-';
    final String weight = widget.uld['weight_total']?.toString() ?? '-';

    return ListenableBuilder(
      listenable: isDarkMode,
      builder: (context, _) {
        final dark = isDarkMode.value;
        final Color bgColor = dark ? const Color(0xFF0f172a) : Colors.white;
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color cardColor = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final Color inputBgColor = dark ? Colors.white.withAlpha(5) : Colors.transparent;
        final Color borderColor = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: 400,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ULD $uldNumber',
                            style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${appLanguage.value == 'es' ? 'Piezas' : 'Pieces'}: $pieces  •  ${appLanguage.value == 'es' ? 'Peso' : 'Weight'}: $weight kg',
                            style: TextStyle(color: textS, fontSize: 13),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textP),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _searchError ? Colors.redAccent : borderColor,
                    width: _searchError ? 1.5 : 1.0,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: textP, fontSize: 15),
                  onChanged: (v) {
                    if (_searchError) {
                      setState(() { _searchError = false; });
                    }
                  },
                  inputFormatters: [
                    AwbTextInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: appLanguage.value == 'es' ? 'Escanear o Buscar AWB...' : 'Scan or Search AWB...',
                    hintStyle: TextStyle(color: textS, fontSize: 15),
                    prefixIcon: Icon(Icons.search, color: textS),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: textS, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocus.requestFocus();
                      },
                    ),
                  ),
                  onSubmitted: _onAwbScanned,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AWB List and Action Button
            Expanded(
              child: ListenableBuilder(
                listenable: widget.logic,
                builder: (context, _) {
                  final bool isCompleted = _isUldCompleted();

                  bool isReadyToComplete = false;
                  if (widget.logic.uldAwbs.isNotEmpty && !widget.logic.isLoadingUldAwbs) {
                    isReadyToComplete = widget.logic.uldAwbs.every((awb) {
                      final locData = awb['data_location'];
                      if (locData is List && locData.isNotEmpty) return true;
                      if (locData is Map) {
                        if (locData['locations'] != null && locData['locations'] is List && (locData['locations'] as List).isNotEmpty) return true;
                        final loc = locData['location']?.toString() ?? '';
                        if (loc.isNotEmpty) return true;
                      }
                      return false;
                    });
                  }

                  Widget listWidget;
                  if (widget.logic.isLoadingUldAwbs) {
                    listWidget = const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                  } else if (widget.logic.uldAwbs.isEmpty) {
                    listWidget = Center(
                      child: Text(
                        appLanguage.value == 'es' ? 'No hay AWBs en este ULD.' : 'No AWBs in this ULD.',
                        style: TextStyle(color: textS),
                      ),
                    );
                  } else {
                    final query = _searchController.text.toUpperCase();
                    final filtered = query.isEmpty 
                        ? widget.logic.uldAwbs 
                        : widget.logic.uldAwbs.where((awb) {
                            final awbObj = awb['awbs'] ?? {};
                            final awbNumber = awbObj['awb_number']?.toString().toUpperCase() ?? awb['awb_number']?.toString().toUpperCase() ?? '';
                            final awbFull = awbObj['awb_full']?.toString().toUpperCase() ?? awb['awb_full']?.toString().toUpperCase() ?? '';
                            return awbNumber.contains(query) || awbFull.contains(query);
                          }).toList();

                    listWidget = ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final awb = filtered[index];
                        final awbObj = awb['awbs'] ?? {};
                        final awbNumber = awbObj['awb_number']?.toString() ?? awb['awb_number']?.toString() ?? '-';
                        final pcs = awb['total_checked']?.toString() ?? awb['pieces']?.toString() ?? '-';
                        final wt = awb['weight']?.toString() ?? '-';
                        
                        final locData = awb['data_location'];
                        bool isLocated = false;
                        if (locData is List && locData.isNotEmpty) {
                          isLocated = true;
                        } else if (locData is Map) {
                          if (locData['locations'] != null && locData['locations'] is List && (locData['locations'] as List).isNotEmpty) {
                            isLocated = true;
                          } else {
                            final loc = locData['location']?.toString() ?? '';
                            if (loc.isNotEmpty) {
                              isLocated = true;
                            }
                          }
                        }

                        return GestureDetector(
                          onTap: () => _openAssignModal(awb),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isLocated ? const Color(0xFF10b981).withAlpha(15) : cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isLocated ? const Color(0xFF10b981).withAlpha(50) : borderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 80,
                                        child: Text('$pcs pcs', style: TextStyle(color: textS, fontSize: 13)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('$wt kg', style: TextStyle(color: textS, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLocated)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10b981).withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 16),
                                  )
                                else
                                  Icon(Icons.chevron_right, color: textS, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return Column(
                    children: [
                      Expanded(child: listWidget),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (isCompleted && !_isRelocating) {
                              setState(() { _isRelocating = true; });
                              _searchFocus.requestFocus();
                              return;
                            }
                            if (isCompleted && _isRelocating) {
                              Navigator.pop(context);
                              return;
                            }
                            if (!isReadyToComplete) return;

                            final idUld = widget.uld['id_uld']?.toString();
                            if (idUld != null && idUld.isNotEmpty) {
                              await widget.logic.markUldAsCompleted(idUld);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          icon: Icon(
                            (isCompleted && !_isRelocating) 
                              ? Icons.edit_location_alt_rounded 
                              : (isCompleted && _isRelocating)
                                ? Icons.check_circle_rounded
                                : Icons.save_rounded,
                            size: 20,
                          ),
                          label: Text(
                            (isCompleted && !_isRelocating)
                              ? (appLanguage.value == 'es' ? 'Reubicar' : 'Relocate')
                              : (isCompleted && _isRelocating)
                                ? (appLanguage.value == 'es' ? 'Terminar Reubicación' : 'Finish Relocation')
                                : (appLanguage.value == 'es' ? 'Marcar Completado' : 'Mark as Completed'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isCompleted && !_isRelocating) 
                                ? const Color(0xFFF59E0B) 
                                : (isCompleted && _isRelocating)
                                    ? const Color(0xFF10b981) 
                                    : (!isReadyToComplete) 
                                        ? Colors.white.withAlpha(20) 
                                        : const Color(0xFF6366f1),
                            foregroundColor: (!isReadyToComplete && !isCompleted) 
                                ? Colors.white.withAlpha(80)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class AwbTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.length > 11) raw = raw.substring(0, 11);
    String formatted = '';
    for (int i = 0; i < raw.length; i++) {
        if (i == 3) formatted += '-';
        if (i == 7) formatted += ' ';
        formatted += raw[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
