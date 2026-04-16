import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show appLanguage, isDarkMode;

class AreaNobreakModule extends StatefulWidget {
  const AreaNobreakModule({super.key});

  @override
  State<AreaNobreakModule> createState() => _AreaNobreakModuleState();
}

class _AreaNobreakModuleState extends State<AreaNobreakModule> {
  final _searchController = TextEditingController();
  final _companyController = TextEditingController();
  final _doorController = TextEditingController();
  final _remarksController = TextEditingController();
  final Set<int> _selectedUldIds = {};
  bool _isSubmitting = false;
  late Stream<List<Map<String, dynamic>>> _uldStream;

  @override
  void initState() {
    super.initState();
    _uldStream = Supabase.instance.client.from('ULD').select().asStream();
  }

  Widget _buildDeliveryTextField(
    String label,
    TextEditingController controller,
    bool dark,
    Color textP,
    Color textS, {
    TextCapitalization textCapitalization = TextCapitalization.characters,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      onChanged: (v) => setState(() {}),
      style: TextStyle(color: textP, fontSize: 13),
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      maxLength: maxLength,
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
      inputFormatters:
          inputFormatters ??
          [
            if (textCapitalization == TextCapitalization.characters)
              TextInputFormatter.withFunction(
                (oldValue, newValue) => TextEditingValue(
                  text: newValue.text.toUpperCase(),
                  selection: newValue.selection,
                ),
              ),
          ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textS, fontSize: 13),
        filled: true,
        fillColor: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366f1), width: 1.5),
        ),
      ),
    );
  }



  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);

    switch (status.toLowerCase()) {
      case 'waiting':
        bg = const Color(0xFF334155);
        fg = const Color(0xFFcbd5e1);
        break;
      case 'received':
        bg = const Color(0xFF1e3a8a).withAlpha(51);
        fg = const Color(0xFF93c5fd);
        break;
      case 'checked':
        bg = const Color(0xFF4c1d95).withAlpha(51);
        fg = const Color(0xFFc4b5fd);
        break;
      case 'ready':
        bg = const Color(0xFF166534).withAlpha(51);
        fg = const Color(0xFF86efac);
        break;
      case 'delivered':
      case 'entregado':
        bg = const Color(0xFF047857).withAlpha(51);
        fg = const Color(0xFF34d399); 
        break;
      case 'pending':
        bg = const Color(0xFF854d0e).withAlpha(51);
        fg = const Color(0xFFfde047);
        break;
      default:
        bg = const Color(0xFF334155);
        fg = const Color(0xFFcbd5e1);
    }

    return Container(
      width: 100,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _companyController.dispose();
    _doorController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final bgCard = dark
            ? Colors.white.withAlpha(10)
            : const Color(0xFFffffff);
        final borderCard = dark
            ? Colors.white.withAlpha(25)
            : const Color(0xFFE5E7EB);
        final iconColor = dark
            ? const Color(0xFF94a3b8)
            : const Color(0xFF6B7280);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLanguage.value == 'es'
                          ? 'Área (NO BREAK)'
                          : 'Area (NO BREAK)',
                      style: TextStyle(
                        color: textP,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appLanguage.value == 'es'
                          ? 'Lista dedicada para gestionar ULDs clasificados como NO BREAK.'
                          : 'Dedicated list to manage ULDs classified as NO BREAK.',
                      style: TextStyle(color: textS, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
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
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) => TextEditingValue(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection,
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: appLanguage.value == 'es'
                          ? 'Buscar ULD...'
                          : 'Search ULD...',
                      hintStyle: TextStyle(
                        color: textP.withAlpha(76),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: iconColor,
                        size: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _uldStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366f1),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  var ulds = List<Map<String, dynamic>>.from(
                    snapshot.data ?? [],
                  );

                  ulds = ulds.where((u) {
                    final bool isBreak =
                        u['isBreak'] == true ||
                        u['isBreak']?.toString().toLowerCase() == 'true';
                    final status = (u['status']?.toString() ?? '').toLowerCase();
                    final isDelivered = status == 'delivered' || status == 'entregado';
                    return !isBreak && !isDelivered;
                  }).toList();

                  if (_searchController.text.isNotEmpty) {
                    final term = _searchController.text.toLowerCase();
                    ulds = ulds.where((u) {
                      final str = u.toString().toLowerCase();
                      return str.contains(term);
                    }).toList();
                  }

                  ulds.sort((a, b) {
                    final statusA = (a['status']?.toString() ?? '').toLowerCase();
                    final statusB = (b['status']?.toString() ?? '').toLowerCase();
                    
                    int weight(String s) {
                      if (s == 'waiting') return 1;
                      if (s == 'received') return 2;
                      if (s == 'checked') return 3;
                      if (s == 'ready') return 4;
                      if (s == 'pending') return 5;
                      if (s == 'delivered' || s == 'entregado') return 7;
                      return 6;
                    }

                    final wA = weight(statusA);
                    final wB = weight(statusB);

                    if (wA != wB) {
                      return wA.compareTo(wB);
                    }
                    
                    final uldA = a['ULD-number']?.toString() ?? '';
                    final uldB = b['ULD-number']?.toString() ?? '';
                    return uldA.compareTo(uldB);
                  });

                  final selectedUlds = ulds
                      .where((u) => _selectedUldIds.contains(u['id'] as int))
                      .toList();

                  return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF0f172a).withAlpha(100)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderCard),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                appLanguage.value == 'es'
                                    ? 'Información de Entrega'
                                    : 'Delivery Information',
                                style: TextStyle(
                                  color: textP,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildDeliveryTextField(
                                      'Company',
                                      _companyController,
                                      dark,
                                      textP,
                                      textS,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 70,
                                    child: _buildDeliveryTextField(
                                      'Door',
                                      _doorController,
                                      dark,
                                      textP,
                                      textS,
                                      keyboardType: TextInputType.number,
                                      maxLength: 2,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 5,
                                    child: _buildDeliveryTextField(
                                      'Remarks',
                                      _remarksController,
                                      dark,
                                      textP,
                                      textS,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      inputFormatters: [
                                        TextInputFormatter.withFunction((
                                          oldValue,
                                          newValue,
                                        ) {
                                          if (newValue.text.isEmpty) {
                                            return newValue;
                                          }
                                          final text = newValue.text;
                                          final formatted =
                                              text[0].toUpperCase() +
                                              text.substring(1).toLowerCase();
                                          return TextEditingValue(
                                            text: formatted,
                                            selection: newValue.selection,
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                appLanguage.value == 'es'
                                    ? 'Seleccionar ULDs NO BREAK (${_selectedUldIds.length} selecc.)'
                                    : 'Select NO BREAK ULDs (${_selectedUldIds.length} selected)',
                                style: TextStyle(
                                  color: textS,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ulds.isEmpty
                                    ? Center(
                                        child: Text(
                                          appLanguage.value == 'es'
                                              ? 'No hay ULDs disponibles'
                                              : 'No ULDs available',
                                          style: TextStyle(
                                            color: textP.withAlpha(76),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: ulds.length,
                                        itemBuilder: (context, index) {
                                          final su = ulds[index];
                                          final isSelected = _selectedUldIds.contains(su['id'] as int);
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedUldIds.remove(su['id'] as int);
                                                } else {
                                                  _selectedUldIds.add(su['id'] as int);
                                                }
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected 
                                                    ? (dark ? const Color(0xFF6366f1).withAlpha(30) : const Color(0xFFe0e7ff)) 
                                                    : bgCard,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSelected ? const Color(0xFF6366f1) : borderCard,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: isSelected 
                                                          ? const Color(0xFF6366f1) 
                                                          : const Color(0xFF6366f1).withAlpha(30),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: TextStyle(
                                                        color: isSelected ? Colors.white : const Color(0xFF6366f1),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'ULD NUMBER:',
                                                          style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          su['ULD-number']?.toString() ?? '-',
                                                          style: TextStyle(
                                                            color: textP,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'FLIGHT:',
                                                          style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.flight_takeoff_rounded, size: 12, color: Colors.grey),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              su['refCarrier'] == null 
                                                                  ? 'Standalone ULD' 
                                                                  : '${su['refCarrier']} ${su['refNumber'] ?? ''}',
                                                              style: TextStyle(
                                                                color: textP,
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ]
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'PIECES:',
                                                          style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          su['pieces']?.toString() ?? '0',
                                                          style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'WEIGHT:',
                                                          style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${su['weight']?.toString() ?? '0'} kg',
                                                          style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'REMARKS:',
                                                          style: TextStyle(color: textS, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          (su['remarks'] == null || su['remarks'].toString().trim().isEmpty)
                                                              ? 'No remarks' 
                                                              : su['remarks'].toString(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(color: textP, fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: _buildStatusBadge(
                                                        su['status']?.toString() ?? 'Received',
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: isSelected 
                                                          ? const Color(0xFF6366f1) 
                                                          : (dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: isSelected 
                                                          ? null 
                                                          : Border.all(color: dark ? Colors.white.withAlpha(50) : Colors.black.withAlpha(30)),
                                                    ),
                                                    child: isSelected 
                                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) 
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: (_isSubmitting ||
                                          selectedUlds.isEmpty ||
                                          _companyController.text.trim().isEmpty ||
                                          _doorController.text.trim().isEmpty)
                                      ? null
                                      : () async {
                                          setState(() => _isSubmitting = true);
                                          final company = _companyController.text.trim();
                                          final door = _doorController.text.trim();
                                          final remarks = _remarksController.text.trim();
                                          
                                          String fullname = Supabase.instance.client.auth.currentUser?.email ?? 'Unknown';
                                          try {
                                              final uUser = Supabase.instance.client.auth.currentUser;
                                              if (uUser != null) {
                                                final profile = await Supabase.instance.client.from('users').select('full-name').eq('email', uUser.email!).maybeSingle();
                                                if (profile != null && profile['full-name'] != null) {
                                                  fullname = profile['full-name'].toString();
                                                }
                                              }
                                          } catch (_) {}

                                          final now = DateTime.now().toIso8601String();

                                          final deliveryData = {
                                              'company': company,
                                              'door': door,
                                              'remarks': remarks,
                                              'time': now,
                                              'user': fullname,
                                          };

                                          try {
                                            for (var su in selectedUlds) {
                                                final uId = su['id'] as int;
                                                final uldName = su['ULD-number']?.toString() ?? '';

                                                await Supabase.instance.client.from('ULD').update({
                                                   'data-delivery': deliveryData,
                                                   'status': 'Delivered'
                                                }).eq('id', uId);

                                                if (uldName.isNotEmpty) {
                                                  await Supabase.instance.client.rpc('process_uld_delivery', params: {
                                                    'p_uld_name': uldName,
                                                    'p_delivery_data': deliveryData,
                                                  });
                                                }
                                            }

                                            if (!context.mounted) return;
                                            setState(() {
                                                _selectedUldIds.clear();
                                                _companyController.clear();
                                                _doorController.clear();
                                                _remarksController.clear();
                                                _isSubmitting = false;
                                            });
                                            
                                            bool dialogOpen = true;
                                            showGeneralDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              barrierColor: Colors.black54,
                                              transitionDuration: const Duration(milliseconds: 350),
                                              pageBuilder: (ctx, anim1, anim2) {
                                                final dark = isDarkMode.value;
                                                return Center(
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: Container(
                                                      width: 320,
                                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                                      decoration: BoxDecoration(
                                                        color: dark ? const Color(0xFF1e293b) : Colors.white,
                                                        borderRadius: BorderRadius.circular(24),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFF10b981).withAlpha(40),
                                                            blurRadius: 40,
                                                            offset: const Offset(0, 10),
                                                          ),
                                                        ],
                                                        border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.all(20),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF10b981).withAlpha(20),
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48),
                                                          ),
                                                          const SizedBox(height: 24),
                                                          Text(
                                                            appLanguage.value == 'es' ? '¡ULDs Entregados!' : 'ULDs Delivered!',
                                                            style: TextStyle(
                                                              color: dark ? Colors.white : const Color(0xFF111827),
                                                              fontSize: 22,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            appLanguage.value == 'es'
                                                                ? 'La entrega se ha registrado exitosamente.'
                                                                : 'The delivery has been recorded successfully.',
                                                            style: TextStyle(
                                                              color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              transitionBuilder: (ctx, anim1, anim2, child) {
                                                return Transform.scale(
                                                  scale: Curves.easeOutBack.transform(anim1.value),
                                                  child: FadeTransition(
                                                    opacity: anim1,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                            ).then((_) => dialogOpen = false);

                                            Future.delayed(const Duration(milliseconds: 2000), () {
                                              if (context.mounted && dialogOpen) {
                                                Navigator.of(context).pop();
                                              }
                                            });
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            setState(() => _isSubmitting = false);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                                            );
                                          }
                                      },
                                  icon: _isSubmitting 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                      : const Icon(Icons.outbox_rounded, size: 20),
                                  label: Text(
                                    appLanguage.value == 'es'
                                        ? 'Entregar ULDs'
                                        : 'Deliver ULDs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366f1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class ResizeGripPainter extends CustomPainter {
  final Color color;
  ResizeGripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Small line
    canvas.drawLine(
      Offset(size.width - 2, size.height - 2),
      Offset(size.width - 2, size.height - 2),
      paint,
    );
    // Medium line
    canvas.drawLine(
      Offset(size.width - 6, size.height - 2),
      Offset(size.width - 2, size.height - 6),
      paint,
    );
    // Large line
    canvas.drawLine(
      Offset(size.width - 10, size.height - 2),
      Offset(size.width - 2, size.height - 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
