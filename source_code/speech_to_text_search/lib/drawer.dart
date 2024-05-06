import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/account.dart';
import 'package:speech_to_text_search/add_product.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/login_profile.dart';
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/preferences.dart';
import 'package:speech_to_text_search/sub_user_signup.dart';
import 'package:speech_to_text_search/transaction_list.dart';
import 'package:speech_to_text_search/update_inventory.dart';

class Sidebar extends StatefulWidget {
  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _name = '';
  String _userName = '';
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadName();
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
    print(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          // Handle back button press

          return true; // Return true to allow popping the route
        },
        child: Container(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(243, 203, 71, 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/user.png'),
                      backgroundColor: Color.fromRGBO(243, 203, 71, 1),
                    ),
                    Text(
                      'Hello $_name',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      '$_userName',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add Inventory'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AddInventory()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('Update Inventory'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ProductListPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.document_scanner),
                title: Text('Transactions'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TransactionListPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.person_add_rounded),
                title: Text('User'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpSubUserScreen()),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Preferences'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => PreferencesPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Account'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => UserDetailForm()),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.password),
                title: Text('Change Password'),
                onTap: () {
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => PreferencesPage()),
                  // );
                },
              ),

              ListTile(
                leading: Icon(Icons.account_balance_outlined),
                title: Text('Subscription'),
                onTap: () {
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => PreferencesPage()),
                  // );
                },
              ),

              Divider(), // Add a horizontal line
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () {
                  _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(
        onItemSelected: (index) {
          // Handle navigation item selection
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
      ),
    );
  }

  void _logout(BuildContext context) async {
    EasyLoading.show(status: 'Logging out...');
    try {
      var token = await APIService.getToken();
      final String apiUrl = '$baseUrl/logout';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('User is logged out successfully.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        final jsonData = json.decode(response.body);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to logout. Please try again.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Exception: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while logging out. Please try again.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
