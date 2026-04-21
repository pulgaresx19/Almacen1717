import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage, isDarkMode;

class LocationV2NotFoundModal {
  static Future<void> show(BuildContext context, String query) async {
    final dark = isDarkMode.value;
    final bgCol = dark ? const Color(0xFF1e293b) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appLanguage.value == 'es' ? 'AWB No Encontrado' : 'AWB Not Found',
                style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: Text(
            appLanguage.value == 'es'
                ? 'No se encontró el AWB "$query" o el ULD aún no ha sido revisado.'
                : 'The AWB "$query" was not found or the ULD has not been checked yet.',
            style: TextStyle(color: textS, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              appLanguage.value == 'es' ? 'Cerrar' : 'Close',
              style: const TextStyle(color: Color(0xFF6366f1)),
            ),
          ),
        ],
      ),
    );
  }
}
