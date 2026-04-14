import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage;
import 'flights_v2_service.dart';
import 'flights_v2_drawer_general_info.dart';
import 'flights_v2_drawer_uld_list.dart';
import 'flights_v2_print_preview.dart';

class FlightsV2Drawer extends StatefulWidget {
  final Map<String, dynamic> flight;
  final bool dark;

  const FlightsV2Drawer({
    super.key,
    required this.flight,
    required this.dark,
  });

  @override
  State<FlightsV2Drawer> createState() => _FlightsV2DrawerState();
}

class _FlightsV2DrawerState extends State<FlightsV2Drawer> {
  final FlightsV2Service _service = FlightsV2Service();
  List<Map<String, dynamic>> _ulds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final flightId = widget.flight['id_flight']?.toString() ?? '';
    if (flightId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final ulds = await _service.fetchFlightDetails(flightId);
    if (mounted) {
      setState(() {
        _ulds = ulds;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final carrier = widget.flight['carrier'] ?? '';
    final number = widget.flight['number'] ?? '';

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
                      appLanguage.value == 'es' ? 'Detalles de Vuelo' : 'Flight Details',
                      style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.flight_land_rounded, color: textP, size: 24),
                        const SizedBox(width: 8),
                        Text('$carrier $number', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.print_rounded, color: textP),
                      onPressed: _isLoading ? null : () => showFlightPrintPreviewDialog(context, widget.flight, _ulds, widget.dark),
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
          // Premium Detail Grid
          FlightsV2GeneralInfo(flight: widget.flight, dark: widget.dark),
          
          Expanded(
            child: FlightsV2UldList(
              ulds: _ulds,
              isLoading: _isLoading,
              dark: widget.dark,
            ),
          ),
        ],
      ),
    );
  }
}
