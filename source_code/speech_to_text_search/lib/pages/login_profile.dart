// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/Service/local_database.dart';
import 'package:speech_to_text_search/Service/result.dart';
import 'package:speech_to_text_search/pages/search_app.dart';
import 'package:speech_to_text_search/pages/sign_up_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
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

  void showApiResponseDialog(
      BuildContext context, Map<String, dynamic> response) {
    String title;
    String content;

    // Determine title and content based on the response
    if (response['status'] == 'success') {
      title = "Login Successful";
      content = "Welcome to Probill";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchApp()),
      );
    } else if (response['status'] == 'failed' &&
        response['message'] == 'Validation Error!') {
      title = "Validation Error";
      content = "Please check the following errors:\n";

      // Loop through validation errors
      Map<String, dynamic> errors = response['data'];
      errors.forEach((field, messages) {
        content += "$field: ${messages[0]}\n";
      });
    } else if (response['status'] == 'failed' &&
        response['message'] == 'Invalid credentials') {
      title = "Invalid Credentials";
      content = "Please check your mobile number and password.";
    } else if (response['status'] == 'failed' &&
        response['message'] == 'User Not Found') {
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
                  const Color.fromRGBO(243, 203, 71, 1),
                ), // Change color here
              ),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
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
    return phoneNumberController.text != null &&
        phoneNumberController.text.isNotEmpty &&
        (phoneNumberController.text.length < 10 ||
            phoneNumberController.text.length > 10);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
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
                    style: const ButtonStyle(

                        // Change color here
                        ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
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
          return Future.value();
        } else {
          return Future.value();
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32.0),
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
                        const SizedBox(height: 22.0),
                        TextFormField(
                          style: const TextStyle(fontSize: 30.0),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 10 ||
                                value.length > 10 ||
                                int.tryParse(value) == null) {
                              return 'Must be 10-digit Number';
                            }

                            return null;
                          },
                          controller: phoneNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Mobile Number',
                            hintStyle: TextStyle(fontSize: 30.0),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // Display the error message below the input field
                        if (_isPhoneNumberErrorVisible())
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Must be a 10-digit number',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          style: const TextStyle(fontSize: 30.0),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Minimum 8 Charecters';
                            }
                            return null;
                          },
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(fontSize: 30.0),
                            suffixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Handle Forgot Password
                            },
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(
                                color: Color.fromRGBO(232, 90, 79, 1),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              EasyLoading.show(status: 'Logging in...');
                              try {
                                // Retrieve user input from text fields
                                String phoneNumberSt =
                                    phoneNumberController.text;
                                String password = passwordController.text;
                                int? phoneNumInt = int.tryParse(phoneNumberSt);

                                // Validate the input if needed

                                // Call the login function with user input
                                Map<String, dynamic> response =
                                    await loginUser(phoneNumInt!, password);
                                EasyLoading.dismiss();

                                // Show dialog based on the API response

                                // Check the status in the API response
                                if (response['status'] == 'success') {
                                  // Successful login
                                  await storeTokenAndUser(
                                      response['data']['token'],
                                      response['data']['user']);
                                  // Navigate to the next screen, for example:
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(builder: (context) => ()),
                                  // );
                                  LocalDatabase.instance.clearTable();
                                  LocalDatabase.instance
                                      .fetchDataAndStoreLocally();
                                } else if (response['status'] == 'failed' &&
                                    response['message'] ==
                                        'Validation Error!') {
                                  // Validation error, display error messages
                                  Map<String, dynamic> errors =
                                      response['data'];
                                  errors.forEach((field, messages) {
                                    // You can display these error messages to the user
                                  });
                                } else if (response['status'] == 'failed' &&
                                    response['message'] ==
                                        'Invalid credentials') {
                                  // Invalid credentials error, display error message
                                  debugPrint('Invalid credentials');
                                  // You can display this error message to the user
                                } else {
                                  // Handle other cases or unexpected responses
                                  debugPrint('Unexpected response: $response');
                                }
                              } catch (e) {
                                // Handle other errors
                                Result.error("Book list not available");
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32.0, vertical: 16.0),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen()), // Change to AddItemScreen()
                                );
                              },
                              child: const Text(
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
  Future<Map<String, dynamic>> loginUser(
      int phoneNumber, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'YourApp/1.0',
      },
      body: jsonEncode({"mobile": phoneNumber, "password": password}),
    );
    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchApp()),
      );
      // Successful login
      final Map<String, dynamic> responseData = json.decode(response.body);
      // No need to show any dialog, just return the response data
      return responseData;
    } else {
      // Handle non-200 status codes
      debugPrint('Failed to login. Status code: ${response.statusCode}');
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
          errorResponse['message'] =
              'Failed to login. Status code: ${response.statusCode}';
          break;
      }

      // Display error dialog
      showApiResponseDialog(context, errorResponse);
      // Return the error response for further handling in the frontend
      return errorResponse;
    }
  }
}

Future<void> storeTokenAndUser(
    String token, Map<String, dynamic> userData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
  await prefs.setString('user', userData.toString());
}
