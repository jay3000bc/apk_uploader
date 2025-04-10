import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/color_constants.dart';

import 'package:readybill/pages/login_page.dart';
import 'package:readybill/pages/subscriptions.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  bool isLoading = false;
  bool maintainMRP = false;
  bool showMRPInInvoice = false;
  bool maintainStock = false;
  bool showHSNSACCode = false;
  bool showHSNSACCodeInInvoice = false;

  Future<void> _fetchUserPreferences() async {
    setState(() {
      isLoading = true;
    });

    // Measure the starting time
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    // Make API call to fetch user preferences
    const String apiUrl = '$baseUrl/user-preferences';
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$apiKey',
    });
    var jsonData = jsonDecode(response.body);
    //
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final preferencesData = jsonData['data'];
      setState(() {
        maintainMRP = preferencesData['preference_mrp'] == 1 ? true : false;
        showMRPInInvoice =
            preferencesData['preference_mrp_invoice'] == 1 ? true : false;
        maintainStock =
            preferencesData['preference_quantity'] == 1 ? true : false;
        showHSNSACCode = preferencesData['preference_hsn'] == 1 ? true : false;
        showHSNSACCodeInInvoice =
            preferencesData['preference_hsn_invoice'] == 1 ? true : false;
      });
    } else if (response.statusCode == 403 &&
        jsonData['message'] == 'No subscription found for the shop.') {
      showDialog(
          context: context,
          builder: (context) {
            return customAlertBox(
                title: "No Subscription Found",
                content:
                    "No valid subscription found for the shop.\nPress 'OK' to get a new subscription.",
                actions: [
                  customElevatedButton("OK", green2, white, () {
                    navigatorKey.currentState!.pop();
                    navigatorKey.currentState!.push(CupertinoPageRoute(
                        builder: (context) => const Subscriptions()));
                  }),
                  customElevatedButton("Cancel", red, white, () {
                    navigatorKey.currentState!.pop();
                  })
                ]);
          });
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return customAlertBox(
            title: 'Error',
            content:
                'Error while fetching saved preferences. Please login and try again.',
            actions: <Widget>[
              customElevatedButton(
                'Login',
                green2,
                white,
                () {
                  navigatorKey.currentState?.pushReplacement(
                    CupertinoPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
              customElevatedButton(
                'Cancel',
                red,
                white,
                () {
                  navigatorKey.currentState?.pop();
                },
              ),
            ],
          );
        },
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveUserPreferences() async {
    setState(() {
      isLoading = true;
    });
    if (showHSNSACCode == false) {
      showHSNSACCodeInInvoice = false;
    }
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();

    const String apiUrl = '$baseUrl/prefernce';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'auth-key': '$apiKey',
      },
      body: jsonEncode({
        'preference_mrp': maintainMRP ? 1 : 0,
        'preference_mrp_invoice': showMRPInInvoice ? 1 : 0,
        'preference_quantity': maintainStock ? 1 : 0,
        'preference_hsn': showHSNSACCode ? 1 : 0,
        'preference_hsn_invoice': showHSNSACCodeInInvoice ? 1 : 0,
      }),
    );

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return customAlertBox(
            title: 'Success',
            content: 'User preferences updated successfully.',
            actions: <Widget>[
              customElevatedButton('OK', green2, white, () {
                navigatorKey.currentState?.pop();
              }),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return customAlertBox(
            title: 'Error',
            content: 'Failed to update user preferences.',
            actions: <Widget>[
              customElevatedButton('OK', green2, white, () {
                navigatorKey.currentState?.pop();
              }),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // _fetchUserPreferences();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fetchUserPreferences());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Preferences",[]),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  green2,
                ), // Change color here
              ), // Show loading indicator
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    buildCheckbox('Do you maintain MRP?', maintainMRP, (value) {
                      setState(() {
                        maintainMRP = value!;
                      });
                    }),
                    buildCheckbox(
                        'Do you want to show MRP in invoice?', showMRPInInvoice,
                        (value) {
                      setState(() {
                        showMRPInInvoice = value!;
                      });
                    }),
                    buildCheckbox(
                      'Do you want to maintain stock?',
                      maintainStock,
                      (value) {
                        setState(() {
                          maintainStock = value!;
                        });
                      },
                    ),
                    buildCheckbox(
                      'Do you want HSN/ SAC code?',
                      showHSNSACCode,
                      (value) {
                        setState(() {
                          showHSNSACCode = value!;
                        });
                      },
                    ),
                    showHSNSACCode == true
                        ? buildCheckbox(
                            'Do you want to show HSN/ SAC code \nin invoice?',
                            showHSNSACCodeInInvoice,
                            (value) {
                              setState(() {
                                showHSNSACCodeInInvoice = value!;
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 20),
                    customElevatedButton("Save Changes", green2, white, () {
                      _saveUserPreferences();
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildCheckbox(
      String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          activeColor: green2,
          value: value,
          onChanged: onChanged,
        ),
        Text(title),
      ],
    );
  }
}
