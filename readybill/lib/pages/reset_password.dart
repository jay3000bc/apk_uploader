import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/services/api_services.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  final String phoneNumber;

  const ResetPasswordPage({super.key, required this.phoneNumber});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordFormKey = GlobalKey<FormState>();

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void resetPassword() async {
    var token = await APIService.getToken();
    var authKey = await APIService.getXApiKey();
    var response =
        await http.post(Uri.parse("$baseUrl/update-password"), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$authKey',
    }, body: {
      'mobile': widget.phoneNumber,
      'password': _newPasswordController.text,
      'password_confirmation': _confirmPasswordController.text,
    });

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: 'Password reset successfully');
      Navigator.pushReplacement(
          context, CupertinoPageRoute(builder: (context) => const LoginPage()));
    } else {
      Fluttertoast.showToast(
          msg: 'Password reset failed. Please try again later');
    }
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
        key: _passwordFormKey,
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
                  'Reset Password',
                  style: TextStyle(
                    fontFamily: 'Roboto-Regular',
                    fontSize: 35,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        value.length < 8) {
                                      return 'Length must be atleast 8 characters';
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                  controller: _newPasswordController,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                      color: green,
                                    )),
                                    filled: true,
                                    fillColor: white,
                                    label: Text('Enter new password',
                                        style: TextStyle(
                                          fontFamily: 'Roboto-Regular',
                                        )),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(7.0),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                TextFormField(
                                  cursorColor: green,
                                  validator: (value) {
                                    if (_newPasswordController.text != value) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  controller: _confirmPasswordController,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                      color: green,
                                    )),
                                    filled: true,
                                    fillColor: white,
                                    label: Text('Confirm password'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(7.0),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_passwordFormKey.currentState!
                                          .validate()) {
                                        resetPassword();
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
                                      'Confirm',
                                      style: TextStyle(
                                        fontFamily: 'Roboto-Regular',
                                        fontSize: 16,
                                        color: white,
                                      ),
                                    ),
                                  ),
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
}
