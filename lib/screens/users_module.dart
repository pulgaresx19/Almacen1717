import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier, currentUserData;
import 'add_user_screen.dart';

class UsersModule extends StatefulWidget {
  final bool isActive;
  const UsersModule({super.key, this.isActive = true});

  @override
  State<UsersModule> createState() => _UsersModuleState();
}

class _UsersModuleState extends State<UsersModule> {
  final _searchController = TextEditingController();
  bool _showAddForm = false;
  final GlobalKey<AddUserScreenState> _addUserKey = GlobalKey<AddUserScreenState>();
  late Stream<List<Map<String, dynamic>>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = Supabase.instance.client.from('Users').stream(primaryKey: ['id']).order('full-name', ascending: true);
  }

  @override
  void didUpdateWidget(covariant UsersModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_showAddForm && _addUserKey.currentState != null) {
        if (!_addUserKey.currentState!.hasDataSync) {
          setState(() => _showAddForm = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        final Color textP = dark ? Colors.white : const Color(0xFF111827);
        final Color textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
        final Color bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff);
        final Color borderCard = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
        final Color iconColor = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Header Row (Title, Search, Buttons)
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
                              if (_addUserKey.currentState != null) {
                                final canPop = await _addUserKey.currentState!.handleBackRequest();
                                if (canPop) {
                                  setState(() => _showAddForm = false);
                                }
                              } else {
                                setState(() => _showAddForm = false);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            tooltip: appLanguage.value == 'es' ? 'Volver' : 'Back',
                          ),
                          const SizedBox(width: 8),
                          Text(appLanguage.value == 'es' ? 'Añadir Nuevo Usuario' : 'Add New User', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                        ],
                      )
                    else
                      Text(appLanguage.value == 'es' ? 'Usuarios Activos' : 'Active Users', style: TextStyle(color: textP, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (_showAddForm)
                      Text(appLanguage.value == 'es' ? 'Registra un nuevo usuario en el sistema.' : 'Register a new user in the system.', style: TextStyle(color: textS, fontSize: 13))
                    else
                      Text(appLanguage.value == 'es' ? 'Administración de roles y accesos del personal.' : 'Management of staff roles and accesses.', style: TextStyle(color: textS, fontSize: 13)),
                  ],
            ),
            const Spacer(),
            
            // Search Box
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
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))],
                  style: TextStyle(color: textP, fontSize: 13),
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: appLanguage.value == 'es' ? 'Buscar usuario...' : 'Search user...',
                    hintStyle: TextStyle(color: textP.withAlpha(76), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            
            // Add User Button
            if (!_showAddForm && currentUserData.value?['position'] != 'Supervisor' && currentUserData.value?['position'] != 'Office')
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddForm = true),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(appLanguage.value == 'es' ? 'Añadir Usuario' : 'Add User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 30),
        if (_showAddForm)
          Expanded(
            child: AddUserScreen(
              key: _addUserKey,
              isInline: true,
              onPop: (_) => setState(() => _showAddForm = false),
            )
          )
        else
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCard),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _usersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6366f1)),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                        );
                      }

                      var users = snapshot.data ?? [];
                      
                      if (_searchController.text.isNotEmpty) {
                        final term = _searchController.text.toLowerCase();
                        users = users.where((u) {
                          final str = '${u['full-name']} ${u['email']} ${u['position']} ${u['shift']}'.toLowerCase();
                          return str.contains(term);
                        }).toList();
                      }
                      
                      if (users.isEmpty) {
                        return const Center(
                          child: Text(
                            'No users found in database.',
                            style: TextStyle(color: Color(0xFF94a3b8), fontStyle: FontStyle.italic),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(dark ? Colors.white.withAlpha(13) : const Color(0xFFF9FAFB)),
                            dataRowColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return dark ? Colors.white.withAlpha(8) : const Color(0xFFF3F4F6);
                              }
                              return Colors.transparent;
                            }),
                            dataTextStyle: TextStyle(color: dark ? const Color(0xFFcbd5e1) : const Color(0xFF4B5563), fontSize: 13),
                            headingTextStyle: TextStyle(
                              color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), 
                              fontWeight: FontWeight.w600, 
                              fontSize: 12,
                            ),
                            dividerThickness: 1,
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Member Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Phone')),
                              DataColumn(label: Text('Building')),
                              DataColumn(label: Text('Shift')),
                              DataColumn(label: Text('Position')),
                            ],
                            rows: users.map((u) {
                              final name = u['full-name'] ?? 'Unknown';
                              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                              
                              return DataRow(
                                onSelectChanged: (_) => _showUserDrawer(context, u, dark),
                                cells: [
                                  DataCell(
                                    Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: const Color(0xFF6366f1).withAlpha(40),
                                            child: Text(initial, style: const TextStyle(color: Color(0xFF6366f1), fontSize: 12, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(name, style: TextStyle(color: textP, fontWeight: FontWeight.w500)),
                                        ],
                                    ),
                                  ),
                                  DataCell(Text(u['email'] ?? '-')),
                                  DataCell(
                                      Text(
                                        u['phone-number'] ?? '-',
                                        style: TextStyle(fontFamily: 'monospace', color: textS),
                                      ),
                                  ),
                                  DataCell(Text(u['building'] ?? '-')),
                                  DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: borderCard),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(u['shift'] ?? '-', style: TextStyle(fontSize: 12, color: textP)),
                                      ),
                                  ),
                                  DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(u['position'] ?? '-', style: TextStyle(fontSize: 12, color: textP)),
                                      ),
                                  ),
                                ],
                              );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
     }
    );
  }

  Future<void> _showUserDrawer(BuildContext context, Map<String, dynamic> user, bool dark) async {
    bool wasUpdated = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 520,
              height: double.infinity,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0f172a) : Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: UserDrawerDetails(
                user: user, 
                dark: dark,
                onUpdate: () => wasUpdated = true,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
          child: child,
        );
      },
    );
    if (mounted && wasUpdated) {
      setState(() {});
    }
  }
}

class UserDrawerDetails extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool dark;
  final VoidCallback? onUpdate;

  const UserDrawerDetails({super.key, required this.user, required this.dark, this.onUpdate});

  @override
  State<UserDrawerDetails> createState() => _UserDrawerDetailsState();
}

class _UserDrawerDetailsState extends State<UserDrawerDetails> {
  final List<Map<String, dynamic>> _pagesList = [
    {'key': 'system', 'titleEs': 'Sistema', 'titleEn': 'System', 'descEs': 'Configuración general.', 'descEn': 'General system settings.', 'icon': Icons.settings_system_daydream_rounded},
    {'key': 'coordinator', 'titleEs': 'Coordinador', 'titleEn': 'Coordinator', 'descEs': 'Coordinación de recursos operativos.', 'descEn': 'Coordination of operational resources.', 'icon': Icons.support_agent_rounded},
    {'key': 'location', 'titleEs': 'Ubicación', 'titleEn': 'Location', 'descEs': 'Gestión del almacén.', 'descEn': 'Warehouse management.', 'icon': Icons.location_on_rounded},
    {'key': 'driver', 'titleEs': 'Conductor', 'titleEn': 'Driver', 'descEs': 'Administración y asignación de manejo.', 'descEn': 'Driver management and assignment.', 'icon': Icons.local_shipping_rounded},
    {'key': 'system_bf', 'titleEs': 'Sistema (BF)', 'titleEn': 'System (BF)', 'descEs': 'Acceso a la configuración del sistema.', 'descEn': 'Access to the system configuration.', 'icon': Icons.computer_rounded},
    {'key': 'area_nobreak', 'titleEs': 'Área (No break)', 'titleEn': 'Area (No break)', 'descEs': 'Acceso a la gestión de áreas.', 'descEn': 'Access to area management.', 'icon': Icons.dashboard_customize_rounded},
    {'key': 'control_flight', 'titleEs': 'Control (Flight)', 'titleEn': 'Control (Flight)', 'descEs': 'Acceso al módulo de control de vuelos.', 'descEn': 'Access to the flight control module.', 'icon': Icons.airplane_ticket_rounded},
    {'key': 'dashboard', 'titleEs': 'Dashboard', 'titleEn': 'Dashboard', 'descEs': 'Panel general.', 'descEn': 'General dashboard.', 'icon': Icons.dashboard_rounded},
    {'key': 'flights', 'titleEs': 'Vuelos', 'titleEn': 'Flights', 'descEs': 'Acceso para gestionar y visualizar vuelos.', 'descEn': 'Access to manage and view flights.', 'icon': Icons.flight_land_rounded},
    {'key': 'ulds', 'titleEs': 'Contenedores (ULD)', 'titleEn': 'Unit Load Devices (ULD)', 'descEs': 'Acceso para crear y asignar contenedores.', 'descEn': 'Access to create and assign ULDs.', 'icon': Icons.luggage_rounded},
    {'key': 'awbs', 'titleEs': 'Guías Aéreas (AWB)', 'titleEn': 'Air Waybills (AWB)', 'descEs': 'Acceso a la administración de guías aéreas.', 'descEn': 'Access to the management of Air Waybills.', 'icon': Icons.receipt_long_rounded},
    {'key': 'delivers', 'titleEs': 'Entregas', 'titleEn': 'Delivers', 'descEs': 'Acceso para registrar y administrar entregas.', 'descEn': 'Access to register and manage deliveries.', 'icon': Icons.local_shipping_rounded},
    {'key': 'users', 'titleEs': 'Usuarios', 'titleEn': 'Users', 'descEs': 'Administración de roles y accesos.', 'descEn': 'Management of roles and accesses.', 'icon': Icons.people_alt_rounded},
  ];

  final List<String> _positions = ['Agent', 'Office', 'Coordinator', 'Supervisor', 'Manager'];
  final List<String> _shifts = ['Morning', 'Afternoon'];

  bool _isEditingContact = false;
  bool _isEditingOp = false;
  bool _isEditingAccess = false;

  late TextEditingController _phoneCtrl;
  late TextEditingController _buildingCtrl;
  String? _shift;
  String? _position;
  bool _masterDriver = false;
  Map<String, bool> _accessMap = {};

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.user['phone-number']);
    _buildingCtrl = TextEditingController(text: widget.user['building']);
    
    _shift = widget.user['shift'];
    if (!_shifts.contains(_shift)) _shift = 'Morning';
    
    _position = widget.user['position'];
    if (!_positions.contains(_position)) _position = 'Agent';
    
    _masterDriver = widget.user['master-driver'] == true;
    
    _accessMap = Map<String, bool>.from((widget.user['access-page'] as Map?)?.cast<String, bool>() ?? {});
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _buildingCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    try {
      await Supabase.instance.client.from('Users').update({'phone-number': _phoneCtrl.text.trim()}).eq('id', widget.user['id']);
      setState(() {
        widget.user['phone-number'] = _phoneCtrl.text.trim();
        _isEditingContact = false;
      });
      widget.onUpdate?.call();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _saveOp() async {
    try {
      await Supabase.instance.client.from('Users').update({
        'building': _buildingCtrl.text.trim(),
        'shift': _shift,
        'position': _position,
        'master-driver': _masterDriver,
      }).eq('id', widget.user['id']);
      setState(() {
        widget.user['building'] = _buildingCtrl.text.trim();
        widget.user['shift'] = _shift;
        widget.user['position'] = _position;
        widget.user['master-driver'] = _masterDriver;
        _isEditingOp = false;
      });
      widget.onUpdate?.call();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _saveAccess() async {
    try {
      await Supabase.instance.client.from('Users').update({'access-page': _accessMap}).eq('id', widget.user['id']);
      setState(() {
        widget.user['access-page'] = _accessMap;
        _isEditingAccess = false;
      });
      widget.onUpdate?.call();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isEditing, VoidCallback onEdit, VoidCallback onSave, VoidCallback onCancel, Color textP) {
    final bool isOffice = currentUserData.value?['position'] == 'Office';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: textP),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        if (!isOffice)
          if (!isEditing)
            InkWell(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: textP.withAlpha(10), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.edit_rounded, color: textP.withAlpha(200), size: 14),
              ),
            )
          else
            Row(
              children: [
                InkWell(onTap: onCancel, child: const Icon(Icons.close_rounded, color: Colors.red, size: 20)),
                const SizedBox(width: 16),
                InkWell(onTap: onSave, child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)),
              ],
            ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool dark, Color textP, Color borderC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: borderC),
            borderRadius: BorderRadius.circular(8),
            color: dark ? Colors.white.withAlpha(10) : Colors.white,
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: textP, fontSize: 13),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Adjust alignment
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, bool dark, Color textP, Color borderC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: borderC),
            borderRadius: BorderRadius.circular(8),
            color: dark ? Colors.white.withAlpha(10) : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: dark ? const Color(0xFF1E293B) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? Colors.white54 : Colors.black54, size: 18),
              style: TextStyle(color: textP, fontSize: 13),
              onChanged: onChanged,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, Color colorL, Color colorV, {IconData? icon}) {
    return Container(
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
              Text(label, style: TextStyle(color: colorL, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: colorV, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);
    final bgCard = dark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6);
    final borderC = dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB);
    
    final name = widget.user['full-name'] ?? 'Unknown';
    final initial = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?';

    return Column(
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
                  Text(appLanguage.value == 'es' ? 'Perfil de Usuario' : 'User Profile', style: TextStyle(color: textS, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF6366f1).withAlpha(40),
                        child: Text(initial, style: const TextStyle(color: Color(0xFF6366f1), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(name, style: TextStyle(color: textP, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              IconButton(icon: Icon(Icons.close_rounded, color: textP), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(appLanguage.value == 'es' ? 'Información de Contacto' : 'Contact Information', Icons.contact_mail_outlined, _isEditingContact, 
                            () => setState(() => _isEditingContact = true), _saveContact, () {
                              setState(() {
                                _isEditingContact = false;
                                _phoneCtrl.text = widget.user['phone-number'] ?? '';
                              });
                            }, textP),
                          const SizedBox(height: 12),
                          if (_isEditingContact)
                            Row(children: [
                              Expanded(child: _buildInfoCard('Email', '${widget.user['email'] ?? '-'}', textS, textP, icon: Icons.email_outlined)),
                              Expanded(child: _buildTextField(appLanguage.value == 'es' ? 'Teléfono' : 'Phone', _phoneCtrl, dark, textP, borderC)),
                            ])
                          else
                            Row(children: [
                              Expanded(child: _buildInfoCard('Email', '${widget.user['email'] ?? '-'}', textS, textP, icon: Icons.email_outlined)),
                              Expanded(child: _buildInfoCard(appLanguage.value == 'es' ? 'Teléfono' : 'Phone', '${widget.user['phone-number'] ?? '-'}', textS, textP, icon: Icons.phone_outlined)),
                            ]),
                        ]
                      )
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(appLanguage.value == 'es' ? 'Detalles Operativos' : 'Operational Details', Icons.settings_outlined, _isEditingOp, 
                            () => setState(() => _isEditingOp = true), _saveOp, () {
                              setState(() {
                                _isEditingOp = false;
                                _buildingCtrl.text = widget.user['building'] ?? '';
                                _shift = widget.user['shift'];
                                if (!_shifts.contains(_shift)) _shift = 'Morning';
                                _position = widget.user['position'];
                                if (!_positions.contains(_position)) _position = 'Agent';
                                _masterDriver = widget.user['master-driver'] == true;
                              });
                            }, textP),
                          const SizedBox(height: 12),
                          if (_isEditingOp) ...[
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: _buildTextField(appLanguage.value == 'es' ? 'Edificio' : 'Building', _buildingCtrl, dark, textP, borderC)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildDropdown(appLanguage.value == 'es' ? 'Turno' : 'Shift', _shift, _shifts, (v) => setState(() => _shift = v), dark, textP, borderC)),
                            ]),
                            const SizedBox(height: 12),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: _buildDropdown(appLanguage.value == 'es' ? 'Posición' : 'Position', _position, _positions, (v) => setState(() => _position = v), dark, textP, borderC)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Master Driver', style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563), fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 36,
                                      padding: const EdgeInsets.only(left: 10, right: 2),
                                      decoration: BoxDecoration(border: Border.all(color: borderC), borderRadius: BorderRadius.circular(8), color: dark ? Colors.white.withAlpha(10) : Colors.white),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_masterDriver ? 'Yes' : 'No', style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                          Transform.scale(
                                            scale: 0.7,
                                            child: Switch(
                                              value: _masterDriver,
                                              onChanged: (v) => setState(() => _masterDriver = v),
                                              activeTrackColor: const Color(0xFF6366f1),
                                              inactiveThumbColor: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF),
                                              inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                        ]
                                      )
                                    )
                                  ]
                                )
                              ),
                            ]),
                          ] else ...[
                            Row(children: [
                              Expanded(child: _buildInfoCard(appLanguage.value == 'es' ? 'Edificio' : 'Building', '${widget.user['building'] ?? '-'}', textS, textP, icon: Icons.business_rounded)),
                              Expanded(child: _buildInfoCard(appLanguage.value == 'es' ? 'Turno' : 'Shift', '${widget.user['shift'] ?? '-'}', textS, textP, icon: Icons.access_time_rounded)),
                            ]),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
                            Row(children: [
                              Expanded(child: _buildInfoCard(appLanguage.value == 'es' ? 'Posición' : 'Position', '${widget.user['position'] ?? '-'}', textS, textP, icon: Icons.badge_rounded)),
                              Expanded(child: _buildInfoCard('Master Driver', widget.user['master-driver'] == true ? 'Yes' : 'No', textS, textP, icon: Icons.verified_user_rounded)),
                            ]),
                          ],
                        ]
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderC)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(appLanguage.value == 'es' ? 'Acceso a Páginas' : 'Page Access', Icons.vpn_key_rounded, _isEditingAccess, 
                        () => setState(() => _isEditingAccess = true), _saveAccess, () {
                          setState(() {
                            _isEditingAccess = false;
                            _accessMap = Map<String, bool>.from((widget.user['access-page'] as Map?)?.cast<String, bool>() ?? {});
                          });
                        }, textP),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _pagesList.length,
                          itemBuilder: (context, index) {
                            final page = _pagesList[index];
                            final key = page['key'] as String;
                            final isAccess = _accessMap[key] == true;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dark ? Colors.white.withAlpha(5) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderC),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(page['icon'] as IconData, color: textP, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(appLanguage.value == 'es' ? page['titleEs'] : page['titleEn'], style: TextStyle(color: textP, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(appLanguage.value == 'es' ? page['descEs'] : page['descEn'], style: TextStyle(color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280), fontSize: 12)),
                                      ],
                                    )
                                  ),
                                  Switch(
                                    value: isAccess,
                                    onChanged: _isEditingAccess ? (v) {
                                      setState(() {
                                        _accessMap[key] = v;
                                      });
                                    } : (v) {}, 
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: _isEditingAccess ? const Color(0xFF6366f1) : const Color(0xFF81A1C1),
                                    inactiveThumbColor: dark ? const Color(0xFF94a3b8) : const Color(0xFF9CA3AF),
                                    inactiveTrackColor: dark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}


