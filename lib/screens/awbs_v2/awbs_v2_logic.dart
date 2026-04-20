import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AwbsV2Logic extends ChangeNotifier {
  final Set<String> selectedAwbIds = {};
  List<Map<String, dynamic>> allAwbs = [];
  List<Map<String, dynamic>> displayedAwbs = [];
  String searchQuery = '';
  
  void setAwbs(List<Map<String, dynamic>> awbs) {
    allAwbs = awbs;
    _filterAwbs();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    _filterAwbs();
  }

  void _filterAwbs() {
    if (searchQuery.isEmpty) {
      displayedAwbs = List.from(allAwbs);
    } else {
      final terms = searchQuery.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
      displayedAwbs = allAwbs.where((u) {
        final awbSearch = u['awb_number']?.toString().toLowerCase() ?? '';
        final statusSearch = 'waiting'; // Simplification for now
        final combinedString = '$awbSearch $statusSearch';
        return terms.every((term) => combinedString.contains(term));
      }).toList();
    }
    notifyListeners();
  }

  void toggleSelection(String id, bool selected) {
    if (selected) {
      selectedAwbIds.add(id);
    } else {
      selectedAwbIds.remove(id);
    }
    notifyListeners();
  }

  void toggleAll(bool selected) {
    if (selected) {
      selectedAwbIds.addAll(displayedAwbs.map((e) => e['id'].toString()));
    } else {
      selectedAwbIds.clear();
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    for (var id in selectedAwbIds) {
      await Supabase.instance.client.from('awbs').delete().eq('id', id);
    }
    selectedAwbIds.clear();
    notifyListeners();
  }
}
