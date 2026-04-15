import 'package:flutter/material.dart';
import 'coordinator_v2_logic.dart';

class CoordinatorV2Footer extends StatelessWidget {
  final bool dark;
  final CoordinatorV2Logic logic;

  const CoordinatorV2Footer({super.key, required this.dark, required this.logic});

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
    final Color borderC = dark ? Colors.white.withAlpha(20) : Colors.grey.shade300;
    
    int totalItems = logic.ulds.length;
    int checkedItems = logic.ulds.where((u) => u['time_checked'] != null && u['time_checked'].toString().isNotEmpty).length;
    
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
                  const Text('Start Break: 15/4 6:59 am', style: TextStyle(fontSize: 13, color: Color(0xFF94a3b8), fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 6),
                  const Text('End Break: 15/4 7:05 am', style: TextStyle(fontSize: 13, color: Color(0xFF94a3b8), fontWeight: FontWeight.bold)),
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
                    _buildTotalStat('Checked', checkedItems, totalItems, const Color(0xFF10b981)),
                    _buildTotalStat('No Break', 
                      logic.ulds.where((u) => u['is_break'] == false && u['time_checked'] != null).length, 
                      logic.ulds.where((u) => u['is_break'] == false).length, 
                      const Color(0xFFef4444)
                    ),
                    _buildTotalStat('Total', checkedItems, totalItems, const Color(0xFF6366f1)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 16), color: borderC),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Mark Flight as Received', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
