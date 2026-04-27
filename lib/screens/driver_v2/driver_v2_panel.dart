import 'package:flutter/material.dart';

import '../../main.dart' show isDarkMode;
import 'package:intl/intl.dart';
import 'driver_v2_verify_dialog.dart';
import '../../services/realtime_service.dart';

class DriverV2Panel extends StatelessWidget {
  const DriverV2Panel({super.key});

  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: realtimeService.deliveries,
          builder: (context, deliversList, child) {
            var items = List<Map<String, dynamic>>.from(deliversList);
            
            // Sort by priority (true first), then by time (oldest first)
            items.sort((a, b) {
              final priorityA = a['is_priority'] == true ? 1 : 0;
              final priorityB = b['is_priority'] == true ? 1 : 0;
              
              if (priorityA != priorityB) {
                return priorityB.compareTo(priorityA);
              }
              
              final taStr = a['time']?.toString() ?? '';
              final tbStr = b['time']?.toString() ?? '';
              if (taStr.isEmpty && tbStr.isNotEmpty) return 1;
              if (taStr.isNotEmpty && tbStr.isEmpty) return -1;
              if (taStr.isEmpty && tbStr.isEmpty) return 0;
              
              final da = DateTime.tryParse(taStr) ?? DateTime(1970);
              final db = DateTime.tryParse(tbStr) ?? DateTime(1970);
              return da.compareTo(db);
            });

            if (items.isEmpty) {
              return Center(
                child: Text('No deliveries found.', style: TextStyle(color: dark ? Colors.white54 : Colors.black54)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final u = items[index];
                
                String company = u['company']?.toString() ?? '-';
                String driver = u['driver_name']?.toString() ?? '-';
                String door = u['door']?.toString() ?? '-';
                String type = u['type']?.toString() ?? 'Walk-In'; // Assuming type might be 'Walk-In'
                bool isPriority = u['is_priority'] == true;
                
                String timeStr = '-';
                if (u['time'] != null) {
                  final tdt = DateTime.tryParse(u['time'].toString())?.toLocal();
                  if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
                }

                return GestureDetector(
                  onTap: () {
                    showVerifyDriverDialog(
                      context: context,
                      deliveryData: u,
                      dark: dark,
                      company: company,
                      driver: driver,
                      time: timeStr,
                      door: door,
                      type: type,
                    );
                  },
                  child: _buildDeliveryItem(
                    index: index + 1,
                    company: company,
                    driver: driver,
                    time: timeStr,
                    door: door,
                    type: type,
                    dark: dark,
                    isPriority: isPriority,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryItem({
    required int index,
    required String company,
    required String driver,
    required String time,
    required String door,
    required String type,
    required bool dark,
    required bool isPriority,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          // Index Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1).withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              index.toString(),
              style: const TextStyle(
                color: Color(0xFF6366f1),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 24),
          
          // Company
          Expanded(
            flex: 2,
            child: _buildColumnInfo('COMPANY', company, dark),
          ),
          
          // Driver
          Expanded(
            flex: 2,
            child: _buildColumnInfo('DRIVER', driver, dark),
          ),
          
          // Time
          Expanded(
            flex: 2,
            child: _buildColumnInfo('TIME', time, dark),
          ),
          
          // Door
          Expanded(
            flex: 1,
            child: _buildColumnInfo('DOOR', door, dark),
          ),
          
          // Type
          Expanded(
            flex: 2,
            child: _buildColumnInfo('TYPE', type, dark),
          ),
          
          // Priority Star
          Icon(
            isPriority ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isPriority ? const Color(0xFFFACC15) : (dark ? Colors.white24 : Colors.black26),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnInfo(String label, String value, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: dark ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
