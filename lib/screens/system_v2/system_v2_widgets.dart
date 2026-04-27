import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage;
import 'system_v2_logic.dart';

class SystemV2UldItem extends StatelessWidget {
  final Map<String, dynamic> uld;
  final bool isFlightReceived;
  final bool dark;
  final Color bgCard;
  final Color borderC;
  final Color textP;
  final Color textS;
  final int index;
  final List match;
  final SystemPanelLogic logic;

  const SystemV2UldItem({
    super.key,
    required this.uld,
    required this.isFlightReceived,
    required this.dark,
    required this.bgCard,
    required this.borderC,
    required this.textP,
    required this.textS,
    required this.index,
    required this.match,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLastTouched = logic.lastReceivedUld?['id_uld'] == uld['id_uld'];
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLastTouched ? const Color(0xFF10b981).withAlpha(dark ? 25 : 15) : bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLastTouched ? const Color(0xFF10b981).withAlpha(150) : borderC,
              width: 1.0,
            ),
            boxShadow: isLastTouched
                ? [BoxShadow(color: const Color(0xFF10b981).withAlpha(15), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        hoverColor: dark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(10),
                        splashColor: dark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(10),
                        onTap: () {
                          if (match.isNotEmpty) {
                            logic.loadAwbs(uld);
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 105,
                      child: Text('${uld['uld_number'] ?? '-'}', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 55,
                      child: Text(
                        '${uld['pieces_total'] ?? uld['pieces'] ?? '-'} pcs',
                        style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${uld['weight_total'] ?? uld['weight'] ?? '-'} kg',
                        style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (uld['remarks'] != null && uld['remarks'].toString().trim().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf59e0b).withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFf59e0b).withAlpha(40)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Text('${uld['remarks']}', style: const TextStyle(color: Color(0xFFd97706), fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ] else const Spacer(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Container(
                    width: 75,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (uld['is_break'] == true) ? const Color(0xFF10b981).withAlpha(30) : const Color(0xFFef4444).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (uld['is_break'] == true) ? 'Break' : 'No Break',
                      style: TextStyle(color: (uld['is_break'] == true) ? const Color(0xFF10b981) : const Color(0xFFef4444), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isFlightReceived || uld['time_received'] != null,
                      activeColor: isFlightReceived ? const Color(0xFF10b981) : const Color(0xFF6366f1),
                      side: BorderSide(color: isFlightReceived ? Colors.transparent : borderC, width: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: isFlightReceived ? null : (v) => logic.toggleUldReceived(uld, v == true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (uld['isPriority'] == true || uld['is_priority'] == true)
          Positioned(
            top: -4,
            left: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }
}


class SystemV2StatsFooter extends StatelessWidget {
  final SystemPanelLogic logic;
  final bool isFlightReceived;
  final bool dark;
  final Color borderC;

  const SystemV2StatsFooter({
    super.key,
    required this.logic,
    required this.isFlightReceived,
    required this.dark,
    required this.borderC,
  });

  Widget _buildTotalStat(String label, int rem, int total, Color color) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$rem', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              TextSpan(text: ' / $total', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final flightList = logic.flights;
    final currentFlightIdx = flightList.indexWhere((f) => '${f['carrier']}-${f['number']}' == logic.selectedFlightId);
    final currentFlight = currentFlightIdx != -1 ? flightList[currentFlightIdx] : null;
    String? fTruck = currentFlight?['first_truck']?.toString();
    String? lTruck = currentFlight?['last_truck']?.toString();

    if (currentFlight != null) {
      final Map<String, dynamic> truckMap = currentFlight['local_truck_arrived'] is Map
          ? Map<String, dynamic>.from(currentFlight['local_truck_arrived'])
          : {};
      if (truckMap.isNotEmpty) {
        List<String> times = truckMap.values.map((v) => v.toString()).toList();
        times.sort((a, b) => a.compareTo(b));
        fTruck ??= times.first;
      } else if (currentFlight['local_first_truck'] != null) {
        fTruck ??= currentFlight['local_first_truck'].toString();
      }
    }

    String toAmPm(String? t) {
      if (t == null || t.isEmpty || t == 'null') return '-';
      try {
        DateTime dt = DateTime.parse(t).toLocal();
        return DateFormat('h:mm a').format(dt).toLowerCase();
      } catch (_) {}
      try {
        final pts = t.split(':');
        if (pts.length >= 2) {
          int h = int.parse(pts[0]);
          int m = int.parse(pts[1]);
          bool pm = h >= 12;
          int h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          return '$h12:${m.toString().padLeft(2, '0')} ${pm ? 'PM' : 'AM'}';
        }
      } catch (_) {}
      return t;
    }

    bool allSelected = logic.ulds.isNotEmpty && logic.ulds.every((u) => u['time_received'] != null);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 6),
                  Text('First Truck: ${toAmPm(fTruck)}', style: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8), fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 6),
                  Text('Last Truck: ${toAmPm(lTruck)}', style: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderC),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTotalStat(
                      'Break',
                      logic.ulds.where((u) => (isFlightReceived || u['time_received'] != null) && u['is_break'] == true).length,
                      logic.ulds.where((u) => u['is_break'] == true).length,
                      const Color(0xFF10b981),
                    ),
                    _buildTotalStat(
                      'No Break',
                      logic.ulds.where((u) => (isFlightReceived || u['time_received'] != null) && (u['is_break'] == false || u['is_break'] == null)).length,
                      logic.ulds.where((u) => u['is_break'] == false || u['is_break'] == null).length,
                      const Color(0xFFef4444),
                    ),
                    _buildTotalStat(
                      'Total',
                      logic.ulds.where((u) => (isFlightReceived || u['time_received'] != null)).length,
                      logic.ulds.length,
                      const Color(0xFF6366f1),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 16), color: borderC),
              ElevatedButton.icon(
                onPressed: isFlightReceived
                    ? null
                    : allSelected
                        ? () async {
                            try {
                              await logic.receiveFlight();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        : null,
                icon: Icon(isFlightReceived ? Icons.verified : Icons.check_circle_outline, size: 20),
                label: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      appLanguage.value == 'es' ? 'Marcar como Recibido' : 'Mark Flight as Received',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.transparent),
                    ),
                    Text(
                      isFlightReceived 
                          ? (appLanguage.value == 'es' ? 'Vuelo Recibido' : 'Flight Received') 
                          : (appLanguage.value == 'es' ? 'Marcar como Recibido' : 'Mark Flight as Received'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFlightReceived ? Colors.lightBlue.shade100 : const Color(0xFF10b981),
                  disabledBackgroundColor: isFlightReceived ? Colors.lightBlue.withAlpha(dark ? 40 : 100) : const Color(0xFF10b981).withAlpha(60),
                  disabledForegroundColor: isFlightReceived ? Colors.lightBlue.shade700 : (dark ? Colors.white.withAlpha(100) : Colors.black38),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}


class SystemV2AwbOverlay extends StatelessWidget {
  final SystemPanelLogic logic;
  final bool dark;
  final Color textP;
  final Color textS;
  final Color borderC;

  const SystemV2AwbOverlay({
    super.key,
    required this.logic,
    required this.dark,
    required this.textP,
    required this.textS,
    required this.borderC,
  });

  @override
  Widget build(BuildContext context) {
    if (logic.activeAwbOverlay == null) return const SizedBox.shrink();
    
    final activeUld = logic.activeAwbOverlay!;
    final list = (activeUld['awbList'] as List?) ?? [];
    final isLoading = activeUld['isLoadingAwbs'] == true;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(dark ? 120 : 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AWBs for ${activeUld['uld_number'] ?? 'Unknown'}', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (activeUld['time_received'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF10b981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Received by ${activeUld['user_received'] ?? 'Unknown'} at ${DateFormat('MMM dd, hh:mm a').format(DateTime.parse(activeUld['time_received']).toLocal())}',
                              style: const TextStyle(color: Color(0xFF10b981), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF6366f1))))
                  else if (list.isEmpty)
                    Text('No AWBs found', style: TextStyle(color: textS))
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => Divider(color: borderC),
                        itemBuilder: (c, i) {
                          final awb = list[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long, size: 16, color: Color(0xFF94a3b8)),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${awb['number'] ?? '-'}', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w600))),
                                Text('PCs: ${awb['pieces'] ?? '-'}', style: TextStyle(color: textS, fontSize: 13)),
                                const SizedBox(width: 16),
                                SizedBox(width: 60, child: Text('${awb['weight'] ?? '-'} kg', style: TextStyle(color: textS, fontSize: 13), textAlign: TextAlign.right)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: logic.closeAwbOverlay,
                      child: const Text('OK', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SystemV2SuccessOverlay extends StatelessWidget {
  final SystemPanelLogic logic;
  final bool dark;
  final Color textP;

  const SystemV2SuccessOverlay({
    super.key,
    required this.logic,
    required this.dark,
    required this.textP,
  });

  @override
  Widget build(BuildContext context) {
    if (!logic.showReceivedOverlay) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1e293b) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 64),
              const SizedBox(height: 16),
              Text(
                appLanguage.value == 'es'
                    ? 'Vuelo ${logic.selectedFlightId?.replaceAll('-', ' ') ?? ''} recibido exitosamente'
                    : 'Flight ${logic.selectedFlightId?.replaceAll('-', ' ') ?? ''} received successfully',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textP),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
