// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/pages/drawer.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/pages/login_profile.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/components/navigation_bar.dart';
import 'package:speech_to_text_search/pages/search_app.dart';

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

  int _selectedIndex = 3;

  Future<void> _fetchUserPreferences() async {
    setState(() {
      isLoading = true;
    });

    // Measure the starting time
    var token = await APIService.getToken();

    // Make API call to fetch user preferences
    const String apiUrl = '$baseUrl/user-preferences';
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Authorization': 'Bearer $token',
    });
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
    } else {
      // Handle exceptions

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content:
                const Text('An error occurred. Please login and try again.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Redirect to login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('OK'),
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
    var token = await APIService.getToken();
    const String apiUrl = '$baseUrl/prefernce';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
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
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('User preferences updated successfully.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to update user preferences.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        // Navigate to NextPage when user tries to pop MyHomePage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchApp()),
        );
        // Return false to prevent popping the current route
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Preferences',
            style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          backgroundColor: const Color.fromRGBO(
              243, 203, 71, 1), // Change this color to whatever you desire
        ),
        drawer: const Sidebar(),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(243, 203, 71, 1),
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
                      buildCheckbox('Do you maintain MRP?', maintainMRP,
                          (value) {
                        setState(() {
                          maintainMRP = value!;
                        });
                      }),
                      buildCheckbox('Do you want to show MRP in invoice?',
                          showMRPInInvoice, (value) {
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
                      buildCheckbox(
                        'Do you want to show HSN/ SAC code \nin invoice?',
                        showHSNSACCodeInInvoice,
                        (value) {
                          setState(() {
                            showHSNSACCodeInInvoice = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _saveUserPreferences();
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromRGBO(243, 203, 71, 1),
                          ), // Change color here
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                    ],
                  ),
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
          activeColor: const Color.fromRGBO(243, 203, 71, 1),
          value: value,
          onChanged: onChanged,
        ),
        Text(title),
      ],
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: PreferencesPage(),
  ));
}
