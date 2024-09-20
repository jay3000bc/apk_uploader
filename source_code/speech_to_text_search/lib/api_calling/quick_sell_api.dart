import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/models/quick_sell_suggestion_model.dart';
import '../service/api_constants.dart';
import '../service/is_login.dart';
import '../service/result.dart';

typedef NetworkResponseHandler = void Function(Result result);

class QuickSellApiCalling {
  static Future<List<String>> getQuantityUnits(
      String itemId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/related-units'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'item_id': itemId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> units = responseData['units'];
          return units.cast<String>().toList();
        } else {
          // Handle failed response
          Result.error("Book list not available");
          return [];
        }
      } else {
        // Handle other HTTP status codes
        Result.error("Book list not available");
        return [];
      }
    } catch (e) {
      // Handle exceptions
      Result.error("Book list not available");
      return [];
    }
  }

  static Future<void> fetchDataAndAssign(
      String productName, NetworkResponseHandler networkResponseHandler) async {
    String? token;
    try {
      token = await APIService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/suggesstion-list?item_name=$productName'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          Map<String, dynamic> decoded = json.decode(response.body);
          QuickSellSuggestionModel data =
              QuickSellSuggestionModel.fromJson(decoded);
          networkResponseHandler(Result.success(data));
        } else {
          Result.error("Book list not available");
        }
      } else {
        Result.error("Book list not available");
      }
    } catch (e) {
      Result.error("Book list not available");
    }
  }
}
