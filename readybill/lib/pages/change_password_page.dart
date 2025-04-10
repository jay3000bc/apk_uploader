import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/password_textfield.dart';
import 'package:readybill/components/resend_button.dart';
import 'package:readybill/pages/login_page.dart';

import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/result.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;

class ChangePasswordPage extends StatefulWidget {
  final String countryCode;
  final String phoneNumber;
  final String smsType;
  const ChangePasswordPage(
      {super.key,
      required this.smsType,
      required this.phoneNumber,
      required this.countryCode});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  TextEditingController otpController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final _passwordFormKey = GlobalKey<FormState>();
  bool otpSent = false;

  FocusNode otpFocusNode = FocusNode();
  FocusNode newPasswordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  Future _verifyOtp(String otp) async {
    var token = await APIService.getToken();
    var authKey = await APIService.getXApiKey();
    EasyLoading.show(status: 'Verifying OTP');
    final response =
        await http.post(Uri.parse('$baseUrl/generate-verify-otp'), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$authKey',
    }, body: {
      'type': 'verify-otp',
      'mobile': widget.phoneNumber,
      'otp': otp
    });
    EasyLoading.dismiss();
    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: 'OTP verified successfully');
      resetPasswordModalBottomSheet();
      newPasswordFocusNode.requestFocus();
    } else if (response.statusCode == 410) {
      Fluttertoast.showToast(
          msg: 'OTP Expired. Please press resend to get a new OTP.');
    } else {
      Fluttertoast.showToast(msg: 'Invalid OTP. Please try again.');
    }
  }

  void resetPassword() async {
    var token = await APIService.getToken();
    var authKey = await APIService.getXApiKey();
    var response =
        await http.post(Uri.parse("$baseUrl/update-password"), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$authKey',
    }, body: {
      'mobile': widget.phoneNumber,
      'password': newPasswordController.text,
      'password_confirmation': confirmPasswordController.text
    });

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
          msg:
              'Password reset successfully. Please log in with the neww password.');
      navigatorKey.currentState?.pushReplacement(
          CupertinoPageRoute(builder: (context) => const LoginPage()));
    }
  }

  resetPasswordModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(8),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Form(
          key: _passwordFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                PasswordTextField(
                    controller: newPasswordController,
                    label: "Enter new password",
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 8) {
                        return 'Length must be atleast 8 characters';
                      }
                      return null;
                    },
                    focusNode: newPasswordFocusNode),
                const SizedBox(
                  height: 15,
                ),
                PasswordTextField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    validator: (value) {
                      if (newPasswordController.text != value) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    focusNode: confirmPasswordFocusNode),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: customElevatedButton("Confirm", green2, white, () {
                      if (_passwordFormKey.currentState!.validate()) {
                        resetPassword();
                      }
                    })),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  sendOtp() async {
    print('phone number: ${widget.phoneNumber}');
    var token = await APIService.getToken();
    var authKey = await APIService.getXApiKey();
    print('button tapped');
    final response =
        await http.post(Uri.parse('$baseUrl/generate-verify-otp'), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$authKey',
    }, body: {
      'country_code': widget.countryCode,
      'mobile': widget.phoneNumber,
      'type': 'send-otp',
      'sms_type': widget.smsType,
    });

    if (response.statusCode == 200) {
      setState(() {
        otpSent = true;
        otpFocusNode.requestFocus();
      });
      Fluttertoast.showToast(msg: 'OTP sent successfully');
    } else if (response.statusCode == 400) {
      Fluttertoast.showToast(
          msg: 'Could not find an account with this mobile number');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Change Password", []),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular',
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "To change your password, we will need to send you an OTP to your registered mobile.\n\nClick Send OTP to confirm.\n",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 15),
                Visibility(
                  visible: otpSent,
                  child: Center(
                    child: Pinput(
                      focusNode: otpFocusNode,
                      showCursor: true,
                      onChanged: (value) => setState(() {}),
                      controller: otpController,
                      defaultPinTheme: PinTheme(
                        textStyle: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        width: 50,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: darkGrey,
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        textStyle: const TextStyle(fontSize: 22),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: green,
                        ),
                      ),
                      length: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: otpSent
                        ? () async {
                            if (otpController.text.length == 6) {
                              EasyLoading.show();
                              try {
                                _verifyOtp(otpController.text);
                                EasyLoading.dismiss();
                              } catch (e) {
                                Result.error("Book list not available");
                              }
                            } else {
                              Fluttertoast.showToast(
                                  msg: 'OTP has to be of 6 digits.');
                            }
                          }
                        : () {
                            setState(() {
                              sendOtp();
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15.0),
                      backgroundColor: otpSent
                          ? otpController.text.length == 6
                              ? green2
                              : Colors.grey
                          : green2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      otpSent ? 'Confirm' : 'Send OTP',
                      style: const TextStyle(
                        fontSize: 16,
                        color: white,
                        fontFamily: 'Roboto-Regular',
                      ),
                    ),
                  ),
                ),
                otpSent
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "OTP not recieved?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          ResendButton(
                            onPressed: () {
                              sendOtp();
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
