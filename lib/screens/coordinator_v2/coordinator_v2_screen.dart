import 'package:flutter/material.dart';
import '../../main.dart' show isDarkMode;
import 'coordinator_v2_logic.dart';
import 'coordinator_v2_panel.dart';

class CoordinatorV2Screen extends StatefulWidget {
  const CoordinatorV2Screen({super.key});

  @override
  State<CoordinatorV2Screen> createState() => _CoordinatorV2ScreenState();
}

class _CoordinatorV2ScreenState extends State<CoordinatorV2Screen> {
  final CoordinatorV2Logic _logic = CoordinatorV2Logic();
  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF0f172a).withAlpha(100)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withAlpha(25)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: CoordinatorV2Panel(logic: _logic),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
