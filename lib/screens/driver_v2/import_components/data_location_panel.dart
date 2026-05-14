import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataLocationPanel extends StatelessWidget {
  final bool dark;
  final Color textP;
  final Color textS;
  final Color borderC;
  final Color bgGlassy;
  final ValueNotifier<List<Map<String, dynamic>>> itemsNotifier;
  final Function(String id, String location) onUpdateLocation;
  final Function(String id) onRemoveItem;

  const DataLocationPanel({
    super.key,
    required this.dark,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.bgGlassy,
    required this.itemsNotifier,
    required this.onUpdateLocation,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgGlassy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DATA LOCATION', style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: itemsNotifier,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_rounded, color: textS.withAlpha(100), size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Locations will appear here\nas items are checked.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textS.withAlpha(150), fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final groupedItems = <String, List<Map<String, dynamic>>>{};
                for (var item in items) {
                  groupedItems.putIfAbsent(item['category'], () => []).add(item);
                }

                final categoryOrder = ['AGI Skid', 'Pre Skid', 'Crate', 'Box', 'Other'];
                final sortedCategories = groupedItems.keys.toList()
                  ..sort((a, b) => categoryOrder.indexOf(a).compareTo(categoryOrder.indexOf(b)));

                return ListView.separated(
                  itemCount: sortedCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = sortedCategories[index];
                    final catItems = groupedItems[category]!;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: dark ? Colors.black.withAlpha(20) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderC),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                            child: Text(category.toUpperCase(), style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                          // Items
                          ...catItems.asMap().entries.map((entry) {
                            final itemIndex = entry.key + 1;
                            final item = entry.value;
                            return ItemLocationRow(
                              item: item,
                              index: itemIndex,
                              dark: dark,
                              textP: textP,
                              textS: textS,
                              borderC: borderC,
                              onUpdateLocation: onUpdateLocation,
                              onRemoveItem: onRemoveItem,
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemLocationRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool dark;
  final Color textP;
  final Color textS;
  final Color borderC;
  final Function(String id, String location) onUpdateLocation;
  final Function(String id) onRemoveItem;

  const ItemLocationRow({
    super.key,
    required this.item,
    required this.index,
    required this.dark,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.onUpdateLocation,
    required this.onRemoveItem,
  });

  @override
  State<ItemLocationRow> createState() => _ItemLocationRowState();
}

class _ItemLocationRowState extends State<ItemLocationRow> {
  late TextEditingController _locCtrl;

  @override
  void initState() {
    super.initState();
    _locCtrl = TextEditingController(text: widget.item['location']);
  }

  @override
  void didUpdateWidget(ItemLocationRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['location'] != widget.item['location'] && _locCtrl.text != widget.item['location']) {
      _locCtrl.text = widget.item['location'];
    }
  }

  @override
  void dispose() {
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: widget.borderC.withAlpha(50))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Circular Badge
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${widget.index}', style: TextStyle(color: widget.textP, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  // Pieces Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3b82f6).withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${widget.item['value']} pcs', style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => widget.onRemoveItem(widget.item['id']),
                child: Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TextField Full width
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: widget.dark ? Colors.black.withAlpha(20) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.borderC),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _locCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseTextFormatter(),
              ],
              onChanged: (val) => widget.onUpdateLocation(widget.item['id'], val),
              style: TextStyle(color: widget.textP, fontSize: 13, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: 'Locations (e.g. A1, B2, C3...)',
                hintStyle: TextStyle(color: widget.textS.withAlpha(100), fontSize: 12, letterSpacing: 0),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
