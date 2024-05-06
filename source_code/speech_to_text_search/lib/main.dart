import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:speech_to_text_search/product_mic_state.dart';
import 'package:speech_to_text_search/quantity_mic_state.dart';
import 'package:speech_to_text_search/search_app.dart';
import 'package:speech_to_text_search/login_profile.dart';
import 'package:speech_to_text_search/Service/is_login.dart'; 
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MicState()),
        ChangeNotifierProvider(create: (context) => QuantityMicState()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          // colorScheme: ColorScheme.light().copyWith(primary: Color(0xFF233376)),
          // Set primary color here
          // You can also set other theme properties here if needed
          ),
      builder: EasyLoading.init(),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLogin();
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
      int statusReturnCode = await APIService.getUserDetailsWithoutDialog(token);
      if (statusReturnCode == 404 || statusReturnCode == 333) {
        _navigateToLoginScreen();
      } else if (statusReturnCode == 200) {
        _navigateToSearchApp();
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

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToSearchApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SearchApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(243, 203, 71, 1),
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
            SizedBox(height: 20),
            _isLoggedIn ? CircularProgressIndicator() : SizedBox(),
          ],
        ),
      ),
    );
  }
}
