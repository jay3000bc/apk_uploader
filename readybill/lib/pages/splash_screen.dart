import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/pages/home_page.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/country_code_provider.dart';
import 'package:readybill/services/firebase_api.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/local_database_2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  //bool _isLoggedIn = false;
  late AnimationController _controller;
  late Animation<double> _logoWidthAnimation;
  late Animation<double> _logoOpacityAnimation;
  @override
  void initState() {
    super.initState();
    _checkInternet();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoWidthAnimation = Tween<double>(
      begin: 0.0,
      end: 300.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6),
      ),
    );

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkInternet() async {
    bool result = await InternetConnection().hasInternetAccess;
    if (result) {
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
        builder: (context) => customAlertBox(
              title: 'No Internet Connection',
              content: 'Please check your internet connection and try again.',
              actions: <Widget>[
                customElevatedButton('Retry', green2, white, () {
                  navigatorKey.currentState?.pop();
                  _checkInternet();
                }),
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
    bool storageGranted = await _checkAndRequestPermissionStorage();
    bool locationGranted = await _checkAndRequestPermissionLocation();

    await FirebaseApi().initNotifications();

    await handleLogin();
  }

  Future<bool> _checkAndRequestPermissionStorage() async {
    var status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.storage.request();
      // Check if permission was granted after request
      if (status != PermissionStatus.granted) {
        // Handle denied permission
        _handleDeniedStoragePermission();
        return false;
      }
    }
    return true;
  }

  Future<String> getCountryName() async {
    Position position = await GeolocatorPlatform.instance.getCurrentPosition();
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    return placemarks.first.isoCountryCode!;
  }

  Future<bool> _checkAndRequestPermissionLocation() async {
    var status = await Permission.location.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.location.request();
      // Check if permission was granted after request
      if (status != PermissionStatus.granted) {
        // Handle denied permission
        _handleDeniedLocationPermission();
        return false;
      }
    }
    String countryCode = await getCountryName();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('countryCode', countryCode);
    Provider.of<CountryCodeProvider>(context, listen: false)
        .setAllCountryCodes(countryCode);
    return true;
  }

  void _handleDeniedStoragePermission() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => customAlertBox(
        title: 'Storage Permission Required',
        content:
            'This app needs storage access to save essential files. Without this permission, some features may not work properly.',
        actions: <Widget>[
          customElevatedButton('Open Settings', green2, white, () {
            openAppSettings();
            Navigator.pop(context);
          }),
          customElevatedButton('Continue Anyway', red, white, () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  void _handleDeniedLocationPermission() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => customAlertBox(
        title: 'Location Permission Required',
        content:
            'This app needs location access to provide location-based services. Without this permission, some features may not work properly.',
        actions: <Widget>[
          customElevatedButton('Open Settings', green2, white, () {
            // Open app settings so user can enable permissions
            openAppSettings();
            Navigator.pop(context);
          }),
          TextButton(
            onPressed: () {
              // Continue with limited functionality
              Navigator.pop(context);
              // The _checkPermissionsAndLogin will continue after this dialog is dismissed
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

// You might want to consider adding this method to track which permissions were granted
  void _trackPermissionsAndProceed(
      {bool storageGranted = false, bool locationGranted = false}) {
    // Store permission state for later use
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('storage_permission_granted', storageGranted);
      prefs.setBool('location_permission_granted', locationGranted);
    });

    // Warn user about limited functionality based on which permissions were denied
    List<String> deniedPermissions = [];
    if (!storageGranted) deniedPermissions.add('storage');
    if (!locationGranted) deniedPermissions.add('location');

    if (deniedPermissions.isNotEmpty) {
      String message =
          'Some features related to ${deniedPermissions.join(', ')} '
          'will not be available. You can enable permissions later in app settings.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    }
  }

  storeFcmToken(token, apiKey) async {
    print('storing fcm token');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fcmToken = prefs.getString('fcmToken') ?? '';
    print('fcmtoken: $fcmToken');
    var response = await http.post(Uri.parse('$baseUrl/set-device-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_token': fcmToken,
        }));

    print(response.body);
  }

  Future<void> handleLogin() async {
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    // print('token in handlelogin: $token');
    if (token != null && apiKey != null) {
      int statusReturnCode =
          await APIService.getUserDetailsWithoutDialog(token, apiKey);
      print('statusReturnCode: $statusReturnCode');
      if (statusReturnCode == 404 || statusReturnCode == 333) {
        _navigateToLoginScreen();
      } else if (statusReturnCode == 200) {
        LocalDatabase2.instance.clearTable();
        LocalDatabase2.instance.fetchDataAndStoreLocally();
        storeFcmToken(token, apiKey);
        _navigateToSearchApp();
        await _setLoggedInStatus(true); // Ensure this is awaited
      } else {
        _navigateToLoginScreen();
      }
    } else {
      _navigateToLoginScreen();
    }
    setState(() {
      //_isLoggedIn = true;
    });
  }

  Future<void> _setLoggedInStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn); // Ensure this is awaited
  }

  void _navigateToLoginScreen() {
    Future.delayed(const Duration(milliseconds: 2200), () {
      navigatorKey.currentState?.pushReplacement(
        CupertinoPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  void _navigateToSearchApp() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      navigatorKey.currentState?.pushReplacement(
        CupertinoPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoWidthAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: _logoWidthAnimation.value,
                  child: child,
                );
              },
              child: Image.asset("assets/ReadyBillBlack.png"),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _logoOpacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/AlegraLabsBlack.png',
                width: 240,
              ),
            ),
            const SizedBox(height: 180),
          ],
        ),
      ),
    );
  }
}
