import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/scheduler.dart';

class Internetchecker extends StatefulWidget {
  const Internetchecker({super.key});

  @override
  State<Internetchecker> createState() => _InternetcheckerState();
}

class _InternetcheckerState extends State<Internetchecker>
    with WidgetsBindingObserver {
  bool isConnectedToInternet = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // Observer for app lifecycle changes
    _checkConnection();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this); // Remove observer on dispose
    super.dispose();
  }

  void _checkConnection() {
    // Listen for connection changes
    InternetConnection().onStatusChange.listen((event) {
      // Add a debounce mechanism to avoid quick state changes
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        switch (event) {
          case InternetStatus.connected:
            if (!isConnectedToInternet) {
              setState(() {
                isConnectedToInternet = true;
              });
            }
            break;
          case InternetStatus.disconnected:
            if (isConnectedToInternet) {
              setState(() {
                isConnectedToInternet = false;
              });
            }
            break;
          default:
            setState(() {
              isConnectedToInternet = false;
            });
        }
      });
    });
  }

  // Override the lifecycle event to check connection when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check internet connection again after waking up
      _checkConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return isConnectedToInternet
        ? const SizedBox.shrink()
        : Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              color: const Color.fromARGB(255, 211, 130, 124),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 33,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.02,
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Internet Not Available"),
                    Text(
                      "Please check your internet connection",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}
