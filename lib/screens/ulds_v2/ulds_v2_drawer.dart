import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'ulds_v2_service.dart';
import 'ulds_v2_drawer_general_info.dart';
import 'ulds_v2_drawer_awb_list.dart';
import 'ulds_v2_print_preview.dart';

class UldsV2Drawer extends StatefulWidget {
  final Map<String, dynamic> uld;
  final bool dark;
  final String flightDisplay;

  const UldsV2Drawer({
    super.key,
    required this.uld,
    required this.dark,
    required this.flightDisplay,
  });

  @override
  State<UldsV2Drawer> createState() => _UldsV2DrawerState();
}

class _UldsV2DrawerState extends State<UldsV2Drawer> {
  final UldsV2Service _service = UldsV2Service();
  List<Map<String, dynamic>> _awbs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final uldId = widget.uld['id_uld']?.toString() ?? '';
    if (uldId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final awbs = await _service.fetchUldAwbs(uldId);
    if (mounted) {
      setState(() {
        _awbs = awbs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final uldNumber = widget.uld['uld_number'] ?? '-';
    
    // Attempting to show Ref Flight from uldsV2Screen's logic or data if passed
    // If not, we can safely just ignore it or use what's passed in the map.
    // For now we just show the ULD Details header.

    return SafeArea(
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLanguage.value == 'es' ? 'Detalles del ULD' : 'ULD Details',
                      style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_rounded, color: textP, size: 24),
                        const SizedBox(width: 8),
                        Text(uldNumber, style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.print_rounded, color: textP),
                      onPressed: () {
                         final u = widget.uld;
                         // In order to pass flights map we could fetch it, but wait, we already have flightDisplay string. But the exporter relies on flightsMap if we pass it, otherwise it shows Standalone.
                         // We can just pass an empty flights map, it'll show Standalone or we can simulate the map:
                         Map<String, dynamic> fakeMap = {};
                         if (u['id_flight'] != null && widget.flightDisplay.isNotEmpty && widget.flightDisplay != 'Standalone') {
                            fakeMap[u['id_flight'].toString()] = {
                               'carrier': widget.flightDisplay.split(' ').first,
                               'number': widget.flightDisplay.replaceFirst(widget.flightDisplay.split(' ').first, '').trim()
                            };
                         }
                         showUldV2PrintPreviewDialog(context, u, _awbs, fakeMap, widget.dark);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textP),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // General Info Grid
          UldsV2GeneralInfo(uld: widget.uld, dark: widget.dark, flightDisplay: widget.flightDisplay),
          
          // AWB List
          Expanded(
            child: UldsV2AwbList(
              awbs: _awbs,
              isLoading: _isLoading,
              dark: widget.dark,
            ),
          ),
        ],
      ),
    );
  }
}
