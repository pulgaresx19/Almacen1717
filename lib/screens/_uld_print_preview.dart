import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showUldPrintPreviewDialog(BuildContext context, Map<String, dynamic> uld) {
  showDialog(
    context: context,
    builder: (context) {
      final double width = MediaQuery.of(context).size.width * 0.8;
      final double maxHeight = MediaQuery.of(context).size.height * 0.9;

      List awbList = [];
      if (uld['data-ULD'] is List) {
         awbList = uld['data-ULD'] as List;
      }

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
                        const Text('PRINT ULD DATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                // GENERAL ULD INFO
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
                                                     const Text('ULD NUMBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${uld['ULD-number'] ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('REF FLIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text(uld['refCarrier'] == null ? 'Standalone ULD' : '${uld['refCarrier']} ${uld['refNumber'] ?? ''}'.trim(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('FLIGHT DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text(formatDate(uld['refDate']?.toString()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                                     const Text('TOTAL AWB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${awbList.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('TOTAL PCS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${uld['pieces'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('TOTAL WEIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${uld['weight'] ?? 0} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text((uld['isBreak'] == true || uld['isBreak']?.toString().toLowerCase() == 'true') ? 'BREAK' : 'NO BREAK', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('PRIORITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text((uld['isPriority'] == true || uld['isPriority']?.toString().toLowerCase() == 'true') ? 'YES' : 'NO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: (uld['isPriority'] == true || uld['isPriority']?.toString().toLowerCase() == 'true') ? Colors.orange : Colors.black)),
                                                  ]
                                               )),
                                            ]
                                         ),
                                      ]
                                   )
                                ),

                                const SizedBox(height: 32),
                                // AWB LIST
                                const Text('AWBS REGISTERED TO THIS ULD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                                  Expanded(flex: 3, child: Text('AWB NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 1, child: Text('PCS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('WEIGHT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 4, child: Text('REMARKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                               ]
                                            )
                                         ),
                                         if (awbList.isEmpty)
                                           Container(
                                              padding: const EdgeInsets.all(16),
                                              child: const Center(child: Text('No AWBs found in this ULD')),
                                           )
                                         else
                                           ...awbList.asMap().entries.map((entry) {
                                              final int index = entry.key;
                                              final awb = entry.value;
                                              if (awb is! Map) return const SizedBox.shrink();

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
                                                        Expanded(flex: 3, child: Text(awb['AWB-number']?.toString() ?? awb['awb_number']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                                       Expanded(flex: 1, child: Text(awb['pieces']?.toString() ?? '0', style: const TextStyle(fontSize: 12))),
                                                       Expanded(flex: 2, child: Text('${awb['weight'] ?? 0} kg', style: const TextStyle(fontSize: 12))),
                                                       Expanded(flex: 4, child: Text(awb['remarks']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                    ]
                                                 )
                                              );
                                           }),
                                      ]
                                   )
                                ),

                                const SizedBox(height: 32),
                                // AUDIT TRAIL / RECEIVED TIMESTAMPS
                                const Text('AUDIT TRAIL (RECEPTION DATA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                Builder(
                                   builder: (context) {
                                      List receivedList = [];
                                      if (uld['data-received'] is List) {
                                         receivedList = uld['data-received'] as List;
                                      } else if (uld['data-received'] is Map && (uld['data-received'] as Map).isNotEmpty) {
                                         receivedList = [uld['data-received']];
                                      }

                                      if (receivedList.isEmpty) {
                                         return Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
                                            child: const Text('No reception data available.', style: TextStyle(fontStyle: FontStyle.italic)),
                                         );
                                      }

                                      return Container(
                                         decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                                         child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: receivedList.map((rec) {
                                               if (rec is! Map) return const SizedBox.shrink();
                                               return Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black26))),
                                                  child: Wrap(
                                                     spacing: 16, runSpacing: 8,
                                                     children: [
                                                        Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('USER', style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                                              Text(rec['user']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                           ]
                                                        ),
                                                        Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('DATE', style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                                              Text(formatDate(rec['date']?.toString()), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                           ]
                                                        ),
                                                        Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('TIME RCV', style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                                              Text(formatTime(rec['time']?.toString() ?? rec['time-receive']?.toString()), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                           ]
                                                        ),
                                                        Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('STATUS', style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                                              Text(rec['status']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                           ]
                                                        ),
                                                     ]
                                                  )
                                               );
                                            }).toList(),
                                         )
                                      );
                                   }
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
