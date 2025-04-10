// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Subscriptions extends StatefulWidget {
  const Subscriptions({super.key});

  @override
  State<Subscriptions> createState() => _SubscriptionsState();
}

class _SubscriptionsState extends State<Subscriptions> {
  List<dynamic> plans = [];
  bool isLoading = true;
  String currentPlan = '';
  String expiryDate = '';
  String? currencySymbol;

  @override
  void initState() {
    super.initState();
    getPlans();
    getCurrentPlan();
    setCurrencySymbol();
  }

  setCurrencySymbol() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencySymbol = prefs.getString('currencySymbol');
    });
    print('currencySymbol: $currencySymbol');
  }

  Future<void> getPlans() async {
    try {
      var token = await APIService.getToken();
      var apiKey = await APIService.getXApiKey();
      Uri url = Uri.parse("$baseUrl/subscription-plans");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          plans = jsonData['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching plans: $e');
    }
  }

  getCurrentPlan() async {
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    try {
      Uri url = Uri.parse("$baseUrl/user-detail");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          currentPlan = jsonData["subscription_current_plan"] ?? 'N/A';
          expiryDate = jsonData["subscription_expiry_date"] ?? 'N/A';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching plans: $e');
    }
  }

  Widget buildPlanCard(
      Map<String, dynamic> plan, double screenHeight, double screenWidth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 15, 00, 0),
      margin: EdgeInsets.fromLTRB(
          screenWidth * 0.07, screenWidth * 0.07, screenWidth * 0.07, 0),
      height: screenHeight * 0.23,
      width: screenWidth * 0.5,
      decoration: const BoxDecoration(
        // border: Border(
        //   top: BorderSide(color: black, width: 2),
        // ),
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: lightGrey,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            plan['plan_name'],
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto-Regular',
                fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text(
            "Price: $currencySymbol${plan['price'].toString()}/-",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto-Regular',
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {},
            child: Container(
                decoration: const BoxDecoration(
                    color: black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    )),
                height: screenHeight * 0.06,
                width: double.maxFinite,
                child: const Center(
                  child: Text(
                    "Subscribe Now",
                    style: TextStyle(
                      color: white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = customAppBar("Subscriptions", []);

    final screenHeight =
        MediaQuery.of(context).size.height - appBar.preferredSize.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: white,
      appBar: appBar,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
              ? const Center(child: Text('No subscription plans available'))
              : Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [white, Color(0xff95BB72)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        SizedBox(
                          width: screenWidth * 0.85,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Current Plan Details",
                                  style: TextStyle(
                                      fontFamily: 'Roboto-Regular',
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "Plan: $currentPlan",
                                  style: const TextStyle(
                                    fontFamily: 'Roboto-Regular',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "Expiry Date: $expiryDate",
                                  style: const TextStyle(
                                    fontFamily: 'Roboto-Regular',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]),
                        ),
                        ...plans.map((plan) =>
                            buildPlanCard(plan, screenHeight, screenWidth)),
                        const SizedBox(height: 20),
                        const Text(
                          "Sales and Technical Support",
                          style: TextStyle(
                              fontFamily: 'Roboto-Regular',
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, color: black),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "+91 88227 74191 / +91 98640 81806",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email, color: black),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "info@alegralabs.com",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
    );
  }
}
