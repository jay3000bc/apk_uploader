import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:path/path.dart';
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/models/local_database_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class LocalDatabase {
  static Database? _db;
  static final LocalDatabase instance = LocalDatabase._constructor();

  final String _tableName = 'inventory';
  final String _idColumn = 'id';
  final String _nameColumn = 'name';
  final String _quantityColumn = 'quantity';
  final String _unitColumn = 'unit';
  final String _itemIDColumn = 'itemId';
  List<LocalDatabaseModel> suggestions = [];

  LocalDatabase._constructor();

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirectoryPath = await getDatabasesPath();
    final databasePath = join(databaseDirectoryPath, 'probill_inventory.db');
    final database =
        await openDatabase(databasePath, version: 1, onCreate: (db, version) {
      db.execute(
        'CREATE TABLE $_tableName('
        '$_idColumn INTEGER PRIMARY KEY,'
        '$_itemIDColumn INTEGER,'
        '$_nameColumn TEXT,'
        '$_quantityColumn INTEGER,'
        '$_unitColumn TEXT)',
      );
    });
    return database;
  }

  Future<List<Map<String, dynamic>>> fetchDataFromAPI() async {
    var token = await APIService.getToken();
    final response = await http.get(Uri.parse('$baseUrl/all-items'), headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      // Decode the JSON response into a Map
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Check if 'data' key exists and is a list
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        List<dynamic> data = jsonResponse['data'];

        // Map the list of items to a list of maps
        return data
            .map((item) => {
                  "itemId": item['id'],
                  "name": item['item_name'],  
                  "quantity": item['quantity'],
                  "unit": item['short_unit'],
                })
            .toList();
      } else {
        throw Exception('Invalid data format from server');
      }
    } else {
      print('fetchDataFromAPI: ${response.body}');
      throw Exception(response.body);
    }
  }

  Future<void> insertDataIntoSQLite(
      Database db, List<Map<String, dynamic>> data) async {
    for (var row in data) {
      await db.insert(
        _tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  void clearTable() async {
    Database db = await database;
    await db.delete(_tableName);
  }

  void clearSuggestions() {
    suggestions.clear();
  }

  Future<void> fetchDataAndStoreLocally() async {
    try {
      List<Map<String, dynamic>> data = await fetchDataFromAPI();
      Database db = await getDatabase();
      await insertDataIntoSQLite(db, data);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void printData() async {
    Database db = await database;
    List<Map<String, dynamic>> data = await db.query(_tableName);
    for (var row in data) {
      print(row);
    }
  }

  Future<List<LocalDatabaseModel>> searchDatabase(String query) async {
    // print("Ratio: ${ratio("karl", "carl")}");
    Database db = await database;
    List<String> names = await getNamesFromDatabase(query);
    //print("Names: $names");

    List<Map<String, dynamic>> data = [];

    final result = await db.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ["%$query%"],
    );
    for (var entry in result) {
      // Check if the entry is already in the data list
      bool isDuplicate =
          data.any((existingEntry) => existingEntry['id'] == entry['id']);
      if (!isDuplicate) {
        data.add(entry);
      }
    }
    if (data.isEmpty) {
      for (String name in names) {
        final result = await db.query(
          _tableName,
          where: 'name LIKE ?',
          whereArgs: ["%$name%"],
        );

        for (var entry in result) {
          // Check if the entry is already in the data list
          bool isDuplicate =
              data.any((existingEntry) => existingEntry['id'] == entry['id']);
          if (!isDuplicate) {
            data.add(entry);
          }
        }
      }
    }
    if (query == "") {
      data = [];
    }

    suggestions = data
        .map(
          (e) => LocalDatabaseModel(
            id: e["id"] as int,
            itemId: e["itemId"] as int,
            //quantity: "quantity",
            quantity: int.tryParse(e["quantity"].toString()) ?? 0,
            //name: "name",
            name: e["name"] as String,
            //unit: "unit",
            unit: e["unit"] as String,
          ),
        )
        .toList();
    print('Suggestions: $data');
    return suggestions;
  }

  Future<List<String>> getNamesFromDatabase(query) async {
    Database db = await database;

    List<Map<String, dynamic>> data = await db.query(_tableName);

    List<String> names = data.map((e) => e['name'] as String).toList();

    names.removeWhere(
        (name) => ratio(name.toLowerCase(), query.toLowerCase()) < 75);

    print("Names inside fn: $names");
    return names;
  }
}