import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/models/transaction.dart';
import 'dart:convert';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/search_app.dart';
import 'package:speech_to_text_search/transaction_details.dart';
import 'Service/api_constants.dart';
import 'package:intl/intl.dart';

String getProductNames(List<Map<String, dynamic>> itemList) {
  final productNames = itemList.map((item) => item['itemName']).toList();
  return productNames.join(', ');
}

class TransactionService {
  static const String apiUrl = '$baseUrl/all-transactions';

  static Future<List<Transaction>> fetchTransactions() async {
    var token = await APIService.getToken();
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'start': 0,
        'length': 1000, // Fetch a large number of transactions to handle all data
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
  int _selectedIndex = 3;
  String _searchQuery = '';
  String _selectedColumn = 'Invoice'; // Default selected column
  List<String> _columnNames = ['Invoice', 'Transactions', 'Total', 'Date-time']; // List of column names
  List<Transaction> _transactions = []; // Store all transactions
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
    List<Transaction> transactions = await TransactionService.fetchTransactions();

    // Sort transactions by date in descending order
    transactions.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

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
          case 'Transactions':
            return getProductNames(transaction.itemList).toLowerCase().contains(query);
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

  Map<String, List<Transaction>> _groupTransactionsByMonth(List<Transaction> transactions) {
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      String month = DateFormat.yMMMM().format(DateTime.parse(transaction.createdAt));
      if (!groupedTransactions.containsKey(month)) {
        groupedTransactions[month] = [];
      }
      groupedTransactions[month]!.add(transaction);
    }

    // Sort transactions within each month by invoice number in descending order
    groupedTransactions.forEach((month, monthTransactions) {
      monthTransactions.sort((a, b) => b.invoiceNumber.compareTo(a.invoiceNumber));
    });

    return groupedTransactions;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _selectedIndex = 0;
        // Navigate to NextPage when user tries to pop MyHomePage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchApp()),
        );
        // Return false to prevent popping the current route
        return false;
      },
      child: Scaffold(
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
            'Sales & Refund',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          backgroundColor: Color.fromRGBO(243, 203, 71, 1),
        ),
        body: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          child: FutureBuilder(
            future: TransactionService.fetchTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Failed to load transactions'));
              } else {
                _transactions = snapshot.data!;
                _filteredTransactions = _searchTransactions(_searchQuery);

                var groupedTransactions = _groupTransactionsByMonth(_filteredTransactions);

                var sortedMonths = groupedTransactions.keys.toList()..sort((a, b) => DateFormat.yMMMM().parse(b).compareTo(DateFormat.yMMMM().parse(a)));

                return Container(
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: sortedMonths.length,
                        itemBuilder: (context, index) {
                          String month = sortedMonths[index];
                          List<Transaction> monthTransactions = groupedTransactions[month]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                color: Colors.grey[300],
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Text(
                                    month,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              DataTable(
                                showCheckboxColumn: false,
                                columns: [
                                  DataColumn(label: Text('Invoice')),
                                  DataColumn(label: Text('Transactions')),
                                  DataColumn(label: Text('Total')),
                                  DataColumn(label: Text('Date-time')),
                                ],
                                rows: monthTransactions.map((transaction) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(transaction.invoiceNumber)),
                                      DataCell(Container(
                                        width: 100,
                                        child: Text(
                                          getProductNames(transaction.itemList),
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
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
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
            getProductNames(transaction.itemList),
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
