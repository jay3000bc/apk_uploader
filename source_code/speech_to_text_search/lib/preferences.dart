import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/drawer.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/login_profile.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/search_app.dart';

class PreferencesPage extends StatefulWidget {
  @override
  _PreferencesPageState createState() => _PreferencesPageState();
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
    final startTime = DateTime.now();

    print("Starting API data fetching...");

    var token = await APIService.getToken();

    // Make API call to fetch user preferences
    final String apiUrl = '$baseUrl/user-preferences';
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Authorization': 'Bearer $token',
    });

    // Measure the ending time
    final endTime = DateTime.now();

    // Calculate and print the time taken
    final timeTaken = endTime.difference(startTime);
    print("API data fetched in ${timeTaken.inMilliseconds} milliseconds");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final preferencesData = jsonData['data'];

      setState(() {
        maintainMRP = preferencesData['preference_mrp'] == 1 ? true : false;
        showMRPInInvoice = preferencesData['preference_mrp_invoice'] == 1 ? true : false;
        maintainStock = preferencesData['preference_quantity'] == 1 ? true : false;
        showHSNSACCode = preferencesData['preference_hsn'] == 1 ? true : false;
        showHSNSACCodeInInvoice = preferencesData['preference_hsn_invoice'] == 1 ? true : false;
      });
    } else {
      // Handle exceptions

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred. Please login and try again.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Redirect to login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('OK'),
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
    final String apiUrl = '$baseUrl/api/prefernce';
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
      final jsonData = json.decode(response.body);
      // Handle success response
      print(jsonData);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('User preferences updated successfully.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      final jsonData = json.decode(response.body);
      // Handle error response
      print(jsonData);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to update user preferences.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserPreferences());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to NextPage when user tries to pop MyHomePage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchApp()),
        );
        // Return false to prevent popping the current route
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Preferences',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          backgroundColor: Color.fromRGBO(243, 203, 71, 1), // Change this color to whatever you desire
        ),
        drawer: Sidebar(),
        bottomNavigationBar: CustomNavigationBar(
          onItemSelected: (index) {
            // Handle navigation item selection
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedIndex: _selectedIndex,
        ),
        body: isLoading
            ? Center(
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
                      SizedBox(height: 30),
                      buildCheckbox('Do you maintain MRP?', maintainMRP, (value) {
                        setState(() {
                          maintainMRP = value!;
                        });
                      }),
                      buildCheckbox('Do you want to show MRP in invoice?', showMRPInInvoice, (value) {
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
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _saveUserPreferences();
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromRGBO(243, 203, 71, 1),
                          ), // Change color here
                        ),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
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

  Widget buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          activeColor: Color.fromRGBO(243, 203, 71, 1),
          value: value,
          onChanged: onChanged,
        ),
        Text(title),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PreferencesPage(),
  ));
}
