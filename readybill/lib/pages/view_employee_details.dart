import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/pages/change_password_page.dart';
import 'package:readybill/pages/view_employee.dart';
import 'package:readybill/services/api_services.dart';
import 'package:http/http.dart' as http;
import 'package:readybill/services/country_code_provider.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';

class ViewEmployeeDetails extends StatefulWidget {
  final Employee user;

  const ViewEmployeeDetails({super.key, required this.user});

  @override
  State<ViewEmployeeDetails> createState() => _ViewEmployeeDetailsState();
}

class _ViewEmployeeDetailsState extends State<ViewEmployeeDetails> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Store the image file instead of Image widget
  File? selectedImageFile;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.user.name;
    mobileController.text = widget.user.mobile;
    addressController.text = widget.user.address;
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

  Future<void> updateUserDetails() async {
    print(
        'edit employee country code: ${Provider.of<CountryCodeProvider>(context, listen: false).editEmployeePageCountryCode}');
    try {
      String? token = await APIService.getToken();
      String? apiKey = await APIService.getXApiKey();
      EasyLoading.show(status: 'Updating...');

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/update-sub-users'));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'auth-key': '$apiKey',
      });

      request.fields['name'] = nameController.text;
      request.fields['address'] = addressController.text;
      request.fields['mobile'] = mobileController.text;
      request.fields['staff_id'] = widget.user.id.toString();
      request.fields['country_code'] =
          Provider.of<CountryCodeProvider>(context, listen: false)
              .editEmployeePageCountryCode;

      if (selectedImageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          selectedImageFile!.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      EasyLoading.dismiss();

      print("status code: ${response.statusCode}");
      if (response.statusCode == 201) {
        var jsonData = jsonDecode(response.body);
        Fluttertoast.showToast(msg: jsonData['message'].toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return const EmployeeListPage();
        }));
      } else {
        Fluttertoast.showToast(msg: 'Update failed');
      }
    } catch (e) {
      print(e);
      EasyLoading.dismiss();
      Fluttertoast.showToast(msg: 'Error updating details');
    }
  }

  Widget labeltext(String label) {
    return Text(
      label,
      style: const TextStyle(
          color: black,
          fontFamily: 'Roboto-Regular',
          fontWeight: FontWeight.bold,
          fontSize: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Employee Details", []),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
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
                            : (widget.user.photo != 'N/A'
                                ? NetworkImage(
                                        "https://dev.readybill.app/storage/photo/${widget.user.photo}")
                                    as ImageProvider
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
              const SizedBox(
                height: 40,
              ),
              labeltext("Enter Name:"),
              buildTextField("Enter Name", nameController),
              const SizedBox(
                height: 20,
              ),
              labeltext("Enter Mobile Number:"),
              buildPhoneField("Enter Mobile Number", mobileController),
              const SizedBox(
                height: 20,
              ),
              labeltext("Enter Address:"),
              buildTextField("Enter Address", addressController),
              const SizedBox(height: 20),
              customElevatedButton("Change Password", blue, white, () {
                navigatorKey.currentState
                    ?.push(CupertinoPageRoute(builder: (context) {
                  return ChangePasswordPage(
                    phoneNumber: widget.user.mobile,
                    smsType: 'chnange_password',
                    countryCode: '+91',
                  );
                }));
              }),
              SizedBox(
                  width: double.infinity,
                  child: customElevatedButton(
                      "Update", green2, white, updateUserDetails)),
            ],
          ),
        ),
      ),
    );
  }

  buildTextField(String label, TextEditingController controller) {
    return TextField(
      textCapitalization: TextCapitalization.words,
      decoration: customTfInputDecoration(label),
      controller: controller,
    );
  }

  buildPhoneField(String label, TextEditingController controller) {
    return TextField(
      textCapitalization: TextCapitalization.words,
      decoration: phoneNumberInputDecoration(
          label,
          Provider.of<CountryCodeProvider>(context)
              .setEditEmployeePageCountryCode,
          widget.user.countryCode),
      controller: controller,
    );
  }
}
