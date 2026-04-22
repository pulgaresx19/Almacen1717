part of 'add_deliver_v2_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
extension AddDeliverV2SubmitExt on AddDeliverV2ScreenState {
  void _addImportAwb() {
    String? missingField;
    if (_importAwbNumberCtrl.text.trim().isEmpty) {
      missingField = 'AWB Number';
    } else if (_importPiecesCtrl.text.trim().isEmpty) {
      missingField = 'Pieces';
    } else if (_importTotalCtrl.text.trim().isEmpty) {
      missingField = 'Total';
    }

    if (missingField != null) {
      _showMissingFieldAlert(missingField);
      return;
    }

    final int pcs = int.tryParse(_importPiecesCtrl.text) ?? 1;
    final int tot = int.tryParse(_importTotalCtrl.text) ?? 1;
    if (tot < pcs) {
      _showMissingFieldAlert(
        'Invalid Total', 
        customMessage: appLanguage.value == 'es'
          ? 'El campo Total ($tot) no puede ser menor a la cantidad de Pieces ($pcs).'
          : 'Total ($tot) cannot be less than Pieces ($pcs).'
      );
      return;
    }

    setState(() {
      _importAwbs.add({
         'awbNumber': _importAwbNumberCtrl.text.trim().toUpperCase(),
         'pieces': int.tryParse(_importPiecesCtrl.text) ?? 1,
         'total': int.tryParse(_importTotalCtrl.text) ?? 1,
         'weight': double.tryParse(_importWeightCtrl.text) ?? 0.0,
         'house': _importHouseCtrl.text.split(RegExp(r'\n+')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList(),
         'remarks': _importRemarksCtrl.text.trim().isEmpty ? null : _importRemarksCtrl.text.trim(),
      });
      _importAwbNumberCtrl.clear();
      _importPiecesCtrl.clear();
      _importTotalCtrl.clear();
      _importWeightCtrl.clear();
      _importHouseCtrl.clear();
      _importRemarksCtrl.clear();
      _importTotalLocked = false;
    });
  }

  void _showMissingFieldAlert(String fieldName, {String? customMessage}) {
    showDialog(
      context: context,
      builder: (alertCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withAlpha(50)),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Action Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              customMessage ?? 'The field "$fieldName" is missing.\nPlease provide this information to proceed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFcbd5e1),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFef4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(alertCtx),
                child: const Text(
                  'UNDERSTOOD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayload() async {
    if (_truckCompanyCtrl.text.trim().isEmpty) {
      setState(() => _missingField = 'Truck Company');
      return;
    }
    if (_driverCtrl.text.trim().isEmpty) {
      setState(() => _missingField = 'Driver');
      return;
    }
    if (_idPickupCtrl.text.trim().isEmpty) {
      setState(() => _missingField = 'ID Pickup');
      return;
    }

    if (_typeCtrl.text == 'Import') {
      if (_importAwbs.isEmpty) {
        _showMissingFieldAlert('Air Waybills (AWBs)');
        return;
      }
    } else {
      if (_selectedAwbs.isEmpty && _selectedUlds.isEmpty) {
        _showMissingFieldAlert('Air Waybills (AWBs) or ULDs');
        return;
      }
      final List<Map<String, dynamic>> combinedToValidate = [..._selectedAwbs, ..._selectedUlds];
      for (var item in combinedToValidate) {
        final awbNum = item['awb_number']?.toString() ?? item['AWB-number']?.toString() ?? item['uld_number']?.toString() ?? item['ULD-number']?.toString() ?? '';
        final pcsStr = _deliveryPcsControllers[awbNum]?.text.trim() ?? '';
        final pcs = int.tryParse(pcsStr) ?? 0;
        
        if (pcs <= 0) {
          _showMissingFieldAlert(
            'Pieces for $awbNum', 
            customMessage: appLanguage.value == 'es'
                ? 'Las piezas a entregar para la guía o ULD $awbNum tienen un valor numérico no válido ($pcsStr).\nPor favor, introduzca un número mayor a 0 para guardar.'
                : 'The pieces for item $awbNum has an invalid value ($pcsStr).\nPlease enter a number greater than 0 to proceed.'
          );
          return;
        }

        if (_overLimitErrors[awbNum] == true) {
          _showMissingFieldAlert(
            'Pieces Exceeded for $awbNum', 
            customMessage: appLanguage.value == 'es'
                ? 'La cantidad de piezas a entregar para $awbNum supera la cantidad de piezas disponibles.\nPor favor, reduzca el número de piezas.'
                : 'The amount of pieces to deliver for $awbNum exceeds the available pieces.\nPlease reduce the number of pieces.'
          );
          return;
        }
      }
    }

    String finalTime = _timeCtrl.text.trim();
    if (_typeCtrl.text == 'Appointment') {
      if (finalTime.isEmpty || finalTime == 'NOW') {
        setState(() => _missingField = 'Time');
        return;
      }
    } else {
      if (finalTime.isEmpty || finalTime == 'NOW') {
        final now = DateTime.now();
        finalTime = DateFormat('hh:mm a').format(now);
      }
    }

    setState(() {
      _isLoading = true;
      _missingField = null;
    });
    
    String doorText = _doorCtrl.text.trim();
    if (doorText.isEmpty) doorText = 'PENDING';

    try {
      final nowForDate = DateTime.now();
      int hours = 0;
      int minutes = 0;
      if (finalTime.contains(':')) {
        try {
          if (finalTime.toUpperCase().contains('M')) {
            final dtParsed = DateFormat('hh:mm a').parse(finalTime.toUpperCase());
            hours = dtParsed.hour;
            minutes = dtParsed.minute;
          } else {
            final parts = finalTime.split(':');
            hours = int.tryParse(parts[0]) ?? 0;
            minutes = int.tryParse(parts[1]) ?? 0;
          }
        } catch (_) {
          final parts = finalTime.split(':');
          hours = int.tryParse(parts[0]) ?? 0;
          minutes = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
      }
      final timeDeliverDate = DateTime(nowForDate.year, nowForDate.month, nowForDate.day, hours, minutes);

      final listPickup = _typeCtrl.text == 'Import' 
          ? _importAwbs.map((e) => {
              'awb_number': e['awbNumber']?.toString() ?? '',
              'found': e['pieces']?.toString() ?? '0',
              'weight': e['weight']?.toString() ?? '0',
              'remarks': e['remarks']?.toString() ?? ''
            }).toList() 
          : [
              ..._selectedAwbs.map((e) {
                final awbNum = e['awb_number']?.toString() ?? e['AWB-number']?.toString() ?? '';
                final pcsCtrlText = _deliveryPcsControllers[awbNum]?.text.trim() ?? '0';
                final pcs = pcsCtrlText.replaceAll(RegExp(r'[^0-9]'), '');
                final rem = _deliveryRemarkControllers[awbNum]?.text.trim() ?? '';
                
                double expectedWeight = 0.0;
                if (e['data-AWB'] is List) {
                  for (var item in e['data-AWB']) {
                     expectedWeight += double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
                  }
                } else if (e['data-AWB'] is Map) {
                     expectedWeight += double.tryParse(e['data-AWB']['weight']?.toString() ?? '0') ?? 0.0;
                }

                return {
                  'awb_id': e['id'],
                  'awb_number': awbNum,
                  'found': pcs,
                  'weight': expectedWeight.toStringAsFixed(2),
                  'remarks': rem
                };
              }),
              ..._selectedUlds.map((e) {
                 final uNum = e['uld_number']?.toString() ?? e['ULD-number']?.toString() ?? '';
                 final pcsCtrlText = _deliveryPcsControllers[uNum]?.text.trim() ?? '0';
                 final pcs = pcsCtrlText.replaceAll(RegExp(r'[^0-9]'), '');
                 final rem = _deliveryRemarkControllers[uNum]?.text.trim() ?? '';
                 return {
                   'uld_id': e['id_uld'],
                   'uld_number': uNum,
                   'found': pcs,
                   'weight': e['weight_total']?.toString() ?? e['weight']?.toString() ?? '0.00',
                   'remarks': rem
                 };
              })
            ];

      int totalPieces = 0;
      double totalWeight = 0.0;
      for (var item in listPickup) {
        totalPieces += int.tryParse(item['found']?.toString() ?? '0') ?? 0;
        totalWeight += double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
      }

      final payload = {
        'company': _truckCompanyCtrl.text.trim(),
        'driver_name': _driverCtrl.text.trim(),
        'door': doorText,
        'id_pickup': _idPickupCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'time': timeDeliverDate.toUtc().toIso8601String(),
        'remarks': _remarksCtrl.text.trim(),
        'is_priority': _isPriority,
        'list_deliver': listPickup,
        'total_pieces': totalPieces,
        'total_weight': totalWeight,
      };

      await Supabase.instance.client.from('deliveries').insert(payload);

      if (_typeCtrl.text == 'Import' && _importAwbs.isNotEmpty) {
        Map<String, Map<String, dynamic>> mergedAwbs = {};
        final nowUtc = DateTime.now().toUtc().toIso8601String();
        for (var a in _importAwbs) {
          final num = a['awbNumber'];
          if (!mergedAwbs.containsKey(num)) {
             mergedAwbs[num] = {
               'AWB-number': num,
               'total': a['total'],
               'data-AWB': [],
             };
          }
          (mergedAwbs[num]!['data-AWB'] as List).add({
             'flightID': null,
             'refCarrier': 'WRHS',
             'refNumber': 'IMP',
             'refDate': nowUtc.substring(0, 10),
             'refULD': 'IMPORT',
             'pieces': a['pieces'],
             'weight': a['weight'],
             'remarks': a['remarks'],
             'house_number': a['house'],
             'status': 'Received',
          });
        }
        
        final awbNumbers = mergedAwbs.keys.toList();
        final existingDbAwbs = await Supabase.instance.client.from('AWB').select('AWB-number, data-AWB').inFilter('AWB-number', awbNumbers);
        final existingAwbMap = { for (var e in existingDbAwbs) e['AWB-number'] : e['data-AWB'] };
        
        for (var awbNum in mergedAwbs.keys) {
           if (existingAwbMap.containsKey(awbNum)) {
              var dbData = existingAwbMap[awbNum];
              if (dbData is List) {
                 (mergedAwbs[awbNum]!['data-AWB'] as List).insertAll(0, dbData);
              } else if (dbData is Map) {
                 (mergedAwbs[awbNum]!['data-AWB'] as List).insert(0, dbData);
              }
           }
        }
        
        final finalAwbPayloads = mergedAwbs.values.map((v) {
          final n = v['AWB-number'];
          Map<String, dynamic> out = {
            'AWB-number': n,
            'total': v['total'],
            'data-AWB': v['data-AWB'],
          };
          if (!existingAwbMap.containsKey(n)) {
             out['created_at'] = DateTime.now().toIso8601String();
          }
          return out;
        }).toList();
        
        await Supabase.instance.client.from('AWB').upsert(finalAwbPayloads, onConflict: 'AWB-number');
      }

      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black54,
          barrierDismissible: false,
          barrierLabel: 'Success',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (ctx, animation, secondaryAnimation) => const SizedBox(),
          transitionBuilder: (ctx, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              child: FadeTransition(
                opacity: animation,
                child: AlertDialog(
                  backgroundColor: const Color(0xFF1e293b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: const Color(0xFF10b981).withAlpha(50), width: 1),
                  ),
                  contentPadding: const EdgeInsets.all(32),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 64),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        appLanguage.value == 'es' ? 'Ã‚Â¡Entrega Creada!' : 'Delivery Created!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLanguage.value == 'es' ? 'Los datos han sido guardados.' : 'Records have been saved.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss Dialog
          if (widget.onPop != null) widget.onPop!(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
}
