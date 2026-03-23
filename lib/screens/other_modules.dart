import 'package:flutter/material.dart';

class SystemModule extends StatelessWidget {
  const SystemModule({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildTemplate('System Operations', 'Sincronizar vuelos y ULDs, reportes generales y configuración.', Icons.settings_system_daydream_rounded);
  }

  Widget _buildTemplate(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: const Color(0xFF334155)),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF94a3b8))),
        ],
      ),
    );
  }
}

class CoordinatorModule extends StatelessWidget {
  const CoordinatorModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const SystemModule(); // Placeholder reuse
  }
}

class LocationModule extends StatelessWidget {
  const LocationModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const SystemModule(); // Placeholder reuse
  }
}
