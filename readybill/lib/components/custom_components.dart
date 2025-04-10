import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/country_selector_prefix.dart';
import 'package:readybill/services/api_services.dart';
import 'package:http/http.dart' as http;

getCountryCode() async {
  var apiKey = await APIService.getXApiKey();
  var token = await APIService.getToken();

  var response = await http.get(Uri.parse('$baseUrl/countries-json'),
      headers: {'token': '$token', 'auth-key': '$apiKey'});

  print('getcountrycode response: ${response.body}');
  List<dynamic> data = json.decode(response.body);

  // Convert List<dynamic> to List<Map<String, dynamic>>
  return data.map((country) => country as Map<String, dynamic>).toList();
}

InputDecoration customTfInputDecoration(String hintText) {
  return InputDecoration(
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
    hintText: hintText,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );
}

InputDecoration disabledTfInputDecoration(String hintText) {
  return InputDecoration(
    filled: true,
    fillColor: lightGrey,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    hintText: hintText,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );
}

InputDecoration phoneNumberInputDecoration(
    String hintText, Function provider, String initialCountryCode) {
  return InputDecoration(
    prefixIcon: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: CountrySelectorPrefix(
        provider: provider,
        initialCountryCode: initialCountryCode,
      ),
    ),
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
    hintText: hintText,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );
}

ElevatedButton customElevatedButton(String text, Color backgroundColor,
    Color textColor, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(textColor),
        backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
        shape: WidgetStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        )),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Roboto-Regular',
      ),
    ),
  );
}

InputDecoration customTfDecorationWithSuffix(
    String hintText, Widget? suffix, FocusNode focusNode) {
  return InputDecoration(
    hintText: hintText,
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
    suffixIcon: suffix != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8.0),
                  bottomRight: Radius.circular(8.0)),
              color: focusNode.hasFocus ? green2 : darkGrey,
            ),
            child: suffix,
          )
        : null,
  );
}

customAppBar(String title, List<Widget>? actions) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
          fontFamily: 'Roboto-Regular', fontWeight: FontWeight.w500),
    ),
    backgroundColor: green2,
    actions: actions ?? [],
  );
}

customToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 1,
      backgroundColor: green2,
      textColor: black,
      fontSize: 16.0);
}

customAlertBox(
    {required String title,
    required String content,
    required List<Widget> actions}) {
  return AlertDialog(
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto-Regular',
      ),
      textAlign: TextAlign.center,
    ),
    content: Text(
      content,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto-Regular',
      ),
      textAlign: TextAlign.center,
    ),
    actions: actions,
    actionsAlignment: MainAxisAlignment.spaceEvenly,
  );
}

labeltext(String label) {
  return Text(
    label,
    style: const TextStyle(
        color: black,
        fontFamily: 'Roboto-Regular',
        fontWeight: FontWeight.bold,
        fontSize: 16),
  );
}
