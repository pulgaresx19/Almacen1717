const fs = require('fs');
let code = fs.readFileSync('lib/screens/driver_module.dart', 'utf8');

const replacement = \  Widget _buildDriverVerificationCard(Map<String, dynamic> u, bool dark, {BuildContext? dialogCtx}) {
    String timeStr = '-';
    if (u['time-deliver'] != null) {
      final tdt = DateTime.tryParse(u['time-deliver'].toString())?.toLocal();
      if (tdt != null) timeStr = DateFormat('hh:mm a').format(tdt);
    }

    String awbsStr = '0';
    if (u['list-pickup'] != null) {
      if (u['list-pickup'] is List) {
        awbsStr = (u['list-pickup'] as List).length.toString();
      } else {
        awbsStr = '1';
      }
    }

    return Container(
      width: dialogCtx != null ? 440 : 500,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: dialogCtx != null ? [
          BoxShadow(
            color: Colors.black.withAlpha(dark ? 100 : 25),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          )
        ] : [],
        border: dialogCtx == null ? Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)))
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF6366f1), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    appLanguage.value == 'es' ? 'Verificar Conductor' : 'Verify Driver', 
                    style: TextStyle(color: dark ? Colors.white : const Color(0xFF0f172a), fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                ),
                if (u['isPriority'] == true)
                  const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.star_rounded, color: Colors.orange, size: 28),
                  ),
                if (dialogCtx != null)
                  IconButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    icon: Icon(Icons.close_rounded, color: dark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF0f172a).withAlpha(128) : const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warehouse_rounded, color: Color(0xFF10b981), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appLanguage.value == 'es' ? 'DESTINO' : 'DESTINATION', style: TextStyle(color: dark ? const Color(0xFF10b981) : Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(u['origin']?.toString() ?? 'Warehouse', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: dark ? Colors.amberAccent.withAlpha(20) : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dark ? Colors.amberAccent.withAlpha(50) : Colors.amber.shade300)
                        ),
                        child: Column(
                          children: [
                            Text(appLanguage.value == 'es' ? 'PUERTA' : 'DOOR', style: TextStyle(color: dark ? Colors.amberAccent : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(u['door']?.toString().isNotEmpty == true ? u['door'].toString() : '-', style: TextStyle(color: dark ? Colors.white : const Color(0xFF111827), fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), height: 24),
                Row(
                  children: [
                    Expanded(child: _confirmDetailRow(Icons.local_shipping_rounded, appLanguage.value == 'es' ? 'Tipo' : 'Type', u['type']?.toString().isNotEmpty == true ? u['type'].toString() : '-', dark)),
                    Container(width: 1, height: 40, color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Expanded(child: _confirmDetailRow(Icons.qr_code_rounded, 'ID Pickup', u['id-pickup']?.toString().isNotEmpty == true ? u['id-pickup'].toString() : '-', dark)),
                  ],
                ),
                Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), height: 24),
                Row(
                  children: [
                    Expanded(child: _confirmDetailRow(Icons.access_time_rounded, appLanguage.value == 'es' ? 'Hora' : 'Time', timeStr, dark)),
                    Container(width: 1, height: 40, color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Expanded(child: _confirmDetailRow(Icons.inventory_2_outlined, 'AWBs', awbsStr, dark)),
                  ],
                ),
                if (u['remarks']?.toString().isNotEmpty == true) ...[
                  Divider(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0), height: 24),
                  _confirmDetailRow(Icons.notes_rounded, appLanguage.value == 'es' ? 'Comentarios' : 'Remarks', u['remarks'].toString(), dark),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              border: Border(top: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.block_rounded, size: 18),
                  onPressed: () async {
                    final currentTime = DateTime.now().toIso8601String();
                    final currentUserFullName = currentUserData.value?['full-name'] ?? 'Unknown';
                    
                    try {
                      final currentNoShow = u['no-show'];
                      List updatedNoShowList = [];
                      if (currentNoShow is List) {
                        updatedNoShowList = List.from(currentNoShow);
                      } else if (currentNoShow is Map && currentNoShow.isNotEmpty) {
                        updatedNoShowList.add(currentNoShow);
                      }
                      updatedNoShowList.add({
                        'time': currentTime,
                        'user': currentUserFullName,
                      });
                      
                      Map<String, dynamic> updatePayload = {
                        'no-show': updatedNoShowList
                      };
                      
                      if (updatedNoShowList.length >= 2) {
                        updatePayload['status'] = 'Canceled';
                      }
                      
                      await Supabase.instance.client.from('Delivers').update(updatePayload).eq('id', u['id']);
                    } catch (e) {
                      debugPrint('NO SHOW Update Error: ');
                    }
                    
                    if (dialogCtx != null && dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFef4444),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  label: const Text('NO SHOW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final currentTime = DateTime.now().toUtc().toIso8601String();
                    final currentUserFullName = currentUserData.value?['full-name'] ?? 'Unknown';
                    final currentUserAvatar = currentUserData.value?['avatar-url'];

                    try {
                      await Supabase.instance.client.from('Delivers').update({
                        'ref-userDrive': {
                          'time': currentTime,
                          'user': currentUserFullName,
                          'avatar': currentUserAvatar,
                        }
                      }).eq('id', u['id']);
                      u['ref-userDrive'] = {
                          'time': currentTime,
                          'user': currentUserFullName,
                          'avatar': currentUserAvatar,
                      };
                    } catch (e) {
                      debugPrint('Confirm Update Error: ');
                    }
                    
                    if (dialogCtx != null && dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    _loadDriverDetails(u);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  label: Text(appLanguage.value == 'es' ? 'Confirmar' : 'Confirm', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDriverConfirmationOverlay(Map<String, dynamic> u) {
    bool dark = isDarkMode.value;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: _buildDriverVerificationCard(u, dark, dialogCtx: ctx),
        );
      }
    );
  }
\;

const startStr = '  void _showDriverConfirmationOverlay(Map<String, dynamic> u) {';
const endStr = '  Widget _confirmDetailRow(IconData icon, String label, String value, bool dark) {';

const startIndex = code.indexOf(startStr);
const endIndex = code.indexOf(endStr);

if (startIndex !== -1 && endIndex !== -1) {
  const newCode = code.substring(0, startIndex) + replacement + '\n' + code.substring(endIndex);
  fs.writeFileSync('lib/screens/driver_module.dart', newCode);
  console.log('REPLACEMENT SUCCESSFUL!');
} else {
  console.log('START OR END NOT FOUND');
}
