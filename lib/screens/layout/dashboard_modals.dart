import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart'; // To get appLanguage, isDarkMode, currentUserData, scaffoldMessengerKey

void showProfileModal(BuildContext context, bool dark, Color textP, Color textS, Color borderWhite) {
  bool isUploading = false;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close Profile',
    barrierColor: Colors.black.withAlpha(20),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (BuildContext modalContext, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 90),
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Usuario';
                final avatarUrl = currentUserData.value?['avatar_url'] as String?;
                
                return Container(
                  width: 260, // Matches sidebar exactly
                  padding: const EdgeInsets.only(top: 12, bottom: 32, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1e293b) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderWhite.withAlpha(50)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Bottom sheet handle
                       Container(
                         width: 40,
                         height: 4,
                         margin: const EdgeInsets.only(bottom: 12),
                         decoration: BoxDecoration(
                           color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                           borderRadius: BorderRadius.circular(2),
                         ),
                       ),
                       // Title & Close Button
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           const SizedBox(width: 20), // Spacer for balance
                           Text(appLanguage.value == 'es' ? 'Mi Perfil' : 'My Profile', style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.bold)),
                           InkWell(
                             onTap: () => Navigator.pop(context),
                             child: Container(
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(
                                 color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                 shape: BoxShape.circle,
                               ),
                               child: Icon(Icons.close_rounded, color: textS, size: 14),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),
                 Stack(
                   alignment: Alignment.center,
                   children: [
                     CircleAvatar(
                       radius: 40,
                       backgroundColor: const Color(0xFF4f46e5),
                       backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                       child: avatarUrl == null || avatarUrl.isEmpty ? Text(
                         (currentUserData.value?['full_name'] as String?)?.isNotEmpty == true
                             ? currentUserData.value!['full_name'][0].toUpperCase()
                             : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U'),
                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                       ) : null,
                     ),
                     if (isUploading)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                     Positioned(
                       bottom: 0,
                       right: 0,
                       child: InkWell(
                         onTap: () async {
                            if (isUploading) return;
                            
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                            );

                            if (image == null) return;
                            setModalState(() { isUploading = true; });

                            try {
                              final bytes = await image.readAsBytes();
                              final userId = Supabase.instance.client.auth.currentUser?.id;
                              if (userId == null) throw Exception("User not authenticated");

                              final fileExt = image.name.split('.').last.isEmpty ? 'jpg' : image.name.split('.').last;
                              final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                              await Supabase.instance.client.storage.from('avatars').uploadBinary(
                                fileName,
                                bytes,
                                fileOptions: FileOptions(contentType: image.mimeType ?? 'image/jpeg'),
                              );

                              final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

                              await Supabase.instance.client.from('users').update({
                                'avatar_url': publicUrl,
                              }).eq('id', userId);

                              if (currentUserData.value != null) {
                                final Map<String, dynamic> updatedData = Map.from(currentUserData.value!);
                                updatedData['avatar_url'] = publicUrl;
                                currentUserData.value = updatedData;
                              }
                              
                              setModalState(() { isUploading = false; });
                              if (modalContext.mounted) Navigator.pop(modalContext);
                            } catch (e) {
                              debugPrint('Avatar Error: $e');
                              setModalState(() { isUploading = false; });
                              scaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
                              );
                            }
                         },
                         child: Container(
                           padding: const EdgeInsets.all(6),
                           decoration: BoxDecoration(
                             color: const Color(0xFF6366f1),
                             shape: BoxShape.circle,
                             border: Border.all(color: dark ? const Color(0xFF1e293b) : Colors.white, width: 2),
                           ),
                           child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                         ),
                       ),
                     )
                   ],
                 ),
                 const SizedBox(height: 16),
                 Text(
                   currentUserData.value?['full_name'] ?? userEmail.split('@')[0],
                   style: TextStyle(color: textP, fontWeight: FontWeight.w600, fontSize: 16),
                 ),
                 Text(
                   currentUserData.value?['position'] ?? 'Admin',
                   style: TextStyle(color: textS, fontSize: 14),
                 ),
              ],
            ),
          );
        }
      ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}

void showBroadcastModal(BuildContext context, bool dark, Color textP, Color textS, Color borderWhite) {
  String selectedRole = 'All';
  final TextEditingController msgCtrl = TextEditingController();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close Broadcast',
    barrierColor: Colors.black.withAlpha(80),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setState) {
              final bgDialog = dark ? const Color(0xFF1e293b) : Colors.white;
              final bool isMessageEmpty = msgCtrl.text.trim().isEmpty;
              return Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgDialog,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderWhite.withAlpha(50)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF3b82f6).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.campaign_rounded, color: Color(0xFF3b82f6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(appLanguage.value == 'es' ? 'Enviar Notificación' : 'Broadcast Message', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: textS, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(appLanguage.value == 'es' ? 'Destinatarios' : 'Target Audience', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
                          style: TextStyle(color: textP, fontSize: 14),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Users')),
                            DropdownMenuItem(value: 'Agent', child: Text('Agent')),
                            DropdownMenuItem(value: 'Office', child: Text('Office')),
                            DropdownMenuItem(value: 'Coordinator', child: Text('Coordinator')),
                            DropdownMenuItem(value: 'Supervisor', child: Text('Supervisor')),
                            DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => selectedRole = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(appLanguage.value == 'es' ? 'Mensaje' : 'Message', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: msgCtrl,
                      maxLines: 4,
                      onChanged: (val) {
                        setState(() {}); // Trigger rebuild to enable/disable button
                      },
                      style: TextStyle(color: textP, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: appLanguage.value == 'es' ? 'Escribe tu mensaje aquí...' : 'Type your message here...',
                        hintStyle: TextStyle(color: textS.withAlpha(100)),
                        filled: true,
                        fillColor: dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isMessageEmpty ? null : () async {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6))),
                            );

                            final userFullName = currentUserData.value?['full_name'] ?? Supabase.instance.client.auth.currentUser?.email ?? 'Unknown';
                            final myId = Supabase.instance.client.auth.currentUser?.id;

                            await Supabase.instance.client.from('broadcast_messages').insert({
                              'message': msgCtrl.text.trim(),
                              'target_role': selectedRole,
                              'created_by': userFullName,
                              'read_by': myId != null ? [myId] : []
                            });

                            if (!context.mounted) return;
                            Navigator.pop(context); // Close loading
                            Navigator.pop(context); // Close modal

                            scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text(appLanguage.value == 'es' ? '¡Mensaje enviado exitosamente!' : 'Message sent successfully!'), backgroundColor: const Color(0xFF10b981)),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.pop(context); // Close loading
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(appLanguage.value == 'es' ? 'Enviar Mensaje' : 'Send Message', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3b82f6),
                          disabledBackgroundColor: dark ? Colors.white.withAlpha(5) : Colors.grey.shade200,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: textS.withAlpha(100),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

void showIncomingBroadcastDialog(BuildContext context, Map<String, dynamic> msg, String myId, VoidCallback onClosed) {
  final bool dark = isDarkMode.value;
  final bgDialog = dark ? const Color(0xFF1e293b) : Colors.white;
  final textP = dark ? Colors.white : const Color(0xFF111827);
  final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
  
  showGeneralDialog(
    context: context,
    barrierDismissible: false, // Must click OK
    barrierColor: Colors.black.withAlpha(150),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: bgDialog,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFFef4444).withAlpha(40), blurRadius: 40, spreadRadius: 10),
                BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Color(0xFFef4444), size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  appLanguage.value == 'es' ? '¡Nuevo Aviso!' : 'New Notice!',
                  style: TextStyle(color: textP, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  msg['created_by']?.toString() ?? 'Oficina',
                  style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withAlpha(5) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg['message']?.toString() ?? '',
                    style: TextStyle(color: textP, fontSize: 16, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                         try {
                           final currentReadBy = List<dynamic>.from(msg['read_by'] ?? []);
                           if (!currentReadBy.contains(myId)) {
                             currentReadBy.add(myId);
                             msg['read_by'] = currentReadBy; // Optimistic local update to prevent double-showing
                             await Supabase.instance.client.from('broadcast_messages').update({
                               'read_by': currentReadBy
                             }).eq('id', msg['id']);
                           }
                       } catch(e) {
                         debugPrint('Error updating broadcast: $e');
                       }
                       
                       if (!context.mounted) return;
                       Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFef4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(appLanguage.value == 'es' ? 'Entendido' : 'Got it', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        child: child,
      );
    },
  ).then((_) {
     onClosed();
  });
}
