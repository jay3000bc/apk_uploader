import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readybill/components/api_constants.dart';

import 'package:readybill/components/color_constants.dart';

import 'package:http/http.dart' as http;
import 'package:readybill/pages/add_shop_details_page.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';

class AddPasswordPage extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  const AddPasswordPage(
      {super.key, required this.phoneNumber, required this.countryCode});

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();
  bool isPasswordObscure = true;
  bool isConfirmPasswordObscure = true;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  Widget _buildPasswordTF() {
    // Flag to toggle password visibility
    return TextFormField(
      focusNode: passwordFocusNode,
      // textCapitalization: TextCapitalization.sentences,
      controller: passwordController,
      obscureText: isPasswordObscure,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        errorStyle: const TextStyle(color: red),
        filled: true,
        fillColor: white,
        hintText: 'Password *',
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
          color: green,
        )),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordObscure ? Icons.visibility_off : Icons.visibility,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
          onPressed: () {
            setState(() {
              isPasswordObscure = !isPasswordObscure;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          passwordFocusNode.requestFocus();
          return 'Password is required';
        } else if (value.length < 8) {
          passwordFocusNode.requestFocus();
          return 'Password must be of atleast 8 characters';
        } else {
          return null;
        }
      },
    );
  }

  Widget _buildConfirmPasswordTF() {
    return TextFormField(
      focusNode: confirmPasswordFocusNode,
      obscureText: isConfirmPasswordObscure,
      // textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.visiblePassword,
      controller: confirmPasswordController,
      decoration: InputDecoration(
        errorStyle: const TextStyle(color: red),
        suffixIcon: IconButton(
          icon: Icon(
            isConfirmPasswordObscure ? Icons.visibility_off : Icons.visibility,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
          onPressed: () {
            setState(() {
              isConfirmPasswordObscure = !isConfirmPasswordObscure;
            });
          },
        ),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
          color: green,
        )),
        filled: true,
        fillColor: white,
        hintText: 'Confirm Password *',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          confirmPasswordFocusNode.requestFocus();
          return 'Password is required';
        } else if (value.length < 8) {
          confirmPasswordFocusNode.requestFocus();
          return 'Password must be of atleast 8 characters';
        } else if (value != passwordController.text) {
          confirmPasswordFocusNode.requestFocus();
          return 'Passwords do not match';
        } else {
          return null;
        }
      },
    );
  }

  Widget _buildSignUpBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          print('pressed');

          if (_passwordFormKey.currentState!.validate()) {
            var response = await http
                .post(Uri.parse("$baseUrl/register/create-user"), body: {
              'mobile': widget.phoneNumber,
              'password': passwordController.text,
              'password_confirmation': confirmPasswordController.text,
              'country_code': widget.countryCode,
              'shop_type': 'grocery',
            });

            var userID =
                jsonDecode(response.body)['data']['user']['user_id'].toString();

            if (response.statusCode == 200) {
              Fluttertoast.showToast(msg: 'User created successfully');
              navigatorKey.currentState?.push(CupertinoPageRoute(
                  builder: (context) => AddShopDetailsPage(userID: userID)));
            } else {}
          }
        },
        style: ElevatedButton.styleFrom(
          elevation: 5.0,
          backgroundColor: green,
          padding: const EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 1.5,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto-Regular',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: black,
      body: SizedBox(
        height: screenHeight,
        child: Stack(
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
              top: screenHeight * 0.30,
              left: screenWidth * 0.1,
              child: const Text(
                'Create Password',
                style: TextStyle(
                  fontSize: 35,
                  fontFamily: 'Roboto-Bold',
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.24,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      //dheight: screenHeight * 0.55,
                      width: screenWidth * 0.9,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: SingleChildScrollView(
                          child: Form(
                            key: _passwordFormKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 15),
                                _buildPasswordTF(),
                                const SizedBox(height: 15),
                                _buildConfirmPasswordTF(),
                                const SizedBox(
                                  height: 15,
                                ),

                                _buildSignUpBtn(),
                                // Added Logo Upload field
                              ],
                            ),
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
    );
  }
}
