import 'dart:async';
import 'package:dart_phonetics/dart_phonetics.dart';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:newprobillapp/components/api_constants.dart';
import 'package:newprobillapp/models/local_database_model.dart';
import 'package:newprobillapp/services/api_services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      db.execute('CREATE VIRTUAL TABLE $_tableName USING fts4('
          '$_idColumn, ' // Primary key for identification (doesn't need INTEGER PRIMARY KEY with FTS)
          '$_itemIDColumn UNINDEXED, ' // Adding UNINDEXED to skip FTS indexing if search isn’t needed on this column
          '$_nameColumn, ' // Searchable text column
          '$_quantityColumn UNINDEXED, ' // Optional: exclude if not searching quantities
          '$_unitColumn ' // Searchable unit column
          ');');
    });
    //database.rawQuery('CREATE NONCLUSTERED INDEX idx_name ON inventory(name)');
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
      //  print('fetchDataFromAPI: ${response.body}');
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
    //  print("objects inserted");
  }

  void clearTable() async {
    Database db = await database;
    await db.delete(_tableName);
    // print('Table cleared');
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
      // ignore: avoid_print
      print(row);
    }
  }

  Future<List<LocalDatabaseModel>> searchDatabase(String query) async {
    if (query.isEmpty) return [];

    List<String> splitQuery = query.split(' ');

    Database db = await database;
    List<Map<String, dynamic>> data = [];

    // Perform a single MATCH query with both original and modified query
    List<Map<String, dynamic>> result = await db.query(
      _tableName,
      distinct: true,
      where: 'name MATCH ? OR name MATCH ?',
      whereArgs: [query],
      limit: 20,
    );
    data.addAll(result);
    result = await db.query(
      _tableName,
      distinct: true,
      where: 'name LIKE ? OR name LIKE ?',
      whereArgs: ["%$query%"],
      limit: 20,
    );
    data.addAll(result);

    List<String> names = await getNamesUsingPhonetics(query);

    names = names.toSet().toList(); // Ensure unique names

    if (names.isNotEmpty) {
      final placeholder = List.generate(names.length, (_) => '?').join(',');
      result = await db.query(
        _tableName,
        distinct: true,
        where: 'name IN ($placeholder)',
        whereArgs: names,
        limit: 20,
      );
      data.addAll(result);
    }

    // Map results to LocalDatabaseModel and remove duplicates by itemId

    // If no suggestions found, search with individual words from the query
    if (data.isEmpty && splitQuery.length > 1) {
      // print("Split Query: $splitQuery");
      for (String word in splitQuery) {
        if (word.isEmpty) continue;

        List<Map<String, dynamic>> wordResult = await db.query(
          _tableName,
          distinct: true,
          where: 'name MATCH ?',
          whereArgs: ["%$word%"],
          // limit: 20,
        );
        data.addAll(wordResult);

        wordResult = await db.query(
          _tableName,
          distinct: true,
          where: 'name LIKE ?',
          whereArgs: ["%$word%"],
          // limit: 20,
        );
        data.addAll(wordResult);
      }

      // Remove duplicates again after individual word search
    }
    final ids = <int>{};
    suggestions = data
        .map((e) => LocalDatabaseModel(
              itemId: e["itemId"] as int,
              quantity: int.tryParse(e["quantity"].toString()) ?? 0,
              name: e["name"] as String,
              unit: e["unit"] as String,
            ))
        .where((suggestion) => ids.add(suggestion.itemId))
        .toList();

    // Sort suggestions based on relevance to the query
    // Sort suggestions based on relevance to the query
    suggestions.sort((a, b) {
      final nameA = a.name.toLowerCase();
      final nameB = b.name.toLowerCase();
      final queryLower = query.toLowerCase();

      // Highest priority: Items that start with the query
      final startsWithQueryA = nameA.startsWith(queryLower) ? 1 : 0;
      final startsWithQueryB = nameB.startsWith(queryLower) ? 1 : 0;

      if (startsWithQueryA != startsWithQueryB) {
        return startsWithQueryB.compareTo(
            startsWithQueryA); // Higher priority to those that start with the query
      }

      // Next priority: Items where the query appears as a standalone word
      final wholeWordMatchA =
          RegExp(r'\b' + RegExp.escape(queryLower) + r'\b').hasMatch(nameA)
              ? 1
              : 0;
      final wholeWordMatchB =
          RegExp(r'\b' + RegExp.escape(queryLower) + r'\b').hasMatch(nameB)
              ? 1
              : 0;

      if (wholeWordMatchA != wholeWordMatchB) {
        return wholeWordMatchB.compareTo(
            wholeWordMatchA); // Higher priority to standalone word matches
      }

      // Next priority: Items that contain the query as a substring
      final containsQueryA = nameA.contains(queryLower) ? 1 : 0;
      final containsQueryB = nameB.contains(queryLower) ? 1 : 0;

      if (containsQueryA != containsQueryB) {
        return containsQueryB
            .compareTo(containsQueryA); // Higher priority to substring matches
      }

      // Final priority: Alphabetical order as a tiebreaker
      return nameA.compareTo(nameB);
    });

    return suggestions;
  }

  Future<List<String>> getNamesUsingPhonetics(String query) async {
    Database db = await database;

    List<Map<String, dynamic>> data = await db.query(_tableName);
    List<String> names = data.map((e) => e['name'] as String).toList();

    final doubleMetaphone = DoubleMetaphone.withMaxLength(24);
    final queryEncoded = doubleMetaphone.encode(query)?.primary;

    if (queryEncoded != null) {
      print("Encoded Query: $queryEncoded");

      names.removeWhere((name) {
        // Split the name into individual words
        final words = name.split(' ');

        // Check if any word in `name` matches the query phonetically
        bool hasMatch = words.any((word) {
          final wordEncoded = doubleMetaphone.encode(word)?.primary;
          return wordEncoded != null && ratio(queryEncoded, wordEncoded) >= 80;
        });

        return !hasMatch; // Remove `name` if no words match the query
      });
    } else {
      print("Error: Query encoding failed.");
    }

    // print(" names using phonetics : $names");
    return names;
  }
}
 //List<String> names = await getNamesFromDatabase(query);
    // if (names.isNotEmpty) {
    //   final placeholder = List.generate(names.length, (_) => '?').join(',');

    //   final result = await db.query(
    //     _tableName,
    //     distinct: true,
    //     where: 'name IN ($placeholder)',
    //     whereArgs: names,
    //   );
    //   data.addAll(result);
    // }
    // names = await getNamesFromDatabase(newQuery);
    // if (names.isNotEmpty) {
    //   final placeholder = List.generate(names.length, (_) => '?').join(',');

    //   final result = await db.query(
    //     _tableName,
    //     distinct: true,
    //     where: 'name IN ($placeholder)',
    //     whereArgs: names,
    //   );
    //   data.addAll(result);
    // }

     // Future<List<String>> getNamesFromDatabase(String query) async {
  //   Database db = await database;

  //   List<Map<String, dynamic>> data = await db.query(_tableName);

  //   List<String> names = data.map((e) => e['name'] as String).toList();

  //   // Lowercase the query for case-insensitive comparison
  //   final queryLower = query.toLowerCase();

  //   names.removeWhere((name) {
  //     // Split `name` into words and lowercase them
  //     final words = name.toLowerCase().split(' ');

  //     // Check if any word in `name` meets the ratio threshold with `query`
  //     bool hasMatch = words.any((word) => ratio(word, queryLower) >= 75);

  //     return !hasMatch; // Remove `name` if no words match the query
  //   });

  //   print("Names inside fn: $names");
  //   return names;
  // }