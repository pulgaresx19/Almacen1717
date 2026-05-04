import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../add_awb_v2/add_awb_v2_logic.dart';
import 'awbs_v2_add_awb_form.dart';
import 'awbs_v2_add_uld_form.dart';

class AwbsV2AddItemsScreen extends StatefulWidget {
  final VoidCallback onPop;

  const AwbsV2AddItemsScreen({super.key, required this.onPop});

  @override
  State<AwbsV2AddItemsScreen> createState() => _AwbsV2AddItemsScreenState();
}

class _AwbsV2AddItemsScreenState extends State<AwbsV2AddItemsScreen> {
  final List<Map<String, dynamic>> _addedAwbs = [];
  final List<Map<String, dynamic>> _addedUlds = [];
  bool _isSavingAll = false;

  Future<void> _saveAllItems() async {
    if (_addedAwbs.isEmpty && _addedUlds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appLanguage.value == 'es' ? 'No hay registros para guardar.' : 'No records to save.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSavingAll = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      String userName = session?.user.email ?? 'Unknown';
      if (session != null) {
        if (session.user.userMetadata?['full_name'] != null) {
          userName = session.user.userMetadata!['full_name'].toString();
        }
        try {
          final profile = await Supabase.instance.client.from('users').select('full_name').eq('id', session.user.id).maybeSingle();
          if (profile != null && profile['full_name'] != null && profile['full_name'].toString().trim().isNotEmpty) {
            userName = profile['full_name'].toString().trim();
          }
        } catch (_) {}
      }

      if (_addedUlds.isNotEmpty) {
        final uldsPayload = _addedUlds.map((uld) => {
          'uld_number': uld['uld_number'],
          'pieces_total': uld['pieces'].toString().isEmpty ? null : int.tryParse(uld['pieces'].toString()),
          'weight_total': uld['weight'].toString().isEmpty ? null : double.tryParse(uld['weight'].toString()),
          'remarks': uld['remarks'].toString().isEmpty ? null : uld['remarks'],
          'status': 'Received',
          'is_break': false,
        }).toList();
        await Supabase.instance.client.from('ulds').insert(uldsPayload);
      }

      if (_addedAwbs.isNotEmpty) {
        List<Map<String, dynamic>> localAwbs = _addedAwbs.map((a) {
           return {
              'awbNumber': a['awb_number'],
              'pieces': int.tryParse(a['pieces'].toString()) ?? 1,
              'total': int.tryParse(a['total_pieces'].toString()) ?? 1,
              'weight': double.tryParse(a['weight'].toString()) ?? 0.0,
              'remarks': a['remarks'].toString().isEmpty ? null : a['remarks'],
              'house': a['house_number'].toString().split('\n').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList(),
              'coordinatorCounts': a['data_coordinator'],
              'itemLocations': a['data_location'],
              'flight_id': null,
              'refCarrier': 'WRHS',
              'refNumber': 'LOCAL',
              'refUld': 'MANUAL',
           };
        }).toList();
        
        await AddAwbV2Logic.saveAllAwbs(localAwbs: localAwbs, userName: userName);
      }

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text(appLanguage.value == 'es' ? 'Registros guardados con éxito.' : 'Records saved successfully.'), 
           backgroundColor: Colors.green
         ));
         setState(() {
            _addedAwbs.clear();
            _addedUlds.clear();
         });
         widget.onPop();
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Error: $e'), 
           backgroundColor: Colors.redAccent
         ));
      }
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderCard)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: textP),
                      onPressed: widget.onPop,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      appLanguage.value == 'es' ? 'Añadir Nuevo Ítem' : 'Add New Item',
                      style: TextStyle(color: textP, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingAll ? null : _saveAllItems,
                        icon: _isSavingAll 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          appLanguage.value == 'es' ? 'Guardar Registros' : 'Save Records',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981), // Emerald green for save action
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF10b981).withAlpha(100),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Split Content
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // AWB Section
                    Expanded(
                      child: AwbsV2AddAwbForm(
                        onAdd: (item) {
                          setState(() {
                            _addedAwbs.add(item);
                          });
                        },
                      ),
                    ),
                    
                    // Divider
                    Container(width: 1, color: borderCard),
                    
                    // ULD Section
                    Expanded(
                      child: AwbsV2AddUldForm(
                        onAdd: (item) {
                          setState(() {
                            _addedUlds.add(item);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
            
            const SizedBox(height: 24),
            
            // Bottom Lists Section
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AWB List Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCard),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              appLanguage.value == 'es' ? 'Lista de AWBs' : 'AWB List',
                              style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_addedAwbs.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  appLanguage.value == 'es' ? 'No hay AWBs agregados aún.' : 'No AWBs added yet.',
                                  style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _addedAwbs.length,
                                itemBuilder: (context, index) {
                                  final item = _addedAwbs[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      title: Text(item['awb_number'], style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(
                                        'Piezas: ${item['pieces'].isEmpty ? '0' : item['pieces']} / ${item['total_pieces'].isEmpty ? '0' : item['total_pieces']} | Peso: ${item['weight'].isEmpty ? '0' : item['weight']} | House: ${item['house_number'].isEmpty ? 'N/A' : item['house_number']}',
                                        style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 12),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () => setState(() => _addedAwbs.removeAt(index)),
                                        splashRadius: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // ULD List Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCard),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              appLanguage.value == 'es' ? 'Lista de ULDs' : 'ULD List',
                              style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_addedUlds.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  appLanguage.value == 'es' ? 'No hay ULDs agregados aún.' : 'No ULDs added yet.',
                                  style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563)),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _addedUlds.length,
                                itemBuilder: (context, index) {
                                  final item = _addedUlds[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      title: Text(item['uld_number'], style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(
                                        'Piezas: ${item['pieces'].isEmpty ? '0' : item['pieces']} / ${item['total_pieces'].isEmpty ? '0' : item['total_pieces']} | Peso: ${item['weight'].isEmpty ? '0' : item['weight']}',
                                        style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 12),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () => setState(() => _addedUlds.removeAt(index)),
                                        splashRadius: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
