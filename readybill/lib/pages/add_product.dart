// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:readybill/components/api_constants.dart';

import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/color_constants.dart';

import 'package:readybill/pages/home_page.dart';
import 'package:readybill/pages/how_to_upload_xls.dart';
import 'package:readybill/pages/login_page.dart';
import 'package:readybill/pages/new_dataset.dart';

import 'package:readybill/services/api_services.dart';

import 'package:readybill/services/global_internet_connection_handler.dart';
// import 'package:readybill/services/local_database.dart';
import 'package:readybill/services/local_database_2.dart';
import 'package:readybill/services/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

String uploadExcelAPI = '$baseUrl/preview/excel';
String downloadExcelAPI = '$baseUrl/export';

class AddInventoryService {
  static Future uploadXLS(File file) async {
    var apiKey = await APIService.getXApiKey();
    var token = await APIService.getToken();
    var uri = Uri.parse(uploadExcelAPI);
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['auth-key'] = '$apiKey'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    EasyLoading.show(status: 'Uploading...');
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    EasyLoading.dismiss();
    return response;
  }

  static Future<String?> downloadXLS() async {
    var token = await APIService.getToken();

    var response = await http.get(
      Uri.parse(downloadExcelAPI),
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

class AddInventory extends StatefulWidget {
  const AddInventory({super.key});

  @override
  State<AddInventory> createState() => _AddInventoryState();
}

class _AddInventoryState extends State<AddInventory> {
  List<String> fullUnits = [
    'Full Unit',
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
    'Short Unit *',
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
  TextEditingController itemNameValueController = TextEditingController();
  TextEditingController mrpValueController = TextEditingController();
  TextEditingController salePriceValueController = TextEditingController();
  TextEditingController stockQuantityValueController = TextEditingController();
  TextEditingController codeHSNSACvalueController = TextEditingController();
  TextEditingController rateOneValueController = TextEditingController();
  TextEditingController rateTwoValueController = TextEditingController();
  TextEditingController minumumStockController = TextEditingController();

  Map<int, String> rateControllers = {};
  Map<int, String> taxControllers = {};

  String? fullUnitDropdownValue;
  String? shortUnitDropdownValue;

  bool maintainMRP = false;
  bool maintainStock = false;
  bool showHSNSACCode = false;
  bool isLoading = false;

  String? token;
  String? apiKey;

  @override
  void initState() {
    super.initState();
    var key = GlobalKey();
    taxRateRowKeys.add(key);
    taxRateRows.add(_buildTaxRateRow(key, 0));

    rateControllers[0] = "";
    taxControllers[0] = "GST";
    _initializeData();
  }

  Future<void> _handleUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx', 'csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      var response = await AddInventoryService.uploadXLS(file);

      if (response.statusCode == 200) {
        navigatorKey.currentState?.push(CupertinoPageRoute(
            builder: (context) => const NewDataset(
                  title: "Excel Preview",
                  uploadExcel: 'uploadExcel',
                )));
      } else {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        showDialog(
            context: context,
            builder: (context) => customAlertBox(
                  title: "Failed to Upload",
                  content: jsonResponse['message'],
                  actions: [
                    customElevatedButton("OK", green2, white, () {
                      navigatorKey.currentState?.pop();
                    })
                  ],
                ));
      }
    }
  }

  Widget _buildCombinedDropdown(
      List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: Color(0xffbfbfbf),
            width: 3.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: green2,
            width: 3.0,
          ),
        ),
      ),
      hint: const Text(
        'Full Unit (Short Unit)' ' *',
      ),
      value: fullUnitDropdownValue == null
          ? null
          : '$fullUnitDropdownValue ($shortUnitDropdownValue)', // Initial value
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _initializeData() async {
    token = await APIService.getToken();
    apiKey = await APIService.getXApiKey();
    APIService.getUserDetails(token, _showFailedDialog);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fetchUserPreferences());
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

  downloadFile() async {
    final Uri url =
        Uri.parse('https://dev.readybill.app/storage/media/exported_data.xlsx');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Future<void> returnToLastScreen() async {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Navigate to NextPage when user tries to pop MyHomePage
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => const HomePage()),
        );
        // Return false to prevent popping the current route
        return;
      },
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(246, 247, 255, 1),
        appBar: customAppBar("Add Product", []),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(), // Show loading indicator
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            customElevatedButton(
                                "Upload", blue, white, _handleUpload),
                            const SizedBox(width: 10),
                            customElevatedButton(
                                "Download", green2, white, downloadFile),
                          ],
                        ),
                      ),
                      // Item Name Input Box

                      TextButton(
                        onPressed: () {
                          navigatorKey.currentState?.push(CupertinoPageRoute(
                            builder: (context) => const HowToUploadXlsPage(),
                          ));
                        },
                        child: const Text(
                          "How to upload inventory data in XLS or CSV format?",
                          style: TextStyle(
                              color: blue,
                              decoration: TextDecoration.underline,
                              decorationColor: blue,
                              fontFamily: 'Roboto-Regular'),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      _buildInputBox(' Item Name *', itemNameValueController,
                          (value) {
                        setState(() {
                          itemNameValueController.text =
                              value; // Update the itemNameValue
                        });
                      }),

                      const SizedBox(height: 20.0),
                      // Quantity in Stock
                      Row(children: [
                        Expanded(
                          child: _buildCombinedDropdown(
                              fullUnits
                                  .map((unit) =>
                                      '$unit (${shortUnits[fullUnits.indexOf(unit)]})')
                                  .toList(), (value) {
                            // Split the selected value into full unit and short unit
                            List<String> units = value!.split(' (');
                            String fullUnit = units[0];
                            String shortUnit =
                                units[1].substring(0, units[1].length - 1);
                            setState(() {
                              fullUnitDropdownValue =
                                  fullUnit; // Update the fullUnitDropdownValue
                              shortUnitDropdownValue =
                                  shortUnit; // Update the shortUnitDropdownValue
                            });
                          }),
                        )
                      ]),

                      const SizedBox(height: 20.0),

                      // Sale Price Input Box
                      Row(
                        children: [
                          Flexible(
                            // Use Flexible for salePriceValue as well
                            child: _buildInputBox(
                                ' Sale price: Rs. *', salePriceValueController,
                                (value) {
                              setState(() {
                                salePriceValueController.text =
                                    value; // Update the itemNameValue
                              });
                            }, isNumeric: true),
                          ),
                          const SizedBox(
                              width: 16.0), // Add spacing if MRP is visible
                          Flexible(
                            child: _buildInputBox(
                                ' MRP ${maintainMRP ? '*' : ''}',
                                mrpValueController, (value) {
                              setState(() {
                                mrpValueController.text =
                                    value; // Update the mrpValue
                              });
                            }, isNumeric: true),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Flexible(
                            child: _buildInputBox(
                                ' Stock Quantity ${maintainStock ? '*' : ''}',
                                stockQuantityValueController, (value) {
                              setState(() {
                                stockQuantityValueController.text =
                                    value; // Update the stockValue
                              });
                            }, isNumeric: true),
                          ),
                          const SizedBox(width: 16.0),
                          Flexible(
                              child: Visibility(
                            visible:
                                stockQuantityValueController.text.isNotEmpty,
                            child: _buildInputBox(
                                ' Minimum Stock ', minumumStockController,
                                (value) {
                              setState(() {
                                codeHSNSACvalueController.text =
                                    value; // Update the stockValue
                              });
                            }, isNumeric: true),
                          ))
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      _buildInputBox(
                          ' HSN/ SAC Code ${showHSNSACCode ? '*' : ''}',
                          codeHSNSACvalueController, (value) {
                        setState(() {
                          codeHSNSACvalueController.text =
                              value; // Update the stockValue
                        });
                      }, isNumeric: true),

                      // new emplementation

                      const SizedBox(height: 20.0),

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

                      SizedBox(
                        width: double.infinity,
                        child: customElevatedButton(
                            "Submit", blue, white, submitData),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputBox(String hintText, TextEditingController textControllers,
      void Function(String) updateIdentifier,
      {bool isNumeric = false}) {
    return TextField(
      controller: textControllers,
      decoration: customTfInputDecoration("$hintText "),
      keyboardType: isNumeric
          ? TextInputType.number
          : TextInputType.text, // Set keyboardType based on isNumeric flag
      onChanged: (value) {
        updateIdentifier(
            value); // Call the callback function to update the identifier
      },
    );
  }

// Function to submit data
  void submitData() async {
    if (token == null || token!.isEmpty) {
      return;
    }

    Map<String, dynamic> postData = {
      'item_name': itemNameValueController.text,
      'quantity': int.tryParse(stockQuantityValueController.text),
      'sale_price': int.tryParse(salePriceValueController.text),
      'full_unit': fullUnitDropdownValue,
      'short_unit': shortUnitDropdownValue,
      'mrp': mrpValueController.text, // Add mrp
      'hsn': codeHSNSACvalueController.text,
    };

    // for(var value in taxControllers.values){
    taxControllers.forEach((index, value) {
      index = index + 1;
      postData['tax$index'] = value;
    });

    postData['rate1'] = rateOneValueController.text;
    postData['rate2'] = rateTwoValueController.text;
    var apiKey = await APIService.getXApiKey();
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/add-item'),
        body: jsonEncode(postData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
        },
      );

      if (response.statusCode == 200) {
        LocalDatabase2.instance.clearTable();
        LocalDatabase2.instance.fetchDataAndStoreLocally();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return customAlertBox(
              title: "Success",
              content: "Item added successfully.",
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear input fields
                    fullUnitDropdownValue = fullUnits[0];
                    shortUnitDropdownValue = shortUnits[0];
                    // taxControllers.clear();
                    rateControllers.clear();
                    taxRateRows.clear();
                    taxRateRowKeys.clear();
                    var key = GlobalKey();
                    taxRateRowKeys.add(key);
                    taxRateRows.add(_buildTaxRateRow(key, 0));
                    itemNameValueController.clear();
                    mrpValueController.clear();
                    salePriceValueController.clear();
                    stockQuantityValueController.clear();
                    codeHSNSACvalueController.clear();
                    rateOneValueController.clear();
                    rateTwoValueController.clear();
                    setState(() {
                      LocalDatabase2.instance.clearTable();
                      LocalDatabase2.instance.fetchDataAndStoreLocally();
                    });
                    navigatorKey.currentState?.pop(); // Close dialog
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      } else if (response.statusCode == 401) {
        Result.error("Book list not available");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return customAlertBox(
              title: "Unauthorized",
              content: "Token missing or unauthorized.",
              actions: [
                customElevatedButton("OK", green2, white, () {
                  navigatorKey.currentState?.pop();
                }),
              ],
            );
          },
        );
      } else {
        var errorData = jsonDecode(response.body);
        Result.error("Book list not available");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return customAlertBox(
              title: "Error",
              content: "Error: ${errorData['message']}",
              actions: [
                customElevatedButton("OK", green2, white, () {
                  navigatorKey.currentState?.pop();
                }),
              ],
            );
          },
        );
      }
    } catch (error) {
      Result.error("Book list not available");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return customAlertBox(
            title: "Error",
            content: "Error: $error",
            actions: [
              customElevatedButton("OK", green2, white, () {
                navigatorKey.currentState?.pop();
              }),
            ],
          );
        },
      );
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
                  child: Text('GST'),
                ),
                DropdownMenuItem<String>(
                  value: 'SASS',
                  child: Text('SASS'),
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
        ),
      ],
    );
  }
}
