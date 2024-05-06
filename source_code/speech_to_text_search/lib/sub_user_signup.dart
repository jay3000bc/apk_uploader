import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/login_profile.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/search_app.dart';
import 'package:speech_to_text_search/view_sub_user.dart';

class SignUpSubUserScreen extends StatefulWidget {
  @override
  _SignUpSubUserScreenState createState() => _SignUpSubUserScreenState();
}

class _SignUpSubUserScreenState extends State<SignUpSubUserScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  Future<void> submitData() async {
    EasyLoading.show(status: 'Loading...');
    var token = await APIService.getToken();

    print("token eytu:::$token");
    String apiUrl = '$baseUrl/add-new-user';

    // Prepare the request headers
    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Replace token with your actual token
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

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        // Request successful
        var responseBody = await response.stream.bytesToString();
        print(responseBody);
        // Call the function to show the response dialog
        showApiResponseDialog(context, jsonDecode(responseBody));
      } else {
        // Request failed
        print('Failed with status code: ${response.statusCode}');
        EasyLoading.showError('Failed with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
      EasyLoading.showError('Error: $error');
    } finally {
      EasyLoading.dismiss(); // Dismiss the loading indicator regardless of the request outcome
    }
  }

  void showApiResponseDialog(BuildContext context, Map<String, dynamic> response) {
    String title;
    String content;

    // Determine title and content based on the response
    if (response['status'] == 'success') {
      title = "Success";
      content = response['message'];
    } else if (response['status'] == 'failed' && response['message'] == 'Validation Error!') {
      title = "Validation Error";
      content = "Please check the following errors:\n";

      // Loop through validation errors
      Map<String, dynamic> errors = response['data'];
      errors.forEach((field, messages) {
        content += "$field: ${messages[0]}\n";
      });
    } else {
      title = "Error";
      content = response['message'] ?? "An unexpected error occurred";
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
              child: Text("OK"),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SearchApp()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(246, 247, 255, 1),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              Container(
                height: double.infinity,
                width: double.infinity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
              Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 60.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'SubUser Sign Up',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontFamily: 'OpenSans',
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 30.0),
                      ElevatedButton(
                        child: Text("View User"),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => SubUserListPage()),
                          );
                        },
                      ),
                      _buildNameTF(),
                      _buildMobileTF(),
                      _buildPasswordTF(),
                      _buildConfirmPasswordTF(),
                      _buildAddressTF(),
                      SizedBox(height: 40.0),
                      _buildSignUpBtn(),
                      SizedBox(height: 10.0),
                      _buildSignInText(),
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

  Widget _buildNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: nameController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.person,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Name',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.phone,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Mobile',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    bool _isObscure = true; // Flag to toggle password visibility

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 10.0),
        Container(
          child: TextField(
            controller: passwordController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
                onPressed: () {
                  // Toggle password visibility
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordTF() {
    bool _isObscureConfirm = true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: confirmPasswordController,
            obscureText: _isObscureConfirm,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Confirm Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscureConfirm ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
                onPressed: () {
                  // Toggle password visibility
                  setState(() {
                    _isObscureConfirm = !_isObscureConfirm;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: addressController,
            keyboardType: TextInputType.text,
            style: TextStyle(
              color: const Color.fromARGB(255, 7, 7, 7),
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.location_on,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              hintText: 'Address',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          submitData();
        },
        style: ElevatedButton.styleFrom(
          elevation: 5.0, backgroundColor: Colors.green,
          padding: EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Text(
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
          MaterialPageRoute(builder: (context) => LoginScreen()), // Change to AddItemScreen()
        );
      },
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(
                color: Color.fromARGB(255, 97, 97, 97),
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: Color.fromRGBO(221, 79, 60, 1),
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
