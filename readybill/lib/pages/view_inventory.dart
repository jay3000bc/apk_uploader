import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import 'package:readybill/components/bottom_navigation_bar.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/sidebar.dart';
import 'package:readybill/pages/add_product.dart';
import 'package:readybill/pages/edit_product.dart';
import 'package:readybill/pages/subscriptions.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';

import 'package:readybill/services/local_database_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String _searchQuery = '';
  String _selectedColumn = 'Item Name'; // Default selected column
  final List<String> _columnNames = ['Item Name', 'Qty', 'Unit'];
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  final ScrollController _scrollController =
      ScrollController(); // For scrolling
  int _selectedIndex = 2;
  final FocusNode _focusNode = FocusNode();

  int? isAdmin;
  int? subscriptionExpired;

  @override
  void initState() {
    super.initState();
    _fetchProductsFromLocalDatabase();
    getPrefs();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  getPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    subscriptionExpired = prefs.getInt('isSubscriptionExpired');
    isAdmin = prefs.getInt('isAdmin');
    print(" sub exp: ${prefs.getInt('isSubscriptionExpired')}");
    if (subscriptionExpired != 0) {
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
  }

  Future<void> _fetchProductsFromLocalDatabase() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch all data from local SQLite database
      final db = await LocalDatabase2.instance.database;
      final List<Map<String, dynamic>> data = await db.query('inventory');

      setState(() {
        _products = data; // Set fetched products
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching products from local database: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _handleColumnSelect(String? columnName) {
    setState(() {
      _selectedColumn = columnName!;
    });
  }

  bool _filterProduct(Map<String, dynamic> product) {
    if (_searchQuery.isEmpty) return true;
    final itemName = product['name'].toString().toLowerCase();
    final quantity = product['quantity'].toString();
    final unit = product['unit'].toString();
    final id = product['itemId'].toString();

    switch (_selectedColumn) {
      case 'ID':
        return id.contains(_searchQuery);
      case 'Item Name':
        final similarity = partialRatio(
          itemName,
          _searchQuery.toLowerCase(),
        );
        return similarity >= 70;
      case 'Qty':
        return quantity.contains(_searchQuery);
      case 'Unit':
        return unit.contains(_searchQuery);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return Scaffold(
      drawer: const Drawer(
        child: Sidebar(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isKeyboardVisible || isAdmin == 0
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) {
                  return const AddInventory();
                }));
              },
              shape: const CircleBorder(),
              backgroundColor: green2,
              child: const Icon(Icons.add, color: black),
            ),
      bottomNavigationBar: CustomNavigationBar(
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
      ),
      appBar: customAppBar("Inventory",[]),
      body: subscriptionExpired == 0
          ? _products.isNotEmpty
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        focusNode: _focusNode,
                        onTap: () {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          setState(() {});
                        },
                        onChanged: _handleSearch,
                        decoration: customTfDecorationWithSuffix(
                          "Search",
                          DropdownButton<String>(
                            value: _selectedColumn,
                            onChanged: _handleColumnSelect,
                            style: const TextStyle(color: Colors.black),
                            underline: Container(),
                            icon: Icon(Icons.arrow_drop_down,
                                color: _focusNode.hasFocus ? white : lightGrey),
                            items: _columnNames.map((columnName) {
                              return DropdownMenuItem<String>(
                                value: columnName,
                                child: Text(columnName),
                              );
                            }).toList(),
                          ),
                          _focusNode,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Padding(
                      padding: EdgeInsets.only(
                          left: 15, right: 15, top: 8.0, bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 5, // Larger space for item name
                            child: Text(
                              'Item Name',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Expanded(
                            flex: 2, // Smaller space for Qty
                            child: Text(
                              'Stock',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Expanded(
                            flex: 2, // Smaller space for Unit
                            child: Text(
                              "Unit",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount:
                                    _products.where(_filterProduct).length,
                                itemBuilder: (context, index) {
                                  final product = _products
                                      .where(_filterProduct)
                                      .toList()[index];
                                  return _products
                                          .where(_filterProduct)
                                          .isNotEmpty
                                      ? InkWell(
                                          onTap: () {
                                            isAdmin == 1
                                                ? Navigator.push(context,
                                                    CupertinoPageRoute(
                                                        builder: (context) {
                                                    return ProductEditPage(
                                                        productId:
                                                            product['itemId']);
                                                  }))
                                                : null;
                                          },
                                          child: itemWidget(product),
                                        )
                                      : const Center(
                                          child: Text('No Data Found'),
                                        );
                                },
                              )),
                  ],
                )
              : const Center(
                  child: Text(
                    'You have not added any item. Go to "Add Inventory" and start adding items.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
          : const Center(
              child: Text(
              "No active subscription found.\n Please renew your subscription to view inventory data.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
    );
  }

  Widget itemWidget(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 4.0, bottom: 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 5, // Larger space for item name
                child: Text(
                  product['name'],
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2, // Smaller space for Qty
                child: Text(
                  product['quantity'].toString(),
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2, // Smaller space for Unit
                child: Text(
                  product['unit'],
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      ),
    );
  }
}
