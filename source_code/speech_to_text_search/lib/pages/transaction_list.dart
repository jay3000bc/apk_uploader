import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/models/transaction.dart';
import 'dart:convert';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/pages/transaction_details.dart';
import '../Service/api_constants.dart';
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
        'length': 1000, // Fetch a large number of transactions
      }),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
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

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
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
          case 'Transactions':
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2CC44),
        title: const Text('Sales & Refund'),
      ),
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
class _SearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final String selectedColumn;
  final Function(String?) onColumnSelect;
  final List<String> _columnNames = [
    'Invoice',
    'Transactions',
    'Total',
    'Date-time'
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

// Widget for displaying the list of transactions
class _TransactionList extends StatelessWidget {
  final List<Transaction> filteredTransactions;

  const _TransactionList({required this.filteredTransactions});

  Map<String, List<Transaction>> _groupTransactionsByMonth(
      List<Transaction> transactions) {
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      String month =
          DateFormat.yMMMM().format(DateTime.parse(transaction.createdAt));
      if (!groupedTransactions.containsKey(month)) {
        groupedTransactions[month] = [];
      }
      groupedTransactions[month]!.add(transaction);
    }
    return groupedTransactions;
  }

  @override
  Widget build(BuildContext context) {
    var groupedTransactions = _groupTransactionsByMonth(filteredTransactions);
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
              color: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  month,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('Invoice')),
                DataColumn(label: Text('Transactions')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Date-time')),
              ],
              rows: monthTransactions.map((transaction) {
                int totalPrice = int.parse(transaction.totalPrice);
                return DataRow(
                  cells: [
                    DataCell(Text(transaction.invoiceNumber)),
                    DataCell(SizedBox(
                      width: 100,
                      child: Text(
                        getProductNames(transaction.itemList),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(totalPrice > 0
                        ? "₹$totalPrice"
                        : "-₹${totalPrice.abs()}")),
                    DataCell(SizedBox(
                        width: 70, child: Text(transaction.createdAt))),
                  ],
                  onSelectChanged: (isSelected) {
                    if (isSelected != null && isSelected) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
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
