import 'package:flutter/material.dart';

import '../../main.dart' show isDarkMode;
import '../../services/realtime_service.dart';

class NoBreakAreaV2Panel extends StatelessWidget {
  final String searchQuery;
  const NoBreakAreaV2Panel({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: realtimeService.ulds,
          builder: (context, uldsList, child) {
            var items = List<Map<String, dynamic>>.from(uldsList);
            
            // Filter only No Break ULDs
            items = items.where((u) => u['is_break'] == false).toList();

            // Apply search
            if (searchQuery.isNotEmpty) {
              final query = searchQuery.toLowerCase();
              items = items.where((u) {
                final uldNumber = u['uld_number']?.toString().toLowerCase() ?? '';
                final flightNumber = u['flight_number']?.toString().toLowerCase() ?? '';
                final trackingNumber = u['tracking_number']?.toString().toLowerCase() ?? '';
                return uldNumber.contains(query) || flightNumber.contains(query) || trackingNumber.contains(query);
              }).toList();
            }

            // Sort by uld_number
            items.sort((a, b) {
               final uA = a['uld_number']?.toString() ?? '';
               final uB = b['uld_number']?.toString() ?? '';
               return uA.compareTo(uB);
            });

            if (items.isEmpty) {
              return Center(
                child: Text('No "No Break" ULDs found.', style: TextStyle(color: dark ? Colors.white54 : Colors.black54)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final u = items[index];
                
                String uldNumber = u['uld_number']?.toString() ?? '-';
                String flightNumber = u['flight_number']?.toString() ?? '-';
                String trackingNumber = u['tracking_number']?.toString() ?? '-';
                String pieces = u['pieces']?.toString() ?? '-';
                String weight = u['weight']?.toString() ?? '-';

                return _buildUldItem(
                  index: index + 1,
                  uldNumber: uldNumber,
                  flightNumber: flightNumber,
                  trackingNumber: trackingNumber,
                  pieces: pieces,
                  weight: weight,
                  dark: dark,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUldItem({
    required int index,
    required String uldNumber,
    required String flightNumber,
    required String trackingNumber,
    required String pieces,
    required String weight,
    required bool dark,
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
          
          // ULD Number
          Expanded(
            flex: 2,
            child: _buildColumnInfo('ULD NUMBER', uldNumber, dark),
          ),
          
          // Flight
          Expanded(
            flex: 2,
            child: _buildColumnInfo('FLIGHT', flightNumber, dark),
          ),
          
          // Tracking
          Expanded(
            flex: 2,
            child: _buildColumnInfo('TRACKING', trackingNumber, dark),
          ),
          
          // Pieces
          Expanded(
            flex: 1,
            child: _buildColumnInfo('PIECES', pieces, dark),
          ),
          
          // Weight
          Expanded(
            flex: 1,
            child: _buildColumnInfo('WEIGHT', weight, dark),
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
