import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'location_v2_logic.dart';
import 'location_v2_history_modal.dart';

class LocationV2AwbAssignModal extends StatefulWidget {
  final Map<String, dynamic> awb;
  final Function(List<String> locations, bool isConfirmed) onSave;
  final LocationV2Logic logic;

  const LocationV2AwbAssignModal({
    super.key,
    required this.awb,
    required this.onSave,
    required this.logic,
  });

  @override
  State<LocationV2AwbAssignModal> createState() => _LocationV2AwbAssignModalState();
}

class _LocationV2AwbAssignModalState extends State<LocationV2AwbAssignModal> {
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocus = FocusNode();
  bool _isMultipleMode = false;
  final List<String> _pendingLocations = [];

  @override
  void initState() {
    super.initState();
    // Auto focus the text field so the user can just scan the location
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _locationFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _save({bool isConfirmed = false, String? exactLocation}) {
    final loc = exactLocation ?? _locationController.text.trim().toUpperCase();
    if (loc.isNotEmpty && !_pendingLocations.contains(loc)) {
      _pendingLocations.add(loc);
    }
    
    if (_pendingLocations.isEmpty) {
      _locationFocus.requestFocus();
      return;
    }

    widget.onSave(_pendingLocations, isConfirmed);
    Navigator.pop(context); // close modal
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: isDarkMode,
      builder: (context, _) {
        final dark = isDarkMode.value;
        final Color bgColor = dark ? const Color(0xFF0f172a) : Colors.white;
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color cardColor = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final Color inputBgColor = dark ? Colors.white.withAlpha(5) : Colors.transparent;

        final awbObj = widget.awb['awbs'] ?? {};
        final String awbNumber = awbObj['awb_number']?.toString() ?? widget.awb['awb_number']?.toString() ?? '-';
        final String pieces = widget.awb['pieces']?.toString() ?? '-';
        final String weight = widget.awb['weight']?.toString() ?? '-';

        List<Map<String, dynamic>> parsedLocations = [];
    if (widget.awb['data_location'] != null) {
      if (widget.awb['data_location'] is List) {
        for (var item in widget.awb['data_location']) {
          if (item is Map) parsedLocations.add(Map<String, dynamic>.from(item));
        }
      } else if (widget.awb['data_location'] is Map) {
        final locData = widget.awb['data_location'] as Map;
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF10b981), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appLanguage.value == 'es' ? 'Asignar Locación' : 'Assign Location',
                    style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(appLanguage.value == 'es' ? 'Múltiple' : 'Multiple', style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                SizedBox(
                  height: 20,
                  child: Switch(
                    value: _isMultipleMode,
                    onChanged: (v) {
                      setState(() {
                        _isMultipleMode = v;
                      });
                      if (v) {
                        _locationFocus.requestFocus();
                      }
                    },
                    activeThumbColor: const Color(0xFF10b981),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (parsedLocations.isNotEmpty) const SizedBox(width: 8),
                if (parsedLocations.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.history, color: Color(0xFF6366f1), size: 22),
                    onPressed: () {
                      LocationV2HistoryModal.show(
                        context, 
                        parsedLocations, 
                        widget.awb, 
                        widget.logic,
                        () {
                          setState(() {});
                        }
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // AWB Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AWB', style: TextStyle(color: textS, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(awbNumber, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appLanguage.value == 'es' ? 'Piezas' : 'Pieces', style: TextStyle(color: textS, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(pieces, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appLanguage.value == 'es' ? 'Peso' : 'Weight', style: TextStyle(color: textS, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$weight kg', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location Required Banner
            Builder(
              builder: (ctx) {
                String requiredLoc = widget.awb['required_location']?.toString() ?? '';
                bool isConfirmed = widget.awb['is_location_confirmed'] == true;

                if (requiredLoc.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf59e0b).withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFf59e0b).withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFFf59e0b), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                appLanguage.value == 'es' ? 'Locación Requerida:' : 'Required Location:',
                                style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(requiredLoc, style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 18, fontWeight: FontWeight.bold)),
                              if (!isConfirmed)
                                ElevatedButton.icon(
                                  onPressed: () => _save(isConfirmed: true, exactLocation: requiredLoc),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: Text(appLanguage.value == 'es' ? 'Confirmar' : 'Confirm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFf59e0b),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 16),
                                    const SizedBox(width: 4),
                                    Text(appLanguage.value == 'es' ? 'Confirmada' : 'Confirmed', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appLanguage.value == 'es' ? 'O escanea otra ubicación:' : 'Or scan a different location:',
                      style: TextStyle(color: textS, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // Location Label & Oversize
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location / Rack / Zone',
                  style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _locationController.text = 'OVERSIZE';
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.open_in_full_rounded, size: 14, color: textS),
                      const SizedBox(width: 4),
                      Text(
                        'OVERSIZE',
                        style: TextStyle(
                          color: textS,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location Input
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10b981), width: 1.5),
              ),
              child: TextField(
                controller: _locationController,
                focusNode: _locationFocus,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    );
                  }),
                ],
                style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Ej. RACK-A1, FLOOR-2',
                  hintStyle: TextStyle(color: textS, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: textS, size: 20),
                    onPressed: () {
                      _locationController.clear();
                      _locationFocus.requestFocus();
                    },
                  ),
                ),
                onSubmitted: (_) {
                  if (_isMultipleMode) {
                    final loc = _locationController.text.trim().toUpperCase();
                    if (loc.isNotEmpty && !_pendingLocations.contains(loc)) {
                      setState(() {
                        _pendingLocations.add(loc);
                        _locationController.clear();
                      });
                    } else if (loc.isNotEmpty) {
                      setState(() {
                        _locationController.clear();
                      });
                    }
                    _locationFocus.requestFocus();
                  } else {
                    _save();
                  }
                },
              ),
            ),
            if (_isMultipleMode && _pendingLocations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pendingLocations.map((loc) => Chip(
                  label: Text(loc, style: TextStyle(color: textP, fontSize: 12, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF10b981).withAlpha(20),
                  deleteIcon: const Icon(Icons.cancel, size: 16, color: Color(0xFF10b981)),
                  onDeleted: () {
                    setState(() {
                      _pendingLocations.remove(loc);
                    });
                  },
                  side: BorderSide(color: const Color(0xFF10b981).withAlpha(50)),
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                    style: TextStyle(color: textS, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_isMultipleMode) {
                      final loc = _locationController.text.trim().toUpperCase();
                      if (loc.isNotEmpty && !_pendingLocations.contains(loc)) {
                        _pendingLocations.add(loc);
                      }
                    }
                    _save();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    appLanguage.value == 'es' 
                        ? (_isMultipleMode && _pendingLocations.isNotEmpty ? 'Guardar ${_pendingLocations.length} Locs' : 'Guardar') 
                        : (_isMultipleMode && _pendingLocations.isNotEmpty ? 'Save ${_pendingLocations.length} Locs' : 'Save'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
