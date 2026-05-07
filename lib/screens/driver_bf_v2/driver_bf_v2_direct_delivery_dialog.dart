import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage;

class DriverBfV2DirectDeliveryDialog extends StatefulWidget {
  final bool dark;
  const DriverBfV2DirectDeliveryDialog({super.key, required this.dark});

  @override
  State<DriverBfV2DirectDeliveryDialog> createState() => _DriverBfV2DirectDeliveryDialogState();
}

class _DriverBfV2DirectDeliveryDialogState extends State<DriverBfV2DirectDeliveryDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableUlds = [];
  final Set<String> _selectedUldIds = {};

  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _doorCtrl = TextEditingController();
  String _type = 'Send-ULD';

  @override
  void initState() {
    super.initState();
    _fetchUlds();
  }

  Future<void> _fetchUlds() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('ulds')
          .select()
          .eq('is_break', false);

      final filtered = (res as List).where((u) {
        final hasTimeReceived = u['time_received'] != null && u['time_received'].toString().isNotEmpty;
        final isInProcess = u['in_process'] == true;
        final isWaiting = u['waiting'] == true;
        final isSendDriver = u['send_driver'] == true;
        final hasTimeDeliver = u['time_deliver'] != null && u['time_deliver'].toString().isNotEmpty;
        final isSendUld = u['send_uld'] == true;
        final isSendBreak = u['send_break'] == true;
        final isInFlight = u['in_flight'] == true;

        if (!hasTimeReceived) return false;
        if (isInProcess || isWaiting || isSendDriver || hasTimeDeliver || isSendUld || isSendBreak || isInFlight) return false;
        
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _availableUlds = List<Map<String, dynamic>>.from(filtered);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ULDs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _driverNameCtrl.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUldIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLanguage.value == 'es' ? 'Selecciona al menos un ULD.' : 'Select at least one ULD.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // El botón es puramente visual por ahora hasta que se defina la lógica del RPC.
    debugPrint('Botón presionado. Lógica pendiente.');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appLanguage.value == 'es' ? 'Funcionalidad de entrega pendiente de configuración.' : 'Delivery functionality pending configuration.'),
        backgroundColor: Colors.blueAccent,
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final size = MediaQuery.of(context).size;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);
    final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
    final bgGlassy = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: size.height * 0.85,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: bgDialog,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366f1).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.outbox_rounded, color: Color(0xFF6366f1), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLanguage.value == 'es' ? 'Entrega Directa ULD' : 'Direct ULD Delivery',
                              style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appLanguage.value == 'es' ? 'Crear Nuevo Registro' : 'Create New Record',
                              style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: textS),
                        hoverColor: Colors.white.withAlpha(10),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderC),
                
                // Body
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
                      : Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // General Info Section
                                Text(
                                  appLanguage.value == 'es' ? 'INFORMACIÓN GENERAL' : 'GENERAL INFORMATION',
                                  style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: bgGlassy,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderC),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _buildInput('Company', _companyCtrl, dark, textS, textP, borderC)),
                                          const SizedBox(width: 16),
                                          Expanded(child: _buildInput('Driver Name', _driverNameCtrl, dark, textS, textP, borderC)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(child: _buildInput('Door', _doorCtrl, dark, textS, textP, borderC)),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Type', style: TextStyle(color: textS, fontSize: 11)),
                                                const SizedBox(height: 4),
                                                DropdownButtonFormField<String>(
                                                  initialValue: _type,
                                                  items: ['Import', 'Export', 'Transfer', 'Walk-In', 'Send-ULD']
                                                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                                                      .toList(),
                                                  onChanged: (v) => setState(() => _type = v!),
                                                  dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
                                                  style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold),
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
                                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
                                                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366f1))),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // List of Deliveries Section
                                Text(
                                  appLanguage.value == 'es' ? 'LISTA DE ENTREGAS' : 'DELIVERIES LIST',
                                  style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                const SizedBox(height: 16),
                                
                                if (_availableUlds.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Text(
                                        appLanguage.value == 'es' ? 'No hay ULDs disponibles para entrega.' : 'No ULDs available for delivery.',
                                        style: TextStyle(color: textS),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _availableUlds.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final item = _availableUlds[index];
                                      final uldId = item['id_uld']?.toString() ?? '';
                                      final rawNumber = item['uld_number']?.toString() ?? 'N/A';
                                      final uldNumber = 'ULD: $rawNumber';
                                      
                                      final pieces = item['pieces']?.toString() ?? '0';
                                      final weight = item['weight']?.toString() ?? '0';
                                      
                                      final isSelected = _selectedUldIds.contains(uldId);
                                      
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedUldIds.remove(uldId);
                                            } else {
                                              _selectedUldIds.add(uldId);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? (dark ? const Color(0xFF10b981).withAlpha(15) : const Color(0xFF10b981).withAlpha(10))
                                                : bgGlassy,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFF10b981) : borderC,
                                              width: isSelected ? 1.5 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: isSelected 
                                                      ? const Color(0xFF10b981) 
                                                      : (dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10)),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: isSelected
                                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                                    : Text('${index + 1}', style: TextStyle(color: textS, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  uldNumber, 
                                                  style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Pieces', style: TextStyle(color: textS, fontSize: 10)),
                                                    Text(pieces, style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Weight', style: TextStyle(color: textS, fontSize: 10)),
                                                    Text('$weight kg', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
                
                // Fixed Bottom Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgDialog,
                    border: Border(top: BorderSide(color: borderC)),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: const Icon(Icons.task_alt_rounded, size: 20),
                    label: Text(
                      appLanguage.value == 'es' ? 'Marcar Entrega Finalizada' : 'Mark Delivery Finished',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF10b981).withAlpha(80),
                      disabledForegroundColor: Colors.white.withAlpha(180),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, bool dark, Color textS, Color textP, Color borderC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold),
          validator: (v) => v == null || v.trim().isEmpty ? '*' : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366f1))),
            errorStyle: const TextStyle(height: 0),
          ),
        ),
      ],
    );
  }
}
