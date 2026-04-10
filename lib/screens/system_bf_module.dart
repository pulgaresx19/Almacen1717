import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show isDarkMode;

class SystemBfModule extends StatefulWidget {
  const SystemBfModule({super.key});

  @override
  State<SystemBfModule> createState() => _SystemBfModuleState();
}

class _SystemBfModuleState extends State<SystemBfModule> {
  late Stream<List<Map<String, dynamic>>> _system1Stream;
  late Stream<List<Map<String, dynamic>>> _system2Stream;
  bool _isSplitView = false;

  @override
  void initState() {
    super.initState();
    _system1Stream = Supabase.instance.client.from('System1').stream(primaryKey: ['id']).eq('id', 1).limit(1);
    _system2Stream = Supabase.instance.client.from('System2').stream(primaryKey: ['id']).eq('id', 1).limit(1);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        final bgPage = dark ? const Color(0xFF0f172a) : const Color(0xFFF3F4F6);
        return Container(
          color: bgPage,
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final childListWidgets = !_isSplitView
                  ? [
                      Expanded(
                        child: _buildSystemCard(
                          context: context,
                          systemName: 'ULD Received',
                          tableName: 'System1',
                          stream: _system1Stream,
                          dark: dark,
                          index: 1,
                          isLeft: true,
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: _buildSystemCard(
                          context: context,
                          systemName: 'System 1',
                          tableName: 'System1',
                          stream: _system1Stream,
                          dark: dark,
                          index: 1,
                          isLeft: true,
                        ),
                      ),
                      const SizedBox(width: 24, height: 24),
                      Expanded(
                        child: _buildSystemCard(
                          context: context,
                          systemName: 'System 2',
                          tableName: 'System2',
                          stream: _system2Stream,
                          dark: dark,
                          index: 2,
                          isLeft: false,
                        ),
                      ),
                    ];

              return SizedBox(
                height: constraints.maxHeight,
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: childListWidgets,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: childListWidgets,
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSystemCard({
    required BuildContext context,
    required String systemName,
    required String tableName,
    required Stream<List<Map<String, dynamic>>> stream,
    required bool dark,
    required int index,
    required bool isLeft,
  }) {
    final bgCard = dark ? const Color(0xFF1E293B) : Colors.white;
    final textP = dark ? Colors.white : const Color(0xFF111827);
    final textS = dark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final borderC = dark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(20);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderC),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366f1)),
            ),
          );
        }

        final data = (snapshot.data != null && snapshot.data!.isNotEmpty)
            ? snapshot.data!.first
            : <String, dynamic>{};

        final carrier = data['carrier-flight$index']?.toString() ?? 'N/A';
        final number = data['number-flight$index']?.toString() ?? 'N/A';
        final rawDate = data['date-flight$index']?.toString() ?? 'N/A';

        String formattedDate = rawDate;
        if (rawDate != 'N/A') {
          try {
            final dt = DateTime.parse(rawDate).toLocal();
            int h = dt.hour;
            int m = dt.minute;
            bool pm = h >= 12;
            int h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);

            if (dt.hour == 0 && dt.minute == 0 && !rawDate.contains('T')) {
              formattedDate =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            } else {
              formattedDate =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} $h12:${m.toString().padLeft(2, '0')} ${pm ? 'PM' : 'AM'}';
            }
          } catch (_) {
            if (rawDate.contains('T')) {
              formattedDate = rawDate.split('T')[0];
            }
          }
        }

        final uldNumber = data['ULD-number$index']?.toString() ?? 'N/A';
        final hasBreakValue = data['ULD-isBreak$index'] != null;
        final isBreak =
            data['ULD-isBreak$index'] == true ||
            data['ULD-isBreak$index']?.toString().toLowerCase() == 'true';

        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderC),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(dark ? 40 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    systemName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textP,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Positioned(
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isSplitView && isLeft)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isSplitView = true;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                            color: const Color(0xFF6366f1),
                            tooltip: 'Split view',
                          ),
                        if (_isSplitView && !isLeft)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isSplitView = false;
                              });
                            },
                            icon: const Icon(Icons.close_rounded, size: 28),
                            color: Colors.redAccent,
                            tooltip: 'Close panel',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Datos del vuelo compactos
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.black.withAlpha(20)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'FLIGHT DATA',
                      style: TextStyle(
                        fontSize: 14,
                        color: textS,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      carrier == 'N/A' && number == 'N/A'
                          ? 'Sin vuelo asignado'
                          : '$carrier $number',
                      style: TextStyle(
                        fontSize: 26,
                        color: textP,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, color: textS, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 16,
                            color: textS,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ULD Info Centrada
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withAlpha(5)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderC),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          uldNumber,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: textP,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: hasBreakValue
                                ? (isBreak
                                      ? const Color(0xFF10b981).withAlpha(40)
                                      : const Color(0xFFef4444).withAlpha(40))
                                : Colors.grey.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasBreakValue
                                  ? (isBreak
                                        ? const Color(0xFF10b981)
                                        : const Color(0xFFef4444))
                                  : Colors.grey,
                              width: 2,
                            ),
                            boxShadow: [
                              if (hasBreakValue)
                                BoxShadow(
                                  color:
                                      (isBreak
                                              ? const Color(0xFF10b981)
                                              : const Color(0xFFef4444))
                                          .withAlpha(20),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Text(
                            hasBreakValue
                                ? (isBreak ? 'BREAK' : 'NO BREAK')
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: hasBreakValue
                                  ? (isBreak
                                        ? const Color(0xFF10b981)
                                        : const Color(0xFFef4444))
                                  : Colors.grey.shade600,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await Supabase.instance.client
                          .from(tableName)
                          .update({
                            'ULD-number$index': null,
                            'ULD-isBreak$index': null,
                          })
                          .eq('id', 1);
                    } catch (e) {
                      debugPrint('Confirm Error $tableName: $e');
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 24),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  label: const Text(
                    'CONFIRM',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
