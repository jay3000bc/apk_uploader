import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:newprobillapp/pages/home_page.dart';
import 'package:newprobillapp/pages/login_page.dart';
import 'package:newprobillapp/services/api_services.dart';
import 'package:newprobillapp/services/local_database.dart';
import 'package:newprobillapp/services/product_mic_state.dart';
import 'package:newprobillapp/services/quantity_mic_state.dart';

import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MicState()),
        ChangeNotifierProvider(create: (context) => QuantityMicState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light()
            .copyWith(primary: const Color(0xFFF2CC44)),
        // Set primary color here
        // You can also set other theme properties here if needed
      ),
      builder: EasyLoading.init(),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkInternet();
  }

  Future<void> _checkInternet() async {
    bool result = await InternetConnection().hasInternetAccess;
    if (result) {
      print('Internet available');
      _checkPermissionsAndLogin();
      //LocalDatabase.instance.clearTable();
      //LocalDatabase.instance.fetchDataAndStoreLocally();
    } else {
      _noInternetDialog();
    }
  }

  void _noInternetDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('No Internet Connection'),
              content: const Text(
                  'Please check your internet connection and try again.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkInternet();
                  },
                  child: const Text('Retry'),
                ),
                TextButton(
                    onPressed: () {
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      }
                      if (Platform.isIOS) {
                        exit(0);
                      }
                    },
                    child: const Text('Exit')),
              ],
            ));
  }

  Future<void> _checkPermissionsAndLogin() async {
    await _checkAndRequestPermissionStorage();
    await _handleLogin();
  }

  Future<void> _checkAndRequestPermissionStorage() async {
    var status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      await Permission.storage.request();
    }
  }

  Future<void> _handleLogin() async {
    String? token = await APIService.getToken();
    if (token != null) {
      int statusReturnCode =
          await APIService.getUserDetailsWithoutDialog(token);
      if (statusReturnCode == 404 || statusReturnCode == 333) {
        _navigateToLoginScreen();
      } else if (statusReturnCode == 200) {
        print('statusCode: $statusReturnCode');
        LocalDatabase.instance.clearTable();
        LocalDatabase.instance.fetchDataAndStoreLocally();
        _navigateToSearchApp();
        await _setLoggedInStatus(true); // Ensure this is awaited
      } else {
        _navigateToLoginScreen();
      }
    } else {
      _navigateToLoginScreen();
    }
    setState(() {
      _isLoggedIn = true;
    });
  }

  Future<void> _setLoggedInStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn); // Ensure this is awaited
  }

  Future<bool> _getLoggedInStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _navigateToSearchApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                "assets/logo256.png",
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),
            _isLoggedIn ? const CircularProgressIndicator() : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
