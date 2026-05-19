import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../main.dart' show isDarkMode, currentUserData, scaffoldMessengerKey;
import 'driver_v2_verify_dialog.dart';
import 'driver_v2_verify_card.dart';
import 'driver_v2_confirm_dialog.dart';
import 'driver_v2_animated_toast.dart';
import 'driver_v2_door_dialog.dart';
import '../../services/realtime_service.dart';

class DriverV2Panel extends StatefulWidget {
  final String searchQuery;
  const DriverV2Panel({super.key, this.searchQuery = ''});

  @override
  State<DriverV2Panel> createState() => _DriverV2PanelState();
}

class _DriverV2PanelState extends State<DriverV2Panel> {
  final Set<String> _skippedDeliveries = {};
  Map<String, dynamic>? _assignedDelivery;
  bool _isLoadingNoShow = false;

  void _requestNextDriver(BuildContext context, List<Map<String, dynamic>> availableItems) {
    // Filter out skipped items
    final validItems = availableItems.where((u) {
      final id = u['id_delivery']?.toString();
      if (id == null) return false;
      return !_skippedDeliveries.contains(id);
    }).toList();

    if (validItems.isEmpty) {
      showAnimatedCenterToast(
        context: context,
        message: 'No drivers available in the queue.',
        icon: Icons.hourglass_empty_rounded,
        color: Colors.blueAccent,
        dark: isDarkMode.value,
      );
      return;
    }

    setState(() {
      _assignedDelivery = validItems.first;
    });
  }

  Future<void> _handleNoShow(Map<String, dynamic> delivery) async {
    final idDelivery = delivery['id_delivery']?.toString();
    if (idDelivery == null) return;

    setState(() {
      _isLoadingNoShow = true;
    });

    try {
      final userFullName = currentUserData.value?['full_name'] ?? 'Unknown User';
      
      await Supabase.instance.client.rpc(
        'rpc_register_no_show',
        params: {
          'p_id_delivery': idDelivery,
          'p_full_name': userFullName,
        },
      );

      setState(() {
        _skippedDeliveries.add(idDelivery);
        _assignedDelivery = null;
      });
    } catch (e) {
      debugPrint('Error registering no show: $e');
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNoShow = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: currentUserData,
          builder: (context, userData, child) {
            final isMasterDriver = userData?['master_driver'] == true;

            return ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: realtimeService.deliveries,
              builder: (context, deliversList, child) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                var items = List<Map<String, dynamic>>.from(deliversList).where((u) {
                  if (u['all_uld'] == true) return false;
                  if (u['check_in'] != true) return false;
                  
                  final st = (u['status']?.toString() ?? '').toLowerCase();
                  if (st != 'waiting' && st != 'pending') return false;
                  
                  final tStr = u['time']?.toString() ?? '';
                  if (tStr.isEmpty) return false;
                  final tDt = DateTime.tryParse(tStr)?.toLocal();
                  if (tDt == null) return false;
                  
                  final itemDate = DateTime(tDt.year, tDt.month, tDt.day);
                  if (itemDate != today) return false;

                  return true;
                }).toList();
                
                if (isMasterDriver && widget.searchQuery.trim().isNotEmpty) {
                  final q = widget.searchQuery.trim().toLowerCase();
                  items = items.where((u) {
                    final c = (u['company']?.toString() ?? '').toLowerCase();
                    final d = (u['driver_name']?.toString() ?? '').toLowerCase();
                    final dr = (u['door']?.toString() ?? '').toLowerCase();
                    final tp = (u['type']?.toString() ?? '').toLowerCase();
                    return c.contains(q) || d.contains(q) || dr.contains(q) || tp.contains(q);
                  }).toList();
                }
                
                // Sort by status priority, then by time (oldest first)
                items.sort((a, b) {
                  int getPriority(Map<String, dynamic> item) {
                    final st = (item['status']?.toString() ?? '').toLowerCase();
                    if (st == 'pending') return 3;
                    if (st == 'waiting' && item['is_priority'] == true) return 2;
                    return 1;
                  }
                  
                  final pA = getPriority(a);
                  final pB = getPriority(b);
                  
                  if (pA != pB) {
                    return pB.compareTo(pA); // higher priority number first
                  }
                  
                  final taStr = a['time']?.toString() ?? '';
                  final tbStr = b['time']?.toString() ?? '';
                  if (taStr.isEmpty && tbStr.isNotEmpty) return 1;
                  if (taStr.isNotEmpty && tbStr.isEmpty) return -1;
                  if (taStr.isEmpty && tbStr.isEmpty) return 0;
                  
                  final da = DateTime.tryParse(taStr) ?? DateTime(1970);
                  final db = DateTime.tryParse(tbStr) ?? DateTime(1970);
                  return da.compareTo(db);
                });

                if (isMasterDriver) {
                  return _buildMasterView(items, dark);
                } else {
                  return _buildRegularUserView(items, dark);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMasterView(List<Map<String, dynamic>> items, bool dark) {
    if (items.isEmpty) {
      return Center(
        child: Text('No deliveries found.', style: TextStyle(color: dark ? Colors.white54 : Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final u = items[index];
        
        String company = u['company']?.toString() ?? '-';
        String driver = u['driver_name']?.toString() ?? '-';
        String door = u['door']?.toString() ?? '-';
        String type = u['type']?.toString() ?? 'Walk-In';
        bool isPriority = u['is_priority'] == true;
        
        String timeStr = '-';
        if (u['time'] != null) {
          final tdt = DateTime.tryParse(u['time'].toString())?.toLocal();
          if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
        }

        return GestureDetector(
          onTap: () {
            showVerifyDriverDialog(
              context: context,
              deliveryData: u,
              dark: dark,
              company: company,
              driver: driver,
              time: timeStr,
              door: door,
              type: type,
            );
          },
          child: _buildDeliveryItem(
            index: index + 1,
            company: company,
            driver: driver,
            time: timeStr,
            door: door,
            type: type,
            dark: dark,
            isPriority: isPriority,
          ),
        );
      },
    );
  }

  Widget _buildRegularUserView(List<Map<String, dynamic>> items, bool dark) {
    // If the assigned delivery was completed by someone else, reset it
    if (_assignedDelivery != null) {
      final assignedId = _assignedDelivery!['id_delivery'];
      final stillExists = items.any((e) => e['id_delivery'] == assignedId);
      if (!stillExists) {
        // Someone else processed it or it's no longer waiting
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _assignedDelivery = null);
        });
      }
    }

    if (_assignedDelivery == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_rounded, size: 64, color: Color(0xFF6366f1)),
            ),
            const SizedBox(height: 32),
            const Text(
              'Ready for Next Delivery',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Request the next available driver from the queue.',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _requestNextDriver(context, items),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Request Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366f1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
            if (_skippedDeliveries.isNotEmpty) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _skippedDeliveries.clear();
                  });
                  showAnimatedCenterToast(
                    context: context,
                    message: 'Queue reset successfully',
                    icon: Icons.refresh_rounded,
                    color: Colors.greenAccent,
                    dark: dark,
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Reset Skipped Drivers (${_skippedDeliveries.length})'),
                style: TextButton.styleFrom(
                  foregroundColor: dark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Render the embedded Verify Driver Card
    final awbsCount = (_assignedDelivery!['awbs'] is List) ? (_assignedDelivery!['awbs'] as List).length : 1;
    String timeStr = '-';
    if (_assignedDelivery!['time'] != null) {
      final tdt = DateTime.tryParse(_assignedDelivery!['time'].toString())?.toLocal();
      if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: DriverV2VerifyCard(
          deliveryData: _assignedDelivery!,
          dark: dark,
          company: _assignedDelivery!['company']?.toString() ?? '-',
          driver: _assignedDelivery!['driver_name']?.toString() ?? '-',
          time: timeStr,
          door: _assignedDelivery!['door']?.toString() ?? '-',
          type: _assignedDelivery!['type']?.toString() ?? 'Walk-In',
          idPickup: _assignedDelivery!['id_pickup']?.toString() ?? '-',
          awbsCount: awbsCount,
          showCloseButton: true,
          onClose: () {
            if (mounted) {
              setState(() => _assignedDelivery = null);
            }
          },
          isLoadingNoShow: _isLoadingNoShow,
          onNoShow: () => _handleNoShow(_assignedDelivery!),
          onConfirm: () async {
            final company = _assignedDelivery!['company']?.toString() ?? '-';
            final driver = _assignedDelivery!['driver_name']?.toString() ?? '-';
            final currentDelivery = _assignedDelivery!;
            
            if (currentDelivery['door']?.toString() == 'PENDING') {
              final newDoor = await showAssignDoorDialog(
                context: context,
                dark: dark,
                deliveryData: currentDelivery,
              );
              if (newDoor == null) return; // User cancelled
              currentDelivery['door'] = newDoor;
            }
            
            if (!mounted) return;
            setState(() {
              _skippedDeliveries.clear();
              _assignedDelivery = null;
            });
            
            showDriverConfirmDialog(
              context: context,
              deliveryData: currentDelivery,
              dark: dark,
              company: company,
              driver: driver,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeliveryItem({
    required int index,
    required String company,
    required String driver,
    required String time,
    required String door,
    required String type,
    required bool dark,
    required bool isPriority,
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
          Expanded(flex: 2, child: _buildColumnInfo('COMPANY', company, dark)),
          Expanded(flex: 2, child: _buildColumnInfo('DRIVER', driver, dark)),
          Expanded(flex: 2, child: _buildColumnInfo('TIME', time, dark)),
          Expanded(flex: 1, child: _buildColumnInfo('DOOR', door, dark)),
          Expanded(flex: 2, child: _buildColumnInfo('TYPE', type, dark)),
          Icon(
            isPriority ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isPriority ? const Color(0xFFFACC15) : (dark ? Colors.white24 : Colors.black26),
            size: 24,
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

