import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/search_app.dart';
import 'package:speech_to_text_search/sign_up_form.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Dispose the controllers to free up resources when the widget is disposed
    phoneNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showApiResponseDialog(BuildContext context, Map<String, dynamic> response) {
    String title;
    String content;

    // Determine title and content based on the response
    if (response['status'] == 'success') {
      title = "Login Successful";
      content = "Welcome to Probill";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SearchApp()),
      );
    } else if (response['status'] == 'failed' && response['message'] == 'Validation Error!') {
      title = "Validation Error";
      content = "Please check the following errors:\n";

      // Loop through validation errors
      Map<String, dynamic> errors = response['data'];
      errors.forEach((field, messages) {
        content += "$field: ${messages[0]}\n";
      });
    } else if (response['status'] == 'failed' && response['message'] == 'Invalid credentials') {
      title = "Invalid Credentials";
      content = "Please check your mobile number and password.";
    } else if (response['status'] == 'failed' && response['message'] == 'User Not Found') {
      title = "User Not Found";
      content = "Please check your mobile number and try again.";
    } else {
      title = "Unexpected Response";
      content = "An unexpected response was received. Please try again.";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromRGBO(243, 203, 71, 1),
                ), // Change color here
              ),
              child: Text(
                "OK",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool _isPhoneNumberErrorVisible() {
    return phoneNumberController.text != null && phoneNumberController.text.isNotEmpty && (phoneNumberController.text.length < 10 || phoneNumberController.text.length > 10);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final value = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text(
                  'Alert',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 59, 59),
                  ),
                ),
                content: const Text('Do You Want to Exit'),
                actions: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color.fromRGBO(243, 203, 71, 1),
                      ), // Change color here
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color.fromRGBO(243, 71, 71, 1),
                      ), // Change color here
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Exit',
                    ),
                  ),
                ],
              );
            });
        if (value != null) {
          return Future.value(value);
        } else {
          return Future.value(false);
        }
      },
      child: Scaffold(
        backgroundColor: Color.fromRGBO(243, 203, 71, 1),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 32.0),
                        SizedBox(
                          width: 350,
                          height: 350,
                          child: Image.asset('assets/man.png'),
                        ),
                        SizedBox(
                          width: 350,
                          height: 60,
                          child: Image.asset('assets/probill.png'),
                        ),
                        SizedBox(height: 22.0),
                        TextFormField(
                          style: TextStyle(fontSize: 30.0),
                          validator: (value) {
                            if (value == null || value.isEmpty || value.length < 10 || value.length > 10 || int.tryParse(value) == null) {
                              return 'Must be 10-digit Number';
                            }

                            return null;
                          },
                          controller: phoneNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Mobile Number',
                            hintStyle: TextStyle(fontSize: 30.0),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        // Display the error message below the input field
                        if (_isPhoneNumberErrorVisible())
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Must be a 10-digit number',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          style: TextStyle(fontSize: 30.0),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Minimum 8 Charecters';
                            }
                            return null;
                          },
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(fontSize: 30.0),
                            suffixIcon: Icon(Icons.lock),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Handle Forgot Password
                            },
                            child: Text(
                              'Forgot Password',
                              style: TextStyle(
                                color: Color.fromRGBO(232, 90, 79, 1),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              EasyLoading.show(status: 'Logging in...');
                              try {
                                // Retrieve user input from text fields
                                String phoneNumberSt = phoneNumberController.text;
                                String password = passwordController.text;
                                int? phoneNumInt = int.tryParse(phoneNumberSt);

                                // Validate the input if needed

                                // Call the login function with user input
                                Map<String, dynamic> response = await loginUser(phoneNumInt!, password);
                                EasyLoading.dismiss();

                                // Show dialog based on the API response

                                // Check the status in the API response
                                if (response['status'] == 'success') {
                                  // Successful login
                                  print('Token: ${response['data']['token']}');
                                  print('User: ${response['data']['user']}');

                                  await storeTokenAndUser(response['data']['token'], response['data']['user']);
                                  // Navigate to the next screen, for example:
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(builder: (context) => ()),
                                  // );
                                } else if (response['status'] == 'failed' && response['message'] == 'Validation Error!') {
                                  // Validation error, display error messages
                                  Map<String, dynamic> errors = response['data'];
                                  errors.forEach((field, messages) {
                                    print('$field: ${messages[0]}');
                                    // You can display these error messages to the user
                                  });
                                } else if (response['status'] == 'failed' && response['message'] == 'Invalid credentials') {
                                  // Invalid credentials error, display error message
                                  print('Invalid credentials');
                                  // You can display this error message to the user
                                } else {
                                  // Handle other cases or unexpected responses
                                  print('Unexpected response: $response');
                                }
                              } catch (e) {
                                // Handle other errors
                                print('Error: $e');
                              }
                            }
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SignUpScreen()), // Change to AddItemScreen()
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color.fromRGBO(232, 90, 79, 1),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // Assuming you have access to the context in this class
  // and showApiResponseDialog function is defined somewhere
  Future<Map<String, dynamic>> loginUser(int phoneNumber, String password) async {
    print('Preparing to make HTTP request');

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'YourApp/1.0',
      },
      body: jsonEncode({"mobile": phoneNumber, "password": password}),
    );

    print('HTTP request completed');

    print('Response status code: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SearchApp()),
      );
      // Successful login
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('Login successful. Response data: $responseData');
      // No need to show any dialog, just return the response data
      return responseData;
    } else {
      // Handle non-200 status codes
      print('Failed to login. Status code: ${response.statusCode}');

      // Prepare error response
      final Map<String, dynamic> errorResponse = {
        'status': 'failed',
        'message': 'Failed to login. Status code: ${response.statusCode}',
      };

      // Display error dialog based on status code
      switch (response.statusCode) {
        case 401:
          // Unauthorized
          errorResponse['message'] = 'Invalid credentials';
          break;
        case 403:
          // Forbidden
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData.containsKey('data')) {
            // Handle specific validation errors
            errorResponse['message'] = 'Validation Error!';
            // Construct a user-friendly message from the validation errors
            String errorMessage = '';
            responseData['data'].forEach((key, value) {
              errorMessage += '${value[0]}\n';
            });
            errorResponse['validationErrors'] = errorMessage;
          } else {
            errorResponse['message'] = 'Forbidden: ${responseData['message']}';
          }
          break;
        case 404:
          // Not Found
          errorResponse['message'] = 'User Not Found';
          break;
        default:
          // Handle other status codes
          errorResponse['message'] = 'Failed to login. Status code: ${response.statusCode}';
          break;
      }

      // Display error dialog
      showApiResponseDialog(context, errorResponse);
      // Return the error response for further handling in the frontend
      return errorResponse;
    }
  }
}

Future<void> storeTokenAndUser(String token, Map<String, dynamic> userData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
  await prefs.setString('user', userData.toString());
}
