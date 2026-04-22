import 'package:flutter/material.dart';
import '../../main.dart' show appLanguage, isDarkMode, isSidebarExpandedNotifier;
import 'driver_v2_panel.dart';

class DriverV2Screen extends StatefulWidget {
  final bool isActive;
  const DriverV2Screen({super.key, this.isActive = false});

  @override
  State<DriverV2Screen> createState() => _DriverV2ScreenState();
}

class _DriverV2ScreenState extends State<DriverV2Screen> {
  final TextEditingController _searchController = TextEditingController();

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
        return Stack(
          children: [
            Column(
              children: [
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
                        Text(
                          appLanguage.value == 'es' ? 'Chofer' : 'Driver',
                          style: TextStyle(
                            color: dark ? Colors.white : const Color(0xFF111827),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 320,
                      height: 42,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withAlpha(10) : const Color(0xFFffffff),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(
                                color: dark ? Colors.white : const Color(0xFF111827),
                                fontSize: 13,
                              ),
                              onChanged: (v) => setState(() {}),
                              onSubmitted: (v) {
                                // Search logic here
                              },
                              decoration: InputDecoration(
                                hintText: appLanguage.value == 'es' ? 'Buscar...' : 'Search...',
                                hintStyle: TextStyle(
                                  color: (dark ? Colors.white : const Color(0xFF111827)).withAlpha(76),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: dark ? const Color(0xFF94a3b8) : const Color(0xFF6B7280),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              if (_searchController.text.trim().isNotEmpty) {
                                // Search logic here
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: _searchController.text.trim().isEmpty
                                    ? (dark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6))
                                    : const Color(0xFF6366f1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: _searchController.text.trim().isEmpty
                                    ? (dark ? Colors.white30 : Colors.black26)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF0f172a).withAlpha(100) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: DriverV2Panel(),
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
