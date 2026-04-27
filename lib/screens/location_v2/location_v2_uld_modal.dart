import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show appLanguage;
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
      _openAssignModal(awbMatch);
    } else {
      // Show error, not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLanguage.value == 'es' ? 'AWB no encontrado en este ULD' : 'AWB not found in this ULD'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    _searchController.clear();
    _searchFocus.requestFocus();
  }

  void _openAssignModal(Map<String, dynamic> awb) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LocationV2AwbAssignModal(
        awb: awb,
        onSave: (location, isOversize, isConfirmed) async {
          final currentLocData = awb['data_location'] is Map ? Map<String, dynamic>.from(awb['data_location']) : <String, dynamic>{};
          currentLocData['location'] = location;
          currentLocData['isOversize'] = isOversize;
          currentLocData['time_saved'] = DateTime.now().toUtc().toIso8601String();

          try {
            await widget.logic.supabase.from('awb_splits').update({
              'data_location': currentLocData,
              'is_location_confirmed': isConfirmed,
            }).eq('id', awb['id']);
            
            // Refetch to update the list
            widget.logic.fetchAwbsForUld(widget.uld['id_uld'].toString());
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(appLanguage.value == 'es' ? 'Locación guardada' : 'Location saved'),
                  backgroundColor: const Color(0xFF10b981),
                ),
              );
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 400,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
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
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appLanguage.value == 'es' ? 'Piezas' : 'Pieces'}: $pieces  •  ${appLanguage.value == 'es' ? 'Peso' : 'Weight'}: $weight kg',
                        style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  inputFormatters: [
                    AwbTextInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: appLanguage.value == 'es' ? 'Escanear o Buscar AWB...' : 'Scan or Search AWB...',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(80), fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
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

            // AWB List
            Expanded(
              child: ListenableBuilder(
                listenable: widget.logic,
                builder: (context, _) {
                  if (widget.logic.isLoadingUldAwbs) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                  }

                  if (widget.logic.uldAwbs.isEmpty) {
                    return Center(
                      child: Text(
                        appLanguage.value == 'es' ? 'No hay AWBs en este ULD.' : 'No AWBs in this ULD.',
                        style: TextStyle(color: Colors.white.withAlpha(150)),
                      ),
                    );
                  }

                  // Filter logic based on current text
                  final query = _searchController.text.toUpperCase();
                  final filtered = query.isEmpty 
                      ? widget.logic.uldAwbs 
                      : widget.logic.uldAwbs.where((awb) {
                          final awbObj = awb['awbs'] ?? {};
                          final awbNumber = awbObj['awb_number']?.toString().toUpperCase() ?? awb['awb_number']?.toString().toUpperCase() ?? '';
                          final awbFull = awbObj['awb_full']?.toString().toUpperCase() ?? awb['awb_full']?.toString().toUpperCase() ?? '';
                          return awbNumber.contains(query) || awbFull.contains(query);
                        }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final awb = filtered[index];
                      final awbObj = awb['awbs'] ?? {};
                      final awbNumber = awbObj['awb_number']?.toString() ?? awb['awb_number']?.toString() ?? '-';
                      final pcs = awb['pieces']?.toString() ?? '-';
                      final wt = awb['weight']?.toString() ?? '-';
                      
                      final locData = awb['data_location'];
                      bool isLocated = false;
                      String locationText = '';
                      if (locData is Map) {
                        final loc = locData['location']?.toString() ?? '';
                        if (loc.isNotEmpty) {
                          isLocated = true;
                          locationText = loc;
                        }
                      }

                      return GestureDetector(
                        onTap: () => _openAssignModal(awb),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isLocated ? const Color(0xFF10b981).withAlpha(15) : Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLocated ? const Color(0xFF10b981).withAlpha(50) : Colors.white.withAlpha(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(awbNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$pcs pcs  •  $wt kg',
                                    style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
                                  ),
                                ],
                              ),
                              if (isLocated)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10b981).withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        locationText,
                                        style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Icon(Icons.chevron_right, color: Colors.white.withAlpha(100), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
