import 'package:flutter/material.dart';

class RefundBillItemProvider extends ChangeNotifier {
  List<Map<String, dynamic>> refundItemForBillRows = [];

  // Method to add an item
  void addItem(Map<String, dynamic> item) {
    refundItemForBillRows.add(item);
    notifyListeners(); // Notify all listeners about the change
  }

  // Method to remove an item
  void removeItem(int index) {
    refundItemForBillRows.removeAt(index);
    notifyListeners();
  }

  // Method to clear the list
  void clearItems() {
    refundItemForBillRows.clear();
    notifyListeners();
  }
}
