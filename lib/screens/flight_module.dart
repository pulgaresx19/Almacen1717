import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../main.dart' show appLanguage;
import 'add_flight_screen.dart';
import 'add_flight_screen.dart';

class FlightModule extends StatefulWidget {
  const FlightModule({super.key});

  @override
  State<FlightModule> createState() => _FlightModuleState();
}

class _FlightModuleState extends State<FlightModule> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Header Row (Title, Search, Buttons)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showAddForm)
                  Text(appLanguage.value == 'es' ? 'Añadir Nuevo Vuelo' : 'Add New Flight', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700))
                else
                  Text(appLanguage.value == 'es' ? 'Vuelos' : 'Flight Documents', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (_showAddForm)
                  Text(appLanguage.value == 'es' ? 'Crea y vincula ULDs y AWBs a un Vuelo.' : 'Create and link ULDs and AWBs to a Flight.', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13))
                else
                  Text(appLanguage.value == 'es' ? 'Administración y estado de los vuelos registrados.' : 'Manage and track all incoming flights.', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13)),
              ],
            ),
            const Spacer(),
            
            // Search Box
            if (!_showAddForm)
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(25)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(76), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94a3b8), size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            
            // Add Flight Button
            if (!_showAddForm)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showAddForm = true);
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(appLanguage.value == 'es' ? 'Añadir Vuelo' : 'Add Flight', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            if (!_showAddForm)
              const SizedBox(width: 8),

            // Refresh Button
            if (!_showAddForm)
            IconButton(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFcbd5e1), size: 18),
              tooltip: appLanguage.value == 'es' ? 'Refrescar' : 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(25),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // Flight Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _showAddForm
                  ? AddFlightScreen(
                      isInline: true,
                      onPop: (bool isSaved) {
                        setState(() {
                          _showAddForm = false;
                        });
                      },
                    )
                  : _buildFlightList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('Flight').select().order('date-arrived', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        var flights = snapshot.data ?? [];
        
        if (_searchController.text.isNotEmpty) {
          final term = _searchController.text.toLowerCase();
          flights = flights.where((f) {
            final str = '${f['carrier']} ${f['number']}'.toLowerCase();
            return str.contains(term);
          }).toList();
        }

        if (flights.isEmpty) return const Center(child: Text('No flights found.', style: TextStyle(color: Color(0xFF94a3b8))));

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withAlpha(13)),
              dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? Colors.white.withAlpha(8) : Colors.transparent),
              dataTextStyle: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13),
              headingTextStyle: const TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.w600, fontSize: 12),
              columns: [
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Vuelo (Aerolínea/No.)' : 'Carrier / Number')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Fecha Llegada' : 'Arrive Date')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Hora Llegada' : 'Arrive Time')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Total ULDs' : 'Qty ULDs')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'B / No B' : 'Break / No B.')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Inicio Desarme' : 'Start Break')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Fin Desarme' : 'End Break')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Primer Camión' : 'First Truck')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Último Camión' : 'Last Truck')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Observaciones' : 'Remarks')),
                DataColumn(label: Text(appLanguage.value == 'es' ? 'Estado' : 'Status')),
              ],
              rows: List.generate(flights.length, (index) {
                final f = flights[index];
                
                final String dateStr = f['date-arrived']?.toString() ?? '';
                final String timeStr = f['time-arrived']?.toString() ?? '-';
                String formattedDate = dateStr.isNotEmpty ? dateStr : '-';

                try {
                  if (dateStr.isNotEmpty) {
                    final dt = DateTime.parse(dateStr);
                    formattedDate = DateFormat('yyyy/MM/dd').format(dt);
                  }
                } catch (_) {}

                return DataRow(
                  cells: [
                    // Carrier / Number
                    DataCell(Row(
                      children: [
                        const Icon(Icons.flight_land_rounded, size: 16, color: Color(0xFF94a3b8)),
                        const SizedBox(width: 8),
                        Text(
                          '${f['carrier'] ?? ''} ${f['number'] ?? ''}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )),
                    // Arrive Date
                    DataCell(Text(formattedDate)),
                    // Arrive Time
                    DataCell(Text(timeStr, style: const TextStyle(color: Color(0xFF64748b)))),
                    // Qty ULD
                    DataCell(Text('${f['qty-uld'] ?? 0}', style: const TextStyle(color: Color(0xFF818cf8)))),
                    // Break / No Break
                    DataCell(Text('${f['cant-break'] ?? 0} / ${f['cant-noBreak'] ?? 0}', style: const TextStyle(color: Color(0xFF94a3b8)))),
                    // Start Break
                    DataCell(Text(f['start-break']?.toString().isNotEmpty == true ? f['start-break'].toString() : '-', style: const TextStyle(color: Colors.white))),
                    // End Break
                    DataCell(Text(f['end-break']?.toString().isNotEmpty == true ? f['end-break'].toString() : '-', style: const TextStyle(color: Colors.white))),
                    // First Truck
                    DataCell(Text(f['first-truck']?.toString().isNotEmpty == true ? f['first-truck'].toString() : '-', style: const TextStyle(color: Colors.white))),
                    // Last Truck
                    DataCell(Text(f['last-truck']?.toString().isNotEmpty == true ? f['last-truck'].toString() : '-', style: const TextStyle(color: Colors.white))),
                    // Remarks
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          f['remarks']?.toString().isNotEmpty == true ? f['remarks'].toString() : '-',
                          style: const TextStyle(color: Color(0xFF94a3b8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ),
                    // Status
                    DataCell(_buildStatusBadge(f['status']?.toString() ?? 'N/A')),
                  ],
                );
              }),
            ),
          ),
        ),
      );
    },
  );
},
);
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    if (status.toLowerCase() == 'pending') {
      bg = const Color(0xFF854d0e).withAlpha(51); fg = const Color(0xFFfde047);
    } else if (status.toLowerCase() == 'ready') {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
