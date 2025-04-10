import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:http/http.dart' as http;
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';

class AddShopDetailsPage extends StatefulWidget {
  final String userID;
  const AddShopDetailsPage({super.key, required this.userID});

  @override
  State<AddShopDetailsPage> createState() => _AddShopDetailsPageState();
}

class _AddShopDetailsPageState extends State<AddShopDetailsPage> {
  final _shopFormKey = GlobalKey<FormState>();
  File? logoImageFile;

  FocusNode nameFocusNode = FocusNode();
  FocusNode businessNameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode addressFocusNode = FocusNode();

  String emailErrorMessage = "";

  TextEditingController fullNameController = TextEditingController();
  TextEditingController buisnessNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController gstinController = TextEditingController();

  Future<void> pickLogoImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        logoImageFile = File(image.path);
      });
    }
  }

  Widget _buildLogoPicker() {
    return Stack(
      children: [
        InkWell(
          onTap: pickLogoImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: green2,
            foregroundImage: logoImageFile != null
                ? FileImage(logoImageFile!)
                : (const AssetImage("assets/user.png")),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: blue,
              border: Border.all(color: blue, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.edit,
              color: white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullNameTF() {
    return TextFormField(
      focusNode: nameFocusNode,
      textCapitalization: TextCapitalization.words,
      controller: fullNameController,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        errorStyle: TextStyle(color: red),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
          color: green,
        )),
        filled: true,
        fillColor: white,
        hintText: 'Your Name *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          nameFocusNode.requestFocus();
          return 'FullName is required';
        }
        return null;
      },
    );
  }

  Widget _buildBuisnessNameTF() {
    return TextFormField(
      focusNode: businessNameFocusNode,
      textCapitalization: TextCapitalization.words,
      controller: buisnessNameController,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        errorStyle: TextStyle(color: red),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
          color: green,
        )),
        filled: true,
        fillColor: white,
        hintText: 'Business Name *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          businessNameFocusNode.requestFocus();
          return 'Buisness Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildEmailTF() {
    return TextFormField(
      focusNode: emailFocusNode,
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        errorStyle: TextStyle(color: red),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
          color: green,
        )),
        filled: true,
        fillColor: white,
        hintText: 'Email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  showEmailErrorMessage() {
    if (emailErrorMessage != '') {
      emailFocusNode.requestFocus();
      return Row(
        children: [
          Text(
            emailErrorMessage,
            textAlign: TextAlign.start,
            style: const TextStyle(color: red),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAddressTF() {
    return TextFormField(
      focusNode: addressFocusNode,
      textCapitalization: TextCapitalization.sentences,
      controller: addressController,
      keyboardType: TextInputType.text,
      style: const TextStyle(
        fontFamily: 'Roboto-Regular',
      ),
      decoration: const InputDecoration(
        errorStyle: TextStyle(color: red),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
          color: green,
        )),
        filled: true,
        fillColor: white,
        hintText: 'Address *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          addressFocusNode.requestFocus();
          return 'Address is required';
        }
        return null;
      },
    );
  }

  Widget _buildGSTINTF() {
    return TextFormField(
      textCapitalization: TextCapitalization.sentences,
      controller: gstinController,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        filled: true,
        fillColor: white,
        hintText: 'GSTIN',
        border: OutlineInputBorder(
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
        onPressed: () async {
          print('pressed');

          if (_shopFormKey.currentState!.validate()) {
            EasyLoading.init();
            var response = await http
                .post(Uri.parse('$baseUrl/register/create-shop'), body: {
              'user_id': widget.userID,
              'business_name': buisnessNameController.text,
              'name': fullNameController.text,
              'email': emailController.text,
              'address': addressController.text,
              'gstin': gstinController.text,
              'terms_n_conditions': '1',
            });
            print(response.body);
            EasyLoading.dismiss();
            if (response.statusCode == 200) {
              Fluttertoast.showToast(msg: 'Shop details added successfully');
              showDialog(
                  context: context,
                  builder: (context) => customAlertBox(
                        title: "Registration Successful",
                        content:
                            "You have successfully registered your account. Please log in now.",
                        actions: [
                          customElevatedButton('OK', green2, white, () {
                            navigatorKey.currentState?.pushReplacement(
                              CupertinoPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          }),
                          customElevatedButton('NO', red, white, () {
                            navigatorKey.currentState?.pop();
                          })
                        ],
                      ));
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
          'Register',
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
                'Enter Shop Details',
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
              bottom: screenHeight * 0.05,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      height: screenHeight * 0.55,
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
                            key: _shopFormKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 15),
                                _buildLogoPicker(),
                                const SizedBox(height: 30),
                                _buildFullNameTF(),
                                const SizedBox(height: 15),
                                _buildBuisnessNameTF(),
                                const SizedBox(height: 15),
                                _buildEmailTF(),
                                showEmailErrorMessage(),
                                const SizedBox(height: 15),
                                _buildAddressTF(),
                                const SizedBox(height: 15),
                                _buildGSTINTF(),
                                const SizedBox(height: 15),

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
