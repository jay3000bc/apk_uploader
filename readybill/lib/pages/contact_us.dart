import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:readybill/services/api_services.dart';
import 'package:http/http.dart' as http;
import 'package:readybill/services/country_code_provider.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _messageFocusNode = FocusNode();
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(26.158480796775176, 91.68502376783557);
  final formKey = GlobalKey<FormState>();
  String emailErrorMessage = "";
  String countryCode = '';

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  submitData() async {
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    var url = Uri.parse('$baseUrl/contact-submit');
    EasyLoading.show();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'auth-key': '$apiKey',
      },
      body: {
        'full_name': _nameController.text,
        'email': _emailController.text,
        'contact_no': _phoneController.text,
        'message': _messageController.text
      },
    );
    EasyLoading.dismiss();
    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: "Message sent successfully");
      _nameController.text = "";
      _emailController.text = "";
      _phoneController.text = "";
      _messageController.text = "";
    } else {
      var jsonData = jsonDecode(response.body);
      print(jsonData);
      var emailError = jsonData['errors']['email'][0];

      if (emailError != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            emailErrorMessage = emailError;
          });
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Contact Us",[]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                height: 200,
                width: MediaQuery.of(context).size.width,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 11.0,
                    ),
                    markers: {
                      const Marker(
                        markerId: MarkerId('Alegra labs'),
                        position: LatLng(26.15797032330177, 91.68481049710812),
                      )
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              labeltext("Full Name: *"),
              const SizedBox(
                height: 8,
              ),
              TextFormField(
                focusNode: _nameFocusNode,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _nameFocusNode.requestFocus();
                    return "Full Name is required";
                  } else {
                    return null;
                  }
                },
                controller: _nameController,
                decoration: customTfInputDecoration("Enter Full Name *"),
              ),
              const SizedBox(
                height: 12,
              ),
              labeltext("Contact Number: *"),
              const SizedBox(
                height: 8,
              ),
              TextFormField(
                focusNode: _phoneFocusNode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _phoneFocusNode.requestFocus();
                    return "Contact Number is required";
                  } else if (value.length < 10) {
                    _phoneFocusNode.requestFocus();
                    return "Number must be of 10 digits";
                  } else {
                    return null;
                  }
                },
                keyboardType: TextInputType.number,
                controller: _phoneController,
                decoration: phoneNumberInputDecoration(
                    "Enter Contact Number *",
                    Provider.of<CountryCodeProvider>(context, listen: false)
                        .setContactPageCountryCode,
                    ''),
              ),
              const SizedBox(
                height: 12,
              ),
              labeltext("Email: *"),
              const SizedBox(
                height: 8,
              ),
              TextFormField(
                focusNode: _emailFocusNode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _emailFocusNode.requestFocus();
                    return "Email is required";
                  } else if (emailErrorMessage != "") {
                    return emailErrorMessage;
                  } else {
                    return null;
                  }
                },
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: customTfInputDecoration("Enter Email *"),
              ),
              const SizedBox(
                height: 12,
              ),
              labeltext("Message: *"),
              const SizedBox(
                height: 8,
              ),
              TextFormField(
                focusNode: _messageFocusNode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _messageFocusNode.requestFocus();
                    return "Message is required";
                  } else {
                    return null;
                  }
                },
                controller: _messageController,
                maxLines: 5,
                decoration: customTfInputDecoration("Enter Your Message *"),
              ),
              const SizedBox(
                height: 12,
              ),
              SizedBox(
                width: double.infinity,
                child: customElevatedButton("Submit", blue, white, () {
                  if (formKey.currentState!.validate()) {
                    submitData();
                  }
                }),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
