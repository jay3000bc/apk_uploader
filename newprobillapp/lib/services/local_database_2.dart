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

class LocalDatabase2 {
  static Database? _db;
  static final LocalDatabase2 instance = LocalDatabase2._constructor();

  final String _tableName = 'inventory';
  final String _idColumn = 'id';
  final String _nameColumn = 'name';
  final String _quantityColumn = 'quantity';
  final String _unitColumn = 'unit';
  final String _itemIDColumn = 'itemId';
  final String _tagsColumn = 'tags';
  List<LocalDatabaseModel> suggestions = [];

  LocalDatabase2._constructor();

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
      db.execute('CREATE TABLE $_tableName ('
          '$_idColumn INTEGER PRIMARY KEY AUTOINCREMENT, '
          '$_itemIDColumn TEXT, '
          '$_nameColumn TEXT, '
          '$_quantityColumn INTEGER, '
          '$_unitColumn TEXT'
          ');');
    });
    return database;
  }

  Future<List<Map<String, dynamic>>> fetchDataFromAPI() async {
    var token = await APIService.getToken();
    final response = await http.get(Uri.parse('$baseUrl/all-items'), headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        List<dynamic> data = jsonResponse['data'];

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
    if (query.isEmpty) return [];
    query = query.toLowerCase().trim();

    Database db = await database;
    final List<Map<String, dynamic>> data = [];
    final Set<int> processedIds = {};

    // 1. Exact matches (highest priority)
    List<Map<String, dynamic>> exactMatches = await db.query(
      _tableName,
      distinct: true,
      where: 'LOWER($_nameColumn) = ?',
      whereArgs: [query],
    );
    data.addAll(exactMatches);

    // 2. Starts with matches
    List<Map<String, dynamic>> startsWithMatches = await db.query(
      _tableName,
      distinct: true,
      where: 'LOWER($_nameColumn) LIKE ?',
      whereArgs: ['$query%'],
    );
    data.addAll(startsWithMatches);

    // 3. Contains matches
    List<Map<String, dynamic>> containsMatches = await db.query(
      _tableName,
      distinct: true,
      where: 'LOWER($_nameColumn) LIKE ?',
      whereArgs: ['%$query%'],
    );
    data.addAll(containsMatches);

    // 4. Phonetic matches
    List<String> phoneticMatches = await getNamesUsingPhonetics(query);
    if (phoneticMatches.isNotEmpty) {
      final placeholder =
          List.generate(phoneticMatches.length, (_) => '?').join(',');
      final result = await db.query(
        _tableName,
        distinct: true,
        where: '$_nameColumn IN ($placeholder)',
        whereArgs: phoneticMatches,
      );
      data.addAll(result);
    }

    // Convert to LocalDatabaseModel and remove duplicates
    suggestions = data
        .map((e) => LocalDatabaseModel(
              itemId: int.tryParse(e["itemId"].toString()) ?? 0,
              quantity: int.tryParse(e["quantity"].toString()) ?? 0,
              name: e["name"] as String,
              unit: e["unit"] as String,
            ))
        .where((suggestion) => processedIds.add(suggestion.itemId))
        .toList();

    // Enhanced sorting with relevance scoring
    suggestions.sort((a, b) {
      final nameA = a.name.toLowerCase();
      final nameB = b.name.toLowerCase();
      final queryLower = query.toLowerCase();

      // Calculate relevance scores
      final scoreA = _calculateRelevanceScore(nameA, queryLower);
      final scoreB = _calculateRelevanceScore(nameB, queryLower);

      // Sort by score (descending)
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }

      // If scores are equal, sort alphabetically
      return nameA.compareTo(nameB);
    });

    return suggestions;
  }

  // Helper function to calculate relevance score
  double _calculateRelevanceScore(String name, String query) {
    double score = 0.0;

    // Exact match (highest priority)
    if (name == query) {
      score += 100;
    }
    // Starts with query
    else if (name.startsWith(query)) {
      score += 80;
    }
    // Whole word match
    else if (RegExp(r'\b' + RegExp.escape(query) + r'\b').hasMatch(name)) {
      score += 60;
    }
    // Contains query
    else if (name.contains(query)) {
      score += 40;
    }

    // Add points for fuzzy string matching using fuzzywuzzy
    score += (ratio(name, query) / 100.0) * 20;

    // Word-level matching
    final nameWords = name.split(' ');
    final queryWords = query.split(' ');
    for (final queryWord in queryWords) {
      for (final nameWord in nameWords) {
        if (nameWord.contains(queryWord)) {
          score += 10;
        }
      }
    }

    return score;
  }

  Future<List<String>> getNamesUsingPhonetics(String query) async {
    Database db = await database;
    List<Map<String, dynamic>> data = await db.query(_tableName);
    List<String> names = data.map((e) => e['name'] as String).toList();

    final doubleMetaphone = DoubleMetaphone.withMaxLength(24);
    final queryEncoded = doubleMetaphone.encode(query)?.primary;

    if (queryEncoded != null) {
      names.removeWhere((name) {
        // Check whole name
        final nameEncoded = doubleMetaphone.encode(name)?.primary;
        bool hasMatch =
            nameEncoded != null && ratio(queryEncoded, nameEncoded) >= 75;

        // If no match for the entire name, check individual words
        if (!hasMatch) {
          final words = name.split(' ');
          hasMatch = words.any((word) {
            final wordEncoded = doubleMetaphone.encode(word)?.primary;
            return wordEncoded != null &&
                ratio(queryEncoded, wordEncoded) >= 75;
          });
        }

        return !hasMatch; // Remove the name if no match is found
      });
    }

    return names;
  }
}
