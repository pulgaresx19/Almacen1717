import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

          // Audit Trail
          _UldsV2AuditTrail(uld: widget.uld, dark: widget.dark),
        ],
      ),
    );
  }
}

class _UldsV2AuditTrail extends StatelessWidget {
  final Map<String, dynamic> uld;
  final bool dark;

  const _UldsV2AuditTrail({required this.uld, required this.dark});

  Widget _buildRow(String labelES, String labelEN, String? time, String? user, Color textColor, Color subTextColor) {
    if ((time == null || time.isEmpty) && (user == null || user.isEmpty)) {
      return const SizedBox.shrink();
    }
    DateTime? dt = DateTime.tryParse(time ?? '')?.toLocal();
    String timeStr = dt != null ? DateFormat('dd/MM HH:mm').format(dt) : (time ?? '-');
    String userStr = user ?? '-';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 85, // Fixed width for labels to align the username column nicely
            child: Text(appLanguage.value == 'es' ? labelES : labelEN, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.person_outline, size: 14, color: subTextColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(userStr, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Icon(Icons.access_time, size: 14, color: subTextColor),
          const SizedBox(width: 4),
          Text(timeStr, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final bgC = dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB);

    bool hasAnyData = (uld['time_received'] != null && uld['time_received'].toString().isNotEmpty) || 
                      (uld['time_checked'] != null && uld['time_checked'].toString().isNotEmpty) || 
                      (uld['time_saved'] != null && uld['time_saved'].toString().isNotEmpty) || 
                      (uld['time_delivered'] != null && uld['time_delivered'].toString().isNotEmpty);

    if (!hasAnyData) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgC,
        border: Border(top: BorderSide(color: borderC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLanguage.value == 'es' ? 'HISTORIAL DE PROCESO' : 'PROCESS HISTORY',
            style: TextStyle(color: textS, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          _buildRow('Recibido', 'Received', uld['time_received']?.toString(), uld['user_received']?.toString(), textP, textS),
          _buildRow('Cotejado', 'Checked', uld['time_checked']?.toString(), uld['user_checked']?.toString(), textP, textS),
          _buildRow('Guardado', 'Saved', uld['time_saved']?.toString(), uld['user_saved']?.toString(), textP, textS),
          _buildRow('Entregado', 'Delivered', uld['time_delivered']?.toString(), uld['user_delivered']?.toString(), textP, textS),
        ],
      ),
    );
  }
}
