import 'package:flutter/material.dart';
import '../main.dart' show appLanguage, isDarkMode;

class ControlFlightModule extends StatelessWidget {
  const ControlFlightModule({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        final textP = dark ? Colors.white : const Color(0xFF111827);
        final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF4B5563);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_takeoff_rounded, size: 64, color: textS.withAlpha(100)),
              const SizedBox(height: 16),
              Text(
                appLanguage.value == 'es' ? 'Módulo Control (Flight)' : 'Control (Flight) Module',
                style: TextStyle(
                  color: textP,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Work in progress...',
                style: TextStyle(
                  color: textS,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
