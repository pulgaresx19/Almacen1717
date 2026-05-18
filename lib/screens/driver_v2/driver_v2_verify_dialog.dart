import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show currentUserData, scaffoldMessengerKey;
import 'driver_v2_confirm_dialog.dart';
import 'driver_v2_verify_card.dart';

void showVerifyDriverDialog({
  required BuildContext context,
  required Map<String, dynamic> deliveryData,
  required bool dark,
  required String company,
  required String driver,
  required String time,
  required String door,
  required String type,
}) {
  final String idPickup = deliveryData['id_pickup']?.toString() ?? '-';
  final int awbsCount = (deliveryData['awbs'] is List) ? (deliveryData['awbs'] as List).length : 1;

  showDialog(
    context: context,
    builder: (ctx) {
      bool isProcessingNoShow = false;

      return StatefulBuilder(
        builder: (statefulContext, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: DriverV2VerifyCard(
              deliveryData: deliveryData,
              dark: dark,
              company: company,
              driver: driver,
              time: time,
              door: door,
              type: type,
              idPickup: idPickup,
              awbsCount: awbsCount,
              showCloseButton: true,
              isLoadingNoShow: isProcessingNoShow,
              onClose: () => Navigator.pop(ctx),
              onNoShow: () async {
                final idDelivery = deliveryData['id_delivery']?.toString();
                if (idDelivery == null) return;

                setStateDialog(() => isProcessingNoShow = true);
                try {
                  final userFullName = currentUserData.value?['full_name'] ?? 'Unknown User';
                  await Supabase.instance.client.rpc(
                    'rpc_register_no_show',
                    params: {
                      'p_id_delivery': idDelivery,
                      'p_full_name': userFullName,
                    },
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  debugPrint('Error registering no show: $e');
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                  if (ctx.mounted) setStateDialog(() => isProcessingNoShow = false);
                }
              },
              onConfirm: () {
                Navigator.pop(ctx);
                showDriverConfirmDialog(
                  context: context,
                  deliveryData: deliveryData,
                  dark: dark,
                  company: company,
                  driver: driver,
                );
              },
            ),
          );
        },
      );
    },
  );
}
