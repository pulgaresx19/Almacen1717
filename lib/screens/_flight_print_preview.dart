import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showFlightPrintPreviewDialog(BuildContext context, Map<String, dynamic> flight, List uldList) {
  showDialog(
    context: context,
    builder: (context) {
      final double width = MediaQuery.of(context).size.width * 0.8;
      final double maxHeight = MediaQuery.of(context).size.height * 0.9;

      String formatTime(String? ts) {
         if (ts == null || ts.trim().isEmpty || ts == '-') return '--:--';
         if (ts.toUpperCase().contains('AM') || ts.toUpperCase().contains('PM')) return ts;
         try {
           if (ts.contains('T') || ts.contains('-')) {
             final dt = DateTime.parse(ts).toUtc();
             final chicago = dt.subtract(const Duration(hours: 5, minutes: 0));
             return DateFormat('hh:mm a').format(chicago).toUpperCase();
           } else {
             final parts = ts.trim().split(':');
             if (parts.length >= 2) {
                return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]))).toUpperCase();
             }
           }
         } catch (_) {}
         return ts;
      }

      String formatDate(String? ts) {
         if (ts == null || ts.trim().isEmpty || ts == '-') return '';
         try {
           if (ts.contains('T') || ts.contains('-')) {
             final dt = DateTime.parse(ts).toLocal();
             return DateFormat('MM/dd/yyyy').format(dt);
           }
         } catch (_) {}
         return '';
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: width > 900 ? 900 : width,
          height: maxHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontFamily: 'Roboto'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                   decoration: BoxDecoration(
                     color: Colors.grey.shade100,
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                     border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        const Text('PRINT FLIGHT DATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                           children: [
                              ElevatedButton.icon(
                                 onPressed: () {}, 
                                 icon: const Icon(Icons.print, size: 16),
                                 label: const Text('Simulate Print'),
                                 style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366f1), 
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                 )
                              ),
                              const SizedBox(width: 16),
                              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                           ]
                        )
                     ]
                   )
                 ),
                 Expanded(
                    child: SingleChildScrollView(
                       padding: const EdgeInsets.all(32),
                       child: Container(
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                // GENERAL FLIGHT INFO
                                Container(
                                   padding: const EdgeInsets.all(16),
                                   decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                                   child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                         Row(
                                            children: [
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('CARRIER & NUMBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${flight['carrier'] ?? ''} ${flight['number'] ?? ''}'.trim(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('DATE ARRIVED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text(formatDate(flight['date-arrived']?.toString()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('TIME ARRIVED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text(formatTime(flight['time-arrived']?.toString()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                            ]
                                         ),
                                         const SizedBox(height: 16),
                                         Row(
                                            children: [
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('TOTAL ULD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${(int.tryParse(flight['cant-break']?.toString() ?? '0') ?? 0) + (int.tryParse(flight['cant-noBreak']?.toString() ?? '0') ?? 0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('BREAK ULDs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${flight['cant-break'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('NO BREAK ULDs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${flight['cant-noBreak'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                            ]
                                         ),
                                      ]
                                   )
                                ),

                                const SizedBox(height: 16),
                                // TIMES BREAKDOWN
                                Container(
                                   decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                                   child: Row(
                                      children: [
                                         Expanded(child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                                            child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.center,
                                               children: [
                                                  const Text('START BREAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                  const SizedBox(height: 4),
                                                  Text(formatTime(flight['start-break']?.toString()), style: const TextStyle(fontSize: 14)),
                                               ]
                                            ),
                                         )),
                                         Expanded(child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                                            child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.center,
                                               children: [
                                                  const Text('END BREAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                  const SizedBox(height: 4),
                                                  Text(formatTime(flight['end-break']?.toString()), style: const TextStyle(fontSize: 14)),
                                               ]
                                            ),
                                         )),
                                         Expanded(child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                                            child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.center,
                                               children: [
                                                  const Text('FIRST TRUCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                  const SizedBox(height: 4),
                                                  Text(formatTime(flight['first-truck']?.toString()), style: const TextStyle(fontSize: 14)),
                                               ]
                                            ),
                                         )),
                                         Expanded(child: Container(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.center,
                                               children: [
                                                  const Text('LAST TRUCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                  const SizedBox(height: 4),
                                                  Text(formatTime(flight['last-truck']?.toString()), style: const TextStyle(fontSize: 14)),
                                               ]
                                            ),
                                         )),
                                      ]
                                   )
                                ),

                                const SizedBox(height: 32),
                                // ULD LIST
                                const Text('ULD REGISTERED TO THIS FLIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                Container(
                                   decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                                   child: Column(
                                      children: [
                                         Container(
                                            color: Colors.grey.shade300,
                                            padding: const EdgeInsets.all(8),
                                            child: const Row(
                                               children: [
                                                  SizedBox(width: 40, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                                  Expanded(flex: 3, child: Text('BUILD UP / ULD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 1, child: Text('PCS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('WEIGHT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 4, child: Text('REMARKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('TIME RCV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                               ]
                                            )
                                         ),
                                         if (uldList.isEmpty)
                                           Container(
                                              padding: const EdgeInsets.all(16),
                                              child: const Center(child: Text('No ULDs found in this flight')),
                                           )
                                         else
                                           ...uldList.asMap().entries.map((entry) {
                                              final int index = entry.key;
                                              final uld = entry.value;
                                              if (uld is! Map) return const SizedBox.shrink();
                                               String rawTime = '';
                                              final dr = uld['data-received'];
                                              if (dr is List && dr.isNotEmpty) {
                                                  if (dr.last is Map) {
                                                      rawTime = dr.last['time']?.toString() ?? dr.last['time-receive']?.toString() ?? '';
                                                  }
                                              } else if (dr is Map) {
                                                  rawTime = dr['time']?.toString() ?? dr['time-receive']?.toString() ?? '';
                                              }
                                              final String parsedTimeReceived = formatTime(rawTime);

                                              return Container(
                                                 padding: const EdgeInsets.all(8),
                                                 decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black26))),
                                                 child: Row(
                                                    children: [
                                                       SizedBox(
                                                          width: 40,
                                                          child: Center(
                                                             child: Container(
                                                                width: 24,
                                                                height: 24,
                                                                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                                                                alignment: Alignment.center,
                                                                child: Text('${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                             ),
                                                          )
                                                       ),
                                                        Expanded(flex: 3, child: Text(uld['ULD-number']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                                       Expanded(flex: 2, child: Text((uld['isBreak'] == true || uld['isBreak']?.toString().toLowerCase() == 'true') ? 'BREAK' : 'NO BREAK', style: const TextStyle(fontSize: 12))),
                                                       Expanded(flex: 1, child: Text(uld['pieces']?.toString() ?? '0', style: const TextStyle(fontSize: 12))),
                                                       Expanded(flex: 2, child: Text('${uld['weight'] ?? 0} kg', style: const TextStyle(fontSize: 12))),
                                                       Expanded(flex: 4, child: Text(uld['remarks']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                       Expanded(flex: 2, child: Text(parsedTimeReceived, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo))),
                                                    ]
                                                 )
                                              );
                                           })
                                      ]
                                   )
                                ),
                             ]
                          )
                       )
                    )
                 )
              ]
            )
          )
        )
      );
    }
  );
}
