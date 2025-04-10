import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:readybill/components/color_constants.dart';

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
      glowColor: green2,
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
          color: green2,
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: const Icon(
          Icons.mic,
          color: black,
          size: 25,
        ),
      ),
    );
  }
}
