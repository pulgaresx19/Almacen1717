import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void showDriverAwbDialog({
  required BuildContext context,
  required Map<String, dynamic> awbItem,
  required bool dark,
}) {
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
  final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
  final bgGlassy = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
  final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
  
  final String awbNumber = awbItem['awb']?.toString() ?? 'N/A';
  final String pieces = awbItem['found']?.toString() ?? '0';
  final String weight = awbItem['weight']?.toString() ?? '0';

  showDialog(
    context: context,
    barrierDismissible: true, // Can close easily
    builder: (ctx) {
      final size = MediaQuery.of(context).size;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: size.height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: bgDialog,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3b82f6).withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF3b82f6), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AWB Details', style: TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(awbNumber, style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: textS),
                          hoverColor: Colors.white.withAlpha(10),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),
                  
                  // Summary Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: bgGlassy,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Total Pieces', pieces, textS, textP),
                        _buildSummaryItem('Total Weight', '$weight kg', textS, textP),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),

                  // FutureBuilder for awb_splits
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: Supabase.instance.client
                        .from('awbs')
                        .select('id, awb, awb_splits(*)')
                        .eq('awb', awbNumber)
                        .maybeSingle(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading locations.', style: TextStyle(color: textS)));
                        }
                        
                        final data = snapshot.data;
                        if (data == null) {
                          return Center(child: Text('AWB not found in master database.', style: TextStyle(color: textS)));
                        }
                        
                        final List<dynamic> splits = data['awb_splits'] ?? [];
                        
                        if (splits.isEmpty) {
                          return Center(child: Text('No locations recorded for this AWB.', style: TextStyle(color: textS)));
                        }
                        
                        return ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: splits.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final split = splits[index];
                            final splitPieces = split['pieces']?.toString() ?? '0';
                            
                            // Extract location
                            String locationName = 'Unknown Location';
                            if (split['data_location'] is Map) {
                              final locMap = split['data_location'] as Map;
                              locationName = locMap['name']?.toString() ?? locMap['id']?.toString() ?? locationName;
                            }
                            
                            // Extract coordinator
                            String coordName = 'Unknown Coordinator';
                            if (split['data_coordinator'] is Map) {
                              final coordMap = split['data_coordinator'] as Map;
                              coordName = coordMap['name']?.toString() ?? coordMap['email']?.toString() ?? coordName;
                            }
                            
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: dark ? Colors.white.withAlpha(5) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.place_rounded, color: Color(0xFF10b981), size: 16),
                                      const SizedBox(width: 8),
                                      Text(locationName, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366f1).withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('$splitPieces pcs', style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.person_rounded, color: textS, size: 14),
                                      const SizedBox(width: 6),
                                      Text(coordName, style: TextStyle(color: textS, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildSummaryItem(String label, String value, Color textS, Color textP) {
  return Column(
    children: [
      Text(label, style: TextStyle(color: textS, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );
}
