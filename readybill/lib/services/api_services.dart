import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/services/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

String userDetailsAPI = '$baseUrl/user-detail';

class APIService {
  static Future<String?> getToken() async {
    String? token;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    return token;
  }

  static Future<String?> getXApiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('auth-key');
    return apiKey;
  }

  static Future<void> clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<void> getUserDetails(
      String? token, Function() showFailedDialog) async {
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      var apiKey = await APIService.getXApiKey();
      var response = await http.get(
        Uri.parse(userDetailsAPI),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
        },
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
        } else {
          showFailedDialog(); // Show dialog if response status is failed
        }
      } else if (response.statusCode == 401) {
        showFailedDialog();
      } else {
        Result.error("Book list not available");
        showFailedDialog();
      }
    } catch (error) {
      Result.error("Book list not available");
      showFailedDialog();
    }
  }

  static Future<int> getUserDetailsWithoutDialog(
      String token, String apiKey) async {
    if (token.isEmpty) {
      return 404;
    }

    try {
      var response = await http.get(
        Uri.parse(userDetailsAPI),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': apiKey,
        },
      );

      Map<String, dynamic> userData = json.decode(response.body);

      if (userData['data'] == null) {
        print("response body: ${response.body}");
        return 404;
      }

      String name = userData['data']['details']['name'];
      int isAdmin = userData['data']['isAdmin'];
      int isSubscriptionExpired = userData['isSubscriptionExpired'];
      String subscriptionExpiryDate = userData['subscription_expiry_date'];
      String currencySymbol =
          userData['data']['country_details']['currency_symbol'];
      print('currencySymbol: $currencySymbol');
      String decimalSeparator =
          userData['data']['country_details']['decimal_separator'];

      print('issubscriptionexpired: $isSubscriptionExpired');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setInt('isAdmin', isAdmin);
      await prefs.setInt('isSubscriptionExpired', isSubscriptionExpired);
      await prefs.setString('subscriptionExpiryDate', subscriptionExpiryDate);
      await prefs.setString('currencySymbol', currencySymbol);
      await prefs.setString('decimalSeparator', decimalSeparator);

      return response.statusCode;
    } catch (error) {
      Result.error("Book list not available");
      return 333;
    }
  }
}
