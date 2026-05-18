
import 'realtime_service.dart';

class DeliveryMathLogic {
  
  /// Calcula y retorna las métricas de disponibilidad para un AWB.
  /// 
  /// [awb]: El mapa de datos del AWB.
  /// Retorna un mapa con las siguientes llaves:
  /// - 'expected': Piezas que se esperaban
  /// - 'arrived': Piezas recibidas en almacén
  /// - 'checked': Piezas contadas por el coordinador
  /// - 'delivered': Piezas ya entregadas al cliente
  /// - 'in_process': Piezas que ya están en proceso de entrega en un driver
  /// - 'available': Piezas reales que el sistema autoriza para entregar
  /// - 'on_hold': Piezas físicamente en almacén pero retenidas (bloqueadas)
  /// - 'remaining': Piezas disponibles para asignar a una nueva entrega (Available - Delivered - In Process)
  static Map<String, int> calculateAwbMetrics(Map<String, dynamic> awb) {
    int expectedPieces = int.tryParse(awb['total_espected']?.toString() ?? '0') ?? 0;
    int arrivedPieces = int.tryParse(awb['pieces_arrived']?.toString() ?? '0') ?? 0;
    int checkedPieces = int.tryParse(awb['pieces_received']?.toString() ?? '0') ?? 0;
    int deliveredPieces = int.tryParse(awb['pieces_delivered']?.toString() ?? '0') ?? 0;
    int inProcessPieces = int.tryParse(awb['pieces_in_process']?.toString() ?? '0') ?? 0;

    int validArrivedPieces = 0;
    
    final awbIdStr = awb['id']?.toString() ?? '';
    if (awbIdStr.isNotEmpty) {
      final splits = realtimeService.awbSplits.value.where((s) => (s['awb_id']?.toString() ?? s['id_awb']?.toString()) == awbIdStr).toList();
      
      if (splits.isEmpty) {
        // Fallback: Si no hay splits, no hay manera de asociarlo a un vuelo directamente desde la tabla awbs.
        // Pero si las piezas ya han llegado ('arrivedPieces'), las marcamos como validas solo si no dependen de un vuelo específico.
        // Como la regla requiere que el vuelo esté habilitado, y un AWB sin splits no está en ningún vuelo,
        // no podemos liberar estas piezas masivamente por vuelo. Deben ser chequeadas por el coordinador.
      } else {
        for (var split in splits) {
          // La realidad contada manda sobre la expectativa. Si no se ha contado, usamos lo esperado.
          int splitCheckedCount = int.tryParse(split['total_checked']?.toString() ?? '0') ?? 0;
          int splitExpectedCount = int.tryParse(split['pieces']?.toString() ?? split['pieces_split']?.toString() ?? '0') ?? 0;
          int splitRealPieces = splitCheckedCount > 0 ? splitCheckedCount : splitExpectedCount;
          
          bool isUldChecked = false;
          bool isFlightEnabled = false;
          
          // 1. Verificamos el ULD
          final uldId = split['uld_id']?.toString() ?? split['id_uld']?.toString();
          Map<String, dynamic>? uld;
          if (uldId != null && uldId.isNotEmpty) {
            try {
              uld = realtimeService.ulds.value.firstWhere((u) => u['id_uld']?.toString() == uldId);
              if (uld['time_checked'] != null && uld['time_checked'].toString().isNotEmpty) {
                isUldChecked = true;
              }
            } catch (_) {}
          }
          
          // 2. Verificamos el Vuelo
          String? flightId = split['flight_id']?.toString() ?? split['id_flight']?.toString();
          if (flightId == null || flightId.isEmpty) {
            if (uld != null) {
              flightId = uld['id_flight']?.toString() ?? uld['id']?.toString();
            }
          }
          
          if (flightId != null && flightId.isNotEmpty) {
            try {
              final flight = realtimeService.flights.value.firstWhere((f) => f['id_flight']?.toString() == flightId);
              if (flight['is_delivery_enabled'] == true || flight['is_delivery_enabled'] == 'true' || flight['is_delivery_enabled'] == 1 || flight['is_delivery_enabled'] == '1') {
                isFlightEnabled = true;
              }
            } catch (_) {}
          }
          
          // Si el ULD está chequeado O el vuelo entero está liberado masivamente -> piezas disponibles
          if (isUldChecked || isFlightEnabled) {
            validArrivedPieces += splitRealPieces;
          }
        }
      }
    }
    
    // Regla de Oro: Si el Coordinador anotó a nivel general del AWB un "Checked" mayor, eso manda.
    // (Por ejemplo, si chequeó manualmente piezas sueltas que no estaban en un vuelo liberado).
    int finalAvailable = validArrivedPieces > checkedPieces ? validArrivedPieces : checkedPieces;
    
    // El On Hold es lo que llegó físicamente pero aún no está habilitado (Available).
    int onHold = arrivedPieces - finalAvailable;
    if (onHold < 0) onHold = 0;
    
    // Remaining (Lo que el operador de oficina ve que puede agregar al camión ahora mismo)
    int remaining = finalAvailable - deliveredPieces - inProcessPieces;
    if (remaining < 0) remaining = 0;
    
    return {
      'expected': expectedPieces,
      'arrived': arrivedPieces,
      'checked': checkedPieces,
      'delivered': deliveredPieces,
      'in_process': inProcessPieces,
      'available': finalAvailable,
      'on_hold': onHold,
      'remaining': remaining,
    };
  }
}
