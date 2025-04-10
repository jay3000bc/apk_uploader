// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/pages/account.dart';
import 'package:readybill/pages/add_product.dart';
import 'package:readybill/pages/change_password_page.dart';
import 'package:readybill/pages/contact_us.dart';
import 'package:readybill/pages/new_dataset.dart';

import 'package:readybill/pages/home_page.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/pages/preferences.dart';
import 'package:readybill/pages/add_employee.dart';

import 'package:readybill/pages/printer_connected.dart';
import 'package:readybill/pages/subscriptions.dart';
import 'package:readybill/pages/support.dart';
import 'package:readybill/pages/transaction_list.dart';
import 'package:readybill/pages/view_inventory.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';

import 'package:readybill/services/result.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _name = '';

  String imageUrl = '';
  Image? logo;
  int isAdmin = 0;
  int? userID;
  String shopName = '';
  String address = '';
  String phone = '';
  int? subscriptionExpired;
  String _selectedPaperSize = '';
  final Uri _userDataUrl = Uri.parse('$baseUrl/user-detail');
  String countryCode = '';
  String dialCode = '';

  @override
  void initState() {
    super.initState();

    _getData();
  }

  noSubscriptionDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return customAlertBox(
              title: "No Subscription Found",
              content:
                  "No valid subscription found for the shop.\nPress 'OK' to get a new subscription.",
              actions: [
                customElevatedButton("OK", green2, white, () {
                  navigatorKey.currentState!.pop();
                  navigatorKey.currentState!.push(CupertinoPageRoute(
                      builder: (context) => const Subscriptions()));
                }),
                customElevatedButton("Cancel", red, white, () {
                  navigatorKey.currentState!.pop();
                })
              ]);
        });
  }

  Future<void> _getData() async {
    String? token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedPaperSize = prefs.getString('paperSize') ?? '80mm';

    final response = await http.get(
      _userDataUrl,
      headers: {'Authorization': 'Bearer $token', 'auth-key': '$apiKey'},
    );

    print(response.body);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (mounted) {
        setState(() {
          imageUrl = jsonData['logo'];
          imageUrl == "assets/img/user.jpg"
              ? logo = Image.asset('assets/user.png')
              : logo = Image.network(imageUrl);
          userID = jsonData['data']['user_id'];
          isAdmin = jsonData['data']['isAdmin'];
          _name = jsonData['data']['details']['name'];
          shopName = jsonData['data']['details']['business_name'];
          address = jsonData['data']['details']['address'];
          phone = jsonData['data']['mobile'];
          subscriptionExpired = jsonData['isSubscriptionExpired'];
          countryCode = jsonData['data']['country_details']['code'];
          dialCode = jsonData['data']['country_details']['dial_code'];
        });
      }
    }
  }

  Widget _buildPrinterSelector() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final device = await FlutterBluetoothPrinter.selectDevice(context);
      if (device != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('printerAddress', device.address);

        if (context.mounted) {
          _showPaperSizeDialog(context);
        }
      } else {
        // If no printer was selected, close the modal
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showPaperSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Paper Size"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('80mm'),
                    value: '80mm',
                    groupValue: _selectedPaperSize,
                    onChanged: (String? value) async {
                      if (value != null) {
                        setState(() {
                          _selectedPaperSize = value;
                        });
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString('paperSize', value);

                        print('paper size: ${prefs.getString('paperSize')}');
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('58mm'),
                    value: '58mm',
                    groupValue: _selectedPaperSize,
                    onChanged: (String? value) async {
                      if (value != null) {
                        setState(() {
                          _selectedPaperSize = value;
                        });
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString('paperSize', value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                customElevatedButton("Save", blue, white, () async {
                  navigatorKey.currentState?.pop();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('paperSize', _selectedPaperSize);
                  navigatorKey.currentState
                      ?.push(MaterialPageRoute(builder: (context) {
                    return const PrinterConnected();
                  }));
                })
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget drawerHeader = Container(
      padding: EdgeInsets.only(
          left: 20,
          top: MediaQuery.of(context).padding.top * 1.5,
          bottom: 10,
          right: 10),
      decoration: const BoxDecoration(
        color: green2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundImage: logo?.image,
            backgroundColor: green2,
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 22,
                        fontFamily: 'Roboto-Regular',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isAdmin == 1)
                      const Text(
                        "(Admin)",
                        style: TextStyle(
                          fontFamily: 'Roboto-Regular',
                          fontSize: 18,
                        ),
                      ),
                  ],
                ),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: white,
                  ),
                ),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 16,
                    color: white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 16,
                    color: white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, d) async {
          // Navigate to NextPage when user tries to pop MyHomePage
          navigatorKey.currentState?.pushReplacement(
            CupertinoPageRoute(builder: (context) => const HomePage()),
          );
          // Return false to prevent popping the current route
          return; // Return true to allow popping the route
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            drawerHeader,
            isAdmin == 1
                ? ListTile(
                    leading: Icon(Icons.add,
                        color: subscriptionExpired == 0 ? black : darkGrey),
                    title: Text(
                      'Add Inventory',
                      style: TextStyle(
                          fontFamily: 'Roboto-Regular',
                          color: subscriptionExpired == 0 ? black : darkGrey),
                    ),
                    onTap: () {
                      subscriptionExpired == 0
                          ? navigatorKey.currentState?.push(
                              CupertinoPageRoute(
                                  builder: (context) => const AddInventory()),
                            )
                          : noSubscriptionDialog();
                    },
                  )
                : const SizedBox.shrink(),
            isAdmin == 1
                ? ListTile(
                    leading: Icon(Icons.inventory_2_outlined,
                        color: subscriptionExpired == 0 ? black : darkGrey),
                    title: Text(
                      'Update Inventory',
                      style: TextStyle(
                          fontFamily: 'Roboto-Regular',
                          color: subscriptionExpired == 0 ? black : darkGrey),
                    ),
                    onTap: () {
                      subscriptionExpired == 0
                          ? navigatorKey.currentState?.push(
                              CupertinoPageRoute(
                                  builder: (context) =>
                                      const ProductListPage()),
                            )
                          : noSubscriptionDialog();
                    },
                  )
                : const SizedBox.shrink(),
            ListTile(
              leading: Icon(Icons.document_scanner_outlined,
                  color: subscriptionExpired == 0 ? black : darkGrey),
              title: Text(
                'Transactions',
                style: TextStyle(
                    fontFamily: 'Roboto-Regular',
                    color: subscriptionExpired == 0 ? black : darkGrey),
              ),
              onTap: () {
                subscriptionExpired == 0
                    ? navigatorKey.currentState?.push(
                        CupertinoPageRoute(
                            builder: (context) => const TransactionListPage()),
                      )
                    : noSubscriptionDialog();
              },
            ),
            isAdmin == 1
                ? ListTile(
                    leading: Icon(Icons.person_add_outlined,
                        color: subscriptionExpired == 0 ? black : darkGrey),
                    title: Text(
                      'Add Employee',
                      style: TextStyle(
                          fontFamily: 'Roboto-Regular',
                          color: subscriptionExpired == 0 ? black : darkGrey),
                    ),
                    onTap: () {
                      subscriptionExpired == 0
                          ? navigatorKey.currentState?.push(
                              CupertinoPageRoute(
                                  builder: (context) =>
                                      const EmployeeSignUpPage()),
                            )
                          : noSubscriptionDialog();
                    },
                  )
                : const SizedBox.shrink(),
            isAdmin == 1
                ? ListTile(
                    leading: Icon(Icons.settings_outlined,
                        color: subscriptionExpired == 0 ? black : darkGrey),
                    title: Text(
                      'Preferences',
                      style: TextStyle(
                          fontFamily: 'Roboto-Regular',
                          color: subscriptionExpired == 0 ? black : darkGrey),
                    ),
                    onTap: () {
                      subscriptionExpired == 0
                          ? navigatorKey.currentState?.push(
                              CupertinoPageRoute(
                                  builder: (context) =>
                                      const PreferencesPage()),
                            )
                          : noSubscriptionDialog();
                    },
                  )
                : const SizedBox.shrink(),
            const Divider(
              color: darkGrey,
              indent: 15,
              endIndent: 15,
            ),
            ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('Connect Printer'),
                onTap: () {
                  _buildPrinterSelector();
                }),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Account'),
              onTap: () {
                navigatorKey.currentState?.push(
                  CupertinoPageRoute(builder: (context) => const UserAccount()),
                );
              },
            ),
            isAdmin == 1
                ? ListTile(
                    leading: const Icon(Icons.password_outlined),
                    title: const Text('Change Password'),
                    onTap: () {
                      navigatorKey.currentState?.push(
                        CupertinoPageRoute(
                            builder: (context) => ChangePasswordPage(
                                  smsType: 'change_password',
                                  phoneNumber: phone,
                                  countryCode: countryCode,
                                )),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            isAdmin == 1
                ? ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Upload Dataset'),
                    onTap: () {
                      navigatorKey.currentState?.push(
                        CupertinoPageRoute(
                            builder: (context) =>
                                const NewDataset(title: "Dataset")),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            isAdmin == 1
                ? ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Subscription'),
                    onTap: () {
                      navigatorKey.currentState?.push(
                        CupertinoPageRoute(
                          builder: (context) => const Subscriptions(),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Support'),
              onTap: () {
                navigatorKey.currentState?.push(
                  CupertinoPageRoute(
                    builder: (context) => const ContactSupportPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_page_outlined),
              title: const Text('Contact Us'),
              onTap: () {
                navigatorKey.currentState?.push(
                  CupertinoPageRoute(
                    builder: (context) => const ContactUsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fcmToken = prefs.getString('fcmToken') ?? '';
    print('fcmToken: $fcmToken');
    EasyLoading.show(status: 'Logging out...');
    try {
      var token = await APIService.getToken();
      var apiKey = await APIService.getXApiKey();

      const String apiUrl = '$baseUrl/logout';
      final response = await http.post(Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'auth-key': '$apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'device_token': fcmToken,
          }));

      print(response.body);

      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        navigatorKey.currentState?.pushReplacement(
          CupertinoPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        print("logout error");
      }
    } catch (e) {
      print("Logout error: $e");
      Result.error("Book list not available");
    }
  }
}
