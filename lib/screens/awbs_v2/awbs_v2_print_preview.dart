import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'awbs_v2_pdf_exporter.dart';

void showPrintPreviewDialog(BuildContext context, Map<String, dynamic> awb) {
  showDialog(
    context: context,
    builder: (context) {
      final double width = MediaQuery.of(context).size.width * 0.8;
      final double maxHeight = MediaQuery.of(context).size.height * 0.9;
      
      // Parse data-dc
      List dcList = [];
      if (awb['data-dc'] != null) {
         if (awb['data-dc'] is List) {
            dcList = awb['data-dc'] as List;
         } else if (awb['data-dc'] is Map && (awb['data-dc'] as Map).isNotEmpty) {
            dcList = [awb['data-dc']];
         }
      }

      // Parse data-lo
      List loList = [];
      if (awb['data-lo'] != null) {
         if (awb['data-lo'] is List) {
            loList = awb['data-lo'] as List;
         } else if (awb['data-lo'] is Map && (awb['data-lo'] as Map).isNotEmpty) {
            loList = [awb['data-lo']];
         }
      }

      // Parse data-deliver
      List delList = [];
      if (awb['data-deliver'] != null) {
         if (awb['data-deliver'] is List) {
            delList = awb['data-deliver'] as List;
         } else if (awb['data-deliver'] is Map && (awb['data-deliver'] as Map).isNotEmpty) {
            delList = [awb['data-deliver']];
         }
      }

      String formatTime(String? timeStr) {
         if (timeStr == null || timeStr.isEmpty) return '-';
         try {
           final dt = DateTime.parse(timeStr).toUtc();
           final chicago = dt.subtract(const Duration(hours: 5));
           return DateFormat('MM/dd/yy hh:mm a').format(chicago);
         } catch (e) {
           return timeStr;
         }
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: width > 950 ? 950 : width, // Slightly wider for table aesthetics
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
                        const Row(
                           children: [
                              Icon(Icons.print_rounded, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text('DOCUMENT PRINT PREVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                           ]
                        ),
                        Row(
                           children: [
                              ElevatedButton.icon(
                                 onPressed: () => AwbsV2PdfExporter.printAwbs([awb]), 
                                 icon: const Icon(Icons.print, size: 16),
                                 label: const Text('Print'),
                                 style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo, 
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                 )
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                 onPressed: () => AwbsV2PdfExporter.downloadPdf([awb]), 
                                 icon: const Icon(Icons.picture_as_pdf, size: 16),
                                 label: const Text('Download PDF'),
                                 style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white, 
                                    foregroundColor: Colors.indigo,
                                    elevation: 0,
                                    side: const BorderSide(color: Colors.indigo),
                                 )
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                 icon: const Icon(Icons.close, color: Colors.black54), 
                                 onPressed: () => Navigator.pop(context),
                                 tooltip: 'Close Preview',
                              ),
                           ]
                        )
                     ]
                   )
                 ),
                 Expanded(
                    child: SingleChildScrollView(
                       padding: const EdgeInsets.all(48),
                       child: Container(
                          decoration: BoxDecoration(
                             color: Colors.white,
                             boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                             ]
                          ),
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                // HEADER SECTION
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                           Row(
                                             children: [
                                                const Icon(Icons.local_shipping, size: 32, color: Colors.black87),
                                                const SizedBox(width: 8),
                                                const Text('AGI LOGISTICS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                             ],
                                           ),
                                           const SizedBox(height: 16),
                                           const Text('AWB TRACEABILITY & DELIVERY REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                           const SizedBox(height: 8),
                                           Text('Generated on: ${DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now())}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                        ]
                                     ),
                                     Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                           Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                 border: Border.all(color: Colors.black, width: 2),
                                                 borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Center(child: Text(awb['awb_number']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2))),
                                           ),
                                           const SizedBox(height: 8),
                                           Container(
                                              height: 45,
                                              width: 180,
                                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                                              child: const Center(child: Text('||| ||| | ||| |||||', style: TextStyle(fontSize: 32, letterSpacing: 4))),
                                           ),
                                        ]
                                     )
                                  ]
                                ),
                                const SizedBox(height: 32),
                                
                                // AWB SUMMARY
                                Container(
                                   width: double.infinity,
                                   padding: const EdgeInsets.all(16),
                                   decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                   child: Row(
                                      children: [
                                         Expanded(
                                            child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                  const Text('MANIFEST ROOT TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                                  const SizedBox(height: 4),
                                                  Text(awb['total_espected']?.toString() ?? '0', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                                               ]
                                            ),
                                         ),
                                         Container(width: 1, height: 40, color: Colors.grey.shade300),
                                         const SizedBox(width: 16),
                                         const Expanded(
                                            child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                  Text('SYSTEM INTEGRITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                                  SizedBox(height: 4),
                                                  Text('VERIFIED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green)),
                                               ]
                                            ),
                                         ),
                                         Container(width: 1, height: 40, color: Colors.grey.shade300),
                                         const SizedBox(width: 16),
                                         const Expanded(
                                            child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                  Text('REPORT ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                                  SizedBox(height: 4),
                                                  Text('DOC-TRACE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                               ]
                                            ),
                                         ),
                                      ]
                                   )
                                ),
                                const SizedBox(height: 48),

                                // DATA COORDINATORS AUDIT
                                if (dcList.isNotEmpty) ...[
                                   Row(
                                     children: [
                                        const Icon(Icons.assignment_turned_in, size: 20, color: Colors.indigo),
                                        const SizedBox(width: 8),
                                        const Text('COORDINATOR RECEIPT AUDIT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.underline)),
                                     ],
                                   ),
                                   const SizedBox(height: 16),
                                   ...dcList.map((dc) {
                                      Map bd = (dc['breakdown'] is Map) ? dc['breakdown'] as Map : {};
                                      return Container(
                                         margin: const EdgeInsets.only(bottom: 12),
                                         decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                                         child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                               Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                                                  child: Row(
                                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                     children: [
                                                        Text('User: ${dc['user']?.toString().toUpperCase() ?? 'UNKNOWN'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                        Text(formatTime(dc['time']), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                     ]
                                                  )
                                               ),
                                               Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Wrap(
                                                     spacing: 8, runSpacing: 8,
                                                     children: bd.entries.map((e) {
                                                        if (e.value is List && (e.value as List).isEmpty) return const SizedBox.shrink();
                                                        return Container(
                                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                           decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.05), border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(4)),
                                                           child: Text('${e.key}: ${e.value is List ? e.value.join(', ') : e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo)),
                                                        );
                                                     }).toList()
                                                  )
                                               )
                                            ]
                                         )
                                      );
                                   }),
                                   const SizedBox(height: 32),
                                ],

                                // LOCATIONS AUDIT
                                if (loList.isNotEmpty) ...[
                                   Row(
                                     children: [
                                        const Icon(Icons.location_on, size: 20, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        const Text('STORAGE LOCATIONS AUDIT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.underline)),
                                     ],
                                   ),
                                   const SizedBox(height: 16),
                                   ...loList.map((loc) {
                                      Map items = (loc['itemLocations'] is Map) ? loc['itemLocations'] as Map : {};
                                      return Container(
                                         margin: const EdgeInsets.only(bottom: 12),
                                         decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                                         child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                               Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                                                  child: Row(
                                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                     children: [
                                                        Text('User: ${loc['user']?.toString().toUpperCase() ?? 'UNKNOWN'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                        Text(formatTime(loc['time']), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                     ]
                                                  )
                                               ),
                                               Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Wrap(
                                                     spacing: 8, runSpacing: 8,
                                                     children: items.entries.map((e) {
                                                        if (e.value == null || e.value.toString().isEmpty) return const SizedBox.shrink();
                                                        return Container(
                                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                           decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.05), border: Border.all(color: Colors.teal.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(4)),
                                                           child: Text('${e.key} ➔ ${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
                                                        );
                                                     }).toList()
                                                  )
                                               )
                                            ]
                                         )
                                      );
                                   }),
                                   const SizedBox(height: 32),
                                ],

                                // DELIVERIES & REJECTIONS
                                Row(
                                  children: [
                                     const Icon(Icons.outbox_rounded, size: 20, color: Colors.green),
                                     const SizedBox(width: 8),
                                     const Text('DELIVERY DISPATCH RECEIPTS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.underline)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                if (delList.isEmpty)
                                   Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('No deliveries have been recorded yet.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54))
                                   )
                                else
                                   ...delList.map((del) {
                                      if (del is! Map) return const SizedBox.shrink();
                                      bool isRejected = del.containsKey('rejection') && del['rejection'] != null;
                                      Map rej = isRejected ? del['rejection'] as Map : {};
                                      return Container(
                                         margin: const EdgeInsets.only(bottom: 24),
                                         decoration: BoxDecoration(
                                            border: Border.all(color: isRejected ? Colors.red.shade300 : Colors.green.shade300, width: 2), 
                                            borderRadius: BorderRadius.circular(6)
                                         ),
                                         child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                               Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(
                                                     color: isRejected ? Colors.red.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05), 
                                                     border: Border(bottom: BorderSide(color: isRejected ? Colors.red.shade200 : Colors.green.shade200))
                                                  ),
                                                  child: Row(
                                                     children: [
                                                        Icon(isRejected ? Icons.warning_amber_rounded : Icons.check_circle, color: isRejected ? Colors.red : Colors.green, size: 20),
                                                        const SizedBox(width: 8),
                                                        Text(isRejected ? 'DELIVERY WITH REJECTION' : 'SUCCESSFUL DELIVERY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isRejected ? Colors.red : Colors.green)),
                                                        const Spacer(),
                                                        Text(formatTime(del['time']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                     ]
                                                  )
                                               ),
                                               Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Row(
                                                     children: [
                                                        Expanded(child: Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('Trucking Company', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                                                              Text(del['company']?.toString().toUpperCase() ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                                           ]
                                                        )),
                                                        Expanded(child: Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('Driver Name', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                                                              Text(del['driver']?.toString().toUpperCase() ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                                           ]
                                                        )),
                                                        Expanded(child: Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('Pickup ID', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                                                              Text(del['pickup_id']?.toString() ?? '-', style: const TextStyle(fontSize: 15)),
                                                           ]
                                                        )),
                                                        Expanded(child: Column(
                                                           crossAxisAlignment: CrossAxisAlignment.start,
                                                           children: [
                                                              const Text('Handed Pieces', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                                                              Text('${del['delivery'] ?? del['total'] ?? 0} / ${del['total'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                                           ]
                                                        )),
                                                     ]
                                                  )
                                               ),
                                               if (isRejected)
                                                  Container(
                                                     padding: const EdgeInsets.all(16),
                                                     decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), border: Border(top: BorderSide(color: Colors.red.shade200))),
                                                     child: Row(
                                                        children: [
                                                           Expanded(child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                 const Text('REJECTED QTY', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                                                 Text('${rej['qty'] ?? 0}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                                              ]
                                                           )),
                                                           Expanded(child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                 const Text('NEW LOCATION', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                                                 Text(rej['location']?.toString() ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                                              ]
                                                           )),
                                                           Expanded(flex: 2, child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                 const Text('REASON', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                                                 Text(rej['reason']?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red)),
                                                              ]
                                                           )),
                                                        ]
                                                     )
                                                  )
                                            ]
                                         )
                                      );
                                   }),
    
                                const SizedBox(height: 64),
                                
                                // Signatures Section
                                Row(
                                   children: [
                                      Expanded(child: Column(
                                         children: [
                                            Container(height: 1, color: Colors.black),
                                            const SizedBox(height: 8),
                                            const Text('Driver Signature / Full Name', style: TextStyle(fontSize: 12)),
                                         ]
                                      )),
                                      const SizedBox(width: 64),
                                      Expanded(child: Column(
                                         children: [
                                            Container(height: 1, color: Colors.black),
                                            const SizedBox(height: 8),
                                            const Text('AGI Coordinator / Warehouse Signature', style: TextStyle(fontSize: 12)),
                                         ]
                                      )),
                                   ]
                                ),
                                const SizedBox(height: 32),
                                const Center(
                                   child: Text('CONFIDENTIAL & PROPRIETARY INFORMATION • AGI LOGISTICS', style: TextStyle(fontSize: 10, color: Colors.black38, letterSpacing: 1))
                                )
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
