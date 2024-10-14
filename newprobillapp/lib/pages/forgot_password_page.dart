import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'package:newprobillapp/components/api_constants.dart';
import 'package:newprobillapp/pages/login_page.dart';


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController emailController = TextEditingController();

  Future<void> _forgotPassword(String email) async {
    print('email: $email');
    var forgotPasswordUrl = Uri.parse("$baseUrl/forgot-password");

    final response = await http.post(forgotPasswordUrl, body: {'email': email});
    print(response.body);

    if (response.statusCode == 200) {
      var result = json.decode(response.body);
      Fluttertoast.showToast(msg: result['message']);
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {}); // Rebuild the widget when the focus changes
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color(0xFFF2CC44),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Enter your e-mail to receive a password reset link.",
            ),
            const SizedBox(height: 20),
            TextField(
              focusNode: _emailFocusNode,
              controller: emailController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: IconTheme(
                  data: IconThemeData(
                    color: _emailFocusNode.hasFocus
                        ? const Color(0xFFF2CC44) // Yellow when in focus
                        : Colors.black, // Black when not in focus
                  ),
                  child: const Icon(Icons.email),
                ),
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2CC44),
                ),
                onPressed: () {
                  _forgotPassword(emailController.text);
                },
                child: const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Password reset complete?"),
                TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                    },
                    child: Text("Go to Login Page"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
