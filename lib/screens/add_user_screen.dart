import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode;

class AddUserScreen extends StatefulWidget {
  final bool isInline;
  final Function(Map<String, dynamic>?)? onPop;

  const AddUserScreen({
    super.key,
    this.isInline = false,
    this.onPop,
  });

  @override
  State<AddUserScreen> createState() => AddUserScreenState();
}

class AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();

  String _position = 'Agent';
  String _shift = 'Morning';
  bool _isLoading = false;

  final List<String> _positions = ['Agent', 'Coordinator', 'Supervisor', 'Admin'];
  final List<String> _shifts = ['Morning', 'Evening', 'Night'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _buildingCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create user auth
      final authRes = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {'full_name': _nameCtrl.text.trim()},
      );

      final user = authRes.user;
      final userId = user?.id;

      if (userId != null) {
        // Insert into Users table
        final userData = {
          'id': userId,
          'email': _emailCtrl.text.trim(),
          'full-name': _nameCtrl.text.trim(),
          'position': _position,
          'building': _buildingCtrl.text.trim(),
          'shift': _shift,
          'phone-number': _phoneCtrl.text.trim(),
        };

        // Try to insert (sometimes signUp trigger creates it, so we upsert or just update)
        await Supabase.instance.client.from('Users').upsert(userData);

        if (mounted) {
          bool dialogOpen = true;
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (context, anim1, anim2) {
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
                          appLanguage.value == 'es' ? '¡Usuario Creado!' : 'User Created!',
                          style: TextStyle(
                            color: dark ? Colors.white : const Color(0xFF111827),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appLanguage.value == 'es' ? 'El registro se ha completado exitosamente.' : 'Registration has been completed successfully.',
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
            transitionBuilder: (context, anim1, anim2, child) {
              return Transform.scale(
                scale: Curves.easeOutBack.transform(anim1.value),
                child: FadeTransition(
                  opacity: anim1,
                  child: child,
                ),
              );
            },
          ).then((_) => dialogOpen = false);

          await Future.delayed(const Duration(milliseconds: 2000));
          
          if (mounted) {
            if (dialogOpen) {
              Navigator.of(context).pop();
            }
            if (widget.isInline && widget.onPop != null) {
              widget.onPop!(userData);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            }
          }
        }
      } else {
        throw Exception('User creation failed, no ID returned.');
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get hasDataSync {
    return _nameCtrl.text.isNotEmpty || 
           _emailCtrl.text.isNotEmpty || 
           _passwordCtrl.text.isNotEmpty || 
           _phoneCtrl.text.isNotEmpty || 
           _buildingCtrl.text.isNotEmpty;
  }

  Future<bool> _onBackPressed() async {
    bool hasData = hasDataSync;

    if (!hasData) {
      if (widget.onPop != null) {
        widget.onPop!(null);
        return false;
      }
      return true;
    }

    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFFf59e0b).withAlpha(100), width: 2)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 60),
            SizedBox(height: 16),
            Text('Discard Data?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Any unsaved data entered for the User will be permanently lost.\n\nDo you want to discard your changes and continue?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 16, height: 1.4),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('STAY', style: TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFFef4444).withAlpha(100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      if (widget.onPop != null) {
        widget.onPop!(null);
        return false;
      }
      return true;
    }
    return false;
  }

  Future<bool> handleBackRequest() async {
    final canPop = await _onBackPressed();
    if (canPop && widget.onPop == null) {
      if (mounted) Navigator.pop(context);
    }
    return canPop;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final bgCard = dark ? const Color(0xFF1e293b) : Colors.white;
        final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);

        Widget content = Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderC),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, color: textP, size: 20),
                              const SizedBox(width: 8),
                              Text('User Details', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField('Full Name', _nameCtrl, dark, Icons.person_rounded),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField('Email', _emailCtrl, dark, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField('Password', _passwordCtrl, dark, Icons.lock_rounded, obscureText: true),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField('Phone Number', _phoneCtrl, dark, Icons.phone_rounded, keyboardType: TextInputType.phone, inputFormatters: [_PhoneFormatter()]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField('Position', _position, _positions, (v) => setState(() => _position = v!), dark, Icons.work_rounded),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField('Building', _buildingCtrl, dark, Icons.domain_rounded),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField('Shift', _shift, _shifts, (v) => setState(() => _shift = v!), dark, Icons.schedule_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveUser,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isLoading ? 'Processing...' : (appLanguage.value == 'es' ? 'Guardar Usuario' : 'Save User'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                ),
              ),
            ),
          ],
        );

        if (widget.isInline) {
          return content;
        }

        return Scaffold(
          backgroundColor: dark ? const Color(0xFF0f172a) : const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: dark ? const Color(0xFF1e293b) : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: textP),
            title: Text(
              appLanguage.value == 'es' ? 'Añadir Usuario' : 'Add User',
              style: TextStyle(color: textP, fontWeight: FontWeight.bold),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool dark, IconData icon, {bool obscureText = false, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final fillC = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final textP = dark ? Colors.white : const Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const ['off'],
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(color: textP),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6366f1), size: 20),
            filled: true,
            fillColor: fillC,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged, bool dark, IconData icon) {
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    final fillC = dark ? Colors.white.withAlpha(10) : const Color(0xFFF9FAFB);
    final textP = dark ? Colors.white : const Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          dropdownColor: dark ? const Color(0xFF1e293b) : Colors.white,
          style: TextStyle(color: textP),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6366f1), size: 20),
            filled: true,
            fillColor: fillC,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderC)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1))),
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        ),
      ],
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 10) text = text.substring(0, 10);

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
    }

    int selectionIndex = formatted.length;
    
    // A more friendly cursor placement logic: 
    // Just force it to the end where typing happens
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
