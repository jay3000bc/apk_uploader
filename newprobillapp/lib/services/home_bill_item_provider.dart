import 'package:flutter/material.dart';

class HomeBillItemProvider extends ChangeNotifier {
  List<Map<String, dynamic>> homeItemForBillRows = [];

  // Method to add an item
  void addItem(Map<String, dynamic> item) {
    homeItemForBillRows.add(item);
    notifyListeners(); // Notify all listeners about the change
  }

  // Method to remove an item
  void removeItem(int index) {
    homeItemForBillRows.removeAt(index);
    notifyListeners();
  }

  // Method to clear the list
  void clearItems() {
    homeItemForBillRows.clear();
    notifyListeners();
  }
}
