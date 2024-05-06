import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text_search/Service/api_constants.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/login_profile.dart';

class ProductEditPage extends StatefulWidget {
  final int productId;

  ProductEditPage({required this.productId});

  @override
  _ProductEditPageState createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  late TextEditingController itemNameController;
  late TextEditingController quantityController;
  late TextEditingController salePriceController;
  late TextEditingController mrpController;
  late TextEditingController rate2Controller;
  late TextEditingController rate1Controller;
  late TextEditingController tax1Controller;
  late TextEditingController tax2Controller;
  late String fullUnitDropdownValue;
  late String shortUnitDropdownValue;
  late String tax1DropdownValue;
  late String tax2DropdownValue;

  List<String> fullUnits = ['Bags', 'Bottle', 'Box', 'Bundle', 'Can', 'Cartoon', 'Gram', 'Kilogram', 'Litre', 'Meter', 'Millilitre', 'Number', 'Pack', 'Pair', 'Piece', 'Roll', 'Square Feet', 'Square Meter'];

  List<String> shortUnits = ['BAG', 'BTL', 'BOX', 'BDL', 'CAN', 'CTN', 'GM', 'KG', 'LTR', 'MTR', 'ML', 'NUM', 'PCK', 'PRS', 'PCS', 'ROL', 'SQF', 'SQM'];

  String? token;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    itemNameController = TextEditingController();
    quantityController = TextEditingController();
    salePriceController = TextEditingController();
    tax1Controller = TextEditingController();
    tax2Controller = TextEditingController();
    rate2Controller = TextEditingController();
    rate1Controller = TextEditingController();
    mrpController = TextEditingController();
    fullUnitDropdownValue = 'Full Unit';
    shortUnitDropdownValue = 'Short Unit';
    tax1DropdownValue = 'Tax 1';
    tax2DropdownValue = 'Tax 2';
    fullUnits = fullUnits.toSet().toList();
    shortUnits = shortUnits.toSet().toList();
    // Fetch product details when the page is initialized
    _initializeData();
  }

  @override
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    salePriceController.dispose();
    tax1Controller.dispose();
    tax2Controller.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    token = await APIService.getToken();
    APIService.getUserDetails(token, _showFailedDialog);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProductDetails());
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      isLoading = true;
    });
    print("onTableFetch::::::");
    print(widget.productId);
    try {
      var response = await http.get(Uri.parse('$baseUrl/item/${widget.productId}'), headers: {
        'Authorization': 'Bearer $token',
      });
      print(jsonDecode(response.body));

      setState(() {
        isLoading = false;
      });
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body)['data'];
        setState(() {
          itemNameController.text = jsonData['item_name'];
          quantityController.text = jsonData['quantity'];
          salePriceController.text = jsonData['sale_price'];
          tax1DropdownValue = jsonData['tax1'];
          tax2DropdownValue = jsonData['tax2'];
          rate1Controller.text = jsonData['rate1'];
          rate2Controller.text = jsonData['rate2'];
          mrpController.text = jsonData['mrp'];
          fullUnitDropdownValue = jsonData['full_unit'];
          shortUnitDropdownValue = jsonData['short_unit'];
        });
      } else {
        print('Failed to fetch product details');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _showFailedDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Failed to Fetch User Details"),
          content: Text("Unable to fetch user details. Please login again."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Navigate to the login page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()), // Change to AddItemScreen()
                );
              },
              child: Text("Login"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCombinedDropdown(String label, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Units',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
      value: items[0], // Initial value
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _updateProduct() async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/update-item'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': widget.productId,
          'item_name': itemNameController.text,
          'quantity': quantityController.text,
          'sale_price': salePriceController.text,
          'full_unit': fullUnitDropdownValue,
          'short_unit': shortUnitDropdownValue,
          'tax1': tax1DropdownValue,
          'tax2': tax2DropdownValue,
        }),
      );
      print("error::");
      print(jsonDecode(response.body));
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('Product updated: $jsonData');
      } else {
        print('Failed to update product');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(246, 247, 255, 1),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Item Detail',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: Color.fromRGBO(243, 203, 71, 1), // Change this color to whatever you desire
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(243, 203, 71, 1),
                ), // Change color here
              ), // Show loading indicator
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    _buildTextField(itemNameController, 'Item Name'),
                    SizedBox(
                      height: 15,
                    ),
                    _buildTextField(quantityController, 'Stock Quantity'),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCombinedDropdown('Unit', ['Full Unit (Short Unit)', ...fullUnits.map((unit) => '$unit (${shortUnits[fullUnits.indexOf(unit)]})').toList()], (value) {
                            // Split the selected value into full unit and short unit
                            List<String> units = value!.split(' (');
                            String fullUnit = units[0];
                            String shortUnit = units[1].substring(0, units[1].length - 1);
                            setState(() {
                              print(fullUnit);
                              fullUnitDropdownValue = fullUnit; // Update the fullUnitDropdownValue
                              print(shortUnit);
                              shortUnitDropdownValue = shortUnit; // Update the shortUnitDropdownValue
                            });
                          }),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(mrpController, 'MRP')),
                        SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(salePriceController, 'Sale Price'),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(children: [
                      Expanded(
                        child: _buildDropdown(
                          'Tax 1',
                          ['Tax 1', 'Tax 2'],
                          tax1DropdownValue, // Add your tax options here
                          (value) {
                            setState(() {
                              tax1DropdownValue = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Expanded(child: _buildTextField(rate1Controller, "Rate")),
                    ]),
                    SizedBox(
                      height: 15,
                    ),
                    Row(children: [
                      Expanded(
                        child: _buildDropdown(
                          'Tax 2',
                          ['Tax 1', 'Tax 2'],
                          tax2DropdownValue, // Add your tax options here
                          (value) {
                            setState(() {
                              tax2DropdownValue = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Expanded(child: _buildTextField(rate2Controller, "Rate")),
                    ]),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: () {
                        _updateProduct();
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.green,
                        ), // Change color here
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(String labelText, List<String> dropdownItems, String unitDropdownValue, void Function(String) updateDropdownValue) {
    return DropdownButtonFormField<String>(
      // Set the value of the dropdown
      items: dropdownItems.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? value) {
        // Call the callback function to update the dropdown value
        updateDropdownValue(value!);
      },
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
