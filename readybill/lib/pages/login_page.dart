import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/country_selector_prefix.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/pages/add_phone_number_page.dart';
import 'package:readybill/pages/add_shop_details_page.dart';
import 'package:readybill/pages/forgot_password_page.dart';
import 'package:readybill/pages/home_page.dart';

import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/country_code_provider.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';

import 'package:readybill/services/local_database_2.dart';
import 'package:readybill/services/result.dart';
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
  final LocalDatabase2 _localDatabase = LocalDatabase2.instance;
  bool isObscure = true;
  final _loginFormKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _phoneNumberFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
    _phoneNumberFocusNode.requestFocus();
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
      content = "Welcome to ReadyBill";

      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const HomePage()),
      );
    } else if (response['status'] == 'failed' &&
        response['message'] == 'Validation Error!') {
      title = "Validation Error";
      content = "Please check the following errors:\n";

      // Loop through validation errors
      Map<String, dynamic> errors = response['data'][0];
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
      title = "ERROR";
      content = response['message'];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return customAlertBox(
          title: title,
          content: content,
          actions: [
            customElevatedButton("OK", green, white, () {
              navigatorKey.currentState?.pop();
            })
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: black,
      drawerEnableOpenDragGesture: false, // Disable swipe to open drawer
      body: Form(
        key: _loginFormKey,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: screenHeight * 0.05,
                left: screenWidth * 0.25,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: Image.asset(
                    'assets/man-phone-green.png',
                    width: screenWidth * 0.8,
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.35,
                left: screenWidth * 0.1,
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 35,
                    fontFamily: 'Roboto-Bold',
                    fontWeight: FontWeight.w900,
                    color: white,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Positioned(
                bottom: screenHeight * 0.1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        height: screenHeight * 0.45,
                        width: screenWidth * 0.9,
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 30),
                                TextFormField(
                                  cursorColor: green,
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
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2),
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: phoneNumberController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    errorStyle: const TextStyle(color: red),
                                    prefixIcon: CountrySelectorPrefix(
                                      provider:
                                          Provider.of<CountryCodeProvider>(
                                                  context,
                                                  listen: false)
                                              .setloginPageCountryCode,
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                      color: green,
                                    )),
                                    filled: true,
                                    fillColor: white,
                                    hintText: 'Mobile Number',
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(7.0),
                                      ),
                                      borderSide: BorderSide.none,
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
                                  style: const TextStyle(
                                      letterSpacing: 2,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  controller: passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: isObscure,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isObscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color:
                                            const Color.fromARGB(255, 0, 0, 0),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isObscure = !isObscure;
                                        });
                                      },
                                    ),
                                    errorStyle: const TextStyle(color: red),
                                    filled: true,
                                    fillColor: white,
                                    hintText: 'Password',
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(7.0),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                                const ForgotPasswordPage(
                                                  smsType: "forgot_password",
                                                )));
                                  },
                                  child: const Text(
                                    'Forgot your password?',
                                    style: TextStyle(
                                      color: green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_loginFormKey.currentState!
                                          .validate()) {
                                        EasyLoading.show();
                                        try {
                                          String phoneNumberSt =
                                              phoneNumberController.text;
                                          String password =
                                              passwordController.text;
                                          int? phoneNumInt =
                                              int.tryParse(phoneNumberSt);

                                          Map<String, dynamic> response =
                                              await loginUser(
                                                  phoneNumInt!, password);
                                          EasyLoading.dismiss();

                                          if (response['status'] == 1 ||
                                              response['status'] ==
                                                  'subscription-failed') {
                                            APIService
                                                .getUserDetailsWithoutDialog(
                                                    response['data'][0]
                                                        ['token'],
                                                    response['data'][0]
                                                        ['api_key']);
                                            storeFcmToken(
                                                response['data'][0]['token'],
                                                response['data'][0]['api_key']);
                                            await storeTokenAndUser(
                                                response['data'][0]['token'],
                                                response['data'][0]['user'],
                                                response['data'][0]['api_key']);
                                            navigatorKey.currentState!
                                                .pushReplacement(
                                                    CupertinoPageRoute(
                                                        builder: (context) =>
                                                            const HomePage()));
                                          } else if (response['status'] ==
                                                  'failed' &&
                                              response['message'] ==
                                                  'Validation Error!') {
                                            // Validation error, display error messages
                                            Map<String, dynamic> errors =
                                                response['data'][0];
                                            errors.forEach((field, messages) {
                                              // You can display these error messages to the user
                                            });
                                          } else if (response['status'] ==
                                                  'failed' &&
                                              response['message'] ==
                                                  'Invalid credentials') {
                                            // Invalid credentials error, display error message
                                            debugPrint('Invalid credentials');
                                            // You can display this error message to the user
                                          } else {
                                            debugPrint(
                                                'Unexpected response: $response');
                                          }
                                        } catch (e) {
                                          // Handle other errors
                                          Result.error(
                                              "Book list not available");
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(15.0),
                                      backgroundColor: green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: white,
                                        fontFamily: 'Roboto-Regular',
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account?",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextButton(
                                        onPressed: () {
                                          navigatorKey.currentState?.push(
                                            CupertinoPageRoute(
                                              builder: (context) =>
                                                  const AddPhoneNumberPage(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Register Now',
                                          style: TextStyle(color: green),
                                        ))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  storeFcmToken(token, apiKey) async {
    print('storing fcm token');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fcmToken = prefs.getString('fcmToken') ?? '';
    print('fcmtoken: $fcmToken');
    var response = await http.post(Uri.parse('$baseUrl/set-device-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_token': fcmToken,
        }));

    print(response.body);
  }

  Future<Map<String, dynamic>> loginUser(
      int phoneNumber, String password) async {
    print(Provider.of<CountryCodeProvider>(context, listen: false)
        .loginPageCountryCode);
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'YourApp/1.0',
      },
      body: jsonEncode({
        "mobile": phoneNumber,
        "password": password,
        "country_code": Provider.of<CountryCodeProvider>(context, listen: false)
            .loginPageCountryCode
      }),
    );

    print(response.statusCode);

    if (response.statusCode == 200) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        _localDatabase.clearTable();
        _localDatabase.fetchDataAndStoreLocally();

        if (timer.tick == 1) {
          timer.cancel();
        }
      });

      final Map<String, dynamic> responseData = json.decode(response.body);

      return responseData;
    } else if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      // print();

      navigatorKey.currentState?.push(
        CupertinoPageRoute(
          builder: (context) => AddShopDetailsPage(
            userID: responseData['data'][0]['user_id'].toString(),
          ),
        ),
      );
      return json.decode(response.body);
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
            errorResponse['message'] = 'Validation Error!';

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
      String token, Map<String, dynamic> userData, String apiKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // print(' apiKey in storetokenanduser: $apiKey');
    // print(' userdata in storetokenanduser: $userData');
    print('token in storetokenanduser: $token');
    await prefs.setString('token', token);
    print('token saved');
    await prefs.setString('user', userData.toString());
    await prefs.setString('auth-key', apiKey);
    print('apikey saved');
  }
}
