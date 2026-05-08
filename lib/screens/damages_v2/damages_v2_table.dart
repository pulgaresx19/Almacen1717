import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage, isDarkMode;

class DamagesV2Table extends StatelessWidget {
  final List<Map<String, dynamic>> damages;
  final Function(Map<String, dynamic>) onSelect;

  const DamagesV2Table({super.key, required this.damages, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (damages.isEmpty) {
      return Center(
        child: Text(
          appLanguage.value == 'es' ? 'No hay reportes de daños.' : 'No damage reports found.',
          style: TextStyle(
            color: isDarkMode.value ? const Color(0xFF94a3b8) : const Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
        final textM = dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563);
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final hoverBg = dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6);

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: damages.length + 1,
          separatorBuilder: (context, index) => Container(height: 1, color: borderC),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text('#', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('AWB', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text(appLanguage.value == 'es' ? 'Tipo de Daño' : 'Damage Type', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text(appLanguage.value == 'es' ? 'Piezas' : 'Pieces', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('Flight', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('ULD', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text(appLanguage.value == 'es' ? 'Fecha' : 'Date', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text(appLanguage.value == 'es' ? 'Reportado por' : 'Reported By', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600))),
                  ],
                ),
              );
            }

            final damage = damages[index - 1];
            final dateStr = damage['created_at'] != null ? DateFormat('MM/dd/yy hh:mm a').format(DateTime.parse(damage['created_at']).toLocal()) : 'N/A';
            

            dynamic awbData = damage['awbs'];
            if (awbData is List && awbData.isNotEmpty) awbData = awbData[0];
            
            dynamic uldData = damage['ulds'];
            if (uldData is List && uldData.isNotEmpty) uldData = uldData[0];
            
            dynamic flightData = damage['flights'];
            if (flightData is List && flightData.isNotEmpty) flightData = flightData[0];

            String awbStr = (awbData != null && awbData['awb_number'] != null) ? awbData['awb_number'].toString() : '-';
            String uldStr = (uldData != null && uldData['uld_number'] != null) ? uldData['uld_number'].toString() : '-';
            String flightStr = (flightData != null && flightData['number'] != null) ? '${flightData['carrier'] ?? ''} ${flightData['number']}'.trim() : '-';

            String damageType = 'Unknown';
            if (damage['damage_type'] != null) {
              if (damage['damage_type'] is List) {
                damageType = (damage['damage_type'] as List).join(', ');
              } else {
                damageType = damage['damage_type'].toString();
              }
            }
            dynamic userData = damage['users'];
            if (userData is List && userData.isNotEmpty) userData = userData[0];
            final reportedBy = userData != null ? userData['full_name']?.toString() ?? 'Unknown' : 'Unknown';
            final pieces = damage['pieces_damage']?.toString() ?? '0';

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(damage),
                hoverColor: hoverBg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text('$index', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text(awbStr, style: TextStyle(color: textP, fontSize: 13, fontWeight: awbStr != '-' ? FontWeight.bold : FontWeight.normal))),
                      Expanded(flex: 2, child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFef4444).withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(damageType, style: const TextStyle(color: Color(0xFFef4444), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )),
                      Expanded(flex: 1, child: Text(pieces, style: TextStyle(color: textM, fontSize: 13))),
                      Expanded(flex: 2, child: Text(flightStr, style: TextStyle(color: textP, fontSize: 13, fontWeight: flightStr != '-' ? FontWeight.bold : FontWeight.normal))),
                      Expanded(flex: 2, child: Text(uldStr, style: TextStyle(color: textP, fontSize: 13, fontWeight: uldStr != '-' ? FontWeight.bold : FontWeight.normal))),
                      Expanded(flex: 2, child: Text(dateStr, style: TextStyle(color: textM, fontSize: 13))),
                      Expanded(flex: 2, child: Text(reportedBy, style: TextStyle(color: textM, fontSize: 13))),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
