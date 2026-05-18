import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../main.dart' show appLanguage, isDarkMode;
import 'coordinator_v2_logic.dart';
import 'coordinator_v2_uld_awbs.dart';
import 'coordinator_v2_footer.dart';

class CoordinatorV2Panel extends StatefulWidget {
  final CoordinatorV2Logic logic;

  const CoordinatorV2Panel({super.key, required this.logic});

  @override
  State<CoordinatorV2Panel> createState() => _CoordinatorV2PanelState();
}

class _CoordinatorV2PanelState extends State<CoordinatorV2Panel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: widget.logic.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final dark = isDarkMode.value;
        return Theme(
          data: dark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF6366f1),
                    surface: Color(0xFF1e293b),
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF4F46E5),
                  ),
                ),
          child: child!,
        );
      },
    );
    if (dt != null) {
      widget.logic.setDate(dt);
    }
  }

  void _showUldInfoDialog(BuildContext context, Map<String, dynamic> uld, bool dark, Color textP, Color textS, Color borderC) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appLanguage.value == 'es' ? 'Info de la Paleta' : 'ULD Info', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (uld['time_received'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.download_done, size: 16, color: Color(0xFF6366f1)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appLanguage.value == 'es' ? 'Recibido Por' : 'Received By', style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${uld['user_received'] ?? 'Unknown'}', style: TextStyle(color: textP, fontSize: 14)),
                                Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(uld['time_received']).toLocal()), style: TextStyle(color: textS, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (uld['time_checked'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.done_all, size: 16, color: Color(0xFF10b981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appLanguage.value == 'es' ? 'Chequeado Por' : 'Checked By', style: const TextStyle(color: Color(0xFF10b981), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${uld['user_checked'] ?? 'Unknown'}', style: TextStyle(color: textP, fontSize: 14)),
                                Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(uld['time_checked']).toLocal()), style: TextStyle(color: textS, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (uld['time_saved'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appLanguage.value == 'es' ? 'Localizado Por' : 'Located By', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${uld['user_saved'] ?? 'Unknown'}', style: TextStyle(color: textP, fontSize: 14)),
                                Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(uld['time_saved']).toLocal()), style: TextStyle(color: textS, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (uld['time_received'] == null && uld['time_checked'] == null && uld['time_saved'] == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(appLanguage.value == 'es' ? 'Aún no se ha recibido, chequeado ni localizado.' : 'Not received, checked, or located yet.', style: TextStyle(color: textS)),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(appLanguage.value == 'es' ? 'Cerrar' : 'Close', style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.logic, isDarkMode]),
      builder: (context, child) {
        final dark = isDarkMode.value;
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff);
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        return Container(
          padding: const EdgeInsets.all(32),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: widget.logic.selectedDate != null ? Container(
                      height: 40,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.toUpperCase(),
                            ),
                          ),
                        ],
                        style: TextStyle(
                          color: textP,
                          fontSize: 13,
                        ),
                        onChanged: (v) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: appLanguage.value == 'es' ? 'Buscar ULD...' : 'Search ULD...',
                          hintStyle: TextStyle(
                            color: textS.withAlpha(150),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  color: textS,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                        ),
                      ),
                    ) : null,
                  ),
                  
                  Text(
                    appLanguage.value == 'es' ? 'Coordinador de Vuelos' : 'Flight Coordinator',
                    style: TextStyle(
                      color: dark ? Colors.white.withAlpha(150) : const Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      widget.logic.selectedDate == null
                          ? (appLanguage.value == 'es'
                              ? 'Seleccionar Fecha'
                              : 'Select Date')
                          : DateFormat('MM/dd/yyyy').format(widget.logic.selectedDate!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.logic.isLoadingFlights)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                  ),
                )
              else if (widget.logic.flights.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      widget.logic.selectedDate == null
                          ? (appLanguage.value == 'es'
                              ? 'Selecciona una fecha.'
                              : 'Pick a date to load flights.')
                          : (appLanguage.value == 'es'
                              ? 'No se encontraron vuelos.'
                              : 'No flights found.'),
                      style: TextStyle(color: textS),
                    ),
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.logic.flights.map((f) {
                          final chipId = f['id_flight']?.toString() ?? '';
                          final isSel = widget.logic.selectedFlightId == chipId && chipId.isNotEmpty;
                          final isChecked = f['is_checked'] == true;

                          Color textColor = isSel
                              ? Colors.white
                              : (isChecked ? const Color(0xFF10b981) : textP);
                          Color selColor = isChecked
                              ? const Color(0xFF10b981)
                              : const Color(0xFF6366f1);
                          Color unselBgColor = isChecked
                              ? const Color(0xFF10b981).withAlpha(15)
                              : bgCard;
                          Color borderColor = isSel
                              ? Colors.transparent
                              : (isChecked
                                  ? const Color(0xFF10b981).withAlpha(50)
                                  : borderC);

                          return ChoiceChip(
                            label: Text(
                              '${f['carrier'] ?? ''} ${f['number'] ?? ''}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: selColor,
                            backgroundColor: unselBgColor,
                            showCheckmark: false,
                            side: BorderSide(color: borderColor),
                            onSelected: (v) {
                              if (chipId.isNotEmpty) {
                                widget.logic.selectFlight(chipId);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    if (widget.logic.selectedFlightId != null) ...[
                      const SizedBox(width: 16),
                      Builder(
                        builder: (context) {
                          final fIdx = widget.logic.flights.indexWhere((f) => f['id_flight'].toString() == widget.logic.selectedFlightId);
                          if (fIdx == -1) return const SizedBox.shrink();
                          final f = widget.logic.flights[fIdx];
                          final isEnabled = f['is_delivery_enabled'] == true;

                          return Tooltip(
                            message: isEnabled 
                                ? (appLanguage.value == 'es' ? 'Entregas habilitadas para este vuelo' : 'Deliveries enabled for this flight')
                                : (appLanguage.value == 'es' ? 'Habilitar entregas de este vuelo para los choferes' : 'Enable deliveries of this flight for drivers'),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isEnabled ? null : () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => _buildEnableDeliveryConfirmDialog(context, widget.logic, f),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isEnabled ? const Color(0xFF10b981).withAlpha(20) : (dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isEnabled ? const Color(0xFF10b981).withAlpha(50) : borderC,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEnabled ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                      size: 16,
                                      color: isEnabled ? const Color(0xFF10b981) : textS,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEnabled 
                                        ? (appLanguage.value == 'es' ? 'Habilitado' : 'Enabled')
                                        : (appLanguage.value == 'es' ? 'Desbloquear Vuelo' : 'Unlock Flight'),
                                      style: TextStyle(
                                        color: isEnabled ? const Color(0xFF10b981) : textS,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                if (widget.logic.selectedFlightId != null) ...[
                  const SizedBox(height: 16),
                  if (widget.logic.isLoadingUlds)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF6366f1))))
                  else if (widget.logic.ulds.isEmpty)
                    Text(
                      appLanguage.value == 'es'
                          ? 'No hay ULDs encontrados para este vuelo.'
                          : 'No ULDs found for this flight.',
                      style: TextStyle(color: textS),
                    )
                  else
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final query = _searchController.text.trim().toLowerCase();
                          final filteredUlds = query.isEmpty 
                              ? widget.logic.ulds 
                              : widget.logic.ulds.where((u) {
                                  final uldNum = u.cast<String, dynamic>()['uld_number']?.toString().toLowerCase() ?? '';
                                  return uldNum.contains(query);
                                }).toList();

                          if (filteredUlds.isEmpty) {
                            return Center(
                              child: Text(
                                appLanguage.value == 'es' ? 'No se encontraron resultados.' : 'No results found.',
                                style: TextStyle(color: textS),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredUlds.length,
                            itemBuilder: (context, index) {
                              final uld = filteredUlds[index];
                          final int pieces = uld['pieces_total'] ?? 0;
                          final num weight = uld['weight_total'] ?? 0;
                          final String remarks = uld['remarks']?.toString() ?? '';

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: widget.logic.selectedUldId == uld['id_uld']?.toString() ? const Color(0xFF6366f1).withAlpha(10) : bgCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: widget.logic.selectedUldId == uld['id_uld']?.toString() ? const Color(0xFF6366f1).withAlpha(50) : borderC
                                  ),
                                ),
                                child: Column(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final id = uld['id_uld']?.toString() ?? '';
                                    if (id.isNotEmpty) widget.logic.selectUld(id);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          _showUldInfoDialog(context, uld, dark, textP, textS, borderC);
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366f1).withAlpha(30),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFF6366f1),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 105,
                                        child: Text(
                                          '${uld['uld_number'] ?? '-'}',
                                          style: TextStyle(
                                            color: textP,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 55,
                                        child: Text(
                                          '$pieces pcs',
                                          style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '$weight kg',
                                          style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (remarks.trim().isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFf59e0b).withAlpha(15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFf59e0b).withAlpha(40)),
                                            ),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics: const BouncingScrollPhysics(),
                                              child: Text(
                                                remarks,
                                                style: const TextStyle(
                                                  color: Color(0xFFd97706),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        const Spacer(),
                                      ],
                                    ],
                                  ),
                                ),
                                  const SizedBox(width: 12),
                                  Builder(
                                    builder: (context) {
                                      final bool isAllChecked = uld['all_checked'] == true;
                                      final bool isReady = uld['time_checked'] != null;
                                      
                                      final List<dynamic> discrepancies = (uld['discrepancies_summary'] is List) ? uld['discrepancies_summary'] as List : [];
                                      final bool hasDiscrepancy = isReady && discrepancies.isNotEmpty;

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (hasDiscrepancy) ...[
                                            InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    backgroundColor: dark ? const Color(0xFF1E293B) : Colors.white,
                                                    title: Row(
                                                      children: [
                                                        const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          appLanguage.value == 'es' ? 'Resumen de Discrepancias' : 'Discrepancy Summary',
                                                          style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
                                                        ),
                                                      ],
                                                    ),
                                                    content: SizedBox(
                                                      width: 300,
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: discrepancies.length,
                                                        itemBuilder: (ctx, i) {
                                                          final d = discrepancies[i];
                                                          return Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                                            child: DefaultTextStyle(
                                                              style: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 14),
                                                              child: Row(
                                                                children: [
                                                                  const Text('AWB: '),
                                                                  Text('${d['awb']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                  const Spacer(),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withAlpha(15), borderRadius: BorderRadius.circular(4)),
                                                                    child: Text('${d['amount']} ${d['type']}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx),
                                                        child: Text(appLanguage.value == 'es' ? 'Cerrar' : 'Close', style: const TextStyle(color: Color(0xFF6366f1))),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444).withAlpha(15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          ElevatedButton(
                                            onPressed: (isAllChecked && !isReady) ? () async {
                                              await widget.logic.markUldReady(uld['id_uld']?.toString() ?? '');
                                              if (context.mounted) {
                                                bool dialogOpen = true;
                                                showGeneralDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  barrierColor: Colors.black54,
                                                  transitionDuration: const Duration(milliseconds: 350),
                                                  pageBuilder: (context, anim1, anim2) {
                                                    return Center(
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: Container(
                                                          width: 320, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                                          decoration: BoxDecoration(color: dark ? const Color(0xFF0f172a) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF10b981).withAlpha(40), blurRadius: 40, offset: const Offset(0, 10))], border: Border.all(color: const Color(0xFF10b981).withAlpha(50), width: 1.5)),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10b981).withAlpha(20), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 48)),
                                                              const SizedBox(height: 24),
                                                              Text(appLanguage.value == 'es' ? '¡ULD Chequeado!' : 'ULD Checked!', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                                              const SizedBox(height: 8),
                                                              Text(appLanguage.value == 'es' ? 'El ULD ha sido marcado como listo y los datos se han guardado.' : 'The ULD has been marked as ready and data saved successfully.', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b), fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  transitionBuilder: (context, anim1, anim2, child) => Transform.scale(scale: Curves.easeOutBack.transform(anim1.value), child: FadeTransition(opacity: anim1, child: child)),
                                                ).then((_) => dialogOpen = false);

                                                await Future.delayed(const Duration(milliseconds: 2000));
                                                if (context.mounted && dialogOpen) {
                                                  Navigator.of(context).pop();
                                                }
                                              }
                                            } : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isReady ? const Color(0xFF10b981) : const Color(0xFF6366f1),
                                              disabledBackgroundColor: isReady ? const Color(0xFF10b981).withAlpha(150) : (dark ? Colors.white.withAlpha(20) : Colors.grey.shade300),
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              minimumSize: const Size(0, 32),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isReady) ...[
                                                  const Icon(Icons.check, color: Colors.white, size: 14),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  'Ready',
                                                  style: TextStyle(
                                                    color: (isAllChecked || isReady) ? Colors.white : (dark ? Colors.white30 : Colors.black26),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  ),
                                const SizedBox(width: 12),
                                Icon(
                                  widget.logic.selectedUldId == uld['id_uld']?.toString() ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: widget.logic.selectedUldId == uld['id_uld']?.toString() ? const Color(0xFF6366f1) : textS,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          if (widget.logic.selectedUldId == uld['id_uld']?.toString())
                            CoordinatorV2UldAwbs(
                              logic: widget.logic, 
                              dark: dark,
                              flightId: widget.logic.selectedFlightId ?? '',
                              uldId: uld['id_uld']?.toString() ?? '',
                            ),
                        ],
                      ),
                    ),
                    if (uld['is_priority'] == true)
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B), // Orange
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: const Icon(Icons.flash_on, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ],
              if (widget.logic.selectedFlightId != null && widget.logic.ulds.isNotEmpty)
                CoordinatorV2Footer(dark: dark, logic: widget.logic),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnableDeliveryConfirmDialog(BuildContext context, CoordinatorV2Logic logic, Map<String, dynamic> flight) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgDialog = dark ? const Color(0xFF0f172a) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: bgDialog,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFf59e0b).withAlpha(50), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFFf59e0b).withAlpha(20), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              appLanguage.value == 'es' ? '¿Habilitar Entregas?' : 'Enable Deliveries?',
              style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              appLanguage.value == 'es'
                  ? '¿Estás seguro de habilitar las entregas para este vuelo? La oficina podrá comenzar a despachar la mercancía a los choferes y esta acción no se puede deshacer.'
                  : 'Are you sure you want to enable deliveries for this flight? The office will be able to start dispatching cargo to drivers and this action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textS, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                      style: TextStyle(color: textS, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      logic.toggleFlightDeliveryEnabled(flight['id_flight']!.toString(), true);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf59e0b),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      appLanguage.value == 'es' ? 'Sí, Habilitar' : 'Yes, Enable',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
