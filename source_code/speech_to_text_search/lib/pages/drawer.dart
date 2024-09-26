// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:speech_to_text_search/Service/internet_checker.dart';
import 'package:speech_to_text_search/service/api_constants.dart';
import 'package:speech_to_text_search/service/result.dart';
import 'package:speech_to_text_search/service/account.dart';
import 'package:speech_to_text_search/pages/add_product.dart';
import 'package:speech_to_text_search/service/is_login.dart';
import 'package:speech_to_text_search/pages/login_profile.dart';
import 'package:speech_to_text_search/components/navigation_bar.dart';
import 'package:speech_to_text_search/pages/preferences.dart';
import 'package:speech_to_text_search/pages/search_app.dart';
import 'package:speech_to_text_search/pages/sub_user_signup.dart';
import 'package:speech_to_text_search/pages/transaction_list.dart';
import 'package:speech_to_text_search/pages/view_inventory.dart';
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchApp()),
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
              title: const Text('User'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SignUpSubUserScreen()),
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
                  MaterialPageRoute(
                      builder: (context) => const UserDetailForm()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Password'),
              onTap: () {
                _launchUrl(_url);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => PreferencesPage()),
                // );
              },
            ),

            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Subscription'),
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => PreferencesPage()),
                // );
              },
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
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        // Directly navigate to login screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Directly navigate to login screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      Result.error("Book list not available");
      // Directly navigate to login screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}
