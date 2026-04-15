import 'package:flutter/material.dart';
import 'coordinator_v2_awb_dialog.dart';

void showCoordinatorV2AwbModal(BuildContext context, Map<String, dynamic> combined, Map<String, dynamic> awbSplit, bool dark, [bool isReadOnly = false]) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return CoordinatorV2AwbDialog(
        combined: combined,
        awbSplit: awbSplit,
        dark: dark,
        isReadOnly: isReadOnly,
      );
    },
  );
}
