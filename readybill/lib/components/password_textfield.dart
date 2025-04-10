import 'package:flutter/material.dart';
import 'package:readybill/components/color_constants.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator validator;
  final FocusNode focusNode;

  const PasswordTextField(
      {super.key,
      required this.controller,
      required this.label,
      required this.validator,
      required this.focusNode});

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool obscureText = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: widget.validator,
      controller: widget.controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                obscureText = !obscureText;
              });
            },
            icon: obscureText == true
                ? const Icon(Icons.visibility_off)
                : const Icon(Icons.visibility)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: Color(0xffbfbfbf),
            width: 3.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: green2,
            width: 3.0,
          ),
        ),
        hintText: widget.label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
