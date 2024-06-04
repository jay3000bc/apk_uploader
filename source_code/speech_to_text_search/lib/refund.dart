import 'dart:async';
import 'dart:convert';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text_search/drawer.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/login_profile.dart';
import 'package:speech_to_text_search/product_mic_state.dart';
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/quantity_mic_state.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'Service/api_constants.dart';

class MicStateListener {
  final Function(bool) _listener;

  MicStateListener(this._listener);

  void notify(bool isListening) {
    _listener(isListening);
  }
}

class Refund extends StatefulWidget {
  @override
  _RefundState createState() => _RefundState();
}

class _RefundState extends State<Refund> with TickerProviderStateMixin {
  GlobalKey<_RefundState> yourButtonKey = GlobalKey();

  TextEditingController productNameController = TextEditingController();
  late final AnimationController _animationController;
  TextEditingController quantityController = TextEditingController();
  FocusNode productNameFocusNode = FocusNode();
  FocusNode quantityFocusNode = FocusNode();
  String errorMessage = "";
  bool isListeningMic = false;
  bool validProductName = true;
  int _selectedIndex = 1;
  bool isActive = false;
  bool isquantityavailable = false;
  bool isSuggetion = false;
  String? token;
  String query = "";
  String? availableStockValue = '';
  String? itemNameforTable = '';
  String unitOfQuantity = '';
  double quantityNumeric = 0;

  final FocusNode _searchFocus = FocusNode();

  bool shouldOpenDropdown = false;

  //New Variable

  bool _hasSpeech = false;
  bool _logEvents = false;
  bool _onDevice = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  final SpeechToText speech = SpeechToText();

  //New Variable

  String itemId = '';
  String salePrice = '';
  String parseQuantity = '';
  bool quantityFound = false;

  List<Map<String, dynamic>> itemForBillRows = [];
  List<Map<String, String>> items = [];
  Map<String, int> quantities = {};
  List<String> item_name_suggetion = [];

  List<String> convertListToLowerCase(List<String> inputList) {
    return inputList.map((item) => item.toLowerCase()).toList();
  }

  Map<String, String> convertMapKeysToLowerCase(Map<String, String> inputMap) {
    return Map.fromEntries(inputMap.entries.map((entry) => MapEntry(entry.key.toLowerCase(), entry.value)));
  }

  Map<String, double> convertMapKeysToLowerCaseDouble(Map<String, double> inputMap) {
    return Map.fromEntries(inputMap.entries.map((entry) => MapEntry(entry.key.toLowerCase(), entry.value)));
  }

  String? _selectedQuantitySecondaryUnit;
  // Define _selectedQuantitySecondaryUnit as a String variable
  String? _primaryUnit;

  List<String> _dropdownItemsQuantity = [
    'Unit',
  ];

  String quantitySelectedValue = '';

  List<String> additionalSuggestions = [];

  String _errorMessage = '';

  bool listening = false;

  String recognizedWord = '';
  List<Map<String, String>> similarItems = [];

  GlobalKey<AutoCompleteTextFieldState<String>> productNameKey = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> quantityKey = GlobalKey();

  List<String> suggestionList = [];

  List<String> getSuggestions() {
    return items.map<String>((item) => item['name']!).toList();
  }

  Future<void> fetchDataAndAssign() async {
    // You need to replace this with your recognized word
    // You need to replace this with your token

    final response = await http.get(
      Uri.parse('$baseUrl/product-suggesstions?item_name='),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        final List<dynamic> data = responseData['data'];
        setState(() {
          items = data.map<Map<String, String>>((item) {
            return {
              'id': item['id'].toString(),
              'name': item['item_name'].trim(),
              'unit': item['short_unit'],
            };
          }).toList();
          final List<String> suggestions = data.map<String>((item) {
            return item['item_name'].toString(); // Assuming 'item_name' is a String
          }).toList();
          setState(() {
            item_name_suggetion = suggestions;
          });
        });
      } else {
        print('API call failed with status: ${responseData['status']}. Response body: ${response.body}');
      }
    } else {
      print('Failed to load data. Response body: ${response.body}');
    }
  }

  @override
  void initState() {
    initSpeechState();
    super.initState();

    _animationController = AnimationController(vsync: this);
    _selectedQuantitySecondaryUnit = _dropdownItemsQuantity.first;
    // Fixed method name
    _checkAndRequestPermission(); // Fixed method name
    if (items.isNotEmpty) {
      query = items[0]['name'] ?? ''; // Accessing the 'name' field of the first item
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  @override
  void dispose() {
    speech.cancel(); // Cancel speech recognition
    productNameFocusNode.dispose();
    quantityFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    token = await APIService.getToken();
    APIService.getUserDetails(token, _showFailedDialog);
    await fetchDataAndAssign();
  }

  void _checkAndRequestPermission() async {
    var status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      await Permission.microphone.request();
    }
  }

  // Update the controller's state based on isListeningMic

  @override
  Widget build(BuildContext context) {
    return Consumer2<MicState, QuantityMicState>(
      builder: (context, micState, quantityMicState, _) {
        return WillPopScope(
          onWillPop: () async {
            final value = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Alert'),
                    content: const Text('Do You Want to Exit'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Exit'),
                      ),
                    ],
                  );
                });
            if (value != null) {
              return Future.value(value);
            } else {
              return Future.value(false);
            }
          },
          child: GestureDetector(
            onTap: () {
              // Hide the suggestion dropdown when tapping outside
              _searchFocus.unfocus();
              setState(() {
                suggestionList.clear();
              });
            },
            child: Scaffold(
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
              body: Stack(
                children: [
                  Container(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                        child: Stack(
                          children: [
                            Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 30,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 20), // Adjust the spacing between the container and the text
                                    Visibility(
                                      visible: isListeningMic,
                                      child: Text(
                                        "I am Listening...",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Adjust the spacing between the container and the text

                                validProductName
                                    ? Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Text(""),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                          Text(
                                            "Product Not Found",
                                            style: TextStyle(fontSize: 20, color: Colors.red),
                                          ),
                                        ],
                                      ),

                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: productNameController,
                                        focusNode: _searchFocus,
                                        onChanged: updateSuggestionList,
                                        decoration: InputDecoration(
                                          // border: OutlineInputBorder(
                                          //   borderRadius: BorderRadius.circular(50.0),
                                          // ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.cyan),
                                          ),
                                          hintText: "  Type a Product...",
                                          hintStyle: TextStyle(fontSize: 20.0, color: Color.fromRGBO(0, 0, 0, 1)),
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Visibility(
                                                visible: productNameController.text.isNotEmpty,
                                                child: IconButton(
                                                  padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
                                                  icon: Icon(
                                                    Icons.clear,
                                                    color: Color.fromRGBO(0, 0, 0, 1),
                                                  ),
                                                  onPressed: () {
                                                    // _searchFocus.unfocus();
                                                    setState(() {
                                                      suggestionList.clear();
                                                      clearProductName();
                                                      stopListening();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // _buildSuggestionDropdown(),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 60, // Adjust the height as needed
                                    child: Stack(
                                      children: <Widget>[
                                        // AutoCompleteTextField
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: AutoCompleteTextField<String>(
                                            // Your existing AutoCompleteTextField code here
                                            key: quantityKey,
                                            controller: quantityController,
                                            suggestions: ["1", "2", "3", "4", "5"], // Adjust as needed
                                            clearOnSubmit: false,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              enabledBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                                              ),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(color: Colors.cyan),
                                              ),
                                              hintText: "  Type a Quantity...",
                                              hintStyle: TextStyle(fontSize: 20.0, color: Color.fromRGBO(0, 0, 0, 1)),
                                              suffixIcon: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Visibility(
                                                    visible: quantityController.text.isNotEmpty,
                                                    child: IconButton(
                                                      padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
                                                      icon: Icon(Icons.clear, color: Color.fromARGB(255, 0, 0, 0)),
                                                      onPressed: () {
                                                        setState(() {
                                                          // Clear product name and stop listening
                                                          clearProductName();

                                                          stopListening();
                                                          // Set quantityController.text to null or an empty string
                                                          quantityController.text = ""; // or null
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            itemFilter: (String item, query) {
                                              return item.startsWith(query);
                                            },
                                            itemSorter: (String a, String b) {
                                              return a.compareTo(b);
                                            },
                                            itemSubmitted: (String item) {
                                              quantityController.text = item;
                                            },
                                            itemBuilder: (BuildContext context, String itemData) {
                                              return ListTile(
                                                title: Text(itemData),
                                              );
                                            },
                                          ),
                                        ),
                                        // DropdownButton
                                        Positioned(
                                          top: 3,
                                          right: 50,
                                          child: DropdownButton<String>(
                                            value: _selectedQuantitySecondaryUnit,
                                            onChanged: (newValue) {
                                              setState(() {
                                                _selectedQuantitySecondaryUnit = newValue;
                                                quantitySelectedValue = newValue ?? ''; // Update quantitySelectedValue with the selected value
                                              });
                                            },
                                            items: _dropdownItemsQuantity.map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                // Display the total price for the selected product

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Align buttons at the ends
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: (productNameController.text.isEmpty || quantityController.text.isEmpty) ? const Color.fromRGBO(210, 211, 211, 1) : Colors.blue,
                                      ),
                                      padding: const EdgeInsets.all(5.0),
                                      child: MaterialButton(
                                        onPressed: () async {
                                          if (productNameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                                            // Both productNameController and quantityController are not empty, proceed void handleStockStatus(String itemId, String quantity, String relatedUnit, String token) async {
                                            String quantityValue = quantityController.text;
                                            int? stockStatus = await checkStockStatus(itemId, quantityValue, _selectedQuantitySecondaryUnit!, token!);
                                            print("eytu status");
                                            print(stockStatus);
                                            if (stockStatus == 1) {
                                              double? quantityValueforConvert = double.tryParse(quantityValue);
                                              double quantityValueforTable = convertQuantityBasedOnUnit(_primaryUnit!, _selectedQuantitySecondaryUnit!, quantityValueforConvert!);
                                              double? salePriceforTable = double.tryParse(salePrice);
                                              addProductTable(itemNameforTable!, quantityValueforTable, _selectedQuantitySecondaryUnit!, salePriceforTable!);
                                            } else if (stockStatus == 0) {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text("Out of Stock"),
                                                    content: Text("You have only $availableStockValue left"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context); // Close the dialog
                                                        },
                                                        child: Text("OK"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          } else {
                                            // Either productNameController or quantityController is empty, show dialog box
                                            return null;
                                          }
                                        },
                                        height: 10,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "ADD",
                                            style: TextStyle(fontSize: 20, color: (productNameController.text.isEmpty || quantityController.text.isEmpty) ? Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.red, // Example color for refund button
                                      ),
                                      padding: const EdgeInsets.all(5.0),
                                      child: MaterialButton(
                                        onPressed: () async {
                                          if (productNameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                                            // Both productNameController and quantityController are not empty, proceed void handleStockStatus(String itemId, String quantity, String relatedUnit, String token) async {
                                            String quantityValue = quantityController.text;
                                            int? stockStatus = await checkStockStatus(itemId, quantityValue, _selectedQuantitySecondaryUnit!, token!);
                                            print("eytu status");
                                            print(stockStatus);
                                            if (stockStatus == 0 || stockStatus == 1 || stockStatus == 2) {
                                              double? quantityValueforConvert = double.tryParse(quantityValue);
                                              double quantityValueforTable = convertQuantityBasedOnUnit(_primaryUnit!, _selectedQuantitySecondaryUnit!, quantityValueforConvert!);

                                              double? salePriceforTable = double.tryParse(salePrice);
                                              addProductRefundTable(itemNameforTable!, quantityValueforTable, _selectedQuantitySecondaryUnit!, salePriceforTable!);
                                            } else if (stockStatus == 0) {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text("Out of Stock"),
                                                    content: Text("You have only $availableStockValue left"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context); // Close the dialog
                                                        },
                                                        child: Text("OK"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          } else {
                                            // Either productNameController or quantityController is empty, show dialog box
                                            return null;
                                          }
                                        },
                                        height: 10,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "REFUND",
                                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_errorMessage.isNotEmpty) _productErrorWidget(_errorMessage),
                                Visibility(
                                  visible: !itemForBillRows.isNotEmpty,
                                  child: SizedBox(
                                    height: 100,
                                  ),
                                ),

                                Visibility(
                                  visible: !itemForBillRows.isNotEmpty,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Tap Mic and start by saying",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 25.0,
                                            color: Color(0xFFD79922), // Set color to #D79922
                                          ),
                                        ),
                                        Text(
                                          "\"Amul Butter quantity 2packs\"",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 25.0,
                                            color: Color(0xFFD79922), // Set color to #D79922
                                          ),
                                        ),
                                        Text(
                                          "select product and Add",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 25.0,
                                            color: Color(0xFFD79922), // Set color to #D79922
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Inside the DataTable
                                Visibility(
                                  visible: itemForBillRows.isNotEmpty,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Container(
                                      child: DataTable(
                                        columnSpacing: 30.0,
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              "Item",
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            numeric: false,
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Qty",
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                            numeric: false,
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Rate",
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                            numeric: false,
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Amount",
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                            numeric: false,
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "",
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                            numeric: false,
                                          ),
                                        ],
                                        rows: List<DataRow>.generate(
                                          itemForBillRows.length,
                                          (index) => DataRow(cells: [
                                            DataCell(
                                              Container(width: 50, child: Text(itemForBillRows[index]['itemName'])),
                                            ),
                                            DataCell(
                                              Container(width: 40, child: Text('${itemForBillRows[index]['quantity']} ${itemForBillRows[index]['selectedUnit']}')),
                                            ),
                                            DataCell(
                                              Container(
                                                width: 70,
                                                height: 40,
                                                child: TextField(
                                                  decoration: InputDecoration(
                                                    hintText: itemForBillRows[index]['rate'].toString(),
                                                    filled: true,
                                                    fillColor: const Color.fromARGB(255, 216, 216, 216),
                                                    // Adding asterisk (*) to the label text
                                                    labelStyle: TextStyle(color: Colors.black), // Setting label text color to black

                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8.0),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (newRate) {
                                                    // Update the rate value in your data model
                                                    itemForBillRows[index]['rate'] = double.parse(newRate);
                                                    // Recalculate the amount
                                                    itemForBillRows[index]['amount'] = itemForBillRows[index]['rate'] * itemForBillRows[index]['quantity'];
                                                    // Trigger UI update
                                                    setState(() {});
                                                  },
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(width: 50, child: Text(itemForBillRows[index]['amount'].toString())),
                                            ),
                                            DataCell(
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Color.fromARGB(255, 161, 11, 0),
                                                ),
                                                onPressed: () {
                                                  // Delete the product at the current index when IconButton is pressed
                                                  deleteProductFromTable(index);
                                                },
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Visibility(
                                  visible: itemForBillRows.isNotEmpty,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      "Overall Total: \₹${calculateOverallTotal()}",
                                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),

                                Visibility(
                                  visible: itemForBillRows.isNotEmpty,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Align buttons evenly
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          saveData();
                                          // setState(() {
                                          //   itemForBillRows.clear(); // Clear the list
                                          //   clearProductName();
                                          // });
                                        },
                                        child: Text("Save"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Action for print button
                                        },
                                        child: Text("Print"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Positioned(
                            //   bottom: 230,
                            //   left: 1,
                            //   right: 1,
                            //   child: ErrorWidget(
                            //     lastError: lastError,
                            //     quantityWord: isquantityavailable,
                            //   ),
                            // ),
                            // Positioned(
                            //     left: 10,
                            //     right: 10,
                            //     bottom: 80,
                            //     child: Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       children: [
                            //         Text(
                            //           !_hasSpeech || speech.isListening ? "" : "Tap to speak",
                            //           style: const TextStyle(
                            //             color: Colors.green,
                            //           ),
                            //         ),
                            //       ],
                            //     )),
                            // Positioned(bottom: 230, left: 1, right: 1, child: !_hasSpeech || speech.isListening ? listeningAnimation() : SizedBox()),
                            // Positioned.fill(
                            //   bottom: 100,
                            //   child: Align(alignment: Alignment.bottomCenter, child: microphoneButton()),
                            // ),
                            Positioned(
                              top: 128, // Adjust the position as needed
                              left: 0,
                              right: 0,
                              child: Container(
                                  width: MediaQuery.of(context).size.width - 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(0),

                                    color: Colors.grey.shade100, // Background color
                                  ),
                                  child: _buildSuggestionDropdown()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150,
                    left: 1,
                    right: 1,
                    child: ErrorWidget(
                      lastError: lastError,
                      quantityWord: isquantityavailable,
                    ),
                  ),
                  Positioned(
                      left: 10,
                      right: 10,
                      bottom: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            !_hasSpeech || speech.isListening ? "" : "Tap to speak",
                            style: const TextStyle(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      )),
                  Positioned(bottom: 170, left: 1, right: 1, child: !_hasSpeech || speech.isListening ? listeningAnimation() : SizedBox()),
                  Positioned.fill(
                    bottom: 50,
                    child: Align(alignment: Alignment.bottomCenter, child: microphoneButton()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> saveData() async {
    print("Eytu bill::    $itemForBillRows");
    final String apiUrl = '$baseUrl/refund';

    double grandTotal = calculateOverallTotal(); // Calculate overall total
// Determine print flag

    Map<String, dynamic> requestBody = {
      'itemList': itemForBillRows,
      'grand_total': grandTotal,
      'print': 0,
    };

    print("Eytu requst:: $requestBody");
    Map<String, String> formData = convertJsonToFormData(requestBody);
    print("Eytu last $formData");

    // Send POST request with bearer token
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token", // Include bearer token
        },
        body: formData,
      );

      if (response.statusCode == 200) {
        print('Data saved successfully');
        itemForBillRows.clear(); // Clear the list
        clearProductName(); // Call the clearProductName function

        // Show dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Billing is done"),
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
        // Optionally, you can handle further actions after saving the data
      } else {
        print('Failed to save data. Status code: ${response.statusCode}');
        print(response.body);
        // Handle error cases
      }
    } catch (e) {
      print('Error occurred while saving data: $e');
      // Handle exceptions
    }
  }

  void clearProductName() {
    setState(() {
      productNameController.clear();
      errorMessage = "";
      validProductName = true; // Clear error message when clearing the text field
    });
  }

  void addProductTable(String itemName, double finalQuantity, String unit, double salePrice) {
    double amount = salePrice * finalQuantity; // Calculate the amount
    setState(() {
      itemForBillRows.add({
        'itemId': itemId,
        'itemName': itemName,
        'quantity': finalQuantity,
        'rate': salePrice,
        'selectedUnit': unit,
        'amount': amount,
        'isDelete': 0,
        'isRefund': 0,
      });
    });
    // Add the product to the list
  }

  void addProductRefundTable(String itemName, double finalQuantity, String unit, double salePrice) {
    double amount = salePrice * finalQuantity; // Calculate the amount
    setState(() {
      itemForBillRows.add({
        'itemId': itemId,
        'itemName': itemName,
        'quantity': finalQuantity,
        'rate': salePrice,
        'selectedUnit': unit,
        'amount': amount * -1,
        'isDelete': 0,
        'isRefund': 1,
      });
    });
    // Add the product to the list
  }

  Future<int?> checkStockStatus(String itemId, String quantity, String relatedUnit, String token) async {
    print("eygal sob");
    print(itemId);
    print(quantity);
    print(relatedUnit);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock-quantity'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'item_id': itemId,
          'quantity': quantity,
          'relatedUnit': relatedUnit,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print(responseData);
        if (responseData.containsKey('stockStatus')) {
          // Assign quantity from response to availableStockValue if available
          availableStockValue = responseData['data']?['quantity'] as String?;
          itemNameforTable = responseData['data']?['item_name'] as String?;
          // Parse stockStatus to int
          int? stockStatus = int.tryParse(responseData['stockStatus']);
          if (stockStatus == 1) {
            salePrice = responseData['data']['sale_price'];
          }
          return stockStatus;
        } else {
          // If stockStatus is not present in the response, return -1 to indicate an error
          return -1;
        }
      } else {
        // Handle other HTTP status codes
        print('HTTP request failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}'); // Print the whole response body
        return -1;
      }
    } catch (e) {
      // Handle exceptions
      print('Error occurred: $e');
      return -1;
    }
  }

  bool _areWordsSimilar(String word1, String word2) {
    final double similarityThreshold = .35; // Adjust the threshold as needed
    final double similarity = StringSimilarity.compareTwoStrings(word1, word2);
    print('Similar Words: $word1, $word2, Similarity: $similarity');
    return similarity >= similarityThreshold;
  }

//New Code

  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: _logEvents,
      );
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  String? getUnitForItem(String itemName) {
    // Iterate over the items list to find the item with the matching name
    for (var item in items) {
      if (item['name'] == itemName) {
        // Return the unit if the item name matches
        return item['unit'];
      }
    }
    // Return null if no matching item is found
    return null;
  }

  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    lastError = '';

    final options = SpeechListenOptions(onDevice: _onDevice, cancelOnError: true, partialResults: true, autoPunctuation: true, enableHapticFeedback: true);
    // Note that `listenFor` is the maximum, not the minimum, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 9),
    );
    setState(() {});

    if (shouldOpenDropdown) {
      Future.delayed(Duration(milliseconds: 100));
      openDropdown(productNameFocusNode);
    }
  }

  void resultListener(SpeechRecognitionResult result) {
    _logEvent('Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    print('Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      lastWords = '${result.recognizedWords} - ${result.finalResult}';

      ///my code
      final recognizedWord = result.recognizedWords.toLowerCase();

      print("Recognized Word: $recognizedWord");

      final isValidWord = items.any((item) => _areWordsSimilar(item['name']!.toLowerCase(), recognizedWord));
      final similarItems = items.where((item) => _areWordsSimilar(item['name']!.toLowerCase(), recognizedWord)).toList();

      if (similarItems.isNotEmpty) {
        shouldOpenDropdown = true;
        validProductName = true;
        _parseSpeech(recognizedWord);
      } else {
        if (!additionalSuggestions.contains(recognizedWord)) {
          setState(() {
            additionalSuggestions.add(recognizedWord);
          });

          if (!isValidWord) {
            setState(() {
              validProductName = false;
            });
          }
        }
      }
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent('Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent('Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = status;
    });
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      debugPrint('$eventTime $eventDescription');
    }
  }

  listeningAnimation() {
    return Column(
      children: [
        const Text(
          "I'm Listening...",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
        )
      ],
    );
  }

  microphoneButton() {
    return AvatarGlow(
      animate: !_hasSpeech || speech.isListening,
      glowColor: Colors.green,
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      child: Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(blurRadius: .26, spreadRadius: level * 1.5, color: Colors.white.withOpacity(.05))],
            color: Colors.green,
            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
          child: InkWell(
            onTap: !_hasSpeech || speech.isListening ? stopListening : startListening,
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 40,
            ),
          )),
    );
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    _logEvent('cancel');
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

//New Code

  Widget _parseSpeech(String words) {
    print("Sentence: $words");
    RegExp regex = RegExp(r'(\w+(?:\s+\w+)*)\s+quantity\s+(\d+)\s*(\w+)?');
    Match? match = regex.firstMatch(words);

    if (match != null) {
      String product = match.group(1) ?? "";
      String quantity = match.group(2) ?? "";
      String unitOfQuantity = match.group(3) ?? "";

      if (product.isNotEmpty && quantity.isNotEmpty && unitOfQuantity != null && unitOfQuantity.isNotEmpty) {
        productNameController.text = product;
        quantityController.text = quantity;

        updateSuggestionList(product);

        setState(() {
          _errorMessage = ''; // Clear error message on successful parsing
        });
      } else if (unitOfQuantity == null || unitOfQuantity.isEmpty) {
        setState(() {
          _errorMessage = 'Unit is missing.';
        });
        return _productErrorWidget(_errorMessage);
      }
    }

    if (!words.contains('quantity')) {
      setState(() {
        _errorMessage = 'Quantity word is missing.';
      });
      return _productErrorWidget(_errorMessage);
    }

    if (words.contains('quantity') && !words.contains(RegExp(r'\d+'))) {
      setState(() {
        _errorMessage = 'Quantity is missing.';
      });
      return _productErrorWidget(_errorMessage);
    }

    if (words.contains(RegExp(r'quantity\s+\d+')) && !words.contains(RegExp(r'\w+$'))) {
      setState(() {
        _errorMessage = 'Unit is missing.';
      });
      return _productErrorWidget(_errorMessage);
    }

    if (words.contains(RegExp(r'\d+\s*\w+$')) && !words.contains('quantity')) {
      setState(() {
        _errorMessage = 'Quantity word is missing.';
      });
      return _productErrorWidget(_errorMessage);
    }

    if (words.startsWith('quantity')) {
      setState(() {
        _errorMessage = 'Product is missing.';
      });
      return _productErrorWidget(_errorMessage);
    }

    setState(() {
      _errorMessage = 'Invalid input.';
    });
    return _productErrorWidget(_errorMessage);
  }

  Widget _productErrorWidget(error) {
    return Align(
        alignment: Alignment.center,
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ));
  }

  Map<String, String> convertJsonToFormData(Map<String, dynamic> jsonData) {
    Map<String, String> formData = {};

    // Convert itemList
    if (jsonData.containsKey('itemList') && jsonData['itemList'] is List) {
      List itemList = jsonData['itemList'];
      for (int i = 0; i < itemList.length; i++) {
        formData['itemList[$i][itemId]'] = itemList[i]['itemId'].toString();
        formData['itemList[$i][itemName]'] = itemList[i]['itemName'];
        formData['itemList[$i][quantity]'] = itemList[i]['quantity'].toString();
        formData['itemList[$i][rate]'] = itemList[i]['rate'].toString();
        formData['itemList[$i][selectedUnit]'] = itemList[i]['selectedUnit'];
        formData['itemList[$i][amount]'] = itemList[i]['amount'].toString();
        formData['itemList[$i][isDelete]'] = itemList[i]['isDelete'].toString();
        formData['itemList[$i][isRefund]'] = itemList[i]['isRefund'].toString(); // Include isRefund field
      }
    }

    // Add grand total and print
    formData['grand_total'] = jsonData['grand_total'].toString();
    formData['print'] = jsonData['print'].toString();

    return formData;
  }

// Update the path
  void deleteProductFromTable(int index) {
    // Remove the product at the specified index
    setState(() {
      itemForBillRows.removeAt(index);
    });
  }

  void assignQuantityFunction(String itemId, String token) async {
    // Assuming you have `itemId` and `token` available here
    // Assuming you have `itemId` and `token` available here
    List<String> fetchedItems = await getQuantityUnits(itemId, token);
    setState(() {
      _dropdownItemsQuantity = fetchedItems;
      if (_dropdownItemsQuantity.length == 1) {
        _selectedQuantitySecondaryUnit = _dropdownItemsQuantity.first;
        _primaryUnit = _selectedQuantitySecondaryUnit;
        print("jetiya eta$_primaryUnit");
      } else {
        // If the recognized unit is not among the dropdown items, select the most similar one
        String selectedUnit = "Select Unit"; // Initialize selected unit as "Select Unit"
        double maxSimilarity = 0; // Initialize maximum similarity score

        // Iterate through dropdown items and find the most similar unit
        for (String unit in _dropdownItemsQuantity) {
          double similarity = unit.toLowerCase().similarityTo(unitOfQuantity);

          print("eytu actual unit   $unit");
          print("eytu similarirty  $similarity");
          if (similarity > maxSimilarity) {
            maxSimilarity = similarity;
            selectedUnit = unit;
          }
        }

        // If "Select Unit" is not already in the dropdown, insert it at the beginning
        if (!_dropdownItemsQuantity.contains("Select Unit")) {
          _dropdownItemsQuantity.insert(0, "Select Unit");
        }

        // Set the selected unit
        _selectedQuantitySecondaryUnit = selectedUnit;

        // Print the selected unit
        print("Selected Unit: $_selectedQuantitySecondaryUnit");

        // Assuming _primaryUnit is initialized elsewhere in your code
        _primaryUnit = _dropdownItemsQuantity[1]; // Example: Set _primaryUnit to the second item in the dropdown
        print("Primary Unit: $_primaryUnit");
      }
    });
  }

  double convertQuantityBasedOnUnit(String primaryUnit, String selectedQuantitySecondaryUnit, double quantityValue) {
    if (primaryUnit == 'KG') {
      if (selectedQuantitySecondaryUnit == 'KG') {
        return quantityValue;
      } else if (selectedQuantitySecondaryUnit == 'GM') {
        return quantityValue / 1000;
      }
    } else if (primaryUnit == 'GM') {
      if (selectedQuantitySecondaryUnit == 'KG') {
        return quantityValue * 1000;
      } else if (selectedQuantitySecondaryUnit == 'GM') {
        return quantityValue;
      }
    } else if (primaryUnit == 'LTR') {
      if (selectedQuantitySecondaryUnit == 'LTR' || selectedQuantitySecondaryUnit == 'KG') {
        return quantityValue;
      } else if (selectedQuantitySecondaryUnit == 'ML' || selectedQuantitySecondaryUnit == 'GM') {
        return quantityValue / 1000;
      }
    } else if (primaryUnit == 'ML') {
      if (selectedQuantitySecondaryUnit == 'LTR' || selectedQuantitySecondaryUnit == 'KG') {
        return quantityValue * 1000;
      } else if (selectedQuantitySecondaryUnit == 'ML' || selectedQuantitySecondaryUnit == 'GM') {
        return quantityValue;
      }
    }
    return quantityValue;
  }

  void updateQuantity(int quantity) {
    if (mounted) {
      setState(() {
        quantityController.text = quantity.toString();
      });
    }
  }

  void updateSuggestionList(String recognizedWord) {
    setState(() {
      // Clear the existing suggestions
      suggestionList.clear();

      // Filter items that start with the recognized word
      suggestionList.addAll(items.where((item) => item['name']?.toLowerCase().startsWith(recognizedWord) == true).map((item) => item['name']!).toList());

      // Filter items that contain the recognized word
      suggestionList.addAll(items.where((item) => item['name']?.toLowerCase().contains(recognizedWord) == true).map((item) => item['name']!).toList());

      // Filter items that sound similar to the recognized word
      suggestionList.addAll(items.where((item) => _areWordsSimilar(item['name']?.toLowerCase() ?? '', recognizedWord) || (item['name']?.toLowerCase()?.contains(recognizedWord) == true)).map((item) => item['name']!).toList());

      // Remove duplicates and limit the list size if needed
      // suggestionList = suggestionList.toSet().take(maxSuggestions).toList();
      isSuggetion = true;
    });
  }

  bool isNumeric(String s) {
    // Null or empty string is not a number
    if (s == null || s.isEmpty) {
      return false;
    }

    // Try to parse input string to number.
    // Both integer and double work.
    // Use int.tryParse if you want to check integer only.
    // Use double.tryParse if you want to check double only.
    final number = num.tryParse(s);

    if (number == null) {
      return false;
    }

    return true;
  }

  double calculateOverallTotal() {
    double overallTotal = 0.0; // Initialize overall total

    // Iterate over each product in the products list
    for (var itemForBillRow in itemForBillRows) {
      double amount = itemForBillRow['amount']; // Get the amount for the current product
      overallTotal += amount; // Add the amount to the overall total
    }

    return overallTotal;
  }

  void updateQueryAndController(String newWord, TextEditingController controller) {
    if (mounted) {
      setState(() {
        query = newWord;
        controller.text = newWord;
      });
    }
  }

  void openDropdown(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  Future<List<String>> getQuantityUnits(String itemId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/related-units'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'item_id': itemId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> units = responseData['units'];
          return units.cast<String>().toList();
        } else {
          // Handle failed response
          print('API call failed with message: ${responseData['message']}');
          return [];
        }
      } else {
        // Handle other HTTP status codes
        print('HTTP request failed with status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Handle exceptions
      print('Error occurred: $e');
      return [];
    }
  }

  void deleteProduct(String product) {
    setState(() {
      quantities.remove(product);
    });
  }

  void _showFailedDialog() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Change to LoginScreen()
    );
  }

  Widget _buildSuggestionDropdown() {
    double dropdownHeight = suggestionList.length * 70.0; // Assuming each ListTile is 56 pixels in height

    return suggestionList.isNotEmpty
        ? Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(243, 203, 71, 1),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Container(
              margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
              constraints: BoxConstraints(maxHeight: dropdownHeight),
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 1),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(0),
              ),
              child: ListView.builder(
                itemCount: suggestionList.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestionList[index];

                  final item = items.firstWhereOrNull((item) => item['name'] == suggestion);
                  final itemIdforStock = item != null ? item['id'] : null;
                  // Declare itemId here
                  String? unit = getUnitForItem(suggestionList[index]);
                  if (unit != null) {
                    print(unit); // This will print the unit associated with the item name
                  } else {
                    print('No unit found for the specified item name');
                  }

                  print("Suggestion: $suggestion, itemId: $itemIdforStock"); // Debugging
                  return Column(
                    children: [
                      ListTile(
                        trailing: Text(
                          "$quantityNumeric$unit",
                          style: TextStyle(
                            color: Color.fromARGB(255, 61, 136, 17),
                          ),
                        ),
                        title: Text(suggestionList[index]),
                        onTap: () {
                          productNameController.text = suggestionList[index];
                          print('Selected item ID: $itemIdforStock');
                          itemId = itemIdforStock!;
                          assignQuantityFunction(itemIdforStock!, token!);
                          setState(() {
                            suggestionList.clear();
                          });
                        },
                      ),
                      if (index != suggestionList.length - 1) // Add Divider between items, except for the last one
                        Divider(
                          color: Colors.grey,
                          thickness: .2,
                        ),
                    ],
                  );
                },
              ),
            ),
          )
        : SizedBox.shrink();
  }
}

/// Display the current error status from the speech
/// recognizer
class ErrorWidget extends StatelessWidget {
  const ErrorWidget({Key? key, required this.lastError, required this.quantityWord}) : super(key: key);

  final String lastError;
  final bool quantityWord;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (lastError != null && lastError.isNotEmpty)
          Center(
            child: Text("Couldn't Recognize, Please say it Again!"),
          ),
        if (!quantityWord) // Check if flag is false
          Center(
            child: Text(" "),
          ),
      ],
    );
  }
}
