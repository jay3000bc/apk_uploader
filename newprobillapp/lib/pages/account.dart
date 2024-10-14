// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'package:newprobillapp/components/api_constants.dart';
import 'package:newprobillapp/services/api_services.dart';


String userDetailsAPI = "$baseUrl/user-detail";

class UserDetail {
  final int id;
  final String name;
  final String username;
  final String email;
  final String mobile;
  final String address;
  final String shopType;
  final String gstin;
  final String logo;

  UserDetail({
    required this.id,
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

class UserAccount extends StatefulWidget {
  const UserAccount({super.key});

  @override
  State<UserAccount> createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  late TextEditingController nameController;
  late TextEditingController userNameController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController shopTypeController;
  late TextEditingController gstinController;
  late TextEditingController newPasswordController;

  UserDetail? userDetail;
  XFile? logoImageFile;
  String? logo;

  @override
  void initState() {
    super.initState();
    getUserDetail();
  }

  Future<void> pickLogoImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      logoImageFile = image;
    });
  }

  _submitData() async {
    var token = await APIService.getToken();
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('https://dev.probill.app/api/update-profile'));
      request.headers.addAll({
        'Authorization':
            'Bearer $token', // Replace $token with your actual token value
      });
      request.fields.addAll({
        'id': userDetail!.id.toString(), // Add your user ID here
        'name': nameController.text,
        'address': addressController.text,
        'shop_type': shopTypeController.text,
        'password': newPasswordController.text,
      });
      if (logoImageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('logo', logoImageFile!.path));
      }
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        // Handle successful response
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Success"),
              content: const Text("Profile updated successfully."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        // Handle error response
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content:
                  Text("Failed to update profile. ${response.reasonPhrase}"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Handle exception
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("An error occurred while updating profile. $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
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
      logo = jsonData['logo'];
      setState(() {
        userDetail = UserDetail(
          id: userData['id'],
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

  Widget textFieldCustom(TextEditingController controller, bool obscureText,
      String labelText, bool readOnly) {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Check if logo URL is available and valid
        userDetail!.logo.isNotEmpty && Uri.parse(logo as String).isAbsolute
            ? SizedBox(
                width: 50, // Set the width of the thumbnail
                height: 50, // Set the height of the thumbnail
                child: Image.network(logo as String),
              )
            : Container(
                width: 50, // Set the width of the placeholder
                height: 50, // Set the height of the placeholder
                color: Colors.grey, // Placeholder color
                child: const Icon(
                  Icons.image_not_supported, // Placeholder icon
                  color: Colors.white, // Icon color
                ),
              ),
        const SizedBox(
            width: 10), // Add some space between the button and the thumbnail
        // ElevatedButton(
        //   onPressed: pickLogoImage,
        //   child: Text('Change Logo'),
        // ),
      ],
    );
  }

  Widget _logoPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          onPressed: pickLogoImage,
          child: const Text('Pick Logo'),
        ),
        const SizedBox(
            width: 10), // Add some space between the button and the thumbnail
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(246, 247, 255, 1),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back when pressed
          },
        ),
        toolbarHeight: 40,
        title: const Text(
          'Account Details',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: const Color.fromRGBO(
            243, 203, 71, 1), // Change this color to whatever you desire
      ),
      body: userDetail == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textFieldCustom(nameController, false, 'Name', false),
                  const SizedBox(height: 10.0),
                  textFieldCustom(
                      userNameController, false, 'Business Name', true),
                  const SizedBox(height: 10.0),
                  textFieldCustom(emailController, false, 'Email', true),
                  const SizedBox(height: 10.0),
                  textFieldCustom(phoneController, false, 'Mobile', true),
                  const SizedBox(height: 10.0),
                  textFieldCustom(addressController, false, 'Address', false),
                  const SizedBox(height: 10.0),
                  textFieldCustom(
                      shopTypeController, false, 'Shop Type', false),
                  const SizedBox(height: 10.0),
                  textFieldCustom(
                      gstinController, false, 'GSTIN Number', false),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text('Logo: '),
                      _buildLogoPicker(),
                      _logoPicker(), // Display current logo and replace logo button
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  textFieldCustom(
                      newPasswordController, true, 'New Password', false),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _submitData,
                    // Implement your update logic here

                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          const Color(0xFF0B5ED7), // Change the color here
                    ),
                    child: const Text('Update Changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
