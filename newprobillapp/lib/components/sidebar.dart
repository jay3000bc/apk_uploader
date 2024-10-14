// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:newprobillapp/components/api_constants.dart';
import 'package:newprobillapp/pages/account.dart';
import 'package:newprobillapp/pages/add_product.dart';
import 'package:newprobillapp/pages/home_page.dart';
import 'package:newprobillapp/pages/login_page.dart';
import 'package:newprobillapp/pages/preferences.dart';
import 'package:newprobillapp/pages/employee_signup.dart';
import 'package:newprobillapp/pages/transaction_list.dart';
import 'package:newprobillapp/pages/view_inventory.dart';
import 'package:newprobillapp/services/api_services.dart';
import 'package:newprobillapp/services/internet_checker.dart';
import 'package:newprobillapp/services/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:url_launcher/url_launcher.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _name = '';
  String _userName = '';
  int _selectedIndex = 3;
  String imageUrl = '';
  Image? logo;

  final Uri _imageUrl = Uri.parse('$baseUrl/user-detail');

  final Uri _url = Uri.parse('https://probill.app/forgot-password');

  @override
  void initState() {
    super.initState();
    _loadName();
    _getLogo();
  }

  Future<void> _getLogo() async {
    String? token = await APIService.getToken();
    final response = await http.get(
      _imageUrl,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (mounted) {
        setState(() {
          imageUrl = jsonData['logo'];
          logo = Image.network(imageUrl);
        });
      }
    }
  }

  Future<void> _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('name');
    String? userName = prefs.getString('username');
    if (name != null && name.isNotEmpty) {
      setState(() {
        _name = name;
        _userName = userName!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          _selectedIndex = 0;
          // Navigate to NextPage when user tries to pop MyHomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          // Return false to prevent popping the current route
          return; // Return true to allow popping the route
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(243, 203, 71, 1),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Internetchecker(),
                    ),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: logo?.image,
                      backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
                    ),
                    Text(
                      'Hello $_name',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Inventory'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddInventory()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Update Inventory'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProductListPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Transactions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TransactionListPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_rounded),
              title: const Text('Employee'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EmployeeSignUpPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Preferences'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PreferencesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Account'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserAccount()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Password'),
              onTap: () {
                _launchUrl(_url);
              },
            ),

            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Subscription'),
              onTap: () {},
            ),

            const Divider(), // Add a horizontal line
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

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _logout(BuildContext context) async {
    EasyLoading.show(status: 'Logging out...');
    try {
      var token = await APIService.getToken();
      const String apiUrl = '$baseUrl/logout';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print(response.statusCode);
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        // Directly navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // Directly navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      Result.error("Book list not available");
      // Directly navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }
}
