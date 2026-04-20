import 'package:flutter/material.dart';

class AwbsV2Drawer {
  static void show(BuildContext context, Map<String, dynamic> u, bool dark, int receivedPieces, int expectedPieces, String status) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBuilder) {

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
                                Text('AWB Detail & Traceability', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(u['awb_number']?.toString() ?? 'N/A', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: textP),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text('Traceability Flow', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            // Here goes the content that we will build out later for the V2 module
                            Text('Traceability data will be loaded here...', style: TextStyle(color: textS)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            );
          }
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
