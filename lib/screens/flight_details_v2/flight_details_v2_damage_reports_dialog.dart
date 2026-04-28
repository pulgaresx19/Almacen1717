import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;

Future<void> showFlightDamageReportsDialog(BuildContext context, String flightId, bool dark) {
  return showDialog(
    context: context,
    builder: (ctx) => FlightDamageReportsDialogComponent(flightId: flightId, dark: dark),
  );
}

class FlightDamageReportsDialogComponent extends StatefulWidget {
  final String flightId;
  final bool dark;

  const FlightDamageReportsDialogComponent({super.key, required this.flightId, required this.dark});

  @override
  State<FlightDamageReportsDialogComponent> createState() => _FlightDamageReportsDialogComponentState();
}

class _FlightDamageReportsDialogComponentState extends State<FlightDamageReportsDialogComponent> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchDamageReports();
  }

  void _showPhotoPreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              maxScale: 5.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(32),
                      child: const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchDamageReports() async {
    try {
      final response = await Supabase.instance.client
          .from('damage_reports')
          .select()
          .eq('flight_id', widget.flightId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> enriched = [];
      for (var r in response) {
        Map<String, dynamic> row = Map<String, dynamic>.from(r);
        
        // Manual Lookups to prevent PostgREST FK relationship errors
        try {
          if (row['user_id'] != null) {
             final u = await Supabase.instance.client.from('users').select('full_name').eq('id', row['user_id']).maybeSingle();
             if (u != null) row['users'] = u;
          }
        } catch (_) {}
        
        try {
          if (row['uld_id'] != null) {
             final uld = await Supabase.instance.client.from('ulds').select('uld_number').eq('id_uld', row['uld_id']).maybeSingle();
             if (uld != null) row['ulds'] = uld;
          }
        } catch (_) {}

        try {
          if (row['awb_id'] != null) {
             final awb = await Supabase.instance.client.from('awbs').select('awb_number').eq('id_awb', row['awb_id']).maybeSingle();
             if (awb != null) row['awbs'] = awb;
          }
        } catch (_) {}
        
        enriched.add(row);
      }

      if (mounted) {
        setState(() {
          _reports = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching damage reports: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textP = widget.dark ? Colors.white : const Color(0xFF111827);
    final textS = widget.dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);
    final bgCard = widget.dark ? const Color(0xFF0f172a) : Colors.white;
    final borderC = widget.dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 700,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderC, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.report_problem_rounded, color: Colors.orangeAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        appLanguage.value == 'es' ? 'Reportes de Daños' : 'Damage Reports',
                        style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textS),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Body
            Flexible(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()))
                  : _reports.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: textS.withAlpha(100), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                appLanguage.value == 'es' ? 'No hay daños registrados' : 'No damages recorded',
                                style: TextStyle(color: textS, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            String damageType = 'Unknown';
                            if (report['damage_type'] != null) {
                              if (report['damage_type'] is List) {
                                damageType = (report['damage_type'] as List).join(', ');
                              } else {
                                damageType = report['damage_type'].toString();
                              }
                            }
                            final String userName = report['users']?['full_name'] ?? 'System';
                            final String? uldNum = report['ulds']?['uld_number'];
                            final String? awbNum = report['awbs']?['awb_number'];
                            int? damagedPieces;
                            if (report['pieces_damage'] != null) {
                              damagedPieces = int.tryParse(report['pieces_damage'].toString());
                            }
                            
                            // Parse date
                            String dateStr = '';
                            if (report['created_at'] != null) {
                              final dt = DateTime.tryParse(report['created_at'].toString())?.toLocal();
                              if (dt != null) {
                                dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                              }
                            }
                            
                            // Photo URLs
                            List<String> photos = [];
                            if (report['photo_urls'] != null && report['photo_urls'] is List) {
                              photos = (report['photo_urls'] as List).map((e) => e.toString()).toList();
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderC),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Damage Header Info
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  damageType.toUpperCase(),
                                                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold),
                                                ),
                                                if (damagedPieces != null && damagedPieces > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.redAccent.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                                    child: Text(
                                                      '$damagedPieces ${appLanguage.value == 'es' ? 'Pzs' : 'Pcs'}',
                                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  )
                                                ],
                                              ],
                                            ),
                                            if (dateStr.isNotEmpty)
                                              Text(
                                                dateStr,
                                                style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline_rounded, color: textS, size: 16),
                                            const SizedBox(width: 6),
                                            Text(userName, style: TextStyle(color: textP, fontSize: 14)),
                                            const SizedBox(width: 16),
                                            if (uldNum != null) ...[
                                              Icon(Icons.view_in_ar_rounded, color: textS, size: 16),
                                              const SizedBox(width: 6),
                                              Text(uldNum, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w600)),
                                              const SizedBox(width: 16),
                                            ],
                                            if (awbNum != null) ...[
                                              Icon(Icons.inventory_2_outlined, color: textS, size: 16),
                                              const SizedBox(width: 6),
                                              Text(awbNum, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.w600)),
                                            ]
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Photos Section
                                  if (photos.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: widget.dark ? Colors.black.withAlpha(20) : Colors.white.withAlpha(50),
                                        border: Border(top: BorderSide(color: borderC)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appLanguage.value == 'es' ? 'Evidencia Fotográfica' : 'Photo Evidence',
                                            style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height: 120,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: photos.length,
                                              itemBuilder: (context, photoIndex) {
                                                return Container(
                                                  width: 120,
                                                  margin: const EdgeInsets.only(right: 12),
                                                  decoration: BoxDecoration(
                                                    color: widget.dark ? Colors.black.withAlpha(50) : Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: borderC.withAlpha(50)),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(11),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () => _showPhotoPreview(context, photos[photoIndex]),
                                                        child: Image.network(
                                                          photos[photoIndex],
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                                color: widget.dark ? Colors.white54 : Colors.black54,
                                                                strokeWidth: 2,
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Icon(Icons.broken_image_rounded, color: widget.dark ? Colors.white54 : Colors.black54);
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
