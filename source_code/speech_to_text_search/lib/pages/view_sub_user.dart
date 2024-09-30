import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/Service/internet_checker.dart';
import 'package:speech_to_text_search/pages/view_sub_user_details.dart';
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
  static const String apiUrl = '$baseUrl/all-sub-users-without-pagination';

  static Future<List<SubUser>> fetchSubUsers() async {
    var token = await APIService.getToken();
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      final List<dynamic> subUsersData = jsonData['data'];

      return subUsersData.map((json) => SubUser.fromJson(json)).toList();
    } else {
      throw Exception(response.body);
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

  final List<SubUser> _employees = [];
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _selectedIndex = 3;
  int _noOfEmployees = 0;
  String _selectedColumn = 'Name';

  String _searchQuery = '';

  List<SubUser> _filteredEmployees = [];

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
      List<SubUser> fetchedSubUsers = await SubUserService.fetchSubUsers();
      _noOfEmployees = fetchedSubUsers.length;
      setState(() {
        _filteredEmployees.addAll(fetchedSubUsers);
        _employees.addAll(fetchedSubUsers);

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

  _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredEmployees = _searchEmployees(_searchQuery);
    });
  }

  List<SubUser> _searchEmployees(String query) {
    if (query.isEmpty) {
      return _employees;
    } else {
      return _employees.where((employee) {
        switch (_selectedColumn) {
          case 'Name':
            return employee.name.toLowerCase().contains(query);
          case 'Mobile':
            return employee.mobile.toLowerCase().contains(query);
          case 'Address':
            return employee.address.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
  }

  void _handleColumnSelect(String? columnName) {
    setState(() {
      _selectedColumn = columnName!;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isKeyboardVisible
          ? null
          : FloatingActionButton(
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
          'Employees',
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
          _SearchBar(
              onSearch: _handleSearch,
              selectedColumn: _selectedColumn,
              onColumnSelect: _handleColumnSelect),
          _employees.isNotEmpty
              ? Text(_noOfEmployees > 0
                  ? 'Total Employees: $_noOfEmployees'
                  : 'No Employees Found')
              : const SizedBox.shrink(),
          const Divider(
            thickness: 1,
            height: 5,
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
              itemCount: _filteredEmployees.length + 1,
              itemBuilder: (context, index) {
                if (index == _filteredEmployees.length) {
                  // Display loading indicator at the bottom
                  return _isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox();
                }
                final subUser = _filteredEmployees[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewSubUserDetails(user: subUser),
                      ),
                    );
                  },
                  child: Padding(
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

class _SearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final String selectedColumn;
  final Function(String?) onColumnSelect;
  final List<String> _columnNames = [
    'Name',
    'Mobile',
    'Address',
  ];

  _SearchBar({
    required this.onSearch,
    required this.selectedColumn,
    required this.onColumnSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: selectedColumn,
            onChanged: onColumnSelect,
            style: const TextStyle(color: Colors.black),
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            items: _columnNames.map((columnName) {
              return DropdownMenuItem<String>(
                value: columnName,
                child: Text(columnName),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
