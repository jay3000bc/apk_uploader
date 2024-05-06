import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';

String userDetailsAPI = '$baseUrl/user-detail';

class APIService {
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<void> getUserDetails(String? token, Function() showFailedDialog) async {
    if (token == null || token.isEmpty) {
      print('Token is missing');
      return;
    }

    try {
      var response = await http.get(
        Uri.parse(userDetailsAPI),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // User details extracted successfully
          var userData = responseData['data'];
          // Extract user details here and use them as needed
          print(userData);
        } else {
          showFailedDialog(); // Show dialog if response status is failed
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized: Token missing or unauthorized');
        showFailedDialog();
      } else {
        print('Failed to get user details: ${response.reasonPhrase}');
        showFailedDialog();
      }
    } catch (error) {
      print('Error getting user details: $error');
      showFailedDialog();
    }
  }

  static Future<int> getUserDetailsWithoutDialog(String? token) async {
    if (token == null || token.isEmpty) {
      print('Token is missing');
      return 404; // Return a custom status code indicating token missing
    }

    try {
      var response = await http.get(
        Uri.parse(userDetailsAPI),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic> userData = json.decode(response.body);

      if (userData['data'] == null) {
        print('User data not found');
        return 404; // Return a custom status code indicating user data not found
      }

      String name = userData['data']['name'];
      String username = userData['data']['username'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('username', username);

      return response.statusCode; // Return the response status code directly
    } catch (error) {
      print('Error getting user details: $error');
      return 333; // Return a custom status code indicating an error
    }
  }
}
