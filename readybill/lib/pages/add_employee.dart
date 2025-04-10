// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';
import 'package:readybill/components/api_constants.dart';

import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/color_constants.dart';

import 'package:readybill/pages/view_employee.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/country_code_provider.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/result.dart';

class EmployeeSignUpPage extends StatefulWidget {
  const EmployeeSignUpPage({super.key});

  @override
  State<EmployeeSignUpPage> createState() => _EmployeeSignUpPageState();
}

class _EmployeeSignUpPageState extends State<EmployeeSignUpPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  FocusNode focusNode = FocusNode();

  bool isObscureConfirm = true;
  bool isObscure = true;
  File? selectedImageFile;

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  Future<void> submitData() async {
    print(
        "Country Code: ${Provider.of<CountryCodeProvider>(context, listen: false).addEmployeePageCountryCode}");
    EasyLoading.show(status: 'Loading...');
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    String apiUrl = '$baseUrl/add-new-user';
    // Prepare the request headers
    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'auth-key': '$apiKey'
    };

    // Prepare the request body
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.headers.addAll(headers);

    // Add fields to the request
    request.fields['name'] = nameController.text;
    request.fields['mobile'] = mobileController.text;
    request.fields['password'] = passwordController.text;
    request.fields['password_confirmation'] = confirmPasswordController.text;
    request.fields['address'] = addressController.text;
    request.fields['country_code'] =
        Provider.of<CountryCodeProvider>(context, listen: false)
            .addEmployeePageCountryCode;
    if (selectedImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        selectedImageFile!.path,
      ));
    }
    try {
      EasyLoading.show(status: 'loading...');
      var response = await request.send();

      print("response status code: ${response.statusCode}");

      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        print(responseBody);
        // showApiResponseDialog(context, jsonDecode(responseBody));
        Fluttertoast.showToast(msg: 'User added successfully');
        navigatorKey.currentState?.pushReplacement(
          CupertinoPageRoute(builder: (_) => const EmployeeListPage()),
        ); // Navigate to the login screen();
      } else {
        // Request successful
        var responseBody = await response.stream.bytesToString();
        // Decode the response body
        var decodedResponse = jsonDecode(responseBody);
        print(decodedResponse);
        String messageMobile =
            decodedResponse['data']['mobile']?.join(', ') ?? '';
        String messagePassword =
            decodedResponse['data']['password']?.join(', ') ?? '';
        String messageName = decodedResponse['data']['name']?.join(', ') ?? '';
        String messageAddress =
            decodedResponse['data']['address']?.join(', ') ?? '';
        String finalMessage =
            '$messageName\n$messageMobile\n$messagePassword\n$messageAddress';
        callAlert(finalMessage);

        print(jsonDecode(responseBody));
        Result.error("Book list not available");
      }
    } catch (error) {
      Result.error("Book list not available");
    } finally {
      EasyLoading
          .dismiss(); // Dismiss the loading indicator regardless of the request outcome
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Add Employee", []),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              SizedBox(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 30.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        children: [
                          InkWell(
                            onTap: pickLogoImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: green2,
                              foregroundImage: selectedImageFile != null
                                  ? FileImage(selectedImageFile!)
                                  : (const AssetImage("assets/user.png")),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: green2,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30.0),

                      _buildNameTF("Name *", nameController, TextInputType.text,
                          false, TextCapitalization.words),
                      const SizedBox(height: 10.0),

                      _buildMobileTF(),
                      const SizedBox(height: 10.0),
                      _buildPasswordTF(
                          "Password *", passwordController, TextInputType.text),
                      const SizedBox(height: 10.0),
                      _buildConfirmPasswordTF("Confirm Password *",
                          confirmPasswordController, TextInputType.text),
                      const SizedBox(height: 10.0),
                      _buildTF("Address *", addressController,
                          TextInputType.text, false, TextCapitalization.words),
                      const SizedBox(height: 40.0),
                      SizedBox(
                        width: double.maxFinite,
                        child: customElevatedButton(
                          "Save",
                          blue,
                          white,
                          () {
                            if (mobileController.text == '' ||
                                nameController.text == '' ||
                                passwordController.text == '' ||
                                confirmPasswordController.text == '' ||
                                addressController.text == '') {
                              callAlert("all fields are required");
                            } else {
                              submitData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      // _buildSignInText(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTF(
      String hintText,
      TextEditingController controller,
      TextInputType keyboardType,
      bool isObscure,
      TextCapitalization textCapitalization) {
    return Container(
      alignment: Alignment.centerLeft,
      child: TextField(
        textCapitalization: textCapitalization,
        controller: controller,
        keyboardType: keyboardType,
        decoration: customTfInputDecoration(hintText),
        obscureText: isObscure,
      ),
    );
  }

  Widget _buildMobileTF() {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(),
      controller: mobileController,
      decoration: phoneNumberInputDecoration(
          "Mobile *",
          Provider.of<CountryCodeProvider>(context)
              .setAddEmployeePageCountryCode,
          ''),
    );
  }

  Widget _buildNameTF(
      String hintText,
      TextEditingController controller,
      TextInputType keyboardType,
      bool isObscure,
      TextCapitalization textCapitalization) {
    return Container(
      alignment: Alignment.centerLeft,
      child: TextField(
        focusNode: focusNode,
        textCapitalization: textCapitalization,
        controller: controller,
        keyboardType: keyboardType,
        decoration: customTfInputDecoration(hintText),
        obscureText: isObscure,
      ),
    );
  }

  Widget _buildPasswordTF(
    String hintText,
    TextEditingController controller,
    // bool isObscure,
    TextInputType keyboardType,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isObscure = !isObscure;
              });
              print(isObscure);
            },
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Color(0xffbfbfbf),
              width: 3.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: green2,
              width: 3.0,
            ),
          ),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        obscureText: isObscure,
      ),
    );
  }

  Widget _buildConfirmPasswordTF(
    String hintText,
    TextEditingController controller,
    // bool isObscure,
    TextInputType keyboardType,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isObscureConfirm = !isObscureConfirm;
              });
              print(isObscure);
            },
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Color(0xffbfbfbf),
              width: 3.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: green2,
              width: 3.0,
            ),
          ),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        obscureText: isObscureConfirm,
      ),
    );
  }

  Future<void> pickLogoImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImageFile = File(image.path);
      });
    }
  }

  callAlert(String message) {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return customAlertBox(
            title: "Alert",
            content: message,
            actions: [
              customElevatedButton("OK", green2, white, () {
                navigatorKey.currentState?.pop();
              }),
            ],
          );
        });
  }
}
