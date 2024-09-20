import 'package:flutter/material.dart';
import 'package:speech_to_text_search/Service/internet_checker.dart';
import 'package:speech_to_text_search/Service/local_database.dart';
import 'package:speech_to_text_search/components/navigation_bar.dart';
import 'package:speech_to_text_search/pages/add_product.dart';
import 'package:speech_to_text_search/pages/edit_product.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProductsFromLocalDatabase();
  }

  Future<void> _fetchProductsFromLocalDatabase() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch all data from local SQLite database
      final db = await LocalDatabase.instance.database;
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
    final itemName = product['name'].toString().toLowerCase();
    final quantity = product['quantity'].toString();
    final unit = product['unit'].toString();
    final id = product['itemId'].toString();

    switch (_selectedColumn) {
      case 'ID':
        return id.contains(_searchQuery);
      case 'Item Name':
        return itemName.contains(_searchQuery);
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
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const AddInventory();
          }));
        },
        shape: CircleBorder(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomNavigationBar(
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
      ),
      appBar: AppBar(
        toolbarHeight: 40,
        title: const Text(
          'View & Update Inventory',
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
          Padding(
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
                      onChanged: _handleSearch,
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
                  value: _selectedColumn,
                  onChanged: _handleColumnSelect,
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
          ),
          const Padding(
            padding: EdgeInsets.only(left: 15, right: 15, top: 8.0, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 5, // Larger space for item name
                  child: Text(
                    'Item Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 2, // Smaller space for Qty
                  child: Text(
                    'Stock',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 2, // Smaller space for Unit
                  child: Text(
                    "Unit",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      itemCount: _products.where(_filterProduct).length,
                      itemBuilder: (context, index) {
                        final product =
                            _products.where(_filterProduct).toList()[index];
                        return _products.where(_filterProduct).isNotEmpty
                            ? InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return ProductEditPage(
                                        productId: product['itemId']);
                                  }));
                                },
                                child: itemWidget(product),
                              )
                            : const Center(
                                child: Text('No Data Found'),
                              );
                      },
                    )),
        ],
      ),
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
