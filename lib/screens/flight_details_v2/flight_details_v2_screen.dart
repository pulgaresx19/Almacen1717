import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;
import '../flights_v2/flights_v2_service.dart';
import '../flights_v2/flights_v2_drawer_general_info.dart';
import '../flights_v2/flights_v2_drawer_uld_list.dart';
import '../flights_v2/flights_v2_print_preview.dart';
import 'flight_details_v2_add_uld.dart';
import 'flight_details_v2_reports_dialog.dart';
import 'flight_details_v2_damage_reports_dialog.dart';

class FlightDetailsV2Screen extends StatefulWidget {
  final Map<String, dynamic> flight;
  final bool dark;
  final VoidCallback onBack;

  const FlightDetailsV2Screen({
    super.key,
    required this.flight,
    required this.dark,
    required this.onBack,
  });

  @override
  State<FlightDetailsV2Screen> createState() => _FlightDetailsV2ScreenState();
}

class _FlightDetailsV2ScreenState extends State<FlightDetailsV2Screen> {
  final FlightsV2Service _service = FlightsV2Service();
  List<Map<String, dynamic>> _ulds = [];
  int _damageCount = 0;
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
    
    int damages = 0;
    try {
      final flightRes = await Supabase.instance.client
          .from('flights')
          .select('final_discrepancy_report')
          .eq('id_flight', flightId)
          .maybeSingle();
      if (flightRes != null) {
        widget.flight['final_discrepancy_report'] = flightRes['final_discrepancy_report'];
      }

      final res = await Supabase.instance.client
          .from('damage_reports')
          .select('id')
          .eq('flight_id', flightId);
      damages = res.length;
    } catch (e) {
      // Ignore
    }

    if (mounted) {
      setState(() {
        _ulds = ulds;
        _damageCount = damages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = widget.dark ? const Color(0xFF1e293b) : Colors.white;
    final borderCard = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    
    final carrier = widget.flight['carrier'] ?? '';
    final number = widget.flight['number'] ?? '';
    final flightId = widget.flight['id_flight']?.toString() ?? '';
    
    final String reportStr = widget.flight['final_discrepancy_report']?.toString() ?? '';
    final bool hasReport = reportStr.isNotEmpty && reportStr != 'null' && reportStr != '{}';

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera (Header) de la Sala de Control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderCard)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: textP),
                        onPressed: widget.onBack,
                        tooltip: appLanguage.value == 'es' ? 'Volver a Vuelos' : 'Back to Flights',
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            if (widget.flight['date'] != null && widget.flight['date'].toString().isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Builder(
                                builder: (context) {
                                  final dt = DateTime.tryParse(widget.flight['date'].toString())?.toLocal();
                                  final dateStr = dt != null ? "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}" : widget.flight['date'].toString().split(' ')[0];
                                  return Text(
                                    '[$dateStr]',
                                    style: TextStyle(color: textS, fontSize: 20, fontWeight: FontWeight.w500),
                                  );
                                }
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                         final bool? result = await showAddUldComponent(context, widget.flight, widget.dark, _ulds);
                         if (result == true) {
                           _fetchDetails();
                         }
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(appLanguage.value == 'es' ? 'Añadir ULD' : 'Add ULD', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1).withAlpha(20),
                        foregroundColor: const Color(0xFF818cf8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.report_problem_rounded, color: Colors.orangeAccent),
                            onPressed: () => showFlightDamageReportsDialog(context, flightId, widget.dark),
                            tooltip: appLanguage.value == 'es' ? 'Daño' : 'Damage',
                          ),
                        ),
                        if (_damageCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: bgCard, width: 1.5),
                              ),
                              child: Text(
                                '$_damageCount',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: hasReport ? Colors.blueAccent.withAlpha(30) : (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5)),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.assignment_rounded, color: hasReport ? Colors.blueAccent : textS.withAlpha(100)),
                        onPressed: hasReport ? () => showFlightReportsDialog(context, widget.flight, widget.dark) : null,
                        tooltip: appLanguage.value == 'es' ? 'Reporte' : 'Report',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.print_rounded, color: textP),
                        onPressed: _isLoading ? null : () => showFlightPrintPreviewDialog(context, widget.flight, _ulds, widget.dark),
                        tooltip: appLanguage.value == 'es' ? 'Imprimir Reporte' : 'Print Report',
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // Información General Premium
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FlightsV2GeneralInfo(flight: widget.flight, dark: widget.dark),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de ULDs (Acordeón reutilizado)
          Expanded(
            child: FlightsV2UldList(
              ulds: _ulds,
              flight: widget.flight,
              isLoading: _isLoading,
              dark: widget.dark,
              onRefresh: _fetchDetails,
            ),
          ),
        ],
      ),
    );
  }
}
