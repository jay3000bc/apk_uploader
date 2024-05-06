import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'dart:convert';

import 'package:speech_to_text_search/Service/is_login.dart';

String userDetailsAPI = "$baseUrl/user-detail";

class UserDetail {
  final String name;
  final String username;
  final String email;
  final String mobile;
  final String address;
  final String shopType;
  final String gstin;
  final String logo;

  UserDetail({
    required this.name,
    required this.username,
    required this.email,
    required this.mobile,
    required this.address,
    required this.shopType,
    required this.gstin,
    required this.logo,
  });
}

class UserDetailForm extends StatefulWidget {
  @override
  _UserDetailFormState createState() => _UserDetailFormState();
}

class _UserDetailFormState extends State<UserDetailForm> {
  late TextEditingController nameController;
  late TextEditingController userNameController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController shopTypeController;
  late TextEditingController gstinController;
  late TextEditingController newPasswordController;

  UserDetail? userDetail;

  @override
  void initState() {
    print("$baseUrl /user-detail");
    print("$baseUrl/user-detail");
    super.initState();
    getUserDetail();
  }

  Future<void> getUserDetail() async {
    String? token = await APIService.getToken();
    final response = await http.get(
      Uri.parse(userDetailsAPI),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final userData = jsonData['data'];
      setState(() {
        userDetail = UserDetail(
          name: userData['name'],
          username: userData['username'],
          email: userData['email'],
          mobile: userData['mobile'],
          address: userData['address'],
          shopType: userData['shop_type'],
          gstin: userData['gstin'],
          logo: userData['logo'],
        );
      });
      nameController = TextEditingController(text: userDetail!.name);
      userNameController = TextEditingController(text: userDetail!.username);
      emailController = TextEditingController(text: userDetail!.email);
      phoneController = TextEditingController(text: userDetail!.mobile);
      addressController = TextEditingController(text: userDetail!.address);
      shopTypeController = TextEditingController(text: userDetail!.shopType);
      gstinController = TextEditingController(text: userDetail!.gstin);
      newPasswordController = TextEditingController();
    } else {
      throw Exception('Failed to load user detail');
    }
  }

  Widget textFieldCustom(TextEditingController controller, bool obscureText, String labelText, bool readOnly) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    String logoUrl = 'https://probill.app/storage/logo/${userDetail!.logo}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Check if logo URL is available and valid
        userDetail!.logo.isNotEmpty && Uri.parse(logoUrl).isAbsolute
            ? SizedBox(
                width: 50, // Set the width of the thumbnail
                height: 50, // Set the height of the thumbnail
                child: Image.network(logoUrl),
              )
            : Container(
                width: 50, // Set the width of the placeholder
                height: 50, // Set the height of the placeholder
                color: Colors.grey, // Placeholder color
                child: Icon(
                  Icons.image_not_supported, // Placeholder icon
                  color: Colors.white, // Icon color
                ),
              ),
        SizedBox(width: 10), // Add some space between the button and the thumbnail
        // ElevatedButton(
        //   onPressed: pickLogoImage,
        //   child: Text('Change Logo'),
        // ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(246, 247, 255, 1),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'User Details',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: Color.fromRGBO(243, 203, 71, 1), // Change this color to whatever you desire
      ),
      body: userDetail == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textFieldCustom(nameController, false, 'Name', false),
                  SizedBox(height: 10.0),
                  textFieldCustom(userNameController, false, 'Business Name', true),
                  SizedBox(height: 10.0),
                  textFieldCustom(emailController, false, 'Email', true),
                  SizedBox(height: 10.0),
                  textFieldCustom(phoneController, false, 'Mobile', true),
                  SizedBox(height: 10.0),
                  textFieldCustom(addressController, false, 'Address', false),
                  SizedBox(height: 10.0),
                  textFieldCustom(shopTypeController, false, 'Shop Type', false),
                  SizedBox(height: 10.0),
                  textFieldCustom(gstinController, false, 'GSTIN Number', false),
                  SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Logo: '),
                      _buildLogoPicker(),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  textFieldCustom(newPasswordController, true, 'New Password', false),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {
                      // Implement your update logic here
                      print('Updating user detail...');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Change the color here
                    ),
                    child: Text('Update'),
                  ),
                ],
              ),
            ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: UserDetailForm(),
  ));
}
