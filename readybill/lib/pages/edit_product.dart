import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:readybill/components/api_constants.dart';

import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductEditPage extends StatefulWidget {
  final int productId;

  const ProductEditPage({super.key, required this.productId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  late TextEditingController itemNameController;
  late TextEditingController quantityController;
  late TextEditingController salePriceController;
  late TextEditingController mrpController;
  TextEditingController rateOneValueController = TextEditingController();
  TextEditingController rateTwoValueController = TextEditingController();
  TextEditingController hsnCodeController = TextEditingController();
  late TextEditingController tax1Controller;
  late TextEditingController tax2Controller;
  late String fullUnitDropdownValue;
  late String shortUnitDropdownValue;
  late String tax1DropdownValue;
  late String tax2DropdownValue;
  late String hsn;
  bool maintainMRP = false;
  bool maintainStock = false;
  bool showHSNSACCode = false;

  List<String> fullUnits = [
    'Bags',
    'Bottle',
    'Box',
    'Bundle',
    'Can',
    'Cartoon',
    'Gram',
    'Kilogram',
    'Litre',
    'Meter',
    'Millilitre',
    'Number',
    'Pack',
    'Pair',
    'Piece',
    'Roll',
    'Square Feet',
    'Square Meter'
  ];

  List<String> shortUnits = [
    'BAG',
    'BTL',
    'BOX',
    'BDL',
    'CAN',
    'CTN',
    'GM',
    'KG',
    'LTR',
    'MTR',
    'ML',
    'NUM',
    'PCK',
    'PRS',
    'PCS',
    'ROL',
    'SQF',
    'SQM'
  ];

  List<Widget> taxRateRows = [];
  List<Key> taxRateRowKeys = [];
  Map<int, String> rateControllers = {};
  Map<int, String> taxControllers = {};
  int? isAdmin;

  String? token;
  String? apiKey;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    itemNameController = TextEditingController();
    quantityController = TextEditingController();
    salePriceController = TextEditingController();
    tax1Controller = TextEditingController();
    tax2Controller = TextEditingController();
    rateTwoValueController.text = '0';
    rateOneValueController.text = '0';
    mrpController = TextEditingController();
    fullUnitDropdownValue = 'Full Unit';
    shortUnitDropdownValue = 'Short Unit';
    tax1DropdownValue = 'GST';
    tax2DropdownValue = 'CESS';
    fullUnits = fullUnits.toSet().toList();
    shortUnits = shortUnits.toSet().toList();
    var key = GlobalKey();
    taxRateRowKeys.add(key);
    taxRateRows.add(_buildTaxRateRow(key, 0));
    // Fetch product details when the page is initialized
    _initializeData();
  }

  @override
  void dispose() {
    mrpController.dispose();
    itemNameController.dispose();
    quantityController.dispose();
    salePriceController.dispose();
    tax1Controller.dispose();
    tax2Controller.dispose();
    rateOneValueController.dispose();
    rateTwoValueController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    token = await APIService.getToken();
    apiKey = await APIService.getXApiKey();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getInt('isAdmin');
    APIService.getUserDetails(token, _showFailedDialog);
    _fetchProductDetails();
    _fetchUserPreferences();
  }

  Future<void> _fetchUserPreferences() async {
    setState(() {
      isLoading = true;
    });
    var token = await APIService.getToken();

    const String apiUrl = '$baseUrl/user-preferences';
    var apiKey = await APIService.getXApiKey();
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Authorization': 'Bearer $token',
      'auth-key': '$apiKey',
    });
    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final preferencesData = jsonData['data'];

      setState(() {
        maintainMRP = preferencesData['preference_mrp'] == 1 ? true : false;
        maintainStock =
            preferencesData['preference_quantity'] == 1 ? true : false;
        showHSNSACCode = preferencesData['preference_hsn'] == 1 ? true : false;
      });
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return customAlertBox(
            title: 'Error',
            content: 'An error occurred. Please login and try again.',
            actions: <Widget>[
              customElevatedButton("OK", green2, white, () {
                navigatorKey.currentState?.pop();
                // Redirect to login page
                navigatorKey.currentState?.pushReplacement(CupertinoPageRoute(
                    builder: (context) => const LoginPage()));
              }),
            ],
          );
        },
      );
    }
  }

  Future<void> _fetchProductDetails() async {
    print('productId: ${widget.productId}');
    setState(() {
      isLoading = true;
    });
    try {
      var response = await http
          .get(Uri.parse('$baseUrl/item/${widget.productId}'), headers: {
        'Authorization': 'Bearer $token',
        'auth-key': '$apiKey',
      });
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
          rateOneValueController.text = jsonData['rate1'];
          rateTwoValueController.text = jsonData['rate2'];
          mrpController.text = jsonData['mrp'] ?? '0';
          fullUnitDropdownValue = jsonData['full_unit'];
          shortUnitDropdownValue = jsonData['short_unit'];
          hsnCodeController.text = jsonData['hsn'];
        });
      } else {
        Result.error("Book list not available");
      }
    } catch (error) {
      Result.error("Book list not available");
    }
  }

  void _showFailedDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return customAlertBox(
          title: "Failed to Fetch User Details",
          content: "Unable to fetch user details. Please login again.",
          actions: <Widget>[
            customElevatedButton(
              'Login',
              green2,
              white,
              () {
                navigatorKey.currentState?.pushReplacement(
                  CupertinoPageRoute(builder: (context) => const LoginPage()),
                );
              },
            )
          ],
        );
      },
    );
  }

  Widget _buildCombinedDropdown(
      String label, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: customTfInputDecoration(label),
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
    if (rateOneValueController.text == "N/A") {
      rateOneValueController.text = '0';
    }
    if (rateTwoValueController.text == "N/A") {
      rateTwoValueController.text = '0';
    }
    print("rateTwoValueController.text: ${rateTwoValueController.text}");
    try {
      print(
          "fullUnitDropdoenMenu: $fullUnitDropdownValue, shortUnitDropdoenValue: $shortUnitDropdownValue");

      var response = await http.post(
        Uri.parse('$baseUrl/update-item'),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': widget.productId,
          'mrp': mrpController.text,
          'item_name': itemNameController.text,
          maintainStock ? 'quantity' : quantityController.text: '',
          'quantity': quantityController.text ?? '',
          'sale_price': salePriceController.text,
          'full_unit': fullUnitDropdownValue,
          'short_unit': shortUnitDropdownValue,
          'rate1': rateOneValueController.text,
          'rate2': rateTwoValueController.text,
          'tax1': tax1DropdownValue,
          'tax2': tax2DropdownValue,
          showHSNSACCode ? 'hsn' : hsnCodeController.text: '',
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        Fluttertoast.showToast(msg: jsonResponse['message']);
        navigatorKey.currentState?.pop();
      } else {
        var jsonResponse = jsonDecode(response.body);
        Fluttertoast.showToast(msg: jsonResponse['data'].toString());

        Result.error("Book list not available");
      }
    } catch (error) {
      Result.error("Book list not available");
      print(error);
    }
  }

  Widget labeltext(String label) {
    return Text(
      label,
      style: const TextStyle(
          color: black,
          fontFamily: 'Roboto-Regular',
          fontWeight: FontWeight.bold,
          fontSize: 16),
    );
  }

  Widget _buildTaxRateRow(Key key, int index) {
    bool isFirstRow = index == 0;
    bool isMaxRowsReached = taxRateRows.length >= 2;
    return Row(
      key: key,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
              value: taxControllers[index] ?? 'GST', // Provide a default value
              onChanged: (String? value) {
                setState(() {
                  taxControllers[index] = value!;
                });
              },
              items: const [
                DropdownMenuItem<String>(
                  value: 'GST',
                  child: Text('GST (%)'),
                ),
                DropdownMenuItem<String>(
                  value: 'SASS',
                  child: Text('SASS (%)'),
                ),
              ],
              hint: const Text('Select Tax'),
              decoration: customTfInputDecoration("Select Tax")),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: TextField(
              controller:
                  index == 0 ? rateOneValueController : rateTwoValueController,
              keyboardType: TextInputType.number,
              decoration: customTfInputDecoration("Rate *")),
        ),
        IconButton(
          icon: Icon(isFirstRow ? Icons.add : Icons.remove),
          onPressed: () {
            try {
              if (isMaxRowsReached) {
                // Show a warning dialog when max rows are reached
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return customAlertBox(
                      title: 'Warning',
                      content: 'You cannot add more than 2 tax rows.',
                      actions: <Widget>[
                        customElevatedButton("OK", green2, white, () {
                          navigatorKey.currentState?.pop();
                        }),
                      ],
                    );
                  },
                );
              } else {
                setState(() {
                  if (isFirstRow) {
                    var newKey = GlobalKey();
                    taxRateRowKeys.insert(index + 1, newKey);
                    taxRateRows.insert(
                        index + 1, _buildTaxRateRow(newKey, index + 1));
                    rateControllers[index + 1] = '';
                    taxControllers[index + 1] = '';
                  } else {
                    taxRateRowKeys.removeAt(index);
                    taxRateRows.removeAt(index);
                    rateControllers.remove(index);
                    taxControllers.remove(index);
                  }
                });
              }
            } catch (e) {
              Result.error("Book list not available");
            }
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar('Edit Product', []),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  green2,
                ), // Change color here
              ), // Show loading indicator
            )
          : isAdmin == 1
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        labeltext("Item Name:"),
                        _buildTextField(itemNameController, 'Item Name'),
                        const SizedBox(
                          height: 15,
                        ),
                        maintainStock
                            ? labeltext("Stock Quantity:")
                            : const SizedBox.shrink(),
                        maintainStock
                            ? _buildTextField(
                                quantityController, 'Stock Quantity')
                            : const SizedBox.shrink(),
                        const SizedBox(
                          height: 15,
                        ),
                        labeltext("Unit:"),
                        _buildCombinedDropdown('Unit', [
                          shortUnitDropdownValue,
                          ...fullUnits.map((unit) =>
                              '$unit (${shortUnits[fullUnits.indexOf(unit)]})')
                        ], (value) {
                          List<String> units = value!.split(' (');
                          String fullUnit = units[0];
                          print("Full unit: $fullUnit");
                          String shortUnit =
                              units[1].substring(0, units[1].length - 1);
                          setState(() {
                            fullUnitDropdownValue = fullUnit;
                            shortUnitDropdownValue = shortUnit;
                          });
                          print(
                              "Fullunitdropdownvalue: $fullUnitDropdownValue");
                        }),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            maintainMRP
                                ? SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        labeltext("MRP:"),
                                        _buildTextField(mrpController, 'MRP'),
                                      ],
                                    ))
                                : const SizedBox.shrink(),
                            maintainMRP
                                ? const SizedBox(width: 15)
                                : const SizedBox.shrink(),
                            SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    labeltext("Sale Price:"),
                                    _buildTextField(
                                        salePriceController, 'Sale Price'),
                                  ],
                                )),
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        showHSNSACCode
                            ? labeltext('HSN Code:')
                            : const SizedBox.shrink(),
                        showHSNSACCode
                            ? _buildTextField(hsnCodeController, 'HSN Code')
                            : const SizedBox.shrink(),
                        showHSNSACCode
                            ? const SizedBox(
                                height: 15,
                              )
                            : const SizedBox.shrink(),
                        labeltext("Taxes:"),
                        Column(
                          children: [
                            for (int i = 0; i < taxRateRows.length; i++)
                              Column(
                                children: [
                                  taxRateRows[i],
                                  const SizedBox(height: 8.0),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        customElevatedButton(
                          "Save Changes",
                          green2,
                          white,
                          () {
                            _updateProduct();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "YOU DO NOT HAVE PERMISSION TO EDIT INVENTORY DATA",
                    style: TextStyle(
                        fontSize: 16, color: red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      decoration: customTfInputDecoration(hintText),
    );
  }

  Widget _buildDropdown(String hintText, List<String> dropdownItems,
      String unitDropdownValue, void Function(String) updateDropdownValue) {
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
      decoration: customTfInputDecoration(hintText),
    );
  }
}
