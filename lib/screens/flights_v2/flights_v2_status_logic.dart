class FlightsV2StatusLogic {
  static String getUldStatus(Map<String, dynamic> uld) {
    bool isBreak = uld['is_break'] == true;

    if (isBreak) {
      // BREAK ULD
      if (uld['time_stored'] != null && uld['time_stored'].toString().isNotEmpty) {
        return 'Saved';
      }
      if (uld['time_checked'] != null && uld['time_checked'].toString().isNotEmpty) {
        return 'Checked';
      }
      if (uld['time_received'] != null && uld['time_received'].toString().isNotEmpty) {
        return 'Received';
      }
      return 'Waiting';
    } else {
      // NO-BREAK ULD
      if (uld['time_delivery'] != null && uld['time_delivery'].toString().isNotEmpty) {
        return 'Delivered';
      }
      if (uld['in_process'] == true || uld['in_process'] == 'true') {
        return 'In Process';
      }
      if (uld['time_received'] != null && uld['time_received'].toString().isNotEmpty) {
        return 'Received';
      }
      return 'Waiting';
    }
  }

  static String getAwbStatus(Map<String, dynamic> awbSplit) {
    final dd = awbSplit['data_delivery'];
    if (dd != null && (dd is Map ? dd.isNotEmpty : dd.toString().length > 4)) {
      return 'Delivered';
    }

    final dl = awbSplit['data_location'];
    if (dl != null && (dl is Map ? dl.isNotEmpty : dl.toString().length > 4)) {
      return 'Stored';
    }

    final dc = awbSplit['data_coordinator'];
    if (dc != null && (dc is Map ? dc.isNotEmpty : dc.toString().length > 4)) {
      return 'Checked';
    }

    return 'Pending';
  }
}
