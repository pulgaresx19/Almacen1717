import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../main.dart' show appLanguage;


Widget buildHouseItem(int count, Color textP, Color textS, Color bgCard) {
  return Container(
    width: 100,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('House', style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF6366f1).withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$count',
            style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

Widget buildDetailItem(String label, String value, Color textP, Color textS, Color bgCard, {bool isFullWidth = false}) {
  return Container(
    width: isFullWidth ? double.infinity : 100,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textS, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: textP, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget buildTextFieldBlock(String label, Color textP, Color textS, Color bgCard, bool dark, TextEditingController ctrl, VoidCallback onAdd, bool isReadOnly) {
  return Opacity(
    opacity: isReadOnly ? 0.6 : 1.0,
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 60,
        child: Text(label, style: TextStyle(color: textS, fontSize: 11)),
      ),
      const SizedBox(width: 8),
      Container(
        width: 65,
        height: 38,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
        ),
        child: Material(
          color: Colors.transparent,
          child: TextField(
            controller: ctrl,
            readOnly: isReadOnly,
            style: TextStyle(color: textP, fontSize: 13),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 5,
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isReadOnly ? null : onAdd,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(Icons.add_circle, color: isReadOnly ? textS : const Color(0xFF6366f1), size: 24),
          ),
        ),
      ),
    ],
  ));
}

Widget buildSelectorIcon(int index, int selectedIndex, IconData icon, Color actColor, Color textS, VoidCallback onTap) {
  final isAct = selectedIndex == index;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isAct ? actColor.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isAct ? Border.all(color: actColor.withAlpha(100)) : Border.all(color: Colors.transparent),
      ),
      child: Icon(icon, color: isAct ? actColor : textS.withAlpha(150), size: 26),
    ),
  );
}

Widget buildLocationSection(
  bool dark,
  Color bgCard,
  Color bgModal,
  Color textP,
  Color textS,
  String? selectedLocation,
  TextEditingController locationOtherCtrl,
  Function(String) onSelectLocation,
  bool isReadOnly,
) {
  return Expanded(
    flex: 2,
    child: Opacity(
      opacity: isReadOnly ? 0.6 : 1.0,
      child: Container(
        height: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appLanguage.value == 'es' ? 'Locación Requerida:' : 'Location Required:', style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['2-8C*', 'CRT', 'PSV', 'DG', 'Oversize', 'Small rack', 'Animal live', 'Other'].map((loc) {
              final isSelected = selectedLocation == loc;
              return InkWell(
                onTap: isReadOnly ? null : () => onSelectLocation(loc),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6).withAlpha(dark ? 30 : 20) : (dark ? Colors.white.withAlpha(10) : Colors.white),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loc,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF3B82F6) : textP,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedLocation == 'Other') ...[
            const SizedBox(height: 16),
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: dark ? Colors.white.withAlpha(10) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
              ),
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  controller: locationOtherCtrl,
                  readOnly: isReadOnly,
                  style: TextStyle(color: textP, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: appLanguage.value == 'es' ? 'Especifique locación...' : 'Specify location...',
                    hintStyle: TextStyle(color: textS.withAlpha(150), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    ),
  ));
}

Widget buildDamageSection(
  bool dark,
  Color bgCard,
  Color bgModal,
  Color textP,
  Color textS,
  List<String> selectedDamages,
  Function(List<String>) onDamagesChanged,
  List<XFile> localPhotos,
  VoidCallback onPickGallery,
  VoidCallback onPickCamera,
  Function(int) onRemovePhoto,
  bool isReadOnly,
) {
  final damagesList = ['Torn', 'Crushed', 'Wet', 'Broken', 'Open', 'Missing', 'Cracked', 'Leaking', 'Other'];

  return Expanded(
    flex: 2,
    child: Opacity(
      opacity: isReadOnly ? 0.6 : 1.0,
      child: Container(
        height: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DAMAGE REPORT', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: [
                  if (!isReadOnly) ...[
                    InkWell(
                      onTap: onPickGallery,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withAlpha(10) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF3B82F6)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onPickCamera,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withAlpha(10) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: dark ? Colors.white.withAlpha(5) : Colors.white.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dark ? Colors.white.withAlpha(15) : const Color(0xFFE5E7EB)),
              ),
              child: localPhotos.isEmpty
                ? Center(
                    child: Text('No photos added yet', style: TextStyle(color: textS.withAlpha(150), fontSize: 12)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: localPhotos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: kIsWeb
                                ? Image.network(
                                    localPhotos[index].path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(localPhotos[index].path),
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                          if (!isReadOnly)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => onRemovePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: damagesList.map((dmg) {
                  final isSelected = selectedDamages.contains(dmg);
                  return InkWell(
                    onTap: isReadOnly ? null : () {
                      final newList = List<String>.from(selectedDamages);
                      if (isSelected) {
                        newList.remove(dmg);
                      } else {
                        newList.add(dmg);
                      }
                      onDamagesChanged(newList);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEF4444).withAlpha(dark ? 30 : 20) : (dark ? Colors.white.withAlpha(10) : Colors.white),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFEF4444) : (dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dmg,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFEF4444) : textP,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  ));
}

Widget buildNotesSection(
  bool dark,
  Color bgCard,
  Color textP,
  Color textS,
  TextEditingController notesCtrl,
  bool isReadOnly,
) {
  return Expanded(
    flex: 2,
    child: Opacity(
      opacity: isReadOnly ? 0.6 : 1.0,
      child: Container(
        height: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                appLanguage.value == 'es' ? 'NOTAS Y COMENTARIOS' : 'NOTES & REMARKS',
                style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: dark ? Colors.white.withAlpha(5) : Colors.white.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dark ? Colors.white.withAlpha(25) : const Color(0xFFE5E7EB)),
              ),
              child: SingleChildScrollView(
                child: TextField(
                  controller: notesCtrl,
                  readOnly: isReadOnly,
                  maxLines: null,
                  style: TextStyle(color: textP, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: appLanguage.value == 'es' ? 'Añadir texto detallado aquí...' : 'Add detailed text here...',
                    hintStyle: TextStyle(color: textS.withAlpha(150), fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ));
}
