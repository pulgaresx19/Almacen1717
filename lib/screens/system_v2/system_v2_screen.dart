import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;
import 'system_v2_panel.dart';

class SystemV2Screen extends StatefulWidget {
  final bool singlePanelMode;
  final String? titleOverride;

  const SystemV2Screen({
    super.key,
    this.singlePanelMode = false,
    this.titleOverride,
  });

  @override
  State<SystemV2Screen> createState() => _SystemV2ScreenState();
}

class _SystemV2ScreenState extends State<SystemV2Screen> {
  final _searchController = TextEditingController();
  
  String _cachedAuthorName = 'Usuario';
  bool _isSplitView = false;
  
  Map<String, dynamic>? _globalSearchResult;
  bool _isGlobalSearching = false;

  String? _selectedFlightIdLeft;
  String? _selectedFlightIdRight;

  @override
  void initState() {
    super.initState();
    _initAuthorName();
  }

  Future<void> _initAuthorName() async {
    String userName = Supabase.instance.client.auth.currentUser?.email?.split('@')[0] ?? 'Usuario';
    try {
      final uUser = Supabase.instance.client.auth.currentUser;
      if (uUser != null) {
        final userRow = await Supabase.instance.client
            .from('users')
            .select('full-name')
            .eq('id', uUser.id)
            .maybeSingle();
        if (userRow != null && userRow['full-name'] != null) {
          userName = userRow['full-name'];
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _cachedAuthorName = userName;
      });
    }
  }

  Future<void> _performGlobalSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isGlobalSearching = true;
      _globalSearchResult = null;
    });

    try {
      final resList = await Supabase.instance.client
          .from('ulds')
          .select('*, flights(*)')
          .ilike('uld_number', '%$query%')
          .limit(10);

      if (mounted) {
        setState(() {
          _isGlobalSearching = false;
          if (resList.isNotEmpty) {
            _globalSearchResult = {'list': resList};
          } else {
            _globalSearchResult = {
              'error': true,
              'message': appLanguage.value == 'es'
                  ? 'No se encontró el ULD solicitado.'
                  : 'Requested ULD not found.',
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGlobalSearching = false;
          _globalSearchResult = {'error': true, 'message': 'Error: $e'};
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1100;
    if (!isDesktop && _isSplitView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isSplitView = false);
      });
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return Stack(
          children: [
            Column(
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
                        Text(
                          'System',
                          style: TextStyle(
                            color: dark ? Colors.white : const Color(0xFF111827),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 320,
                      height: 42,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) => newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                  ),
                                ),
                              ],
                              style: TextStyle(
                                color: dark ? Colors.white : const Color(0xFF111827),
                                fontSize: 13,
                              ),
                              onChanged: (v) => setState(() {}),
                              onSubmitted: (v) {
                                if (v.trim().isNotEmpty) _performGlobalSearch();
                              },
                              decoration: InputDecoration(
                                hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                                hintStyle: TextStyle(
                                  color: (dark ? Colors.white : const Color(0xFF111827)).withAlpha(76),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _searchController.text.trim().isEmpty ? null : _performGlobalSearch,
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: _searchController.text.trim().isEmpty
                                    ? (dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6))
                                    : const Color(0xFF6366f1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: _searchController.text.trim().isEmpty
                                    ? (dark ? Colors.white30 : Colors.black26)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Reduced margin to increase table space
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF0f172a).withAlpha(100) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: !_isSplitView
                          ? [
                              Expanded(
                                child: SystemV2Panel(
                                  panelId: 1,
                                  isSplitView: _isSplitView,
                                  oppositeSelectedFlightId: widget.singlePanelMode ? null : _selectedFlightIdRight,
                                  authorName: _cachedAuthorName,
                                  onToggleSplit: () => setState(() => _isSplitView = true),
                                  onCloseSplit: () {}, // System 1 can't be closed, only System 2 has X button
                                  onFlightSelected: (fId) => setState(() => _selectedFlightIdLeft = fId),
                                ),
                              )
                            ]
                          : [
                              Expanded(
                                child: SystemV2Panel(
                                  panelId: 1,
                                  isSplitView: _isSplitView,
                                  oppositeSelectedFlightId: widget.singlePanelMode ? null : _selectedFlightIdRight,
                                  authorName: _cachedAuthorName,
                                  onToggleSplit: () => setState(() => _isSplitView = true),
                                  onCloseSplit: () {},
                                  onFlightSelected: (fId) => setState(() => _selectedFlightIdLeft = fId),
                                ),
                              ),
                              Container(
                                width: 1,
                                color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                              ),
                              Expanded(
                                child: SystemV2Panel(
                                  panelId: 2,
                                  isSplitView: _isSplitView,
                                  oppositeSelectedFlightId: _selectedFlightIdLeft,
                                  authorName: _cachedAuthorName,
                                  onToggleSplit: () {},
                                  onCloseSplit: () => setState(() => _isSplitView = false),
                                  onFlightSelected: (fId) => setState(() => _selectedFlightIdRight = fId),
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isGlobalSearching || _globalSearchResult != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(dark ? 120 : 60),
                  child: Center(
                    child: _isGlobalSearching
                        ? const CircularProgressIndicator(color: Color(0xFF6366f1))
                        : Container(
                            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF1e293b) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appLanguage.value == 'es' ? 'Resultado de Búsqueda' : 'Search Result',
                                  style: TextStyle(
                                    color: dark ? Colors.white : const Color(0xFF111827),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_globalSearchResult!['error'] == true)
                                  Text(
                                    _globalSearchResult!['message'],
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                                  )
                                else if (_globalSearchResult!['list'] != null)
                                  Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: (_globalSearchResult!['list'] as List).length,
                                      separatorBuilder: (_, _) => Divider(color: dark ? Colors.white24 : Colors.black12),
                                      itemBuilder: (context, idx) {
                                        final uItem = (_globalSearchResult!['list'] as List)[idx];
                                        bool isReceived = uItem['time_received'] != null;
                                        final txtColor = dark ? Colors.white : const Color(0xFF111827);
                                        final subColor = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            'ULD: ${uItem['uld_number'] ?? 'Unknown'}',
                                            style: TextStyle(color: txtColor, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(
                                                'Flight: ${uItem['flights']?['carrier'] ?? ''} ${uItem['flights']?['number'] ?? ''} | Date: ${uItem['flights']?['date'] ?? uItem['flights']?['date_arrived'] ?? '-'}',
                                                style: TextStyle(color: subColor, fontSize: 12),
                                              ),
                                              Text(
                                                'PCs: ${uItem['pieces_total'] ?? '-'} | Weight: ${uItem['weight_total'] ?? '-'} kg',
                                                style: TextStyle(color: subColor, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          trailing: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: isReceived,
                                              activeColor: const Color(0xFF10b981),
                                              side: BorderSide(
                                                color: dark ? Colors.white.withAlpha(50) : const Color(0xFFE5E7EB),
                                                width: 2,
                                              ),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              onChanged: (v) async {
                                                final bool isChecked = v == true;
                                                String authorName = _cachedAuthorName;
                                                final truckTime = DateTime.now().toUtc().toIso8601String();
                                                setState(() {
                                                  if (isChecked) {
                                                    uItem['time_received'] = truckTime;
                                                    uItem['user_received'] = authorName;
                                                    // status update removed
                                                  } else {
                                                    uItem['time_received'] = null;
                                                    uItem['user_received'] = null;
                                                    // status update removed
                                                  }
                                                });
                                                if (isChecked) {
                                                  await Supabase.instance.client.from('ulds').update({
                                                    'time_received': truckTime,
                                                    'user_received': authorName,
                                                    // status update removed
                                                  }).eq('id_uld', uItem['id_uld']);

                                                  if (uItem['id_flight'] != null) {
                                                    final fl = await Supabase.instance.client.from('flights')
                                                        .select('first_truck')
                                                        .eq('id_flight', uItem['id_flight'])
                                                        .maybeSingle();
                                                    if (fl != null && fl['first_truck'] == null) {
                                                      await Supabase.instance.client.from('flights').update({'first_truck': truckTime})
                                                          .eq('id_flight', uItem['id_flight']);
                                                    }
                                                  }
                                                } else {
                                                  await Supabase.instance.client.from('ulds').update({
                                                    'time_received': null,
                                                    'user_received': null,
                                                    // status update removed
                                                  }).eq('id_uld', uItem['id_uld']);
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => setState(() => _globalSearchResult = null),
                                    child: Text(
                                      appLanguage.value == 'es' ? 'Cerrar' : 'Close',
                                      style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
