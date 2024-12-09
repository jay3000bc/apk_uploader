import 'package:flutter/material.dart';

class HomeBillItemProvider extends ChangeNotifier {
  List<Map<String, dynamic>> homeItemForBillRows = [];
  int? quantity = 0;
  String unit = 'Unit';

  // Method to add an item
  void addItem(Map<String, dynamic> item) {
    homeItemForBillRows.add(item);
    notifyListeners(); // Notify all listeners about the change
  }

  void assignQuantity(int qty) {
    quantity = qty;
    print('Quantity: $quantity');
    notifyListeners();
  }

  void assignUnit(String ut) {
    unit = ut;
    print("Unit: $unit");
    notifyListeners();
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
