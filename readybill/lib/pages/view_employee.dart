import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/bottom_navigation_bar.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/sidebar.dart';
import 'package:readybill/pages/add_employee.dart';
import 'package:readybill/pages/subscriptions.dart';
import 'package:readybill/pages/view_employee_details.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Employee {
  final int id;
  final String name;
  final String mobile;
  final String address;
  final String photo;
  final String countryCode;
  final String dialCode;

  Employee({
    required this.dialCode,
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.photo,
    required this.countryCode,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['staff_id'],
      name: json['name'],
      mobile: json['mobile'],
      address: json['address'],
      photo: json['photo'],
      countryCode: json['country_details']['code'],
      dialCode: json['country_details']['dial_code'],
    );
  }
}

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final int _rowsPerPage = 30;

  final List<Employee> _employees = [];
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _selectedIndex = 3;
  int _noOfEmployees = 0;
  String _selectedColumn = 'Name';
  int? isSubscriptionExpired;
  String _searchQuery = '';

  List<Employee> _filteredEmployees = [];
  int? isAdmin;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
    _fetchEmployees();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<List<Employee>> fetchEmployees() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getInt('isAdmin');
    const String apiUrl = '$baseUrl/all-sub-users-without-pagination';
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'auth-key': '$apiKey',
      },
    );
    var jsonData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      final List<dynamic> EmployeesData = jsonData['data'];

      var data = EmployeesData.map((json) => Employee.fromJson(json)).toList();

      return data;
    } else if (response.statusCode == 403 &&
            jsonData['message'] == 'No subscription found for the shop.' ||
        jsonData['message'] == 'The shop subscription has expired.') {
      showDialog(
          context: context,
          builder: (context) {
            return customAlertBox(
                title: "No Subscription Found",
                content:
                    "No valid subscription found for the shop.\nPress 'OK' to get a new subscription.",
                actions: [
                  customElevatedButton("OK", green2, white, () {
                    navigatorKey.currentState!.pop();
                    navigatorKey.currentState!.push(CupertinoPageRoute(
                        builder: (context) => const Subscriptions()));
                  }),
                  customElevatedButton("Cancel", red, white, () {
                    navigatorKey.currentState!.pop();
                  })
                ]);
          });
      return [];
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> _fetchEmployees() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isSubscriptionExpired = prefs.getInt('isSubscriptionExpired');
    print('view employee page: $isSubscriptionExpired');
    if (isSubscriptionExpired != 0) {
      showDialog(
          context: context,
          builder: (context) {
            return customAlertBox(
                title: "No Subscription Found",
                content:
                    "No valid subscription found for the shop.\nPress 'OK' to get a new subscription.",
                actions: [
                  customElevatedButton("OK", green2, white, () {
                    navigatorKey.currentState!.pop();
                    navigatorKey.currentState!.push(CupertinoPageRoute(
                        builder: (context) => const Subscriptions()));
                  }),
                  customElevatedButton("Cancel", red, white, () {
                    navigatorKey.currentState!.pop();
                  })
                ]);
          });
    }
    if (!_hasMoreData) return; // No more data to load
    setState(() {
      _isLoadingMore = true;
    });

    try {
      List<Employee> fetchedEmployees = await fetchEmployees();
      _noOfEmployees = fetchedEmployees.length;
      setState(() {
        _filteredEmployees.addAll(fetchedEmployees);
        _employees.addAll(fetchedEmployees);

        if (fetchedEmployees.length < _rowsPerPage) {
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

  _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredEmployees = _searchEmployees(_searchQuery);
    });
  }

  List<Employee> _searchEmployees(String query) {
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

  void deleteEmployee(int id) async {
    String? token = await APIService.getToken();
    String? apiKey = await APIService.getXApiKey();
    var response =
        await http.get(Uri.parse("$baseUrl/delete-sub-user/$id"), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$apiKey',
    });
    print("status code: ${response.statusCode}\nbody: ${response.body}");
    if (response.statusCode == 200) {
      setState(() {
        _filteredEmployees.removeWhere((employee) => employee.id == id);
        _employees.removeWhere((employee) => employee.id == id);
        _fetchEmployees();
      });
      Fluttertoast.showToast(msg: "Employee removed successfully");
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isKeyboardVisible || isAdmin == 0
          ? null
          : FloatingActionButton(
              backgroundColor: green2,
              foregroundColor: black,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const EmployeeSignUpPage(),
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
      drawer: const Drawer(
        child: Sidebar(),
      ),
      appBar: customAppBar("Employees", []),
      body: isSubscriptionExpired == 0
          ? Column(
              children: [
                _SearchBar(
                    onSearch: _handleSearch,
                    selectedColumn: _selectedColumn,
                    onColumnSelect: _handleColumnSelect),
                _employees.isNotEmpty
                    ? Text(_noOfEmployees > 0
                        ? 'Total Employees: $_noOfEmployees'
                        : 'No Employees Found')
                    : const Text(
                        "You have not added any employees.",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                const Divider(
                  thickness: 1,
                  height: 5,
                ),
                _employees.isNotEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Name',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Mobile',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
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
                    controller: _scrollController,
                    itemCount: _filteredEmployees.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _filteredEmployees.length) {
                        return _isLoadingMore
                            ? const Center(child: CircularProgressIndicator())
                            : const SizedBox();
                      }
                      final employee = _filteredEmployees[index];
                      return InkWell(
                        onTap: () {
                          isAdmin == 1
                              ? Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        ViewEmployeeDetails(user: employee),
                                  ),
                                )
                              : null;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4, // Larger space for item name
                                child: Text(
                                  employee.name,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 4, // Larger space for item name
                                child: Text(
                                  '${employee.dialCode} ${employee.mobile}',
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              isAdmin == 1
                                  ? Expanded(
                                      flex: 1,
                                      child: IconButton(
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return customAlertBox(
                                                    title: 'Remove Employee?',
                                                    content:
                                                        "Are you sure you want to remove ${employee.name} from your employees? ",
                                                    actions: [
                                                      customElevatedButton(
                                                          'NO', green2, white,
                                                          () {
                                                        navigatorKey
                                                            .currentState
                                                            ?.pop();
                                                      }),
                                                      customElevatedButton(
                                                        "YES",
                                                        red,
                                                        white,
                                                        () {
                                                          deleteEmployee(
                                                              employee.id);
                                                          navigatorKey
                                                              .currentState
                                                              ?.pop();
                                                        },
                                                      )
                                                    ],
                                                  );
                                                });
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            color: red,
                                          )))
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : const Center(
              child: Text(
              "No active subscription found.\n Please renew your subscription to view employee data.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String selectedColumn;
  final Function(String?) onColumnSelect;

  const _SearchBar({
    required this.onSearch,
    required this.selectedColumn,
    required this.onColumnSelect,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final List<String> _columnNames = [
    'Name',
    'Mobile',
    'Address',
  ];
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
          textCapitalization: TextCapitalization.sentences,
          focusNode: focusNode,
          onTap: () {
            setState(() {});
          },
          onSubmitted: (value) {
            setState(() {});
          },
          onChanged: widget.onSearch,
          decoration: customTfDecorationWithSuffix(
              "Search",
              DropdownButton<String>(
                value: widget.selectedColumn,
                onChanged: widget.onColumnSelect,
                style: const TextStyle(color: Colors.black),
                underline: Container(),
                icon: Icon(Icons.arrow_drop_down,
                    color: focusNode.hasFocus ? white : lightGrey),
                items: _columnNames.map((columnName) {
                  return DropdownMenuItem<String>(
                    value: columnName,
                    child: Text(columnName),
                  );
                }).toList(),
              ),
              focusNode)),
    );
  }
}
