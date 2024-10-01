import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/Service/result.dart';
import 'dart:convert';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/components/navigation_bar.dart';
import 'package:speech_to_text_search/pages/edit_product.dart';
import 'package:speech_to_text_search/pages/search_app.dart';

import 'Service/api_constants.dart';

class Product {
  final int id;
  final String itemName;
  final String quantity;
  final String mrp;
  final String salePrice;
  final String unit;
  final String hsn;
  final String gst;
  final String cess;

  Product({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.mrp,
    required this.salePrice,
    required this.unit,
    required this.hsn,
    required this.gst,
    required this.cess,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      mrp: json['mrp'],
      salePrice: json['sale_price'],
      unit: json['short_unit'],
      hsn: json['hsn'],
      gst: json['rate1'],
      cess: json['rate2'],
    );
  }
}

class ProductService {
  static const String apiUrl = '$baseUrl/items';

  static Future<List<Product>> fetchProducts(
      {required int page, required int pageSize}) async {
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
      return List<Product>.from(
          jsonData['data'].map((x) => Product.fromJson(x)));
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<String?> uploadXLS(File file) async {
    var token = await APIService.getToken();
    var uri = Uri.parse('$baseUrl/preview/excel');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      return responseData;
    } else {
      return null;
    }
  }

  static Future<String?> downloadXLS() async {
    var token = await APIService.getToken();
    var url = '$baseUrl/export';
    var response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      return responseData['file'];
    } else {
      return null;
    }
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final int _rowsPerPage = 10; // Set to 10 items per page
  int _page = 0;
  String _searchQuery = '';
  String _selectedColumn = 'Item Name'; // Default selected column
  final List<String> _columnNames = ['Item Name', 'Qty', 'MRP'];
  final List<Product> _products = [];
  bool _isLoading = false; // Store fetched products
  int _selectedIndex = 3;

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToTop();
    _fetchProducts(); // Fetch initial set of products
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0.0);
      }
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    try {
      List<Product> products = await ProductService.fetchProducts(
        page: _page,
        pageSize: _rowsPerPage,
      );
      setState(() {
        _products.addAll(products);
        _isLoading = false; // Stop loading
      });
    } catch (e) {
      Result.error("Book list not available");
      setState(() {
        _isLoading = false; // Stop loading on error
      });
    }
  }

  void _handleLoadMore() {
    setState(() {
      _page++; // Increment page to load next batch
    });
    _fetchProducts();
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

  bool _filterProduct(Product product) {
    switch (_selectedColumn) {
      case 'Item Name':
        return product.itemName.toLowerCase().contains(_searchQuery);
      case 'Qty':
        return product.quantity.toLowerCase().contains(_searchQuery);
      case 'MRP':
        return product.mrp.toLowerCase().contains(_searchQuery);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        _selectedIndex = 0;
        // Navigate to NextPage when user tries to pop MyHomePage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchApp()),
        );
        // Return false to prevent popping the current route
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'View & Update Inventory',
            style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
        ),
        bottomNavigationBar: CustomNavigationBar(
          onItemSelected: (index) {
            // Handle navigation item selection
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedIndex: _selectedIndex,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors
                            .grey[200], // Change color to match your theme
                        borderRadius:
                            BorderRadius.circular(8), // Add border radius
                      ),
                      child: TextField(
                        onChanged: _handleSearch,
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none, // Remove border
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey), // Adjust icon color
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedColumn,
                    onChanged: _handleColumnSelect,
                    style: const TextStyle(
                        color: Colors.black), // Adjust text color
                    underline: Container(), // Remove underline
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.grey), // Adjust icon color
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
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //     children: [
            //       ElevatedButton(
            //         onPressed: _handleUpload,
            //         child: Text('Upload'),
            //       ),
            //       SizedBox(width: 10),
            //       ElevatedButton(
            //         onPressed: _handleDownload,
            //         child: Text('Download'),
            //       ),
            //     ],
            //   ),
            // ),
            const Padding(
              padding:
                  EdgeInsets.only(left: 15, right: 15, top: 8.0, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('Qty',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ),
            ),
            Expanded(
                child: ListView.builder(
              itemCount: _products.where(_filterProduct).length,
              itemBuilder: (context, index) {
                Product product =
                    _products.where(_filterProduct).toList()[index];
                return _products.where(_filterProduct).isNotEmpty
                    ? itemWidget(product)
                    : Center(
                        child: Text(_isLoading == true ? '' : 'No Data Found'),
                      );
              },
            )
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: SingleChildScrollView(
                //     controller: scrollController,
                //     child: _products.where(_filterProduct).isNotEmpty ?DataTable(
                //       showCheckboxColumn: false,
                //       columns: const [
                //         DataColumn(label: Text('Item Name')),
                //         // DataColumn(label: Text('Qty')),
                //         DataColumn(label: Text('MRP'))
                //       ],
                //       rows: _products.where(_filterProduct).map((product) {
                //         return DataRow(
                //           cells: [
                //             DataCell(Text(product.itemName)),
                //             // DataCell(Text(product.quantity)),
                //             DataCell(Text(product.mrp)),
                //           ],
                //           onSelectChanged: (isSelected) {
                //             if (isSelected != null && isSelected) {
                //               Navigator.of(context).push(
                //                 MaterialPageRoute(
                //                   builder: (context) => ProductEditPage(productId: product.id),
                //                 ),
                //               );
                //             }
                //           },
                //         );
                //       }).toList(),
                //     ):  Center(child: Text(_isLoading == true? '':'No Data Found'),),
                //   ),
                // ),
                ),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _products.where(_filterProduct).isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(
                            bottom: 15.0), // Adjust the value as needed
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _handleLoadMore,
                            child: const Text('Load More'),
                          ),
                        ),
                      )
                    : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget itemWidget(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProductEditPage(productId: product.id),
        ));
      },
      child: Padding(
        padding:
            const EdgeInsets.only(left: 15, right: 15, top: 4.0, bottom: 4),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.itemName,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(product.quantity, style: const TextStyle(fontSize: 14))
              ],
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            )
          ],
        ),
      ),
    );
  }
}
