class FlightsV2StatusLogic {
  static String getUldStatus(Map<String, dynamic> uld) {
    bool isBreak = uld['is_break'] == true;

    if (isBreak) {
      // BREAK ULD
      if (uld['time_saved'] != null && uld['time_saved'].toString().isNotEmpty) {
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
      if ((uld['time_delivery'] != null && uld['time_delivery'].toString().isNotEmpty) ||
          (uld['time_deliver'] != null && uld['time_deliver'].toString().isNotEmpty) ||
          (uld['time-deliver'] != null && uld['time-deliver'].toString().isNotEmpty)) {
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

  static String getFlightStatus(Map<String, dynamic> flight) {
    if (flight['is_ready'] == true) {
      return 'Ready';
    } else if (flight['is_checked'] == true) {
      return 'Checked';
    } else if (flight['start_break'] != null && flight['start_break'].toString().isNotEmpty && flight['start_break'].toString() != 'null') {
      return 'Pending';
    } else if (flight['is_received'] == true) {
      return 'Received';
    }
    
    final st = flight['status']?.toString();
    if (st != null && st.trim().isNotEmpty && st != 'null') {
      return st;
    }
    
    return 'Waiting';
  }
}
