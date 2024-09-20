import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class Internetchecker extends StatefulWidget {
  const Internetchecker({super.key});

  @override
  State<Internetchecker> createState() => _InternetcheckerState();
}

class _InternetcheckerState extends State<Internetchecker> {
  bool isConnectedToIntenet = true;

  @override
  Widget build(BuildContext context) {
    InternetConnection().onStatusChange.listen((event) {
      // print("Event: $event");
      switch (event) {
        case InternetStatus.connected:
          setState(() {
            isConnectedToIntenet = true;
          });

          break;
        case InternetStatus.disconnected:
          setState(() {
            isConnectedToIntenet = false;
          });

          break;
        default:
          setState(() {
            isConnectedToIntenet = false;
          });
      }
    });

    return isConnectedToIntenet
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
