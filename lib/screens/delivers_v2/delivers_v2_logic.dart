import 'package:flutter/material.dart';

class DeliversV2Logic extends ChangeNotifier {
  final Set<String> selectedDeliverIds = {};
  List<Map<String, dynamic>> allDelivers = [];
  List<Map<String, dynamic>> displayedDelivers = [];
  String searchQuery = '';
  
  void setDelivers(List<Map<String, dynamic>> delivers) {
    allDelivers = delivers;
    _filterDelivers();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    _filterDelivers();
  }

  void _filterDelivers() {
    var items = List<Map<String, dynamic>>.from(allDelivers);

    items.sort((a, b) {
      final taStr = a['time']?.toString() ?? '';
      final tbStr = b['time']?.toString() ?? '';
      if (taStr.isEmpty && tbStr.isNotEmpty) return 1;
      if (taStr.isNotEmpty && tbStr.isEmpty) return -1;
      if (taStr.isEmpty && tbStr.isEmpty) return 0;
      
      final da = DateTime.tryParse(taStr) ?? DateTime(1970);
      final db = DateTime.tryParse(tbStr) ?? DateTime(1970);
      return da.compareTo(db);
    });

    if (searchQuery.isNotEmpty) {
      final terms = searchQuery.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
      items = items.where((u) {
         final comp = (u['company']?.toString() ?? '').toLowerCase();
         final dr = (u['driver_name']?.toString() ?? '').toLowerCase();
         final door = (u['door']?.toString() ?? '').toLowerCase();
         final pId = (u['id_pickup']?.toString() ?? '').toLowerCase();
         
         final combinedString = '$comp $dr $door $pId';
         return terms.every((term) => combinedString.contains(term));
      }).toList();
    }

    displayedDelivers = items;
    notifyListeners();
  }

  void toggleSelection(String id, bool selected) {
    if (selected) {
      selectedDeliverIds.add(id);
    } else {
      selectedDeliverIds.remove(id);
    }
    notifyListeners();
  }

  void toggleAll(bool selected) {
    if (selected) {
      selectedDeliverIds.addAll(displayedDelivers.map((e) => e['id_delivery'].toString()));
    } else {
      selectedDeliverIds.clear();
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedDeliverIds.clear();
    notifyListeners();
  }
}
