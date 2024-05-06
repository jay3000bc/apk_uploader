import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text_search/drawer.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/login_profile.dart';
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/search_app.dart';

import 'Service/api_constants.dart';

String uploadExcelAPI = '$baseUrl/preview/excel';
String downloadExcelAPI = '$baseUrl/export';

class AddInventoryService {
  static Future<String?> uploadXLS(File file) async {
    var token = await APIService.getToken();
    var uri = Uri.parse(uploadExcelAPI);
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      return responseData;
    } else {
      // Log the response body
      var errorBody = await response.stream.bytesToString();
      print('Error response body: $errorBody');
      return null;
    }
  }

  static Future<String?> downloadXLS() async {
    var token = await APIService.getToken();

    var response = await http.get(
      Uri.parse(downloadExcelAPI),
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

class AddInventory extends StatefulWidget {
  @override
  _AddInventoryState createState() => _AddInventoryState();
}

class _AddInventoryState extends State<AddInventory> {
  // Dummy data for the unit dropdown
  List<String> fullUnits = ['Bags', 'Bottle', 'Box', 'Bundle', 'Can', 'Cartoon', 'Gram', 'Kilogram', 'Litre', 'Meter', 'Millilitre', 'Number', 'Pack', 'Pair', 'Piece', 'Roll', 'Square Feet', 'Square Meter'];

  List<String> shortUnits = ['BAG', 'BTL', 'BOX', 'BDL', 'CAN', 'CTN', 'GM', 'KG', 'LTR', 'MTR', 'ML', 'NUM', 'PCK', 'PRS', 'PCS', 'ROL', 'SQF', 'SQM'];

  List<Widget> taxRateRows = [];
  List<Key> taxRateRowKeys = [];
  Map<String, TextEditingController> textControllers = {};

  Map<int, String> rateControllers = {};
  Map<int, String> taxControllers = {};

  String fullUnitDropdownValue = '';
  String shortUnitDropdownValue = '';

  String itemNameValue = '';
  String salePriceValue = '';
  String stockQuntityValue = '';
  String mrpValue = '';
  String codeHSNSACvalue = '';

  int _selectedIndex = 1;

  bool maintainMRP = false;
  bool maintainStock = false;
  bool showHSNSACCode = false;
  bool isLoading = false;

  String? token;

  @override
  void initState() {
    super.initState();
    var key = GlobalKey();
    taxRateRowKeys.add(key);
    taxRateRows.add(_buildTaxRateRow(key, 0));
    // Initialize the taxRateRows list with the first row

    rateControllers[0] = "";
    taxControllers[0] = "";
    _initializeData();
    // getToken();
    // getUserDetails();
  }

  Future<void> _handleUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String? response = await AddInventoryService.uploadXLS(file);
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
    final url = '$baseUrl/storage/media/exported_data.xlsx';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Directory? directory;

      directory = Directory('/storage/emulated/0/Download');

      if (directory != null) {
        final filePath = '${directory.path}/exported_data.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Download Error'),
              content: Text('Failed to access external storage.'),
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
    } else {
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

  Future<void> _initializeData() async {
    token = await APIService.getToken();
    APIService.getUserDetails(token, _showFailedDialog);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserPreferences());
  }

  Future<void> _fetchUserPreferences() async {
    setState(() {
      isLoading = true;
    });
    print("kibakibi");
    var token = await APIService.getToken();
    // Make API call to fetch user preferences
    final String apiUrl = '$baseUrl/user-preferences';
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Authorization': 'Bearer $token',
    });
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final preferencesData = jsonData['data'];

      setState(() {
        maintainMRP = preferencesData['preference_mrp'] == 1 ? true : false;
        maintainStock = preferencesData['preference_quantity'] == 1 ? true : false;
        showHSNSACCode = preferencesData['preference_hsn'] == 1 ? true : false;
      });
    } else {
      // Handle exceptions

      // ignore: use_build_context_synchronously
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred. Please login and try again.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Redirect to login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      print(token);
    });
  }

  Future<void> returnToLastScreen() async {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to NextPage when user tries to pop MyHomePage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchApp()),
        );
        // Return false to prevent popping the current route
        return false;
      },
      child: Scaffold(
        backgroundColor: Color.fromRGBO(246, 247, 255, 1),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Add Inventory',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          backgroundColor: Color.fromRGBO(243, 203, 71, 1),
        ),
        drawer: Sidebar(),
        bottomNavigationBar: CustomNavigationBar(
          onItemSelected: (index) {
            // Handle navigation item selection
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedIndex: _selectedIndex,
        ),
        body: isLoading
            ? Center(
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _handleUpload,
                              child: Text('Upload'),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _handleDownload,
                              child: Text('Download'),
                            ),
                          ],
                        ),
                      ),
                      // Item Name Input Box
                      _buildInputBox(' Item Name', itemNameValue, (value) {
                        setState(() {
                          itemNameValue = value; // Update the itemNameValue
                        });
                      }),

                      SizedBox(height: 20.0),
                      // Quantity in Stock
                      Row(children: [
                        Expanded(
                          child: _buildCombinedDropdown('Unit', ['Full Unit (Short Unit)' + ' *', ...fullUnits.map((unit) => '$unit (${shortUnits[fullUnits.indexOf(unit)]})').toList()], (value) {
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
                      ]),

                      SizedBox(height: 20.0),

                      // Sale Price Input Box
                      Row(
                        children: [
                          Flexible(
                            child: Visibility(
                              visible: maintainMRP,
                              child: _buildInputBox(' MRP', mrpValue, (value) {
                                setState(() {
                                  mrpValue = value; // Update the mrpValue
                                });
                              }, isNumeric: true),
                            ),
                          ),
                          SizedBox(width: maintainMRP ? 16.0 : 0), // Add spacing if MRP is visible
                          Flexible(
                            // Use Flexible for salePriceValue as well
                            child: _buildInputBox(' Sale price: Rs.', salePriceValue, (value) {
                              setState(() {
                                salePriceValue = value; // Update the itemNameValue
                              });
                            }, isNumeric: true),
                          ),
                        ],
                      ),

                      // Tax and Rate Input Boxes
                      // Column(
                      //   children: taxRateRows,
                      // ),

                      // new emplementation

                      SizedBox(height: 16.0),
                      Visibility(
                        visible: maintainStock,
                        child: _buildInputBox(' Stock Quantity', stockQuntityValue, (value) {
                          setState(() {
                            stockQuntityValue = value; // Update the stockValue
                          });
                        }, isNumeric: true),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: showHSNSACCode,
                        child: _buildInputBox(' HSN/ SAC Code', codeHSNSACvalue, (value) {
                          setState(() {
                            codeHSNSACvalue = value; // Update the stockValue
                          });
                        }, isNumeric: true),
                      ),

                      // new emplementation

                      SizedBox(height: 20.0),

                      Column(
                        children: [
                          for (int i = 0; i < taxRateRows.length; i++)
                            Column(
                              children: [
                                taxRateRows[i],
                                SizedBox(height: 8.0),
                              ],
                            ),
                        ],
                      ),

                      SizedBox(height: 20.0),

                      // Add More Button
                      ElevatedButton(
                        onPressed: () {
                          submitData();
                          // Submit functionality
                          print('Submit Button Pressed');
                          // TODO: Implement form submission logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Change the color here
                        ),
                        child: Text(
                          'ADD',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputBox(String labelText, String identifier, void Function(String) updateIdentifier, {bool isNumeric = false}) {
    return TextField(
      controller: textControllers[identifier],
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: labelText + ' *', // Adding asterisk (*) to the label text
        labelStyle: TextStyle(color: Colors.black), // Setting label text color to black

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text, // Set keyboardType based on isNumeric flag
      onChanged: (value) {
        updateIdentifier(value); // Call the callback function to update the identifier
      },
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
        filled: true,
        fillColor: Colors.white,
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

// Function to submit data
  void submitData() async {
    print("item $itemNameValue");

    if (token == null || token!.isEmpty) {
      print('Token is missing');
      return;
    }

    Map<String, dynamic> postData = {
      'item_name': itemNameValue,
      'quantity': int.tryParse(stockQuntityValue),
      'sale_price': int.tryParse(salePriceValue),
      'full_unit': fullUnitDropdownValue,
      'short_unit': shortUnitDropdownValue,
      'mrp': mrpValue, // Add mrp
      'hsn': codeHSNSACvalue,
    };

    taxControllers.forEach((index, value) {
      index = index + 1;
      postData['tax$index'] = value;
    });

    rateControllers.forEach((index, value) {
      index = index + 1;
      postData['rate$index'] = value;
    });

    try {
      var response = await http.post(
        Uri.parse('$baseUrl/add-item'),
        body: jsonEncode(postData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text("Item added successfully."),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear input fields
                    setState(() {
                      itemNameValue = '';
                      salePriceValue = '';
                      stockQuntityValue = '';
                      mrpValue = '';
                      codeHSNSACvalue = '';
                      fullUnitDropdownValue = '';
                      shortUnitDropdownValue = '';
                      taxControllers.clear();
                      rateControllers.clear();
                      taxRateRows.clear();
                      taxRateRowKeys.clear();
                      var key = GlobalKey();
                      taxRateRowKeys.add(key);
                      taxRateRows.add(_buildTaxRateRow(key, 0));
                    });

                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else if (response.statusCode == 401) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Unauthorized"),
              content: Text("Token missing or unauthorized."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        var errorData = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text("Error: ${errorData['message']}"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Error: $error"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
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

  Widget _buildTaxRateRow(Key key, int index) {
    bool isFirstRow = index == 0;
    bool isMaxRowsReached = taxRateRows.length >= 2;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: taxControllers[index] ?? 'GST', // Provide a default value
            onChanged: (String? value) {
              setState(() {
                taxControllers[index] = value!;
              });
            },
            items: [
              DropdownMenuItem<String>(
                value: 'GST',
                child: Text('GST'),
              ),
              DropdownMenuItem<String>(
                value: 'SASS',
                child: Text('SASS'),
              ),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Tax' + ' *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.0),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                rateControllers[index] = value;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Rate' + ' *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
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
                    return AlertDialog(
                      title: Text('Warning'),
                      content: Text('You cannot add more than 2 tax rows.'),
                      actions: <Widget>[
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
                setState(() {
                  if (isFirstRow) {
                    var newKey = GlobalKey();
                    taxRateRowKeys.insert(index + 1, newKey);
                    taxRateRows.insert(index + 1, _buildTaxRateRow(newKey, index + 1));
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
              print('Error in onPressed: $e');
            }
          },
        ),
      ],
      key: key,
    );
  }

  void removeTaxRateRow(int index) {
    setState(() {
      taxRateRowKeys.removeAt(index);
      taxRateRows.removeAt(index);
      rateControllers.remove(index);
      taxControllers.remove(index);
    });
  }
}
