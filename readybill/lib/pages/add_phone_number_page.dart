import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/country_selector_prefix.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/resend_button.dart';
import 'package:readybill/pages/add_password_page.dart';
import 'package:readybill/pages/add_shop_details_page.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/pages/terms_and_conditions.dart';
import 'package:readybill/services/country_code_provider.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:http/http.dart' as http;

class AddPhoneNumberPage extends StatefulWidget {
  const AddPhoneNumberPage({super.key});

  @override
  State<AddPhoneNumberPage> createState() => _AddPhoneNumberPageState();
}

class _AddPhoneNumberPageState extends State<AddPhoneNumberPage> {
  FocusNode phoneNumberFocusNode = FocusNode();

  TextEditingController mobileNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool acceptTermsAndConditions = false;
  bool tncError = false;

  void sendOtp() async {
    var response =
        await http.post(Uri.parse('$baseUrl/register/send-otp'), body: {
      'mobile': mobileNumberController.text,
      'country_code': Provider.of<CountryCodeProvider>(context, listen: false)
          .registerPageCountryCode
    });
    print(response.body);
    print(response.statusCode);
    var jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        jsonData['data']['data']['user_id'] == '') {
      showModalBottomSheet(
          context: context,
          builder: (context) => OtpModalBottomSheet(
                sendOtp: sendOtp,
                phoneNumber: mobileNumberController.text,
              ));
    } else if (response.statusCode == 200 &&
        jsonData['data']['data']['user_id'] != '') {
      navigatorKey.currentState?.push(CupertinoPageRoute(
          builder: (context) => AddShopDetailsPage(
              userID: jsonData['data']['data']['user_id'].toString())));
    } else if (response.statusCode == 400) {
      showDialog(
          context: context,
          builder: (context) => customAlertBox(
                title: "Account already exists",
                content:
                    'Account with this phone number already exists. Please log in.',
                actions: [
                  customElevatedButton("Cancel", red, white, () {
                    navigatorKey.currentState?.pop();
                  }),
                  customElevatedButton('Login', green2, white, () {
                    navigatorKey.currentState?.pushReplacement(
                        CupertinoPageRoute(
                            builder: (context) => const LoginPage()));
                  })
                ],
              ));
    }
  }

  Widget _buildMobileNumberTF() {
    return TextFormField(
      cursorColor: green,
      focusNode: phoneNumberFocusNode,
      validator: (value) {
        if (value == null ||
            value.isEmpty ||
            value.length < 10 ||
            value.length > 10 ||
            int.tryParse(value) == null) {
          phoneNumberFocusNode.requestFocus();
          return 'Must be 10-digit Number';
        }
        return null;
      },
      controller: mobileNumberController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        errorStyle: const TextStyle(color: red),
        prefixIcon: CountrySelectorPrefix(
            provider: Provider.of<CountryCodeProvider>(context, listen: false)
                .setRegisterPageCountryCode),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
          color: green,
        )),
        filled: true,
        fillColor: white,
        hintText: 'Mobile Number *',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSignUpBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          print('pressed');

          if (_formKey.currentState!.validate()) {
            if (acceptTermsAndConditions == false) {
              setState(() {
                tncError = true;
              });
            } else {
              sendOtp();
            }
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
                'Enter Phone Number',
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
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Already have an account?",
                                      style: TextStyle(
                                          fontFamily: 'Roboto-Regular',
                                          color: white),
                                    ),
                                    const SizedBox(width: 5),
                                    InkWell(
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold,
                                            color: green),
                                      ),
                                      onTap: () => navigatorKey.currentState!
                                          .push(CupertinoPageRoute(
                                              builder: (context) =>
                                                  const LoginPage())),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),
                                _buildMobileNumberTF(),
                                const SizedBox(
                                  height: 15,
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      side: WidgetStateBorderSide.resolveWith(
                                        (states) => const BorderSide(
                                            width: 2, color: white),
                                      ),
                                      value: acceptTermsAndConditions,
                                      onChanged: (value) => setState(() {
                                        acceptTermsAndConditions = value!;
                                      }),
                                    ),
                                    const Text(
                                      'I agree to all the',
                                      style: TextStyle(color: white),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        navigatorKey.currentState?.push(
                                            CupertinoPageRoute(
                                                builder: (context) =>
                                                    const TermsAndConditionsPage()));
                                      },
                                      child: const Text(
                                        'Terms & Conditions',
                                        style: TextStyle(color: green),
                                      ),
                                    ),
                                  ],
                                ),

                                Visibility(
                                    visible: tncError,
                                    child: const Text(
                                      "Accept Terms and Conditions to proceed",
                                      style: TextStyle(color: red),
                                    )),

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

class OtpModalBottomSheet extends StatefulWidget {
  final Function sendOtp;
  final String phoneNumber;

  const OtpModalBottomSheet({
    super.key,
    required this.phoneNumber,
    required this.sendOtp,
  });

  @override
  State<OtpModalBottomSheet> createState() => _OtpModalBottomSheetState();
}

class _OtpModalBottomSheetState extends State<OtpModalBottomSheet> {
  TextEditingController otpController = TextEditingController();
  FocusNode otpFocusNode = FocusNode();

  void _verifyOtp() async {
    String url = "$baseUrl/register/verify-otp";
    EasyLoading.show(status: 'Verifying OTP...');
    final response = await http.post(Uri.parse(url),
        body: {"mobile": widget.phoneNumber, "otp": otpController.text});

    print(response.statusCode);
    print('response.body: ${response.body}');

    if (response.statusCode == 200) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "OTP Verified.");
      navigatorKey.currentState?.push(
        CupertinoPageRoute(
          builder: (context) => AddPasswordPage(
            phoneNumber: widget.phoneNumber,
            countryCode:
                Provider.of<CountryCodeProvider>(context, listen: false)
                    .registerPageCountryCode,
          ),
        ),
      );
    }
    {
      Fluttertoast.showToast(msg: jsonDecode(response.body)['message']);
    }
    EasyLoading.dismiss();
  }

  @override
  void initState() {
    super.initState();
    otpFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height: MediaQuery.of(context).size.height * 0.9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
            child: Column(
              children: [
                const Text(
                  "Enter the OTP",
                  style: TextStyle(
                      color: white,
                      fontSize: 26,
                      fontFamily: 'Roboto-Regular',
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 20,
                ),
                Pinput(
                  focusNode: otpFocusNode,
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
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "OTP not received?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    ResendButton(onPressed: () {
                      widget.sendOtp();
                    })
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 25.0),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      print('pressed2');
                      _verifyOtp();
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
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto-Regular',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
