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
          '$_itemIDColumn INTEGER, '
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
    final queryWords = query.split(' ');

    Database db = await database;
    final List<Map<String, dynamic>> data;
    final Set<int> processedIds = {};

    // Single consolidated query using OR conditions
    String sqlQuery = '''
      SELECT DISTINCT * FROM $_tableName 
      WHERE 
        LOWER($_nameColumn) = ? OR           -- exact match
        LOWER($_nameColumn) LIKE ? OR        -- starts with
        LOWER($_nameColumn) LIKE ? OR        -- words in sequence
        LOWER($_nameColumn) LIKE ?           -- contains
    ''';

    String partialMatchPattern = queryWords.map((word) => '%$word%').join('');

    data = await db.rawQuery(
      sqlQuery,
      [
        query, // exact match
        '$query%', // starts with
        partialMatchPattern, // words in sequence
        '%$query%', // contains
      ],
    );

    // Process phonetic matches in memory
    List<String> phoneticMatches = await getNamesUsingPhonetics(query);
    Set<String> phoneticMatchSet = phoneticMatches.toSet();

    // Convert to LocalDatabaseModel and handle duplicates
    suggestions = data
        .map((e) => LocalDatabaseModel(
              itemId: e['itemId'],
              quantity: e["quantity"],
              name: e["name"] as String,
              unit: e["unit"] as String,
            ))
        .where((suggestion) {
      // Include if not processed and either matches main query or phonetic
      return processedIds.add(suggestion.itemId) ||
          phoneticMatchSet.contains(suggestion.name);
    }).toList();

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

// Optimized phonetic matching to work with a single batch of names
  Future<List<String>> getNamesUsingPhonetics(String query) async {
    Database db = await database;
    // Single query to get all names
    final result = await db.rawQuery('SELECT DISTINCT name FROM $_tableName');
    List<String> names = result.map((e) => e['name'] as String).toList();

    final doubleMetaphone = DoubleMetaphone.withMaxLength(24);
    final queryEncoded = doubleMetaphone.encode(query)?.primary;

    if (queryEncoded != null) {
      return names.where((name) {
        // Check whole name
        final nameEncoded = doubleMetaphone.encode(name)?.primary;
        if (nameEncoded != null && ratio(queryEncoded, nameEncoded) >= 80) {
          return true;
        }

        // Check individual words
        final words = name.split(' ');
        return words.any((word) {
          final wordEncoded = doubleMetaphone.encode(word)?.primary;
          return wordEncoded != null && ratio(queryEncoded, wordEncoded) >= 80;
        });
      }).toList();
    }
    return [];
  }

// Modified relevance score calculation (same as before)
  double _calculateRelevanceScore(String name, String query) {
    double score = 0.0;

    final nameWords = name.toLowerCase().split(' ');
    final queryWords = query.toLowerCase().split(' ');

    // Exact match (highest priority)
    if (name == query) {
      score += 100;
    }
    // Starts with query
    else if (name.startsWith(query)) {
      score += 80;
    }

    // Check for sequential word matches with gaps allowed
    int lastMatchIndex = -1;
    int sequentialMatches = 0;
    for (String queryWord in queryWords) {
      for (int i = lastMatchIndex + 1; i < nameWords.length; i++) {
        if (nameWords[i].contains(queryWord)) {
          if (lastMatchIndex == -1 || i > lastMatchIndex) {
            lastMatchIndex = i;
            sequentialMatches++;
            break;
          }
        }
      }
    }

    // Add score based on number of sequential matches
    if (sequentialMatches == queryWords.length) {
      score += 70; // High score for all words matching in sequence
    } else {
      score += (sequentialMatches / queryWords.length) * 50;
    }

    // Word-level matching
    for (final queryWord in queryWords) {
      for (final nameWord in nameWords) {
        if (nameWord.contains(queryWord)) {
          score += 10;
        }
      }
    }

    // Add points for fuzzy string matching
    score += (ratio(name, query) / 100.0) * 20;

    return score;
  }
}
