import 'package:flutter/material.dart';

class QuantityMicState extends ChangeNotifier {
  bool _isListeningQuantity = false;

  bool get isListeningQuantity => _isListeningQuantity;

  void setListeningQuantity(bool value) {
    _isListeningQuantity = value;
    notifyListeners();
  }
}
