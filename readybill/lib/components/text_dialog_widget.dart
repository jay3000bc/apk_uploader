import 'package:flutter/material.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';

Future showTextDialog(context, {title, value}) => showDialog(
    context: context,
    builder: (context) => TextDialogWidget(
          title: title,
          value: value,
        ));

class TextDialogWidget extends StatefulWidget {
  final String title;
  final String value;
  const TextDialogWidget({super.key, required this.title, required this.value});

  @override
  State<TextDialogWidget> createState() => _TextDialogWidgetState();
}

class _TextDialogWidgetState extends State<TextDialogWidget> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto-Regular',
        ),
        textAlign: TextAlign.center,
      ),
      content: TextField(
        controller: controller,
        decoration: customTfInputDecoration(widget.value),
      ),
      actions: [
        customElevatedButton('Done', green2, white, () {
          Navigator.of(context).pop(controller.text);
        }),
      ],
    );
  }
}
