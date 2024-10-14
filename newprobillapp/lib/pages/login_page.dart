import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:newprobillapp/components/api_constants.dart';
import 'package:newprobillapp/pages/forgot_password_page.dart';
import 'package:newprobillapp/pages/home_page.dart';
import 'package:newprobillapp/pages/sign_up_page.dart';
import 'package:newprobillapp/services/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _phoneNumberFocusNode.addListener(() {
      setState(() {}); // Rebuilds the widget when focus changes
    });
    _passwordFocusNode.addListener(() {
      setState(() {}); // Rebuilds the widget when focus changes
    });
  }

  @override
  void dispose() {
    // Dispose the controllers to free up resources when the widget is disposed
    phoneNumberController.dispose();
    passwordController.dispose();
    _passwordFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
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
        MaterialPageRoute(builder: (context) => const HomePage()),
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
          actions: [
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  const Color.fromRGBO(243, 203, 71, 1),
                ),
                // Change color here
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
    return phoneNumberController.text.isNotEmpty &&
        (phoneNumberController.text.length < 10 ||
            phoneNumberController.text.length > 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
      drawerEnableOpenDragGesture: false, // Disable swipe to open drawer
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.only(top: 50)),
              Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.43,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset(
                      'assets/man.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.33,
                    left: MediaQuery.of(context).size.width * 0.2,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.08,
                      child: Image.asset('assets/probill.png'),
                    ),
                  ),
                ],
              ),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width + 1000,
                      height: MediaQuery.of(context).size.width + 40,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30)),
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 30),
                          TextFormField(
                            focusNode: _phoneNumberFocusNode,
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
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.phone,
                                color: _phoneNumberFocusNode.hasFocus
                                    ? const Color.fromRGBO(243, 203, 71, 1)
                                    : Colors.black,
                              ),
                              labelText: 'Mobile Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
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
                          const SizedBox(height: 15),
                          TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Minimum 8 Charecters';
                              }
                              return null;
                            },
                            controller: passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock,
                                color: _passwordFocusNode.hasFocus
                                    ? const Color.fromRGBO(243, 203, 71, 1)
                                    : Colors.black,
                              ),
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordPage()));
                                },
                                child: const Text(
                                  'Forgot your password?',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  EasyLoading.show(status: 'Logging in...');
                                  try {
                                    String phoneNumberSt =
                                        phoneNumberController.text;
                                    String password = passwordController.text;
                                    int? phoneNumInt =
                                        int.tryParse(phoneNumberSt);

                                    Map<String, dynamic> response =
                                        await loginUser(phoneNumInt!, password);
                                    EasyLoading.dismiss();

                                    if (response['status'] == 'success') {
                                      // Successful login
                                      await storeTokenAndUser(
                                          response['data']['token'],
                                          response['data']['user']);
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
                                      debugPrint(
                                          'Unexpected response: $response');
                                    }
                                  } catch (e) {
                                    // Handle other errors
                                    Result.error("Book list not available");
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(15.0),
                                backgroundColor:
                                    const Color.fromRGBO(243, 203, 71, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text(
                                'LOGIN',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?"),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SignUpPage()));
                                  },
                                  child: const Text('Sign Up'))
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        MaterialPageRoute(builder: (context) => const HomePage()),
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

  Future<void> storeTokenAndUser(
      String token, Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', userData.toString());
  }
}
