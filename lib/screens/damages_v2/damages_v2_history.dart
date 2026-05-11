import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'damages_v2_table.dart';
import 'damages_v2_drawer.dart';

class DamagesV2History extends StatefulWidget {
  final VoidCallback onBackToMain;
  const DamagesV2History({super.key, required this.onBackToMain});

  @override
  State<DamagesV2History> createState() => _DamagesV2HistoryState();
}

class _DamagesV2HistoryState extends State<DamagesV2History> {
  String? _selectedDate;
  bool _isLoadingSummary = true;
  List<Map<String, dynamic>> _summaryList = [];
  
  bool _isLoadingDay = false;
  List<Map<String, dynamic>> _dayDamages = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isGlobalSearch = false;
  List<Map<String, dynamic>> _searchDamages = [];

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    try {
      final res = await Supabase.instance.client.rpc('rpc_get_damages_summary');
      if (mounted) {
        setState(() {
          _summaryList = List<Map<String, dynamic>>.from(res);
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching damages summary: $e');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  Future<void> _fetchDayItems(String dateStr) async {
    setState(() {
      _selectedDate = dateStr;
      _isLoadingDay = true;
      _dayDamages = [];
    });
    try {
      final start = DateTime.parse(dateStr);
      final end = start.add(const Duration(days: 1));
      
      final data = await Supabase.instance.client
          .from('damage_reports')
          .select('*, flights(carrier, number, date), ulds(uld_number), awbs(awb_number)')
          .gte('created_at', start.toUtc().toIso8601String())
          .lt('created_at', end.toUtc().toIso8601String())
          .order('created_at', ascending: false);

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

      if (mounted && _selectedDate == dateStr) {
        setState(() {
          _dayDamages = mappedData;
          _isLoadingDay = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching damages for day: $e');
      if (mounted && _selectedDate == dateStr) {
        setState(() => _isLoadingDay = false);
      }
    }
  }

  Future<void> _executeSearch() async {
    final query = _searchController.text.trim();
    if (query.length < 4) {
      if (query.isEmpty) {
        setState(() {
          _isGlobalSearch = false;
          _searchDamages = [];
        });
      }
      return;
    }

    setState(() {
      _selectedDate = null;
      _isGlobalSearch = true;
      _isLoadingDay = true;
      _searchDamages = [];
    });

    try {
      final awbRes = await Supabase.instance.client.from('awbs').select('id').ilike('awb_number', '%$query%').limit(10);
      final uldRes = await Supabase.instance.client.from('ulds').select('id').ilike('uld_number', '%$query%').limit(10);

      final List<int> awbIds = (awbRes as List).map((e) => e['id'] as int).toList();
      final List<int> uldIds = (uldRes as List).map((e) => e['id'] as int).toList();

      if (awbIds.isEmpty && uldIds.isEmpty) {
        if (mounted && _isGlobalSearch) {
          setState(() {
            _searchDamages = [];
            _isLoadingDay = false;
          });
        }
        return;
      }

      var q = Supabase.instance.client
          .from('damage_reports')
          .select('*, flights(carrier, number, date), ulds(uld_number), awbs(awb_number)');

      if (awbIds.isNotEmpty && uldIds.isNotEmpty) {
        q = q.or('awb_id.in.(${awbIds.join(',')}),uld_id.in.(${uldIds.join(',')})');
      } else if (awbIds.isNotEmpty) {
        q = q.filter('awb_id', 'in', awbIds);
      } else if (uldIds.isNotEmpty) {
        q = q.filter('uld_id', 'in', uldIds);
      }

      final data = await q.order('created_at', ascending: false).limit(50);

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

      if (mounted && _isGlobalSearch) {
        setState(() {
          _searchDamages = mappedData;
          _isLoadingDay = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching damages: $e');
      if (mounted && _isGlobalSearch) {
        setState(() => _isLoadingDay = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color bgCard = dark ? Colors.white.withAlpha(10) : Colors.white;
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        return Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_isGlobalSearch) {
                          setState(() {
                            _isGlobalSearch = false;
                            _searchController.clear();
                          });
                        } else if (_selectedDate != null) {
                          setState(() {
                            _selectedDate = null;
                          });
                        } else {
                          widget.onBackToMain();
                        }
                      },
                      icon: Icon(Icons.arrow_back_rounded, color: textP),
                      tooltip: appLanguage.value == 'es' ? 'Atrás' : 'Back',
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isGlobalSearch ? Icons.search_rounded : (_selectedDate == null ? Icons.folder_special_rounded : Icons.folder_open_rounded),
                      color: const Color(0xFF6366f1),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isGlobalSearch
                          ? (appLanguage.value == 'es' ? 'Resultados de Búsqueda' : 'Search Results')
                          : (_selectedDate == null
                              ? (appLanguage.value == 'es' ? 'Historial de Daños' : 'Damages History')
                              : (appLanguage.value == 'es' ? 'Daños del $_selectedDate' : 'Damages on $_selectedDate')),
                      style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      width: 250,
                      height: 40,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withAlpha(10) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderCard),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textP, fontSize: 13),
                        onSubmitted: (val) {
                          _executeSearch();
                        },
                        decoration: InputDecoration(
                          hintText: appLanguage.value == 'es' ? 'Buscar en historial...' : 'Search history...',
                          hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, child) {
                              final bool isEnabled = value.text.trim().length >= 4;
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: InkWell(
                                  onTap: isEnabled ? () => _executeSearch() : null,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isEnabled 
                                          ? const Color(0xFF6366f1) 
                                          : (dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                                    ),
                                    child: Icon(
                                      Icons.search_rounded, 
                                      color: isEnabled ? Colors.white : textS.withAlpha(100), 
                                      size: 16
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.transparent),
              Expanded(
                child: _isGlobalSearch
                    ? _buildDayView(dark, textP, textS, borderCard, isSearch: true)
                    : (_selectedDate == null
                        ? _buildFoldersView(dark, textP, textS, borderCard)
                        : _buildDayView(dark, textP, textS, borderCard, isSearch: false)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoldersView(bool dark, Color textP, Color textS, Color borderCard) {
    if (_isLoadingSummary) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
    }

    if (_summaryList.isEmpty) {
      return Center(
        child: Text(
          appLanguage.value == 'es' ? 'No hay historial disponible.' : 'No history available.',
          style: TextStyle(color: textS),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.0,
      ),
      itemCount: _summaryList.length,
      itemBuilder: (context, index) {
        final item = _summaryList[index];
        final dateKey = item['date_group']?.toString() ?? 'Unknown';
        final count = item['damage_count']?.toString() ?? '0';
        
        String niceDate = dateKey;
        if (dateKey != 'Unknown') {
          try {
            final d = DateTime.parse(dateKey);
            niceDate = DateFormat('MMM dd, yyyy').format(d);
          } catch (_) {}
        }

        return InkWell(
          onTap: () {
            _fetchDayItems(dateKey);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCard),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_rounded,
                  color: Color(0xFFeab308),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(niceDate, style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count reports',
                    style: const TextStyle(color: Color(0xFF6366f1), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayView(bool dark, Color textP, Color textS, Color borderCard, {bool isSearch = false}) {
    if (_isLoadingDay) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
    }

    final dataList = isSearch ? _searchDamages : _dayDamages;

    if (dataList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem_rounded, size: 64, color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
            const SizedBox(height: 16),
            Text(appLanguage.value == 'es' ? 'No hay daños' : 'No Damages', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isSearch
                ? (appLanguage.value == 'es' ? 'No se encontraron resultados para tu búsqueda.' : 'No results found for your search.')
                : (appLanguage.value == 'es' ? 'No hay daños reportados en esta fecha.' : 'There are no damages reported on this date.'), 
                 style: TextStyle(color: textS)),
          ],
        )
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      child: DamagesV2Table(
        damages: dataList,
        onSelect: (damage) {
          DamagesV2Drawer.show(context, damage, dark);
        },
      ),
    );
  }
}
