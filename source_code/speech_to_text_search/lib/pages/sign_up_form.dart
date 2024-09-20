// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/Service/result.dart';
import 'package:speech_to_text_search/pages/login_profile.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String? _selectedShopType;
  XFile? logoImageFile;

  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController buisnessNameController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController gstinController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    mobileNumberController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> pickLogoImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      logoImageFile = image;
    });
  }

  Widget _buildMobileNumberTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: mobileNumberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.phone,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            hintText: 'Enter your Mobile Number',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mobile number is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    bool isObscure = true; // Flag to toggle password visibility
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        TextFormField(
          controller: passwordController,
          obscureText: isObscure,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.only(top: 14.0),
            prefixIcon: const Icon(
              Icons.lock,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            hintText: 'Enter your Password',
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility : Icons.visibility_off,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              onPressed: () {
                // Toggle password visibility
                setState(() {
                  isObscure = !isObscure;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordTF() {
    bool isObscureConfirm = true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextFormField(
            controller: confirmPasswordController,
            obscureText: isObscureConfirm,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(top: 14.0),
              prefixIcon: const Icon(
                Icons.lock,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Confirm your Password',
              suffixIcon: IconButton(
                icon: Icon(
                  isObscureConfirm ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
                onPressed: () {
                  // Toggle password visibility
                  setState(() {
                    isObscureConfirm = !isObscureConfirm;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextFormField(
            controller: fullNameController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.person,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Enter your Full Name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'FullName is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBuisnessNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextFormField(
            controller: buisnessNameController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.person,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Enter a Buisness Name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Buisness Name is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.email,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Enter your Email',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextFormField(
            controller: addressController,
            keyboardType: TextInputType.text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.location_on,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Enter your Address',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          hint: const Text(
            'Select Shop Type',
          ),
          value: _selectedShopType,
          icon: const Icon(Icons.arrow_downward),
          iconSize: 24,
          elevation: 16,
          onChanged: (String? newValue) {
            setState(() {
              _selectedShopType = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Shop Type is required';
            }
            return null;
          },
          items: <String>['grocery', 'pharmacy'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSignUpBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            submitData();
          }
        },
        style: ElevatedButton.styleFrom(
          elevation: 5.0, backgroundColor: Colors.green,
          padding: const EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'SIGN UP',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 1.5,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }

  Widget _buildSignInText() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()), // Change to AddItemScreen()
        );
      },
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'I already have an account ',
              style: TextStyle(
                color: Color.fromARGB(255, 97, 97, 97),
                fontSize: 15.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: Color.fromRGBO(221, 79, 60, 1),
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGSTINTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextFormField(
            controller: gstinController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.confirmation_number,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Enter GSTIN (Mandatory)',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'GSTIN is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          onPressed: pickLogoImage,
          child: const Text('Pick Logo Image'),
        ),
        const SizedBox(width: 10), // Add some space between the button and the thumbnail
        logoImageFile != null
            ? SizedBox(
                width: 50, // Set the width of the thumbnail
                height: 50, // Set the height of the thumbnail
                child: Image.file(File(logoImageFile!.path)),
              )
            : Container(), // If no image is selected, display an empty container
      ],
    );
  }

  Future<void> submitData() async {
    String apiUrl = '$baseUrl/register';

    //   Map<String, dynamic> postData = {
    //     'name': fullNameController.text,
    //     'username': buisnessNameController.text,
    //     'email': emailController.text,
    //     'mobile': mobileNumberController.text,
    //     'password': passwordController.text,
    //     'password_confirmation': confirmPasswordController.text,
    //     'address': addressController.text,
    //     'gstin': gstinController.text,
    //     'shop_type': _selectedShopType ?? '',
    //   };

    //   if (logoImageFile != null) {
    //     List<int> logoBytes = await logoImageFile!.readAsBytes();
    //     postData['logo'] = logoBytes;
    //   }

    //   try {
    //     final response = await http.post(
    //       Uri.parse(apiUrl),
    //       body: postData,
    //     );
    //     final Map<String, dynamic> responseData = json.decode(response.body);

    //     showApiResponseDialog(context, responseData);
    //   } catch (error) {
    //     print('Error: $error');
    //   }
    // }

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Add fields to the request
    request.fields['name'] = fullNameController.text;
    request.fields['username'] = buisnessNameController.text;
    request.fields['email'] = emailController.text;
    request.fields['mobile'] = mobileNumberController.text;
    request.fields['password'] = passwordController.text;
    request.fields['password_confirmation'] = confirmPasswordController.text;
    request.fields['address'] = addressController.text;
    request.fields['gstin'] = gstinController.text;
    request.fields['shop_type'] = _selectedShopType ?? '';

    // Add logo if it's available
    if (logoImageFile != null) {
      var logoStream = http.ByteStream(logoImageFile!.openRead());
      var logoLength = await logoImageFile!.length();
      var logoMultipartFile = http.MultipartFile(
        'logo',
        logoStream,
        logoLength,
        filename: logoImageFile!.path.split('/').last,
      );
      request.files.add(logoMultipartFile);
    }

    // Send the request
    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      // Call the function to show the response dialog
      showApiResponseDialog(context, jsonDecode(responseBody));
    } catch (error) {
      Result.error("Book list not available");
    }
  }

  void showApiResponseDialog(BuildContext context, Map<String, dynamic> response) {
    String title;
    String content;

    // Determine title and content based on the response
    if (response['status'] == 'success') {
      title = "Registration Successful";
      content = "Token: ${response['data']['token']}\nUser ID: ${response['data']['user']['id']}";
    } else if (response['status'] == 'failed' && response['message'] == 'Validation Error!') {
      title = "Validation Error";
      content = "Please check the following errors:\n";

      // Loop through validation errors
      Map<String, dynamic> errors = response['data'];
      errors.forEach((field, messages) {
        content += "$field: ${messages[0]}\n";
      });
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
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked : (didPop) async {
        final value = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Alert'),
                content: const Text('Do You Want to Exit'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Exit'),
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
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: <Widget>[
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
                SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 60.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Sign Up',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontFamily: 'OpenSans',
                              fontSize: 40.0,
                            ),
                          ),
                          _buildSignInText(),
                          const SizedBox(height: 30.0),

                          _buildMobileNumberTF(),
                          _buildPasswordTF(),
                          _buildConfirmPasswordTF(),
                          _buildFullNameTF(),
                          _buildBuisnessNameTF(),
                          _buildEmailTF(),
                          _buildAddressTF(),
                          _buildGSTINTF(),
                          _buildShopTypeDropdown(),
                          // Added GSTIN field
                          const SizedBox(
                            height: 10,
                          ),
                          _buildLogoPicker(),

                          // Added Logo Upload field
                          _buildSignUpBtn(),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
