import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:readybill/components/api_constants.dart';

import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/pages/delete_account.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/country_code_provider.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

String userDetailsAPI = "$baseUrl/user-detail";

class UserDetail {
  final int id;
  final String name;

  final String? email;
  final String mobile;
  final String address;
  final String shopType;
  final String gstin;
  final String logo;
  final String businessName;
  final String entityId;
  final String countryCode;
  final String dialCode;

  UserDetail({
    required this.dialCode,
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
    required this.address,
    required this.shopType,
    required this.gstin,
    required this.logo,
    required this.businessName,
    required this.entityId,
    required this.countryCode,
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
  late TextEditingController businessNameController;
  late TextEditingController entityIdController;
  String countryCode = '';

  UserDetail? userDetail;
  XFile? logoImageFile;
  String? logo;
  File? selectedImageFile;
  int isAdmin = 0;
  @override
  void initState() {
    super.initState();
    getUserDetail();
  }

  _submitData() async {
    if (isAdmin == 1) {
      var token = await APIService.getToken();
      var apiKey = await APIService.getXApiKey();

      try {
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/update-profile'),
        );

        // Add headers
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
        });

        // Add text fields
        request.fields.addAll({
          'user_id': userDetail!.id.toString(),
          'name': nameController.text,
          'email': emailController.text,
          'mobile': phoneController.text,
          'address': addressController.text,
          'shop_type': shopTypeController.text,
          'gstin': gstinController.text,
          'isLogoDelete': '0',
        });

        // Add logo file if exists
        if (logoImageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'logo',
              logoImageFile!.path,
            ),
          );
        }
        EasyLoading.show(status: 'Updating...');

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        EasyLoading.dismiss();
        if (response.statusCode == 201) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return customAlertBox(
                title: "Success",
                content: "Profile updated successfully.",
                actions: [
                  customElevatedButton("OK", green2, white, () {
                    navigatorKey.currentState?.pop();
                  }),
                ],
              );
            },
          );
        } else if (response.statusCode == 413) {
          Fluttertoast.showToast(
              msg: 'Image too large. Please select a smaller image.');
        } else {
          // Handle error response
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return customAlertBox(
                title: "Error",
                content: "Failed to update profile. ${response.reasonPhrase}",
                actions: [
                  customElevatedButton("OK", green2, white, () {
                    navigatorKey.currentState?.pop();
                  }),
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
            return customAlertBox(
              title: "Error",
              content: "An error occurred while updating profile. $e",
              actions: [
                customElevatedButton("OK", green2, white, () {
                  navigatorKey.currentState?.pop();
                }),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return customAlertBox(
                title: "Unauthorized",
                content:
                    "You do not have permission to update data. Please contact shop owner to update yur details.",
                actions: [
                  customElevatedButton("OK", green2, white, () {
                    navigatorKey.currentState?.pop();
                  })
                ]);
          });
    }
  }

  Future<void> getUserDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getInt('isAdmin') ?? 0;
    String? token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    final response = await http.get(
      Uri.parse(userDetailsAPI),
      headers: {
        'Authorization': 'Bearer $token',
        'auth-key': '$apiKey',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      //
      final userData = jsonData['data'];
      logo = jsonData['logo'];
      setState(() {
        userDetail = UserDetail(
          id: userData['user_id'],
          name: userData['details']['name'],
          countryCode: userData['country_details']['code'],
          dialCode: userData['country_details']['dial_code'],
          email: userData['details']['email'],
          mobile: userData['mobile'],
          address: userData['details']['address'],
          shopType: userData['shop_type'],
          gstin: userData['details']['gstin'],
          logo: userData['logo'],
          businessName: userData['details']['business_name'],
          entityId: jsonData['entity_id'],
        );
      });
      nameController = TextEditingController(text: userDetail!.name);

      emailController = TextEditingController(text: userDetail!.email);
      phoneController = TextEditingController(text: userDetail!.mobile);
      addressController = TextEditingController(text: userDetail!.address);
      shopTypeController = TextEditingController(text: userDetail!.shopType);
      gstinController = TextEditingController(text: userDetail!.gstin);
      businessNameController =
          TextEditingController(text: userDetail!.businessName);
      entityIdController = TextEditingController(text: userDetail!.entityId);
    } else {
      throw Exception('Failed to load user detail');
    }
  }

  Widget textFieldCustom(
      TextEditingController controller, String hintText, bool readOnly) {
    return TextFormField(
      textCapitalization: TextCapitalization.words,
      controller: controller,
      readOnly: readOnly,
      decoration: readOnly
          ? disabledTfInputDecoration(hintText)
          : customTfInputDecoration(hintText),
    );
  }

  Widget textFieldPhone(
      TextEditingController controller, String hintText, bool readOnly) {
    print('countrycode: ${userDetail!.countryCode}');
    return TextFormField(
      textCapitalization: TextCapitalization.words,
      controller: controller,
      readOnly: readOnly,
      decoration: readOnly
          ? disabledTfInputDecoration(hintText)
          : phoneNumberInputDecoration(
              hintText,
              Provider.of<CountryCodeProvider>(context)
                  .setAccountPageCountryCode,
              userDetail!.countryCode),
    );
  }

  Future<void> pickLogoImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImageFile = File(image.path);
        logoImageFile = image; // Add this line to store the XFile
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    countryCode = Provider.of<CountryCodeProvider>(context, listen: false)
        .accountPageCountryCode;
    return Scaffold(
      //  backgroundColor: const Color.fromRGBO(246, 247, 255, 1),
      appBar: customAppBar('Account Details', [
        Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: () => navigatorKey.currentState?.push(
                CupertinoPageRoute(
                  builder: (context) => DeleteAccountPage(
                    countryCode: countryCode,
                    phoneNumber: userDetail!.mobile,
                    smsType: 'delete_account',
                    userId: userDetail!.id,
                  ),
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  color: white,
                  decoration: TextDecoration.underline,
                  decorationColor: white,
                ),
              ),
            ))
      ]),
      body: userDetail == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        InkWell(
                          onTap: pickLogoImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: green2,
                            foregroundImage: selectedImageFile != null
                                ? FileImage(selectedImageFile!)
                                : (logo != 'assets/img/user.jpg'
                                    ? NetworkImage(logo!) as ImageProvider
                                    : const AssetImage("assets/user.png")),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: green2,
                              border: Border.all(color: Colors.white, width: 2),
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
                  ),
                  const SizedBox(height: 20.0),
                  labeltext("Entity ID:"),
                  textFieldCustom(entityIdController, "Entity ID", true),
                  const SizedBox(height: 20),
                  labeltext('Name:'),
                  textFieldCustom(
                      nameController, 'Name', isAdmin == 0 ? true : false),
                  const SizedBox(height: 20),
                  labeltext("Business Name:"),
                  textFieldCustom(
                      businessNameController, 'Business Name', true),
                  const SizedBox(height: 20),
                  labeltext("Email:"),
                  textFieldCustom(emailController, 'Email', true),
                  const SizedBox(height: 20),
                  labeltext("Mobile:"),
                  textFieldPhone(phoneController, 'Mobile', true),
                  const SizedBox(height: 20),
                  labeltext("Address:"),
                  textFieldCustom(addressController, 'Address',
                      isAdmin == 0 ? true : false),
                  const SizedBox(height: 20),
                  labeltext("Shop Type:"),
                  textFieldCustom(shopTypeController, 'Shop Type', true),
                  const SizedBox(height: 20),
                  labeltext("GSTIN Number:"),
                  textFieldCustom(gstinController, 'GSTIN Number',
                      isAdmin == 0 ? true : false),
                  const SizedBox(height: 40.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: customElevatedButton(
                        "Update Changes", blue, white, _submitData),
                  ),
                ],
              ),
            ),
    );
  }
}
