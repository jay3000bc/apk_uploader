import 'package:flutter/material.dart';

class ViewSubUserDetails extends StatelessWidget {
  final user;

  const ViewSubUserDetails({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Details',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Name'),
            subtitle: Text(user.name),
          ),
          ListTile(
            title: Text('Mobile'),
            subtitle: Text(user.mobile),
          ),
          ListTile(
            title: Text('Address'),
            subtitle: Text(user.address),
          ),
        ],
      ),
    );
  }
}
