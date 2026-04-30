import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AwbsV2UldDrawer {
  static void show(BuildContext context, Map<String, dynamic> u, bool dark, String status, String flightDisplay) {
    final Future<List<Map<String, dynamic>>> splitsFuture = Supabase.instance.client
        .from('awb_splits')
        .select('*, awbs(awb_number, total_pieces, total_espected)')
        .eq('uld_id', u['id_uld'])
        .order('created_at', ascending: false)
        .then((res) => List<Map<String, dynamic>>.from(res));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        final uldNum = u['uld_number']?.toString() ?? u['ULD-number']?.toString() ?? 'N/A';
        int totalPieces = int.tryParse(u['pieces_total']?.toString() ?? '0') ?? 0;
        double totalWeight = double.tryParse(u['weight_total']?.toString() ?? '0') ?? 0.0;
        bool isPriority = u['is_priority'] == true;
        String remarks = u['remarks']?.toString() ?? '';
        if (remarks.toLowerCase() == 'null') remarks = '';

        Widget buildAwbList() {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: splitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))));
              }
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(16), child: Text('Error loading AWBs: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              
              final splits = snapshot.data ?? [];
              if (splits.isEmpty) {
                return Padding(padding: const EdgeInsets.all(16), child: Text('No AWBs found inside this ULD.', style: TextStyle(color: textS)));
              }

              return Column(
                children: splits.map((s) {
                  final awbData = s['awbs'] ?? {};
                  final String awbNumber = awbData['awb_number']?.toString() ?? 'Unknown AWB';
                  final int totalExpected = int.tryParse(awbData['total_pieces']?.toString() ?? awbData['total_espected']?.toString() ?? '0') ?? 0;
                  final int pieces = int.tryParse(s['pieces']?.toString() ?? '0') ?? 0;
                  final double weight = double.tryParse(s['weight']?.toString() ?? '0') ?? 0.0;
                  
                  final String itemRemarks = s['remarks']?.toString() ?? '';
                  List<String> houses = [];
                  final hRaw = s['house_number'];
                  if (hRaw is List) {
                    houses = hRaw.map((e) => e.toString()).toList();
                  } else if (hRaw is String && hRaw.isNotEmpty) {
                    houses = hRaw.split(RegExp(r'[,\n]')).map((str) => str.trim()).where((str) => str.isNotEmpty).toList();
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderC),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF6366f1).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF6366f1)),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: Text(awbNumber, style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 85,
                          child: Text('$pieces / $totalExpected pcs', style: TextStyle(color: textS, fontSize: 13)),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 65,
                          child: Text('$weight kg', style: TextStyle(color: textS, fontSize: 13)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: itemRemarks.isNotEmpty
                            ? Row(
                                children: [
                                  Icon(Icons.notes_rounded, size: 14, color: textS.withAlpha(150)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      itemRemarks,
                                      style: TextStyle(color: textS, fontSize: 12, fontStyle: FontStyle.italic),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                        ),
                        if (houses.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                                  title: Text('House Numbers', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                                  content: SizedBox(
                                    width: 300,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: houses.asMap().entries.map((eh) {
                                        final hi = eh.key;
                                        final h = eh.value;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3b82f6).withAlpha(30),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${hi + 1}',
                                                  style: const TextStyle(color: Color(0xFF60a5fa), fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(h, style: TextStyle(color: textS, fontSize: 14)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3b82f6).withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.house_siding_rounded, size: 12, color: Color(0xFF60a5fa)),
                                  const SizedBox(width: 4),
                                  Text('${houses.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF60a5fa), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                }).toList(),
              );
            }
          );
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: bg,
            elevation: 16,
            child: SizedBox(
              width: 520, // slightly wider to fit everything beautifully
              height: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ULD Detail & Contents', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(uldNum, style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                            if (flightDisplay.isNotEmpty && flightDisplay != '-') ...[
                              const SizedBox(height: 4),
                              Text(flightDisplay, style: const TextStyle(color: Color(0xFF6366f1), fontSize: 13, fontWeight: FontWeight.w600)),
                            ]
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textP),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text('ULD Summary', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Pieces:', style: TextStyle(color: textS)), Text(totalPieces.toString(), style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Weight:', style: TextStyle(color: textS)), Text('${totalWeight.toString().replaceAll(RegExp(r'\.$|\.0$'), '')} kg', style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Type:', style: TextStyle(color: textS)), Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFef4444).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFef4444).withAlpha(50)),
                                ),
                                child: const Text('NO BREAK', style: TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.bold)),
                              )]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Priority:', style: TextStyle(color: textS)), Text(isPriority ? 'Yes' : 'No', style: TextStyle(color: isPriority ? Colors.amber : textP, fontWeight: FontWeight.bold))]),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Status:', style: TextStyle(color: textS)), Text(status, style: TextStyle(color: textP, fontWeight: FontWeight.bold))]),
                              if (remarks.isNotEmpty) ...[
                                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Remarks:', style: TextStyle(color: textS)),
                                    const SizedBox(height: 4),
                                    Text(remarks, style: TextStyle(color: textP, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ]
                            ]
                          )
                        ),
                        const SizedBox(height: 32),
                        
                        Text('AWB Contents', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        buildAwbList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      }
    );
  }
}
