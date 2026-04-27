import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show isDarkMode;
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
  String _cachedAuthorName = 'Usuario';
  bool _isSplitView = false;

  String? _selectedFlightIdLeft;
  String? _selectedFlightIdRight;

  final GlobalKey<SystemV2PanelState> _panel1Key = GlobalKey<SystemV2PanelState>();
  final GlobalKey<SystemV2PanelState> _panel2Key = GlobalKey<SystemV2PanelState>();

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
                                  key: _panel1Key,
                                  panelId: 1,
                                  isSplitView: _isSplitView,
                                  authorName: _cachedAuthorName,
                                  onToggleSplit: () => setState(() => _isSplitView = true),
                                  onCloseSplit: () {}, // System 1 can't be closed, only System 2 has X button
                                  onFlightSelected: (fId) => setState(() => _selectedFlightIdLeft = fId),
                                  onUldToggled: (uldId, isChecked, truckTime, author) {
                                    if (_selectedFlightIdLeft != null && _selectedFlightIdLeft == _selectedFlightIdRight) {
                                      _panel2Key.currentState?.syncUld(uldId, isChecked, truckTime, author);
                                    }
                                  },
                                  onFlightReceived: (firstTruck, lastTruck) {
                                    if (_selectedFlightIdLeft != null && _selectedFlightIdLeft == _selectedFlightIdRight) {
                                      _panel2Key.currentState?.syncFlightRec(firstTruck, lastTruck);
                                    }
                                  },
                                ),
                              )
                            ]
                          : [
                              Expanded(
                                child: SystemV2Panel(
                                  key: _panel1Key,
                                  panelId: 1,
                                  isSplitView: _isSplitView,
                                  authorName: _cachedAuthorName,
                                  onToggleSplit: () => setState(() => _isSplitView = true),
                                  onCloseSplit: () {},
                                  onFlightSelected: (fId) => setState(() => _selectedFlightIdLeft = fId),
                                  onUldToggled: (uldId, isChecked, truckTime, author) {
                                    if (_selectedFlightIdLeft != null && _selectedFlightIdLeft == _selectedFlightIdRight) {
                                      _panel2Key.currentState?.syncUld(uldId, isChecked, truckTime, author);
                                    }
                                  },
                                  onFlightReceived: (firstTruck, lastTruck) {
                                    if (_selectedFlightIdLeft != null && _selectedFlightIdLeft == _selectedFlightIdRight) {
                                      _panel2Key.currentState?.syncFlightRec(firstTruck, lastTruck);
                                    }
                                  },
                                ),
                              ),
                              Container(
                                width: 1,
                                color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                              ),
                              Expanded(
                                child: SystemV2Panel(
                                  key: _panel2Key,
                                  panelId: 2,
                                  isSplitView: _isSplitView,
                                  authorName: _cachedAuthorName,
                                  onToggleSplit: () {},
                                  onCloseSplit: () => setState(() {
                                    _isSplitView = false;
                                    _selectedFlightIdRight = null;
                                  }),
                                  onFlightSelected: (fId) => setState(() => _selectedFlightIdRight = fId),
                                  onUldToggled: (uldId, isChecked, truckTime, author) {
                                    if (_selectedFlightIdRight != null && _selectedFlightIdLeft == _selectedFlightIdRight) {
                                      _panel1Key.currentState?.syncUld(uldId, isChecked, truckTime, author);
                                    }
                                  },
                                  onFlightReceived: (firstTruck, lastTruck) {
                                    if (_selectedFlightIdRight != null && _selectedFlightIdLeft == _selectedFlightIdRight) {
                                      _panel1Key.currentState?.syncFlightRec(firstTruck, lastTruck);
                                    }
                                  },
                                ),
                              ),
                            ],
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
