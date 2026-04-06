import 'package:flutter/material.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;

class DashboardViewModule extends StatelessWidget {
  const DashboardViewModule({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title matches the style in other modules
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: isSidebarExpandedNotifier,
                        builder: (context, expanded, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: expanded ? 0 : 44,
                          );
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(appLanguage.value == 'es' ? 'Panel Principal' : 'Dashboard Overview', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(appLanguage.value == 'es' ? 'Resumen operativo del almacén y vuelos en tiempo real.' : 'Real-time operational overview of warehouse and flights.', style: TextStyle(color: textS, fontSize: 13)),
                    ],
                  ),
                    ],
                  ),
                  _buildQuickActionButton(context, dark),
                ],
              ),
              const SizedBox(height: 30),
              
              // Top Stats Grid
              _buildStatsGrid(context, dark),
              const SizedBox(height: 24),

              // Main content area
              LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive logic
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildRecentFlightsList(context, dark)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildOperationsSummaryCard(context, dark)),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRecentFlightsList(context, dark),
                        const SizedBox(height: 24),
                        _buildOperationsSummaryCard(context, dark),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(BuildContext context, bool dark) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(appLanguage.value == 'es' ? 'Generando reporte de operaciones...' : 'Generating operations report...'),
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
           ),
        );
      },
      icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
      label: Text(appLanguage.value == 'es' ? 'Reporte' : 'Report', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3b82f6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool dark) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
      return GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 3.0,
        children: [
          _buildStatCard(context, dark, 'Vuelos Activos', 'Active Flights', '12', Icons.flight_takeoff, const Color(0xFF3b82f6)),
          _buildStatCard(context, dark, 'ULDs Pendientes', 'Pending ULDs', '48', Icons.inventory_2_outlined, const Color(0xFFf59e0b)),
          _buildStatCard(context, dark, 'AWBs Procesados', 'Processed AWBs', '156', Icons.description_outlined, const Color(0xFF10b981)),
          _buildStatCard(context, dark, 'Entregas Hoy', 'Deliveries Today', '34', Icons.local_shipping_outlined, const Color(0xFF8b5cf6)),
        ],
      );
    });
  }

  Widget _buildStatCard(BuildContext context, bool dark, String titleEs, String titleEn, String value, IconData icon, Color accentColor) {
    final Color bg = dark ? const Color(0xFF1e293b) : const Color(0xFFffffff);
    final Color border = dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB);
    final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final Color textP = dark ? Colors.white : const Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(appLanguage.value == 'es' ? 'Accediendo a estadísticas de $titleEs...' : 'Accessing $titleEn statistics...'),
               behavior: SnackBarBehavior.floating,
             ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withAlpha(30),
        highlightColor: accentColor.withAlpha(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: dark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appLanguage.value == 'es' ? titleEs : titleEn,
                      style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(color: textP, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsSummaryCard(BuildContext context, bool dark) {
    final Color bg = dark ? const Color(0xFF1e293b) : const Color(0xFFffffff);
    final Color border = dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB);
    final Color shadow = dark ? Colors.black.withAlpha(25) : const Color(0xFF000000).withAlpha(12);
    final Color textP = dark ? Colors.white : const Color(0xFF111827);
    final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLanguage.value == 'es' ? 'Capacidad y Progreso' : 'Capacity & Progress',
            style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            appLanguage.value == 'es' ? 'Resumen del estado del almacén.' : 'Running status of warehouse capacity.',
            style: TextStyle(color: textS, fontSize: 13),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularChart(78, const Color(0xFF3b82f6), textP, appLanguage.value == 'es' ? 'Almacén' : 'Storage'), 
              _buildCircularChart(45, const Color(0xFF10b981), textP, appLanguage.value == 'es' ? 'Desglose' : 'Breakdown'),
            ],
          ),
          const SizedBox(height: 30),
          _buildActionRow(context, dark, appLanguage.value == 'es' ? 'Auditoría de ULDs' : 'ULD Audit', Icons.rule, const Color(0xFF6366f1)),
          const SizedBox(height: 12),
          _buildActionRow(context, dark, appLanguage.value == 'es' ? 'Alertas de Manifiestos' : 'Manifest Alerts', Icons.warning_amber_rounded, const Color(0xFFef4444)),
          const SizedBox(height: 12),
          _buildActionRow(context, dark, appLanguage.value == 'es' ? 'Asignaciones Rápidas' : 'Quick Assignments', Icons.touch_app_outlined, const Color(0xFFf59e0b)),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, bool dark, String title, IconData icon, Color color) {
    final Color textP = dark ? Colors.white : const Color(0xFF111827);
    final Color border = dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5);
    
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage.value == 'es' ? 'Abriendo vista de $title...' : 'Opening $title view...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, color: dark ? Colors.white54 : Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularChart(int percentage, Color color, Color textP, String label) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: textP,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w600),
        )
      ],
    );
  }

  Widget _buildRecentFlightsList(BuildContext context, bool dark) {
    final Color bg = dark ? const Color(0xFF1e293b) : const Color(0xFFffffff);
    final Color border = dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB);
    final Color shadow = dark ? Colors.black.withAlpha(25) : const Color(0xFF000000).withAlpha(12);
    final Color textP = dark ? Colors.white : const Color(0xFF111827);
    final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    
    final List<Map<String, dynamic>> recentActivity = [
      {'flight': 'AA 1092', 'route': 'MIA → JFK', 'status': appLanguage.value == 'es' ? 'Aterrizado' : 'Landed', 'time': '10:45 AM', 'color': const Color(0xFF10b981), 'icon': Icons.flight_land},
      {'flight': 'DL 405', 'route': 'ATL → LAX', 'status': appLanguage.value == 'es' ? 'En Proceso' : 'Processing', 'time': '09:30 AM', 'color': const Color(0xFFf59e0b), 'icon': Icons.sync},
      {'flight': 'UA 88', 'route': 'ORD → SFO', 'status': appLanguage.value == 'es' ? 'Completado' : 'Completed', 'time': 'Yesterday', 'color': const Color(0xFF3b82f6), 'icon': Icons.check_circle_outline},
      {'flight': 'BA 201', 'route': 'LHR → JFK', 'status': appLanguage.value == 'es' ? 'Retrasado' : 'Delayed', 'time': '14:00 PM', 'color': const Color(0xFFef4444), 'icon': Icons.warning_amber_rounded},
      {'flight': 'IB 6401', 'route': 'MAD → MIA', 'status': appLanguage.value == 'es' ? 'En Aproximación' : 'Approaching', 'time': 'In 20 mins', 'color': const Color(0xFF8b5cf6), 'icon': Icons.flight},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appLanguage.value == 'es' ? 'Actividad de Vuelos Reciente' : 'Recent Flight Activity',
                style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(appLanguage.value == 'es' ? 'Cargando directorio de vuelos...' : 'Loading flight directory...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(appLanguage.value == 'es' ? 'Ver Todos' : 'View All', style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentActivity.length,
            separatorBuilder: (context, index) => Divider(color: border, height: 16),
            itemBuilder: (context, index) {
              final item = recentActivity[index];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                hoverColor: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item['color'].withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'], color: item['color'], size: 24),
                ),
                title: Text(item['flight'], style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('${item['route']}  •  ${item['status']}  •  ${item['time']}', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(appLanguage.value == 'es' ? 'Gestionando vuelo ${item['flight']}...' : 'Managing flight ${item['flight']}...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark ? Colors.white.withAlpha(15) : const Color(0xFFf1f5f9),
                    foregroundColor: dark ? Colors.white : const Color(0xFF0f172a),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(appLanguage.value == 'es' ? 'Gestionar' : 'Manage', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(appLanguage.value == 'es' ? 'Vuelo seleccionado: ${item['flight']}' : 'Selected flight: ${item['flight']}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
