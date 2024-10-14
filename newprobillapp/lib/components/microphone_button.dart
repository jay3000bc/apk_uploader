import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';

class MicrophoneButton extends StatefulWidget {
  final bool isListening;
  const MicrophoneButton({super.key, required this.isListening});

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton> {
  @override
  Widget build(BuildContext context) {
    return AvatarGlow(
      animate: widget.isListening,
      glowColor: Colors.green,
      duration: const Duration(milliseconds: 1000),
      repeat: true,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: .26,
              color: Colors.white.withOpacity(.05),
            ),
          ],
          color: Colors.green,
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}
