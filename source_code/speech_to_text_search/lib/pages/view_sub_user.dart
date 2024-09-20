import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/Service/internet_checker.dart';
import 'package:speech_to_text_search/service/api_constants.dart';
import 'dart:convert';
import 'package:speech_to_text_search/service/is_login.dart';
import 'package:speech_to_text_search/pages/drawer.dart';
import 'package:speech_to_text_search/components/navigation_bar.dart';
import 'package:speech_to_text_search/pages/sub_user_signup.dart';

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
    print('Page: $page, PageSize: $pageSize');
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
  const SubUserListPage({super.key});

  @override
  State<SubUserListPage> createState() => _SubUserListPageState();
}

class _SubUserListPageState extends State<SubUserListPage> {
  final int _rowsPerPage = 30;
  int _page = 0;
  final List<SubUser> _subUsers = [];
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchSubUsers();
  }

  Future<void> _fetchSubUsers() async {
    if (!_hasMoreData) return; // No more data to load
    setState(() {
      _isLoadingMore = true;
    });

    try {
      List<SubUser> fetchedSubUsers =
          await SubUserService.fetchSubUsers(_page, _rowsPerPage);
      setState(() {
        _subUsers.addAll(fetchedSubUsers);
        _page++;
        if (fetchedSubUsers.length < _rowsPerPage) {
          _hasMoreData = false; // No more data to load
        }
      });
    } catch (error) {
      print("Error fetching sub-users: $error");
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _fetchSubUsers(); // Fetch more data when reaching the bottom
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpSubUserScreen(),
            ),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CustomNavigationBar(
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
      ),
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text(
          'Sub Users',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
      ),
      body: Column(
        children: [
          const Align(
            alignment: Alignment.center,
            child: Internetchecker(),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Mobile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            thickness: 1,
            height: 5,
          ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(
                thickness: 0.2,
                height: 0,
              ),
              controller: _scrollController, // Attach the scroll controller
              itemCount: _subUsers.length + 1,
              itemBuilder: (context, index) {
                if (index == _subUsers.length) {
                  // Display loading indicator at the bottom
                  return _isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox();
                }
                final subUser = _subUsers[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2, // Larger space for item name
                        child: Text(
                          subUser.name,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2, // Larger space for item name
                        child: Text(
                          subUser.mobile,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2, // Larger space for item name
                        child: Text(
                          subUser.address,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// class _SubUserDataSource extends DataTableSource {
//   final List<SubUser> _subUsers;

//   _SubUserDataSource(this._subUsers);

//   @override
//   DataRow getRow(int index) {
//     final subUser = _subUsers[index];
//     return DataRow(cells: [
//       DataCell(Text(subUser.name)),
//       DataCell(Text(subUser.mobile)),
//       DataCell(Text(subUser.address)),
//     ]);
//   }

  // @override
  // bool get isRowCountApproximate => false;

  // @override
  // int get rowCount => _subUsers.length;

  // @override
  // int get selectedRowCount => 0;
//}
