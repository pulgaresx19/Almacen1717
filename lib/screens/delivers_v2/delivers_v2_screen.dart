import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;
import '../add_deliver_v2/add_deliver_v2_screen.dart';
import 'delivers_v2_logic.dart';
import 'delivers_v2_table.dart';
import 'deliver_pdf_exporter.dart';
import 'delivers_v2_history.dart';

class DeliversV2Screen extends StatefulWidget {
  final bool isActive;
  const DeliversV2Screen({super.key, this.isActive = true});

  @override
  State<DeliversV2Screen> createState() => _DeliversV2ScreenState();
}

class _DeliversV2ScreenState extends State<DeliversV2Screen> {
  final DeliversV2Logic _logic = DeliversV2Logic();
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  bool _showHistory = false;
  final GlobalKey<AddDeliverV2ScreenState> _addDeliverKey = GlobalKey<AddDeliverV2ScreenState>();
  late Stream<List<Map<String, dynamic>>> _deliversStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _logic.updateSearchQuery(_searchController.text);
    });
    _deliversStream = Supabase.instance.client.from('deliveries').stream(primaryKey: ['id_delivery']).order('time', ascending: true);
  }

  @override
  void didUpdateWidget(covariant DeliversV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_showAddForm && _addDeliverKey.currentState != null) {
        if (!_addDeliverKey.currentState!.hasDataSync) {
          setState(() => _showAddForm = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (_showAddForm)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (_addDeliverKey.currentState != null) {
                                final canPop = await _addDeliverKey.currentState!.handleBackRequest();
                                if (canPop) {
                                  setState(() => _showAddForm = false);
                                }
                              } else {
                                setState(() => _showAddForm = false);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            tooltip: appLanguage.value == 'es' ? 'Volver' : 'Back',
                            color: textS,
                          ),
                          const SizedBox(width: 8),
                          Text(appLanguage.value == 'es' ? 'Añadir Nuevo Deliver' : 'Add New Deliver', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text(
                        appLanguage.value == 'es' ? 'Entregas / Transferencias' : 'Delivers / Transfers',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textP),
                      ),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(appLanguage.value == 'es' ? 'Registrar un Nuevo Deliver en el sistema.' : 'Register a New Deliver in the system.', style: TextStyle(color: textS, fontSize: 13))
                    else
                      Text(
                        appLanguage.value == 'es' ? 'Manejo de entregas.' : 'Management of deliveries.',
                        style: TextStyle(fontSize: 13, color: textS),
                      ),
                  ],
                ),
                const Spacer(),
                if (!_showAddForm)
                  Container(
                    width: 300,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderCard),
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
                if (!_showAddForm && currentUserData.value?['position'] != 'Supervisor')
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddForm = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(appLanguage.value == 'es' ? 'Añadir Entrega' : 'Add Deliver', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF6366f1).withAlpha(100),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                if (!_showAddForm) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showHistory = !_showHistory;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showHistory ? const Color(0xFF6366f1) : bgCard,
                        foregroundColor: _showHistory ? Colors.white : const Color(0xFF6366f1),
                        elevation: _showHistory ? 4 : 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: _showHistory ? Colors.transparent : borderCard),
                        ),
                      ),
                      child: Icon(_showHistory ? Icons.folder_open_rounded : Icons.folder_special_rounded, size: 20),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            if (_showAddForm)
              Expanded(
                child: AddDeliverV2Screen(
                  key: _addDeliverKey,
                  onPop: (didAdd) {
                    setState(() {
                      _showAddForm = false;
                    });
                  },
                ),
              )
            else
              Expanded(
                child: SizedBox.expand(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderCard),
                          ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _deliversStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)));
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                              }
        
                              var items = snapshot.data ?? [];
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _logic.setDelivers(items);
                              });
        
                              if (_showHistory) {
                                return DeliversV2History(
                                  logic: _logic,
                                  onBackToMain: () {
                                    setState(() {
                                      _showHistory = false;
                                    });
                                  },
                                );
                              }

                              return ListenableBuilder(
                                listenable: _logic,
                                builder: (context, _) {
                                    // Show table even if empty
                                  return DeliversV2Table(logic: _logic, dark: dark);
                                }
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _logic,
                      builder: (context, _) {
                        if (_logic.selectedDeliverIds.isEmpty) return const SizedBox.shrink();
                        return Positioned(
                          bottom: 24,
                          left: 24,
                          right: 24,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF1e293b) : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
                                border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366f1).withAlpha(30),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_logic.selectedDeliverIds.length} Selected',
                                      style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(height: 24, width: 1, color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: () async {
                                        final res = await Supabase.instance.client.from('deliveries').select().inFilter('id_delivery', _logic.selectedDeliverIds.toList());
                                        final selected = List<Map<String, dynamic>>.from(res);
                                        if (selected.isNotEmpty) {
                                          DeliverPdfExporter.printDelivers(selected);
                                        }
                                    }, 
                                    icon: const Icon(Icons.print_rounded, color: Color(0xFF6366f1)), 
                                    tooltip: 'Print Selected', 
                                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () async {
                                        final res = await Supabase.instance.client.from('deliveries').select().inFilter('id_delivery', _logic.selectedDeliverIds.toList());
                                        final selected = List<Map<String, dynamic>>.from(res);
                                        if (selected.isNotEmpty) {
                                          DeliverPdfExporter.downloadPdf(selected);
                                        }
                                    }, 
                                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF6366f1)), 
                                    tooltip: 'Download PDF', 
                                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366f1).withAlpha(15))
                                  ),
                                  const SizedBox(width: 16),
                                  Container(height: 24, width: 1, color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: () {
                                      _logic.clearSelection();
                                    }, 
                                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent), 
                                    tooltip: 'Clear Selection', 
                                    style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withAlpha(15))
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
                ),
              ),
          ],
        );
      },
    );
  }
}
