import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage;
import 'location_v2_logic.dart';
import 'location_v2_uld_modal.dart';

class LocationV2Ulds extends StatelessWidget {
  final LocationV2Logic logic;
  final bool dark;
  final Color textP;
  final Color textS;
  final Color bgCard;
  final Color borderC;
  final VoidCallback? onUldCompleted;

  const LocationV2Ulds({
    super.key,
    required this.logic,
    required this.dark,
    required this.textP,
    required this.textS,
    required this.bgCard,
    required this.borderC,
    this.onUldCompleted,
  });

  void _showUldInfoDialog(BuildContext context, Map<String, dynamic> uld) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appLanguage.value == 'es' ? 'Info de la Paleta' : 'ULD Info', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (uld['time_received'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.download_done, size: 16, color: Color(0xFF6366f1)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appLanguage.value == 'es' ? 'Recibido Por' : 'Received By', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${uld['user_received'] ?? 'Unknown'}', style: TextStyle(color: textP, fontSize: 14)),
                                Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(uld['time_received']).toLocal()), style: TextStyle(color: textS, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (uld['time_checked'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.done_all, size: 16, color: Color(0xFF10b981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appLanguage.value == 'es' ? 'Chequeado Por' : 'Checked By', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${uld['user_checked'] ?? 'Unknown'}', style: TextStyle(color: textP, fontSize: 14)),
                                Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(uld['time_checked']).toLocal()), style: TextStyle(color: textS, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (uld['time_saved'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appLanguage.value == 'es' ? 'Localizado Por' : 'Located By', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${uld['user_saved'] ?? 'Unknown'}', style: TextStyle(color: textP, fontSize: 14)),
                                Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(uld['time_saved']).toLocal()), style: TextStyle(color: textS, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (uld['time_received'] == null && uld['time_checked'] == null && uld['time_saved'] == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(appLanguage.value == 'es' ? 'Aún no se ha recibido, chequeado ni localizado.' : 'Not received, checked, or located yet.', style: TextStyle(color: textS)),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(appLanguage.value == 'es' ? 'Cerrar' : 'Close', style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (logic.isLoadingUlds) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF6366f1)),
        ),
      );
    }

    if (logic.ulds.isEmpty) {
      return Text(
        appLanguage.value == 'es'
            ? 'No hay ULDs encontrados para este vuelo.'
            : 'No ULDs found for this flight.',
        style: TextStyle(color: textS),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: logic.ulds.length,
        itemBuilder: (context, index) {
          final isPhone = MediaQuery.of(context).size.width < 600;
          final uld = logic.ulds[index];
          final int pieces = uld['pieces_total'] ?? 0;
          final String remarks = uld['remarks']?.toString() ?? '';


          final String uldIdStr = uld['id_uld']?.toString() ?? '';
          final bool isSelected = logic.selectedUldId == uldIdStr;
          final bool isCompleted = uld['time_saved'] != null;

          bool isReadyToComplete = false;
          if (!isCompleted && uldIdStr.isNotEmpty) {
            final uldAwbs = logic.allFlightAwbs.where((awb) => awb['uld_id']?.toString() == uldIdStr).toList();
            if (uldAwbs.isNotEmpty) {
              isReadyToComplete = uldAwbs.every((awb) {
                final locData = awb['data_location'];
                if (locData is Map) {
                  if (locData['locations'] is List && (locData['locations'] as List).isNotEmpty) return true;
                  if (locData['location'] != null && locData['location'].toString().trim().isNotEmpty) return true;
                }
                return false;
              });
            }
          }

          Color getBgColor() {
            if (isCompleted) return const Color(0xFF10b981).withAlpha(10);
            return isSelected ? const Color(0xFF6366f1).withAlpha(10) : bgCard;
          }

          Color getBorderColor() {
            if (isCompleted) return const Color(0xFF10b981).withAlpha(40);
            return isSelected ? const Color(0xFF6366f1).withAlpha(50) : borderC;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getBgColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: getBorderColor(),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final id = uld['id_uld']?.toString() ?? '';
                    if (id.isNotEmpty) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => LocationV2UldModal(
                          uld: uld,
                          logic: logic,
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showUldInfoDialog(context, uld),
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366f1).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF6366f1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 105,
                              child: Text(
                                '${uld['uld_number'] ?? '-'}',
                                style: TextStyle(
                                  color: textP,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isPhone) ...[
                              const SizedBox(width: 12),
                              Container(
                                width: 75,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PCs: $pieces',
                                  style: TextStyle(color: textS, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (remarks.trim().isNotEmpty) ...[
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
                                    child: Text(
                                      remarks,
                                      style: const TextStyle(
                                        color: Color(0xFFd97706),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Spacer(),
                            ],
                            const SizedBox(width: 12),
                            SizedBox(
                              width: isPhone ? 40 : 120,
                              child: isCompleted ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: isPhone ? 4 : 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10b981).withAlpha(20),
                                  borderRadius: BorderRadius.circular(isPhone ? 20 : 8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 16),
                                    if (!isPhone) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        appLanguage.value == 'es' ? 'Completado' : 'Completed',
                                        style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ) : Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: appLanguage.value == 'es' 
                                    ? (isReadyToComplete ? 'Marcar Completado' : 'Faltan locaciones') 
                                    : (isReadyToComplete ? 'Mark Completed' : 'Missing locations'),
                                  icon: Icon(
                                    Icons.check_circle_outline, 
                                    color: isReadyToComplete ? const Color(0xFF10b981) : const Color(0xFF94a3b8).withAlpha(100)
                                  ),
                                  hoverColor: isReadyToComplete ? const Color(0xFF10b981).withAlpha(20) : Colors.transparent,
                                  onPressed: isReadyToComplete ? () {
                                    final idUld = uld['id_uld']?.toString();
                                    if (idUld != null && idUld.isNotEmpty) {
                                      onUldCompleted?.call();
                                      logic.markUldAsCompleted(idUld);
                                    }
                                  } : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: textS,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
