import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'delivers_v2_logic.dart';
import 'delivers_v2_dialogs.dart';

class DeliversV2History extends StatefulWidget {
  final DeliversV2Logic logic;
  final VoidCallback onBackToMain;
  const DeliversV2History({super.key, required this.logic, required this.onBackToMain});

  @override
  State<DeliversV2History> createState() => _DeliversV2HistoryState();
}

class _DeliversV2HistoryState extends State<DeliversV2History> {
  String? _selectedDate; // The date folder currently opened
  bool _isLoadingSummary = true;
  List<Map<String, dynamic>> _summaryList = [];
  
  bool _isLoadingDay = false;
  List<Map<String, dynamic>> _dayDeliveries = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isGlobalSearch = false;
  List<Map<String, dynamic>> _searchDeliveries = [];

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
      final res = await Supabase.instance.client.rpc('rpc_get_deliveries_summary');
      if (mounted) {
        setState(() {
          _summaryList = List<Map<String, dynamic>>.from(res);
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching deliveries summary: $e');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  Future<void> _fetchDayDeliveries(String dateStr) async {
    setState(() {
      _selectedDate = dateStr;
      _isLoadingDay = true;
      _dayDeliveries = [];
    });
    try {
      final start = DateTime.parse(dateStr);
      final end = start.add(const Duration(days: 1));
      
      final res = await Supabase.instance.client
          .from('deliveries')
          .select()
          .gte('time', start.toIso8601String())
          .lt('time', end.toIso8601String())
          .order('time', ascending: false);

      if (mounted && _selectedDate == dateStr) {
        setState(() {
          _dayDeliveries = List<Map<String, dynamic>>.from(res);
          _isLoadingDay = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching deliveries for day: $e');
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
          _searchDeliveries = [];
        });
      }
      return;
    }

    setState(() {
      _selectedDate = null;
      _isGlobalSearch = true;
      _isLoadingDay = true;
      _searchDeliveries = [];
    });

    try {
      final res = await Supabase.instance.client
          .from('deliveries')
          .select()
          .or('company.ilike.%$query%,driver_name.ilike.%$query%')
          .order('time', ascending: false)
          .limit(50);

      if (mounted && _isGlobalSearch) {
        setState(() {
          _searchDeliveries = List<Map<String, dynamic>>.from(res);
          _isLoadingDay = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching deliveries: $e');
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
              // Header
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
                              ? (appLanguage.value == 'es' ? 'Historial de Entregas' : 'Deliveries History')
                              : (appLanguage.value == 'es' ? 'Entregas del $_selectedDate' : 'Deliveries on $_selectedDate')),
                      style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    
                    // Search Box
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

              // Content
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
        final count = item['delivery_count']?.toString() ?? '0';
        
        String niceDate = dateKey;
        if (dateKey != 'Unknown') {
          try {
            final d = DateTime.parse(dateKey);
            niceDate = DateFormat('MMM dd, yyyy').format(d);
          } catch (_) {}
        }

        return InkWell(
          onTap: () {
            _fetchDayDeliveries(dateKey);
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
                const SizedBox(height: 12),
                Text(
                  niceDate,
                  style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count ${appLanguage.value == 'es' ? 'entregas' : 'delivers'}',
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

    final dataList = isSearch ? _searchDeliveries : _dayDeliveries;

    if (dataList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: dark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
            const SizedBox(height: 16),
            Text(appLanguage.value == 'es' ? 'No hay entregas' : 'No Delivers', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isSearch 
                ? (appLanguage.value == 'es' ? 'No se encontraron resultados para tu búsqueda.' : 'No results found for your search.')
                : (appLanguage.value == 'es' ? 'No hay entregas en esta fecha.' : 'There are no deliveries on this date.'), 
                 style: TextStyle(color: textS)),
          ],
        )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        final item = dataList[index];
        final company = item['company']?.toString() ?? '-';
        final driver = item['driver_name']?.toString() ?? '-';
        final door = item['door']?.toString() ?? '-';
        final time = item['time']?.toString() ?? '';
        
        String niceTime = time;
        if (time.isNotEmpty) {
          try {
            final dt = DateTime.parse(time);
            niceTime = DateFormat('HH:mm').format(dt.toLocal());
          } catch (_) {}
        }

        return Card(
          color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderCard),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF6366f1),
              child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
            ),
            title: Text(company, style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
            subtitle: Text('$driver • Door $door', style: TextStyle(color: textS)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(niceTime, style: TextStyle(color: textS, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: textS),
              ],
            ),
            onTap: () {
              DeliversV2Dialogs.showDeliverDetails(context, item, dark);
            },
          ),
        );
      },
    );
  }
}

