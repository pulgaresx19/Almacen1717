import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';

class DamageInformationPanel extends StatefulWidget {
  final bool dark;
  final Color textP;
  final Color textS;
  final Color borderC;
  final Color bgGlassy;

  const DamageInformationPanel({
    super.key,
    required this.dark,
    required this.textP,
    required this.textS,
    required this.borderC,
    required this.bgGlassy,
  });

  @override
  State<DamageInformationPanel> createState() => DamageInformationPanelState();
}

class DamageInformationPanelState extends State<DamageInformationPanel> {
  final TextEditingController _pcsCtrl = TextEditingController();
  final TextEditingController _damageRemarkCtrl = TextEditingController();
  final ScrollController _photoScrollCtrl = ScrollController();
  final List<String> _selectedDamages = [];
  final List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _damageTypes = [
    'Torn', 'Crushed', 'Wet', 'Broken', 'Open',
    'Missing', 'Cracked', 'Leaking', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _pcsCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pcsCtrl.dispose();
    _damageRemarkCtrl.dispose();
    _photoScrollCtrl.dispose();
    super.dispose();
  }

  // Expose getters for parent to collect data
  int get pieces => int.tryParse(_pcsCtrl.text) ?? 0;
  List<String> get photos => _photos;
  List<String> get selectedDamages => _selectedDamages;
  String get remarks => _damageRemarkCtrl.text.trim();

  void _showRemarkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.dark ? const Color(0xFF1e293b) : Colors.white,
          title: Text('Damage Remarks', style: TextStyle(color: widget.dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _damageRemarkCtrl,
            style: TextStyle(color: widget.dark ? Colors.white : Colors.black),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter specific details about the damage...',
              hintStyle: TextStyle(color: widget.dark ? Colors.white54 : Colors.black54),
              filled: true,
              fillColor: widget.dark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      }
    );
  }

  Future<void> _pickFromGallery() async {
    if (_photos.length >= 9) {
      _showLimitMessage();
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 60,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (images.isNotEmpty) {
        setState(() {
          for (var img in images) {
            if (_photos.length < 9) {
              _photos.add(img.path);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= 9) {
      _showLimitMessage();
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        setState(() {
          _photos.add(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maximum 9 photos allowed per report.', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showImagePreviewDialog(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb 
                    ? Image.network(path, fit: BoxFit.contain)
                    : Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDamage(String type) {
    setState(() {
      if (_selectedDamages.contains(type)) {
        _selectedDamages.remove(type);
      } else {
        _selectedDamages.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = const Color(0xFFef4444);
    final piecesVal = int.tryParse(_pcsCtrl.text) ?? 0;
    final isEnabled = piecesVal > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.bgGlassy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderC, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'DAMAGE REPORT', 
                style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const Spacer(),
              Text('Pieces:', style: TextStyle(color: widget.textS, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                width: 65,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.dark ? Colors.white.withAlpha(5) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: titleColor.withAlpha(150)),
                ),
                child: TextField(
                  controller: _pcsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: widget.textP, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: widget.textS.withAlpha(100)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _damageRemarkCtrl,
                builder: (context, value, child) {
                  final hasRemark = value.text.trim().isNotEmpty;
                  final Color iconColor = hasRemark ? const Color(0xFFF59E0B) : widget.textS.withAlpha(100);
                  final Color bgColor = hasRemark ? const Color(0xFFF59E0B).withAlpha(30) : (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5));
                  final Color borderColor = hasRemark ? const Color(0xFFF59E0B) : (widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10));

                  return InkWell(
                    onTap: isEnabled ? () => _showRemarkDialog(context) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: isEnabled ? bgColor : (widget.dark ? Colors.white.withAlpha(2) : Colors.black.withAlpha(2)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isEnabled ? borderColor : widget.borderC.withAlpha(50)),
                      ),
                      child: Icon(
                        hasRemark ? Icons.chat_bubble : Icons.chat_bubble_outline,
                        color: isEnabled ? iconColor : widget.textS.withAlpha(50), 
                        size: 16
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: isEnabled ? _pickFromGallery : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isEnabled ? const Color(0xFF3b82f6).withAlpha(20) : (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                  ),
                  child: Icon(Icons.photo_library_outlined, color: isEnabled ? const Color(0xFF3b82f6) : widget.textS.withAlpha(100), size: 16),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: isEnabled ? _pickFromCamera : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isEnabled ? const Color(0xFF10b981).withAlpha(20) : (widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: isEnabled ? const Color(0xFF10b981) : widget.textS.withAlpha(100), size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: widget.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.borderC),
              ),
              alignment: Alignment.center,
              child: _photos.isEmpty
                  ? Text(
                      'No photos added yet',
                      style: TextStyle(color: widget.textS.withAlpha(150), fontSize: 13, fontWeight: FontWeight.w500),
                    )
                  : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: Scrollbar(
                        controller: _photoScrollCtrl,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _photoScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: _photos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final path = entry.value;
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showImagePreviewDialog(path),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: widget.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: kIsWeb ? NetworkImage(path) as ImageProvider : FileImage(File(path)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _photos.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _damageTypes.map((type) {
                    final isSelected = _selectedDamages.contains(type);
                    
                    // Base colors
                    Color bgCol = widget.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5);
                    Color bordCol = widget.borderC;
                    Color textCol = widget.textS;

                    if (isEnabled && isSelected) {
                      bgCol = titleColor.withAlpha(20);
                      bordCol = titleColor.withAlpha(100);
                      textCol = titleColor;
                    } else if (!isEnabled) {
                      bgCol = widget.dark ? Colors.white.withAlpha(2) : Colors.black.withAlpha(2);
                      bordCol = widget.borderC.withAlpha(50);
                      textCol = widget.textS.withAlpha(50);
                    }

                    return InkWell(
                      onTap: isEnabled ? () => _toggleDamage(type) : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgCol,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: bordCol),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: textCol,
                            fontSize: 12,
                            fontWeight: isSelected && isEnabled ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
