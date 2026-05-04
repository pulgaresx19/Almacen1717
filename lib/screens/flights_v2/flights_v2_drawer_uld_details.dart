import 'package:flutter/material.dart';
import 'flights_v2_uld_view_body.dart';
import 'flights_v2_uld_edit_body.dart';
import 'flights_v2_uld_print_preview.dart';

class FlightsV2UldDetailsDrawer extends StatefulWidget {
  final Map<String, dynamic> uld;
  final Map<String, dynamic> flight;
  final bool dark;
  final List<dynamic> ulds;
  final VoidCallback? onRefresh;

  const FlightsV2UldDetailsDrawer({
    super.key,
    required this.uld,
    required this.flight,
    required this.dark,
    required this.ulds,
    this.onRefresh,
  });

  @override
  State<FlightsV2UldDetailsDrawer> createState() => _FlightsV2UldDetailsDrawerState();
}

class _FlightsV2UldDetailsDrawerState extends State<FlightsV2UldDetailsDrawer> {
  bool _isEditing = false;

  void _handleClose() {
    Navigator.pop(context);
  }
  void _handlePrint() {
    showUldPrintPreviewDialog(context, widget.flight, [widget.uld], widget.dark);
  }

  void _handleSaveSuccess() {
    setState(() {
      _isEditing = false;
    });
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
    Navigator.pop(context); // Close the drawer completely after saving
  }

  @override
  Widget build(BuildContext context) {
    final bgDrawer = widget.dark ? const Color(0xFF0f172a) : Colors.white;

    return Container(
      width: 550,
      color: bgDrawer,
      child: _isEditing
          ? FlightsV2UldEditBody(
              uld: widget.uld,
              flight: widget.flight,
              dark: widget.dark,
              ulds: widget.ulds,
              onCancel: () {
                setState(() {
                  _isEditing = false;
                });
              },
              onSaveSuccess: _handleSaveSuccess,
            )
          : FlightsV2UldViewBody(
              uld: widget.uld,
              dark: widget.dark,
              onEdit: () {
                setState(() {
                  _isEditing = true;
                });
              },
              onPrint: _handlePrint,
              onClose: _handleClose,
            ),
    );
  }
}
