import 'dart:convert';
import 'dart:io';

import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:http/http.dart' as http;

class Product {
  final int id;
  final String itemName;
  final String quantity;
  final String mrp;
  final String salePrice;
  final String unit;
  final String hsn;
  final String gst;
  final String cess;

  Product({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.mrp,
    required this.salePrice,
    required this.unit,
    required this.hsn,
    required this.gst,
    required this.cess,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      mrp: json['mrp'],
      salePrice: json['sale_price'],
      unit: json['short_unit'],
      hsn: json['hsn'],
      gst: json['rate1'],
      cess: json['rate2'],
    );
  }
}

class ProductService {
  static const String apiUrl = '$baseUrl/items';

  static Future<List<Product>> fetchProducts(
      {required int page, required int pageSize}) async {
    var token = await APIService.getToken();
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'start': page * pageSize,
        'length': pageSize,
      }),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return List<Product>.from(
          jsonData['data'].map((x) => Product.fromJson(x)));
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<String?> uploadXLS(File file) async {
    var token = await APIService.getToken();
    var uri = Uri.parse('$baseUrl/preview/excel');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      return responseData;
    } else {
      return null;
    }
  }

  static Future<String?> downloadXLS() async {
    var token = await APIService.getToken();
    var url = '$baseUrl/export';
    var response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      return responseData['file'];
    } else {
      return null;
    }
  }
}