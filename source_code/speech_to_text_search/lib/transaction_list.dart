import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/models/transaction.dart';
import 'dart:convert';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/transaction_details.dart';

import 'Service/api_constants.dart';

String _getProductNames(List<Map<String, dynamic>> itemList) {
  final productNames = itemList.map((item) => item['itemName']).toList();
  return productNames.join(', ');
}

class TransactionService {
  static const String apiUrl = '$baseUrl/all-transactions';

  static Future<List<Transaction>> fetchTransactions({required int page, required int pageSize}) async {
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
      return List<Transaction>.from(jsonData['data'].map((x) => Transaction.fromJson(x)));
    } else {
      throw Exception('Failed to load Transactions');
    }
  }
}

class TransactionListPage extends StatefulWidget {
  @override
  _TransactionListPageState createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _page = 0;
  int _selectedIndex = 1;
  String _searchQuery = '';
  String _selectedColumn = 'Invoice'; // Default selected column
  List<String> _columnNames = ['Invoice', 'Transactions', 'Total', 'Date-time']; // List of column names
  List<Transaction> _filteredTransactions = []; // Store filtered transactions

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToTop();
    _fetchTransactions();
  }

  void _scrollToTop() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0.0);
      }
    });
  }

  Future<void> _fetchTransactions() async {
    List<Transaction> transactions = await TransactionService.fetchTransactions(
      page: _page,
      pageSize: _rowsPerPage,
    );

    // Sort transactions by invoice number in descending order
    transactions.sort((a, b) => b.invoiceNumber.compareTo(a.invoiceNumber));

    setState(() {
      _filteredTransactions = transactions;
    });
  }

  void _handleNextPage() {
    setState(() {
      _page++;
    });
    _fetchTransactions();
  }

  void _handlePreviousPage() {
    if (_page > 0) {
      setState(() {
        _page--;
      });
      _fetchTransactions();
    }
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
      return _filteredTransactions;
    } else {
      return _filteredTransactions.where((transaction) {
        switch (_selectedColumn) {
          case 'Invoice':
            return transaction.invoiceNumber.toLowerCase().contains(query);
          case 'Transactions':
            return _getProductNames(transaction.itemList).toLowerCase().contains(query);
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
      bottomNavigationBar: CustomNavigationBar(
        onItemSelected: (index) {
          // Handle navigation item selection
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Transactions',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: Color.fromRGBO(243, 203, 71, 1),
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          onChanged: _handleSearch,
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedColumn,
                      onChanged: _handleColumnSelect,
                      style: TextStyle(color: Colors.black),
                      underline: Container(),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                      items: _columnNames.map((_columnName) {
                        return DropdownMenuItem<String>(
                          value: _columnName,
                          child: Text(_columnName),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              PaginatedDataTable(
                showCheckboxColumn: false,
                columnSpacing: 25.0,
                rowsPerPage: _rowsPerPage,
                onRowsPerPageChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                  });
                },
                columns: [
                  DataColumn(label: Text('Invoice')),
                  DataColumn(label: Text('Transactions')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Date-time')),
                ],
                source: _TransactionDataSource(_filteredTransactions, context),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _handlePreviousPage,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: 5),
                        Text('Previous Page'),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _handleNextPage,
                    child: Row(
                      children: [
                        Text('Next Page'),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProductNames(List<Map<String, dynamic>> itemList) {
    final productNames = itemList.map((item) => item['itemName']).toList();
    return productNames.join(', ');
  }
}

class _TransactionDataSource extends DataTableSource {
  final List<Transaction> _transactions;
  final BuildContext context;

  _TransactionDataSource(this._transactions, this.context);

  @override
  DataRow getRow(int index) {
    final transaction = _transactions[index];
    return DataRow(
      cells: [
        DataCell(Text(transaction.invoiceNumber)),
        DataCell(Container(
          width: 100,
          child: Text(
            _getProductNames(transaction.itemList),
          ),
        )),
        DataCell(Text(transaction.totalPrice)),
        DataCell(Container(width: 70, child: Text(transaction.createdAt))),
      ],
      onSelectChanged: (isSelected) {
        if (isSelected != null && isSelected) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionDetailPage(transaction: transaction),
            ),
          );
        }
      },
    );
  }

  @override
  int get rowCount => _transactions.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
