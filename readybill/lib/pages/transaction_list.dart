import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';

import 'package:readybill/models/transaction.dart';
import 'package:readybill/pages/transaction_details.dart';
import 'package:readybill/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

String getProductNames(List<Map<String, dynamic>> itemList) {
  final productNames = itemList.map((item) => item['itemName']).toList();
  return productNames.join(', ');
}

class TransactionService {
  static const String apiUrl = '$baseUrl/all-transactions';

  static Future<List<Transaction>> fetchTransactions() async {
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'auth-key': '$apiKey',
      },
      body: json.encode({
        'start': 0,
        'length': 1000, // Fetch a large number of transactions
      }),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print(jsonData);
      return List<Transaction>.from(
          jsonData['data'].map((x) => Transaction.fromJson(x)));
    } else {
      throw Exception('Failed to load Transactions');
    }
  }
}

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  String _searchQuery = '';
  String _selectedColumn = 'Invoice';
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  final ScrollController scrollController = ScrollController();
  String? currencySymbol;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _fetchTransactions() async {
    List<Transaction> transactions =
        await TransactionService.fetchTransactions();

    transactions.sort((a, b) =>
        DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

    setState(() {
      _transactions = transactions;
      _filteredTransactions = transactions;
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredTransactions = _searchTransactions(_searchQuery);
    });
  }

  void _handleColumnSelect(String? columnName) {
    setState(() {
      _selectedColumn = columnName!;
    });
  }

  List<Transaction> _searchTransactions(String query) {
    if (query.isEmpty) {
      return _transactions;
    } else {
      return _transactions.where((transaction) {
        switch (_selectedColumn) {
          case 'Invoice':
            return transaction.invoiceNumber.toLowerCase().contains(query);
          case 'Items':
            return getProductNames(transaction.itemList)
                .toLowerCase()
                .contains(query);
          case 'Total':
            return transaction.totalPrice.toLowerCase().contains(query);
          case 'Date-time':
            return transaction.createdAt.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Transactions", []),
      body: Column(
        children: [
          _SearchBar(
            onSearch: _handleSearch,
            selectedColumn: _selectedColumn,
            onColumnSelect: _handleColumnSelect,
          ),
          Expanded(
            child:
                _TransactionList(filteredTransactions: _filteredTransactions),
          ),
        ],
      ),
    );
  }
}

// Widget for search bar
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
  final List<String> _columnNames = ['Invoice', 'Items', 'Total', 'Date-time'];

  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
                onTap: () {
                  setState(() {});
                },
                onSubmitted: (value) {
                  setState(() {});
                },
                focusNode: focusNode,
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
          ),
        ],
      ),
    );
  }
}

// Widget for displaying the list of transactions
class _TransactionList extends StatefulWidget {
  final List<Transaction> filteredTransactions;

  const _TransactionList({required this.filteredTransactions});

  @override
  State<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<_TransactionList> {
  String? currencySymbol;

  @override
  void initState() {
    super.initState();
    setCurrencySymbol();
  }

  setCurrencySymbol() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencySymbol = prefs.getString('currencySymbol');
    });
    print('currencySymbol: $currencySymbol');
  }

  Map<String, List<Transaction>> _groupTransactionsByMonth(
      List<Transaction> transactions) {
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      String month =
          DateFormat.yMMMM().format(DateTime.parse(transaction.createdAt));
      print("Month: $month");
      if (!groupedTransactions.containsKey(month)) {
        groupedTransactions[month] = [];
      }
      groupedTransactions[month]!.add(transaction);
    }
    return groupedTransactions;
  }

  totalMonthAmount(List<Transaction> transactions) {
    double totalAmount = 0;
    for (var transaction in transactions) {
      totalAmount += int.parse(transaction.totalPrice);
    }

    if (totalAmount > 0) {
      return "$currencySymbol${totalAmount.abs().toStringAsFixed(2)}";
    } else {
      return "-$currencySymbol${totalAmount.abs().toStringAsFixed(2)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var groupedTransactions =
        _groupTransactionsByMonth(widget.filteredTransactions);
    var sortedMonths = groupedTransactions.keys.toList()
      ..sort((a, b) =>
          DateFormat.yMMMM().parse(b).compareTo(DateFormat.yMMMM().parse(a)));

    return ListView.builder(
      controller: ScrollController(),
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        String month = sortedMonths[index];
        List<Transaction> monthTransactions = groupedTransactions[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: green2.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Text(
                        month,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto-Regular',
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        " Total: ${totalMonthAmount(monthTransactions)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto-Regular',
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DataTable(
              showCheckboxColumn: false,
              columnSpacing: screenWidth * 0.05,
              columns: const [
                DataColumn(label: Text('Invoice')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Date-time')),
              ],
              rows: monthTransactions.map((transaction) {
                int totalPrice = int.parse(transaction.totalPrice);
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: screenWidth * 0.15,
                        child: Text(transaction.invoiceNumber),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: screenWidth * 0.28,
                        child: Text(
                          getProductNames(transaction.itemList),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: screenWidth * 0.12,
                        child: Text(totalPrice > 0
                            ? "$currencySymbol$totalPrice"
                            : "-$currencySymbol${totalPrice.abs()}"),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: screenWidth * 0.2,
                        child: Text(DateFormat('dd-MM-yyyy hh:mm a')
                            .format(DateTime.parse(transaction.createdAt))),
                      ),
                    ),
                  ],
                  onSelectChanged: (isSelected) {
                    if (isSelected != null && isSelected) {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) =>
                              TransactionDetailPage(transaction: transaction),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
