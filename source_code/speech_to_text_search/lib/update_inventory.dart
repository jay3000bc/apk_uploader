import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:speech_to_text_search/edit_product.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/search_app.dart';

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

  static Future<List<Product>> fetchProducts({required int page, required int pageSize}) async {
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
      return List<Product>.from(jsonData['data'].map((x) => Product.fromJson(x)));
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
    print(response.body);
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      return responseData['file'];
    } else {
      return null;
    }
  }
}

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  int _rowsPerPage = 10; // Set to 10 items per page
  int _page = 0;
  String _searchQuery = '';
  String _selectedColumn = 'Item Name'; // Default selected column
  List<String> _columnNames = ['Item Name', 'Qty', 'MRP'];
  List<Product> _products = [];
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
    WidgetsBinding.instance?.addPostFrameCallback((_) {
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
      print('Error fetching products: $e');
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

  Future<void> _handleUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String? response = await ProductService.uploadXLS(file);
      if (response != null) {
        // Show response in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Upload Response'),
              content: Text(response),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Show error message in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Upload Error'),
              content: Text('Failed to upload the file.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _handleDownload() async {
    String? fileUrl = await ProductService.downloadXLS();
    if (fileUrl != null) {
      // Get the directory where downloaded files are stored
      Directory? directory = await getExternalStorageDirectory();
      if (directory != null) {
        String filePath = '${directory.path}/exported_data.xlsx';
        var response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode == 200) {
          // Save the file
          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          // Show success message in a dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Download Success'),
                content: Text('File downloaded successfully to $filePath'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Show error message in a dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Download Error'),
                content: Text('Failed to download the file.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } else {
      // Show error message in a dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Download Error'),
            content: Text('Failed to download the file.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'View & Update Inventory',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          backgroundColor: Color.fromRGBO(243, 203, 71, 1),
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
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Change color to match your theme
                        borderRadius: BorderRadius.circular(8), // Add border radius
                      ),
                      child: TextField(
                        onChanged: _handleSearch,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none, // Remove border
                          prefixIcon: Icon(Icons.search, color: Colors.grey), // Adjust icon color
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedColumn,
                    onChanged: _handleColumnSelect,
                    style: TextStyle(color: Colors.black), // Adjust text color
                    underline: Container(), // Remove underline
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey), // Adjust icon color
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: [
                      DataColumn(label: Text('Item Name')),
                      // DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('MRP')),
                    ],
                    rows: _products.where(_filterProduct).map((product) {
                      return DataRow(
                        cells: [
                          DataCell(Text(product.itemName)),
                          // DataCell(Text(product.quantity)),
                          DataCell(Text(product.mrp)),
                        ],
                        onSelectChanged: (isSelected) {
                          if (isSelected != null && isSelected) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductEditPage(productId: product.id),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Padding(
                    padding: EdgeInsets.only(bottom: 15.0), // Adjust the value as needed
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _handleLoadMore,
                        child: Text('Load More'),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ProductDataSource extends DataTableSource {
  final List<Product> _products;
  final BuildContext context; // Add context here

  _ProductDataSource(this._products, this.context); // Constructor updated

  @override
  DataRow getRow(int index) {
    final product = _products[index];
    return DataRow(
      cells: [
        DataCell(Container(width: 170, child: Text(product.itemName))),
        DataCell(Container(width: 50, child: Text(product.mrp))),
      ],
      onSelectChanged: (isSelected) {
        print("onTap:::::::");
        print(product.id);
        if (isSelected != null && isSelected) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductEditPage(productId: product.id),
            ),
          );
        }
      },
    );
  }

  @override
  int get rowCount => _products.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
