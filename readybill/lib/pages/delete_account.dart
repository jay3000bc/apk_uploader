import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/resend_button.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/result.dart';

class DeleteAccountPage extends StatefulWidget {
  final String countryCode;
  final String phoneNumber;
  final String smsType;
  final int userId;
  const DeleteAccountPage({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
    required this.smsType,
    required this.userId,
  });

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  TextEditingController otpController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final _passwordFormKey = GlobalKey<FormState>();
  bool otpSent = false;

  FocusNode otpFocusNode = FocusNode();
  FocusNode newPasswordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  // Future _verifyOtp(String otp) async {
  //   var token = await APIService.getToken();
  //   var authKey = await APIService.getXApiKey();
  //   EasyLoading.show(status: 'Verifying OTP');
  //   final response =
  //       await http.post(Uri.parse('$baseUrl/generate-verify-otp'), headers: {
  //     'Authorization': 'Bearer $token',
  //     'auth-key': '$authKey',
  //   }, body: {
  //     'type': 'verify-otp',
  //     'mobile': widget.phoneNumber,
  //     'otp': otp
  //   });
  //   EasyLoading.dismiss();
  //   if (response.statusCode == 200) {
  //     Fluttertoast.showToast(msg: 'OTP verified successfully');
  //     deleteAccount();
  //   } else if (response.statusCode == 410) {
  //     Fluttertoast.showToast(
  //         msg: 'OTP Expired. Please press resend to get a new OTP.');
  //   } else {
  //     Fluttertoast.showToast(msg: 'Invalid OTP. Please try again.');
  //   }
  // }

  deleteAccount(String otp) async {
    var token = await APIService.getToken();
    var authKey = await APIService.getXApiKey();
    EasyLoading.show(status: 'Deleting Account');
    var response =
        await http.post(Uri.parse('$baseUrl/delete-account'), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$authKey',
    }, body: {
      'otp': otp,
      'user_id': widget.userId.toString(),
    });
    print(response.body);
    if (response.statusCode == 200) {
      EasyLoading.dismiss();
      Fluttertoast.showToast(msg: 'Account deleted successfully');
      navigatorKey.currentState?.pushReplacement(
        CupertinoPageRoute(builder: (context) => const LoginPage()),
      );
      //Navigator.pop(context);
    } else if (response.statusCode == 400) {
      EasyLoading.dismiss();
      Fluttertoast.showToast(msg: 'Invalid OTP. Please try again.');
    } else if (response.statusCode == 410) {
      EasyLoading.dismiss();
      Fluttertoast.showToast(
          msg: 'OTP Expired. Please press resend to get a new OTP.');
    }
  }

  sendOtp() async {
    print('phone number: ${widget.phoneNumber}');
    print('sms type: ${widget.smsType}');
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
    print(response.body);

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
      appBar: customAppBar('Delete Account', []),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Delete Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular',
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "To delete your account, we will need to send you an OTP to your registered mobile.\n\nClick Send OTP to confirm.\n",
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
                                deleteAccount(otpController.text);
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
