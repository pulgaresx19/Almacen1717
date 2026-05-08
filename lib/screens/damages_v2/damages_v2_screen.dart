import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode, scaffoldMessengerKey, isSidebarExpandedNotifier;
import 'damages_v2_table.dart';
import 'damages_v2_drawer.dart';
import 'damages_v2_history.dart';

class DamagesV2Screen extends StatefulWidget {
  final bool isActive;
  const DamagesV2Screen({super.key, required this.isActive});

  @override
  State<DamagesV2Screen> createState() => _DamagesV2ScreenState();
}

class _DamagesV2ScreenState extends State<DamagesV2Screen> {
  bool _isLoading = true;
  bool _showHistory = false;
  List<Map<String, dynamic>> _damages = [];
  RealtimeChannel? _realtimeChannel;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    if (widget.isActive) {
      _fetchData();
      _initRealtime();
    }
  }

  @override
  void didUpdateWidget(DamagesV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _fetchData();
      _initRealtime();
    } else if (!widget.isActive && oldWidget.isActive) {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    }
  }

  void _initRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('public:damage_reports')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'damage_reports',
          callback: (payload) => _fetchData(),
        )
        .subscribe();
  }

  Future<void> _fetchData() async {
    try {
      final DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final String dateIso = sevenDaysAgo.toUtc().toIso8601String();
      
      final data = await Supabase.instance.client
          .from('damage_reports')
          .select('*, flights(carrier, number, date), ulds(uld_number), awbs(awb_number)')
          .gte('created_at', dateIso)
          .order('created_at', ascending: false)
          .limit(100);

      // Fetch users manually due to missing foreign key relationship
      final userIds = data.map((d) => d['user_id']).where((id) => id != null).toSet().toList();
      Map<String, String> userMap = {};
      if (userIds.isNotEmpty) {
        final usersData = await Supabase.instance.client
            .from('users')
            .select('id, full_name')
            .inFilter('id', userIds);
        for (var u in usersData) {
          userMap[u['id'].toString()] = u['full_name'].toString();
        }
      }

      final mappedData = data.map((d) {
        final Map<String, dynamic> damage = Map<String, dynamic>.from(d);
        if (damage['user_id'] != null && userMap.containsKey(damage['user_id'].toString())) {
          damage['users'] = [{'full_name': userMap[damage['user_id'].toString()]}];
        }
        return damage;
      }).toList();

      if (mounted) {
        setState(() {
          _damages = mappedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching damages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        try {
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Error de base de datos: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 10),
            ),
          );
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredDamages {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _damages;
    
    return _damages.where((d) {
      String reference = '';
      dynamic awbData = d['awbs'];
      if (awbData is List && awbData.isNotEmpty) awbData = awbData[0];
      dynamic uldData = d['ulds'];
      if (uldData is List && uldData.isNotEmpty) uldData = uldData[0];
      
      if (awbData != null && awbData['awb_number'] != null) {
        reference = awbData['awb_number'].toString().toLowerCase();
      } else if (uldData != null && uldData['uld_number'] != null) {
        reference = uldData['uld_number'].toString().toLowerCase();
      }
      
      return reference.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final bgCard = dark ? Colors.white.withAlpha(10) : Colors.white;
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: isSidebarExpandedNotifier,
                      builder: (context, expanded, child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: expanded ? 0 : 44,
                        );
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_showHistory) ...[
                          Text(
                            appLanguage.value == 'es' ? 'Reportes de Daños' : 'Damage Reports',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textP),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appLanguage.value == 'es' ? 'Manejo de registros y reportes de daños.' : 'Damage reports and records management.',
                            style: TextStyle(fontSize: 13, color: textS),
                          ),
                        ] else ...[
                          Text(
                            appLanguage.value == 'es' ? 'Historial de Daños' : 'Damages History',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textP),
                          ),
                        ]
                      ],
                    ),
                    const Spacer(),
                    if (!_showHistory) ...[
                      Container(
                        width: 300,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderC),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: textP, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                            hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: textS, size: 16),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    
                    // History Button
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: Tooltip(
                        message: appLanguage.value == 'es' ? 'Ver Historial' : 'View History',
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showHistory = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFeab308).withAlpha(40),
                            foregroundColor: const Color(0xFFeab308),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.folder_open_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 24),
                if (_showHistory)
                  Expanded(
                    child: DamagesV2History(
                      onBackToMain: () {
                        setState(() {
                          _showHistory = false;
                        });
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderC),
                      ),
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
                        : DamagesV2Table(
                            damages: _filteredDamages,
                            onSelect: (damage) {
                              DamagesV2Drawer.show(context, damage, dark);
                            },
                          ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
