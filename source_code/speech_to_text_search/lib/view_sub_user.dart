import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'dart:convert';
import 'package:speech_to_text_search/Service/is_login.dart';

class SubUser {
  final String name;
  final String mobile;
  final String address;

  SubUser({
    required this.name,
    required this.mobile,
    required this.address,
  });

  factory SubUser.fromJson(Map<String, dynamic> json) {
    return SubUser(
      name: json['name'],
      mobile: json['mobile'],
      address: json['address'],
    );
  }
}

class SubUserService {
  static const String apiUrl = '$baseUrl/all-sub-users';

  static Future<List<SubUser>> fetchSubUsers(int page, int pageSize) async {
    var token = await APIService.getToken();
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Token': '<token>',
      },
      body: json.encode({
        'start': page * pageSize,
        'length': pageSize,
      }),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> subUsersData = jsonData['data'];
      return subUsersData.map((json) => SubUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sub users');
    }
  }
}

class SubUserListPage extends StatefulWidget {
  @override
  _SubUserListPageState createState() => _SubUserListPageState();
}

class _SubUserListPageState extends State<SubUserListPage> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _page = 0;
  late Future<List<SubUser>> _subUsersFuture;

  @override
  void initState() {
    super.initState();
    _subUsersFuture = _fetchSubUsers();
  }

  Future<List<SubUser>> _fetchSubUsers() async {
    return SubUserService.fetchSubUsers(_page, _rowsPerPage);
  }

  void _handleNextPage() {
    setState(() {
      _page++;
    });
  }

  void _handlePreviousPage() {
    if (_page > 0) {
      setState(() {
        _page--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Sub Users',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: Color.fromRGBO(243, 203, 71, 1),
      ),
      body: FutureBuilder<List<SubUser>>(
        future: _subUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return SingleChildScrollView(
              child: PaginatedDataTable(
                rowsPerPage: _rowsPerPage,
                onRowsPerPageChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                  });
                },
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Mobile')),
                  DataColumn(label: Text('Address')),
                ],
                source: _SubUserDataSource(snapshot.data!),
              ),
            );
          }
        },
      ),
    );
  }
}

class _SubUserDataSource extends DataTableSource {
  final List<SubUser> _subUsers;

  _SubUserDataSource(this._subUsers);

  @override
  DataRow getRow(int index) {
    final subUser = _subUsers[index];
    return DataRow(cells: [
      DataCell(Text(subUser.name)),
      DataCell(Text(subUser.mobile)),
      DataCell(Text(subUser.address)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _subUsers.length;

  @override
  int get selectedRowCount => 0;
}
