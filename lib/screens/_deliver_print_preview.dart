import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showDeliverPrintPreviewDialog(BuildContext context, Map<String, dynamic> u) {
  showDialog(
    context: context,
    builder: (context) {
      final double width = MediaQuery.of(context).size.width * 0.8;
      final double maxHeight = MediaQuery.of(context).size.height * 0.9;

      List awbs = [];
      if (u['list-pickup'] != null && u['list-pickup'] is List) {
        awbs = u['list-pickup'] as List;
      } else if (u['list-pickup'] != null && u['list-pickup'].toString().isNotEmpty) {
        awbs = [u['list-pickup'].toString()];
      }

      String formatTime(String? ts) {
         if (ts == null || ts.trim().isEmpty || ts == '-') return '--:--';
         try {
           final tdt = DateTime.tryParse(ts)?.toLocal();
           if (tdt != null) return DateFormat('hh:mm a').format(tdt);
         } catch (_) {}
         return ts;
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
                        const Text('PRINT DELIVERY DATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                // GENERAL INFO
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
                                                     const Text('TRUCK COMPANY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${u['truck-company'] ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('DRIVER NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${u['driver'] ?? '-'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('ID PICKUP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${u['id-pickup'] ?? '-'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                                     const Text('TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${u['type'] ?? '-'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${u['status'] ?? '-'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('DOOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text('${u['door'] ?? '-'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('PRIORITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text((u['isPriority'] == true || u['isPriority']?.toString().toLowerCase() == 'true') ? 'YES' : 'NO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: (u['isPriority'] == true || u['isPriority']?.toString().toLowerCase() == 'true') ? Colors.orange : Colors.black)),
                                                  ]
                                               )),
                                               Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     const Text('ARRIVAL TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                                     Text(formatTime(u['time-deliver']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ]
                                               )),
                                            ]
                                         ),
                                         const SizedBox(height: 16),
                                         Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                               const Text('REMARKS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
                                               Text('${u['remarks'] ?? 'No remarks'}', style: const TextStyle(fontSize: 14)),
                                            ]
                                         ),
                                      ]
                                   )
                                ),

                                const SizedBox(height: 32),
                                // AWB LIST
                                const Text('AWBS ASSIGNED TO THIS DELIVERY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                                  Expanded(flex: 2, child: Text('PIECES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 5, child: Text('REMARKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                               ]
                                            )
                                         ),
                                         if (awbs.isEmpty)
                                           Container(
                                              padding: const EdgeInsets.all(16),
                                              child: const Center(child: Text('No AWBs found for this delivery')),
                                           )
                                         else
                                           ...awbs.asMap().entries.map((entry) {
                                              final int index = entry.key;
                                              final String str = entry.value.toString();
                                              final parts = str.split(' - ');
                                              final String num = parts.isNotEmpty ? parts[0].trim() : '';
                                              final String pcs = parts.length > 1 ? parts[1].trim() : '';
                                              final String rem = parts.length > 2 ? parts[2].trim() : '';

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
                                                       Expanded(flex: 3, child: Text(num.isNotEmpty ? num : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                                       Expanded(flex: 2, child: Text(pcs.isNotEmpty ? pcs : '0', style: const TextStyle(fontSize: 12))),
                                                       Expanded(flex: 5, child: Text(rem.isNotEmpty ? rem : '', style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                    ]
                                                 )
                                              );
                                           }),
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
