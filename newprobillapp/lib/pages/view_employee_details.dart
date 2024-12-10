import 'package:flutter/material.dart';
import 'package:newprobillapp/pages/home_page.dart';
import 'package:newprobillapp/pages/view_employee.dart';

class ViewEmployeeDetails extends StatelessWidget {
  final Employee user;

  const ViewEmployeeDetails({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const HomePage();
          }));
        },
        child: const Icon(Icons.edit),
      ),
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
            title: const Text('Name'),
            subtitle: Text(user.name),
          ),
          ListTile(
            title: const Text('Mobile'),
            subtitle: Text(user.mobile),
          ),
          ListTile(
            title: const Text('Address'),
            subtitle: Text(user.address),
          ),
        ],
      ),
    );
  }
}
