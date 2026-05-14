import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataCoordinatorPanel extends StatefulWidget {
  final bool dark;
  final Color textP;
  final Color textS;
  final Color borderC;
  final Color bgGlassy;
  final Function(String category, String value) onAdd;

  const DataCoordinatorPanel({
    super.key,
    required this.dark,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.bgGlassy,
    required this.onAdd,
  });

  @override
  State<DataCoordinatorPanel> createState() => _DataCoordinatorPanelState();
}

class _DataCoordinatorPanelState extends State<DataCoordinatorPanel> {
  final Map<String, TextEditingController> _controllers = {
    'AGI Skid': TextEditingController(),
    'Pre Skid': TextEditingController(),
    'Crate': TextEditingController(),
    'Box': TextEditingController(),
    'Other': TextEditingController(),
  };

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Widget _buildVisualInputBlock(String label) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: TextStyle(color: widget.textP, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Container(
          height: 36,
          width: 70,
          decoration: BoxDecoration(
            color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.borderC),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _controllers[label],
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            style: TextStyle(color: widget.textP, fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            final val = _controllers[label]!.text;
            if (val.trim().isNotEmpty) {
              widget.onAdd(label, val);
              _controllers[label]!.clear();
            }
          },
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF10b981), size: 20),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.bgGlassy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DATA COORDINATOR', style: TextStyle(color: widget.textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVisualInputBlock('AGI Skid'),
              const SizedBox(height: 12),
              _buildVisualInputBlock('Pre Skid'),
              const SizedBox(height: 12),
              _buildVisualInputBlock('Crate'),
              const SizedBox(height: 12),
              _buildVisualInputBlock('Box'),
              const SizedBox(height: 12),
              _buildVisualInputBlock('Other'),
            ],
          ),
        ],
      ),
    );
  }
}
