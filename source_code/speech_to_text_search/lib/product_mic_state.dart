import 'package:flutter/material.dart';

class MicState extends ChangeNotifier {
  bool _isListeningMic = false;

  bool get isListeningMic => _isListeningMic;

  void setListeningMic(bool value) {
    _isListeningMic = value;
    notifyListeners();
  }
}
