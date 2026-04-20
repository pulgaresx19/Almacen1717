import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show appLanguage, isDarkMode;

class DeliversV2Dialogs {
  static void showNoShowDetails(BuildContext context, dynamic noShowData, bool dark, Color textP) {
    List<Map<String, dynamic>> items = [];
    if (noShowData is List) {
      items = noShowData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (noShowData is Map) {
      items = [Map<String, dynamic>.from(noShowData)];
    }

    showDialog(context: context, builder: (ctx) {
      return Dialog(
        backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No Show Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...items.map((i) {
                String tStr = i['time']?.toString() ?? '-';
                if (tStr != '-') {
                  final parsed = DateTime.tryParse(tStr)?.toLocal();
                  if (parsed != null) {
                    tStr = DateFormat('MMM dd, hh:mm a').format(parsed);
                  }
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark ? Colors.white.withAlpha(20) : Colors.grey.shade300)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(i['user']?.toString() ?? 'Unknown User', style: TextStyle(color: textP, fontWeight: FontWeight.w600))),
                        ]
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tStr, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                        ]
                      )
                    ]
                  )
                );
              }),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        )
      );
    });
  }

  static void showDeliverDetails(BuildContext context, Map<String, dynamic> u, bool dark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        bool isEditing = false;
        final Map<String, dynamic> tempU = Map.from(u);
        return StatefulBuilder(
          builder: (context, setDrawerState) {
            final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
            final bg = dark ? const Color(0xFF0f172a) : Colors.white;
        final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: bg,
            elevation: 16,
            child: SizedBox(
              width: 520,
              height: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderC))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deliver Details', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, color: textP, size: 24),
                                const SizedBox(width: 8),
                                Text(u['company']?.toString() ?? 'Unknown Company', style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                              ]
                            )
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(Icons.close_rounded, color: textP, size: 20),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [Icon(Icons.badge_outlined, size: 16, color: textP), const SizedBox(width: 8), Text('Driver Information', style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold))]),
                                      if (!isEditing)
                                        IconButton(
                                          onPressed: () {
                                            setDrawerState(() {
                                              isEditing = true;
                                              tempU.clear();
                                              tempU.addAll(u);
                                            });
                                          },
                                          tooltip: appLanguage.value == 'es' ? 'Editar' : 'Edit',
                                          icon: Icon(Icons.edit_rounded, color: textP, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      else
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () => setDrawerState(() => isEditing = false),
                                              tooltip: appLanguage.value == 'es' ? 'Cancelar' : 'Cancel',
                                              icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              onPressed: () async {
                                                try {
                                                  await Supabase.instance.client.from('deliveries').update(tempU).eq('id_delivery', u['id_delivery']);
                                                  u.addAll(tempU);
                                                  setDrawerState(() => isEditing = false);
                                                } catch (_) {}
                                              },
                                              tooltip: appLanguage.value == 'es' ? 'Guardar Cambios' : 'Save Changes',
                                              icon: const Icon(Icons.check_rounded, color: Color(0xFF22c55e), size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        )
                                    ]
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: buildDeliverEditableCard(context, 'Driver Name', 'driver_name', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.person_outline)),
                                      Expanded(child: buildDeliverEditableCard(context, 'ID Pickup', 'id_pickup', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.badge_outlined)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: buildDeliverEditableCard(context, 'Type', 'type', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.local_shipping_outlined, isTypeDropdown: true)),
                                      Expanded(child: buildDeliverEditableCard(context, 'Company', 'company', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.business)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: buildDeliverEditableCard(context, 'Priority', 'is_priority', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.star_outline, isPriority: true)),
                                      Expanded(child: buildDeliverEditableCard(context, 'Time', 'time', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.access_time_rounded, isTime: true)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: buildDeliverEditableCard(context, 'Door', 'door', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.door_front_door_outlined)),
                                      Expanded(child: buildDeliverEditableCard(context, 'Pieces', 'total_pieces', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.inventory_2_outlined)),
                                      Expanded(child: buildDeliverEditableCard(context, 'Weight', 'total_weight', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.scale_outlined)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                                  buildDeliverEditableCard(context, 'Remarks', 'remarks', u, isEditing, tempU, setDrawerState, dark, textS, textP, icon: Icons.notes, isRemarks: true),
                               ]
                             )
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }


  static Widget buildDeliverEditableCard(
    BuildContext context, 
    String label, 
    String key, 
    Map<String, dynamic> u, 
    bool isEditing, 
    Map<String, dynamic> tempU,
    StateSetter setDrawerState, 
    bool dark, 
    Color colorL, 
    Color colorP, 
    {IconData? icon, bool isTime = false, bool isRemarks = false, bool isPriority = false, bool isTypeDropdown = false, bool isStatusDropdown = false}
  ) {
    if (!isEditing) {
      String displayValue = '${u[key] ?? '-'}';
      

      
      if (isTime) {
         displayValue = '-';
         if (u['time'] != null) {
           final tdt = DateTime.tryParse(u['time'].toString())?.toLocal();
           if (tdt != null) displayValue = DateFormat('hh:mm a').format(tdt);
         }
      } else if (isPriority) {
         displayValue = (u[key] == true) ? 'High Priority' : 'Normal';
      } else if (isRemarks) {
         displayValue = (u['remarks']?.toString() ?? '').isEmpty ? 'No remarks' : u['remarks'].toString();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colorL, size: 14),
                  const SizedBox(width: 4),
                ],
                Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            Text(displayValue, style: TextStyle(color: colorP, fontSize: 13, fontWeight: FontWeight.bold), overflow: isRemarks ? null : TextOverflow.ellipsis),
          ],
        ),
      );
    }
    
    final inputBorderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    Widget editor;

    if (isTime) {
      String tStr = '-';
      if (tempU['time'] != null) {
        final tdt = DateTime.tryParse(tempU['time'].toString())?.toLocal();
        if (tdt != null) tStr = DateFormat('hh:mm a').format(tdt);
      }
      editor = InkWell(
        onTap: () async {
          final tdt = DateTime.tryParse(tempU['time']?.toString() ?? '')?.toLocal() ?? DateTime.now();
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: tdt.hour, minute: tdt.minute),
            builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: Color(0xFF6366f1), surface: Color(0xFF1e293b)),
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                ),
            )
          );
          if (picked != null) {
             final now = DateTime.now();
             final newDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute).toUtc();
             setDrawerState(() => tempU[key] = newDate.toIso8601String());
          }
        },
        child: Container(
          width: double.infinity,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
          child: Text(tStr, style: TextStyle(color: colorP, fontSize: 12), textAlign: TextAlign.center),
        ),
      );
    } else if (isTypeDropdown) {
      String currentType = tempU[key]?.toString() ?? 'Walk-in';
      if (!['Walk-in', 'Transfer', 'Priority Load'].contains(currentType)) currentType = 'Walk-in';
      editor = Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentType,
            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 12),
            items: const [
              DropdownMenuItem(value: 'Walk-in', child: Text('Walk-in')),
              DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
              DropdownMenuItem(value: 'Priority Load', child: Text('Priority Load')),
            ],
            onChanged: (v) {
              if (v != null) {
                setDrawerState(() => tempU[key] = v);
              }
            },
          ),
        ),
      );
    } else if (isPriority) {
      editor = Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<bool>(
            value: tempU[key] == true,
            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 12),
            items: const [
              DropdownMenuItem(value: true, child: Text('High Priority')),
              DropdownMenuItem(value: false, child: Text('Normal')),
            ],
            onChanged: (v) {
              if (v != null) {
                setDrawerState(() => tempU[key] = v);
              }
            },
          ),
        ),
      );
    } else if (isStatusDropdown) {
      String currentStatus = tempU[key]?.toString() ?? 'Waiting';
      final statuses = ['Waiting', 'In process', 'Ready', 'Canceled'];
      if (!statuses.contains(currentStatus)) {
        statuses.add(currentStatus);
      }
      editor = Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8), border: Border.all(color: inputBorderC)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentStatus,
            dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: colorP, fontSize: 12),
            items: statuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null) {
                setDrawerState(() => tempU[key] = v);
              }
            },
          ),
        ),
      );
    } else {
      final ctrl = TextEditingController(text: tempU[key]?.toString() ?? '')..selection = TextSelection.collapsed(offset: (tempU[key]?.toString() ?? '').length);
      editor = TextField(
        controller: ctrl,
        style: TextStyle(color: colorP, fontSize: 12),
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))],
        maxLines: isRemarks ? 3 : 1,
        minLines: isRemarks ? 2 : 1,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          fillColor: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderC)),
        ),
        onChanged: (v) => tempU[key] = v,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colorL, size: 14),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(label, style: TextStyle(color: colorL, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          editor,
        ],
      ),
    );
  }

  static void showAgentProfile(BuildContext context, String userName, String? avatarStr, String timeStr, bool dark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(50),
      builder: (BuildContext modalContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10))
                ],
                border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF4f46e5),
                    backgroundImage: avatarStr != null && avatarStr.isNotEmpty ? NetworkImage(avatarStr) : null,
                    child: avatarStr == null || avatarStr.isEmpty ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                    ) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF6366f1).withAlpha(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(modalContext),
                      child: Text('Close', style: TextStyle(color: dark ? const Color(0xFF818cf8) : const Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  static Widget buildStatusBadge(BuildContext context, String status, {Map<String, dynamic>? itemData}) {
    Color bg = const Color(0xFF334155);
    Color fg = const Color(0xFFcbd5e1);
    
    final s = status.toLowerCase();
    if (s.contains('waiting')) {
      bg = const Color(0xFF334155); fg = const Color(0xFFcbd5e1);
    } else if (s.contains('pending')) {
      bg = const Color(0xFFca8a04).withAlpha(51); fg = const Color(0xFFfef08a);
    } else if (s.contains('in process') || s.contains('process')) {
      bg = const Color(0xFF1e3a8a).withAlpha(51); fg = const Color(0xFF93c5fd);
    } else if (s.contains('ready') || s.contains('delivered')) {
      bg = const Color(0xFF166534).withAlpha(51); fg = const Color(0xFF86efac);
    } else if (s.contains('canceled')) {
      bg = const Color(0xFF7f1d1d).withAlpha(51); fg = const Color(0xFFfca5a5);
    }

    Widget badgeContainer = Container(
      width: 100,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );

    if (itemData != null && itemData['report-pending'] != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badgeContainer,
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              bool dark = isDarkMode.value;
              final reportField = itemData['report-pending'];
              List<dynamic> reports = [];
              if (reportField is List) {
                reports = reportField;
              } else if (reportField is Map) {
                reports = [reportField];
              }
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFca8a04).withAlpha(51), shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline_rounded, color: Color(0xFFfef08a), size: 24)
                      ),
                      const SizedBox(width: 12),
                      Text(appLanguage.value == 'es' ? 'Detalles de postergaciÃ³n' : 'Pending Context', style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: SizedBox(
                    width: 400,
                    height: reports.length > 2 ? 300 : null,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: reports.map((report) => Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               buildReportRow(Icons.access_time_rounded, appLanguage.value == 'es' ? 'Hora' : 'Time', report['time'] ?? 'Unknown', dark),
                               const SizedBox(height: 16),
                               buildReportRow(Icons.person_rounded, appLanguage.value == 'es' ? 'Usuario' : 'User', report['user'] ?? 'Unknown', dark),
                               const SizedBox(height: 16),
                               buildReportRow(Icons.comment_rounded, appLanguage.value == 'es' ? 'RazÃ³n' : 'Reason', report['reason'] ?? 'No reason provided', dark),
                               if (report != reports.last) ...[
                                 const SizedBox(height: 12),
                                 Divider(color: dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                               ]
                             ]
                          )
                        )).toList(),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(appLanguage.value == 'es' ? 'Cerrar' : 'Close', style: TextStyle(color: dark ? const Color(0xFFfcd34d) : const Color(0xFFb45309), fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                )
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode.value ? const Color(0xFFca8a04).withAlpha(40) : const Color(0xFFfef08a).withAlpha(150),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline_rounded, color: isDarkMode.value ? const Color(0xFFfde047) : const Color(0xFFb45309), size: 18),
            ),
          )
        ],
      );
    }

    return badgeContainer;
  }

  static Widget buildReportRow(IconData icon, String label, String value, bool dark) {
    if ((label == 'Time' || label == 'Hora') && value != 'Unknown') {
      try {
        final d = DateTime.parse(value).toLocal();
        value = DateFormat('MMM dd, yyyy - hh:mm a').format(d);
      } catch (_) {}
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: dark ? Colors.white54 : Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: dark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: dark ? Colors.white : Colors.black, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
