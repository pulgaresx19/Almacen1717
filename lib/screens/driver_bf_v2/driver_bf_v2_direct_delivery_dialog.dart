import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, currentUserData;

class DriverBfV2DirectDeliveryDialog extends StatefulWidget {
  final bool dark;
  const DriverBfV2DirectDeliveryDialog({super.key, required this.dark});

  @override
  State<DriverBfV2DirectDeliveryDialog> createState() => _DriverBfV2DirectDeliveryDialogState();
}

class _DriverBfV2DirectDeliveryDialogState extends State<DriverBfV2DirectDeliveryDialog> {
  bool _isLoading = true;
  bool _formSubmitted = false;
  List<Map<String, dynamic>> _availableUlds = [];
  final Set<String> _selectedUldIds = {};

  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _doorCtrl = TextEditingController();
  final _idPickupCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _fetchUlds();
  }

  void _onSearchChanged() {
    setState(() {});
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
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _companyCtrl.dispose();
    _driverNameCtrl.dispose();
    _doorCtrl.dispose();
    _idPickupCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _generatePickupId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final result = String.fromCharCodes(Iterable.generate(
      10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    _idPickupCtrl.text = result;
    if (_formSubmitted) setState(() {});
  }

  Future<void> _submit() async {
    setState(() => _formSubmitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUldIds.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? '00000000-0000-0000-0000-000000000000';
      final userName = currentUserData.value?['full_name'] ?? currentUserData.value?['first_name'] ?? 'Unknown User';

      await Supabase.instance.client.rpc(
        'rpc_save_direct_delivery_ulds',
        params: {
          'p_company': _companyCtrl.text.trim(),
          'p_driver_name': _driverNameCtrl.text.trim(),
          'p_door': _doorCtrl.text.trim(),
          'p_id_pickup': _idPickupCtrl.text.trim(),
          'p_remark': _remarkCtrl.text.trim(),
          'p_uld_ids': _selectedUldIds.toList(),
          'p_user_uuid': userId,
          'p_user_name': userName,
        },
      );

      if (!mounted) return;
      
      final dark = widget.dark;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (BuildContext successCtx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1e293b) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10b981).withAlpha(40),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10b981).withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Color(0xFF10b981), size: 48),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            appLanguage.value == 'es' ? '¡Entrega Creada!' : 'Delivery Created!',
                            style: TextStyle(
                              color: dark ? Colors.white : const Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appLanguage.value == 'es' 
                                ? 'La entrega directa se procesó correctamente.' 
                                : 'Direct delivery processed successfully.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );

      // Auto-close both the success dialog and the main dialog
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop(); // Close success dialog
          Navigator.of(context).pop(true); // Close main dialog & return true to parent
        }
      });

    } catch (e) {
      debugPrint('Error en RPC: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                          child: Padding(
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
                                          Expanded(child: _buildInput('Company', _companyCtrl, dark, textS, textP, borderC, 
                                            textCapitalization: TextCapitalization.characters,
                                            inputFormatters: [
                                              TextInputFormatter.withFunction((oldValue, newValue) {
                                                return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
                                              }),
                                            ]
                                          )),
                                          const SizedBox(width: 16),
                                          Expanded(child: _buildInput('Driver Name', _driverNameCtrl, dark, textS, textP, borderC, 
                                            textCapitalization: TextCapitalization.words,
                                            inputFormatters: [
                                              TextInputFormatter.withFunction((oldValue, newValue) {
                                                if (newValue.text.isEmpty) return newValue;
                                                final text = newValue.text;
                                                final buffer = StringBuffer();
                                                bool capitalizeNext = true;
                                                for (int i = 0; i < text.length; i++) {
                                                  final char = text[i];
                                                  if (char == ' ') {
                                                    capitalizeNext = true;
                                                    buffer.write(char);
                                                  } else if (capitalizeNext) {
                                                    buffer.write(char.toUpperCase());
                                                    capitalizeNext = false;
                                                  } else {
                                                    buffer.write(char.toLowerCase());
                                                  }
                                                }
                                                return TextEditingValue(text: buffer.toString(), selection: newValue.selection);
                                              }),
                                            ]
                                          )),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          SizedBox(width: 60, child: _buildInput('Door', _doorCtrl, dark, textS, textP, borderC, 
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(2),
                                            ]
                                          )),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3, 
                                            child: _buildInput(
                                              'ID Pickup', 
                                              _idPickupCtrl, 
                                              dark, textS, textP, borderC, 
                                              suffixIcon: IconButton(
                                                icon: const Icon(Icons.autorenew_rounded, size: 18),
                                                onPressed: _generatePickupId,
                                                color: const Color(0xFF6366f1),
                                              ),
                                            )
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(flex: 5, child: _buildInput('Remark', _remarkCtrl, dark, textS, textP, borderC, isRequired: false, 
                                            textCapitalization: TextCapitalization.sentences,
                                            inputFormatters: [
                                              TextInputFormatter.withFunction((oldValue, newValue) {
                                                if (newValue.text.isEmpty) return newValue;
                                                final text = newValue.text;
                                                final newText = text[0].toUpperCase() + text.substring(1).toLowerCase();
                                                return TextEditingValue(text: newText, selection: newValue.selection);
                                              }),
                                            ]
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // List of Deliveries Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          appLanguage.value == 'es' ? 'LISTA DE ULD NO BREAK' : 'LIST OF ULD NO BREAK',
                                          style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                        ),
                                        if (_selectedUldIds.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366f1).withAlpha(30),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${_selectedUldIds.length}',
                                              style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: TextField(
                                        controller: _searchCtrl,
                                        style: TextStyle(color: textP, fontSize: 13),
                                        textCapitalization: TextCapitalization.characters,
                                        inputFormatters: [
                                          TextInputFormatter.withFunction((oldValue, newValue) {
                                            return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
                                          }),
                                        ],
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: appLanguage.value == 'es' ? 'Buscar ULD...' : 'Search ULD...',
                                          hintStyle: TextStyle(color: textS),
                                          prefixIcon: Icon(Icons.search_rounded, color: textS, size: 16),
                                          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
                                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366f1))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                Expanded(
                                  child: Builder(
                                  builder: (context) {
                                    final searchQuery = _searchCtrl.text.toLowerCase().trim();
                                    final filteredUlds = _availableUlds.where((item) {
                                      final uldNumber = item['uld_number']?.toString().toLowerCase() ?? '';
                                      return uldNumber.contains(searchQuery);
                                    }).toList();
                                    
                                    if (_availableUlds.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Text(
                                            appLanguage.value == 'es' ? 'No hay ULDs disponibles para entrega.' : 'No ULDs available for delivery.',
                                            style: TextStyle(color: textS),
                                          ),
                                        ),
                                      );
                                    } else if (filteredUlds.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Text(
                                            appLanguage.value == 'es' ? 'No se encontraron ULDs con esa búsqueda.' : 'No ULDs found matching your search.',
                                            style: TextStyle(color: textS),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return ListView.separated(
                                        itemCount: filteredUlds.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final item = filteredUlds[index];
                                      final uldId = item['id_uld']?.toString() ?? '';
                                      final rawNumber = item['uld_number']?.toString() ?? 'N/A';
                                      final uldNumber = rawNumber;
                                      
                                      final pieces = item['pieces_total']?.toString() ?? '0';
                                      final weight = item['weight_total']?.toString() ?? '0';
                                      
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
                                  );
                                }
                              },
                            ),
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
                    onPressed: (_isLoading || _selectedUldIds.isEmpty) ? null : _submit,
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

  Widget _buildInput(String label, TextEditingController controller, bool dark, Color textS, Color textP, Color borderC, {bool isRequired = true, Widget? suffixIcon, List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType, TextCapitalization textCapitalization = TextCapitalization.none}) {
    final hasError = _formSubmitted && isRequired && controller.text.trim().isEmpty;
    final labelColor = hasError ? Colors.redAccent : textS;
    final fillColor = hasError ? Colors.redAccent.withAlpha(15) : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: hasError ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold),
          validator: isRequired ? ((v) => v == null || v.trim().isEmpty ? '' : null) : null,
          onChanged: (value) {
            if (_formSubmitted) setState(() {});
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderC)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366f1))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            suffixIcon: suffixIcon ?? const SizedBox(width: 0, height: 40),
            suffixIconConstraints: suffixIcon != null ? const BoxConstraints(minWidth: 36, minHeight: 40) : const BoxConstraints(minWidth: 0, minHeight: 40),
          ),
        ),
      ],
    );
  }
}
