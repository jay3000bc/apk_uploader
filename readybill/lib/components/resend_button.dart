import 'dart:async';

import 'package:flutter/material.dart';
import 'package:readybill/components/color_constants.dart';

class ResendButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final double fontSize;
  final Color textColor;
  final FontWeight fontWeight;
  final String fontFamily;
  final int timerDurationSeconds;

  const ResendButton({
    super.key,
    required this.onPressed,
    this.text = 'Resend OTP',
    this.fontSize = 16,
    this.textColor = green2,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'Roboto-Regular',
    this.timerDurationSeconds = 60, // Default 1 minute
  });

  @override
  State<ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<ResendButton> {
  late Timer _timer;
  int _currentSeconds = 0;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _currentSeconds = widget.timerDurationSeconds;
      _isEnabled = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          _isEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  String get _buttonText {
    if (!_isEnabled) {
      return 'Resend in $_currentSeconds';
    }
    return widget.text;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _handlePress() {
    widget.onPressed();
    startTimer(); // Reset timer after button press
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isEnabled ? _handlePress : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        _buttonText,
        style: TextStyle(
          color: _isEnabled ? widget.textColor : Colors.grey,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
        ),
      ),
    );
  }
}
