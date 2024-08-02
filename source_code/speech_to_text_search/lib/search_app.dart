// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text_search/api_calling/quick_sell_api.dart';
import 'package:speech_to_text_search/drawer.dart';
import 'package:speech_to_text_search/Service/is_login.dart';
import 'package:speech_to_text_search/login_profile.dart';
import 'package:speech_to_text_search/models/quick_sell_suggestion_model.dart';
import 'package:speech_to_text_search/product_mic_state.dart';
import 'package:speech_to_text_search/navigation_bar.dart';
import 'package:speech_to_text_search/quantity_mic_state.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'Service/api_constants.dart';
import 'Service/result.dart';

class SearchApp extends StatefulWidget {
  const SearchApp({super.key});

  @override
  State<SearchApp> createState() => _SearchAppState();
}

class _SearchAppState extends State<SearchApp> with TickerProviderStateMixin {
  TextEditingController productNameController = TextEditingController();
  late final AnimationController _animationController;
  TextEditingController quantityController = TextEditingController();
  FocusNode productNameFocusNode = FocusNode();
  FocusNode quantityFocusNode = FocusNode();
  String errorMessage = "";
  bool isListeningMic = false;
  bool validProductName = true;
  int _selectedIndex = 0;
  bool isquantityavailable = false;
  bool isSuggetion = false;
  String? token;
  String? availableStockValue = '';
  String? itemNameforTable = '';
  String unitOfQuantity = '';
  double quantityNumeric = 0;
  bool isInputThroughText = false;

  final FocusNode _searchFocus = FocusNode();

  bool shouldOpenDropdown = false;
  QuickSellSuggestionModel? newItems;

  //New Variable
  bool _hasSpeech = false;
  final bool _logEvents = false;
  double level = 0.0;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  final SpeechToText speech = SpeechToText();
  FlutterTts flutterTts = FlutterTts();

  //New Variable

  String itemId = '';
  String salePrice = '';

  List<Map<String, dynamic>> itemForBillRows = [];

  String? _selectedQuantitySecondaryUnit;
  // Define _selectedQuantitySecondaryUnit as a String variable
  String? _primaryUnit;

  List<String> _dropdownItemsQuantity = [
    'Unit',
  ];

  String quantitySelectedValue = '';
  GlobalKey<AutoCompleteTextFieldState<String>> quantityKey = GlobalKey();
  String _errorMessage = '';

  @override
  void initState() {
    initSpeechState();
    super.initState();
    _animationController = AnimationController(vsync: this);
    _selectedQuantitySecondaryUnit = _dropdownItemsQuantity.first;
    // Fixed method name
    _checkAndRequestPermission(); // Fixed method name
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  speak(String errorAnnounce) async {
    var result = await flutterTts.speak(errorAnnounce);
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
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
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
              return Future.value();
            } else {
              return Future.value();
            }
          },
          child: GestureDetector(
            onTap: () {
              // Hide the suggestion dropdown when tapping outside
              _searchFocus.unfocus();
              setState(() {
                newItems?.data?.clear();
              });
            },
            child: Scaffold(
                drawer: const Sidebar(),
                bottomNavigationBar: CustomNavigationBar(
                  onItemSelected: (index) {
                    // Handle navigation item selection
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  selectedIndex: _selectedIndex,
                ),
                body: SingleChildScrollView(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                    child: Stack(
                      children: [
                        Column(
                          children: <Widget>[
                            const SizedBox(
                              height: 30,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                    height:
                                        20), // Adjust the spacing between the container and the text
                                Visibility(
                                  visible: isListeningMic,
                                  child: const Text(
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
                                ? const Padding(
                                    padding: EdgeInsets.all(0.0),
                                    child: Text(""),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                      Text(
                                        "Product Not Found",
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.red),
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
                                    onChanged: (m){
                                      isInputThroughText = true;
                                      updateSuggestionList(m);
                                    },
                                    decoration: InputDecoration(
                                      // border: OutlineInputBorder(
                                      //   borderRadius: BorderRadius.circular(50.0),
                                      // ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Color.fromARGB(255, 0, 0, 0)),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.cyan),
                                      ),
                                      hintText: "  Type a Product...",
                                      hintStyle: const TextStyle(
                                          fontSize: 20.0,
                                          color: Color.fromRGBO(0, 0, 0, 1)),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Visibility(
                                            visible: productNameController
                                                .text.isNotEmpty,
                                            child: IconButton(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      40, 0, 0, 0),
                                              icon: const Icon(
                                                Icons.clear,
                                                color:
                                                    Color.fromRGBO(0, 0, 0, 1),
                                              ),
                                              onPressed: () {
                                                // _searchFocus.unfocus();
                                                setState(() {
                                                  newItems?.data?.clear();
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
                                        suggestions: const [
                                          "1",
                                          "2",
                                          "3",
                                          "4",
                                          "5"
                                        ], // Adjust as needed
                                        clearOnSubmit: false,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          enabledBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0)),
                                          ),
                                          focusedBorder:
                                              const UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.cyan),
                                          ),
                                          hintText: "  Type a Quantity...",
                                          hintStyle: const TextStyle(
                                              fontSize: 20.0,
                                              color:
                                                  Color.fromRGBO(0, 0, 0, 1)),
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Visibility(
                                                visible: quantityController
                                                    .text.isNotEmpty,
                                                child: IconButton(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          40, 0, 0, 0),
                                                  icon: const Icon(Icons.clear,
                                                      color: Color.fromARGB(
                                                          255, 0, 0, 0)),
                                                  onPressed: () {
                                                    setState(() {
                                                      // Clear product name and stop listening
                                                      clearProductName();

                                                      stopListening();
                                                      // Set quantityController.text to null or an empty string
                                                      quantityController.text =
                                                          ""; // or null
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
                                        itemBuilder: (BuildContext context,
                                            String itemData) {
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
                                            _selectedQuantitySecondaryUnit =
                                                newValue;
                                            quantitySelectedValue = newValue ??
                                                ''; // Update quantitySelectedValue with the selected value
                                          });
                                        },
                                        items: _dropdownItemsQuantity
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
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
                            const SizedBox(
                              height: 8,
                            ),
                            // Display the total price for the selected product

                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceEvenly, // Align buttons at the ends
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: (productNameController
                                                .text.isEmpty ||
                                            quantityController.text.isEmpty)
                                        ? const Color.fromRGBO(210, 211, 211, 1)
                                        : const Color(0xFF0B5ED7),
                                  ),
                                  padding: const EdgeInsets.all(5.0),
                                  child: MaterialButton(
                                    onPressed: () async {
                                      if (productNameController
                                              .text.isNotEmpty &&
                                          quantityController.text.isNotEmpty) {
                                        // Both productNameController and quantityController are not empty, proceed void handleStockStatus(String itemId, String quantity, String relatedUnit, String token) async {
                                        String quantityValue =
                                            quantityController.text;
                                        int? stockStatus =
                                            await checkStockStatus(
                                                itemId,
                                                quantityValue,
                                                _selectedQuantitySecondaryUnit!,
                                                token!);
                                        if (stockStatus == 1) {
                                          double? quantityValueforConvert =
                                              double.tryParse(quantityValue);
                                          double quantityValueforTable =
                                              convertQuantityBasedOnUnit(
                                                  _primaryUnit!,
                                                  _selectedQuantitySecondaryUnit!,
                                                  quantityValueforConvert!);
                                          double? salePriceforTable =
                                              double.tryParse(salePrice);
                                          addProductTable(
                                              itemNameforTable!,
                                              quantityValueforTable,
                                              _selectedQuantitySecondaryUnit!,
                                              salePriceforTable!);
                                        } else if (stockStatus == 0) {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title:
                                                    const Text("Out of Stock"),
                                                content: Text(
                                                    "You have only $availableStockValue left"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          context); // Close the dialog
                                                    },
                                                    child: const Text("OK"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      }
                                    },
                                    height: 10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "ADD",
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: (productNameController
                                                        .text.isEmpty ||
                                                    quantityController
                                                        .text.isEmpty)
                                                ? const Color.fromARGB(
                                                    255, 0, 0, 0)
                                                : const Color.fromARGB(
                                                    255, 255, 255, 255),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            // if (_errorMessage.isNotEmpty)
                            //   _productErrorWidget(_errorMessage),
                            Visibility(
                              visible: !itemForBillRows.isNotEmpty,
                              child: const SizedBox(
                                height: 100,
                              ),
                            ),
                            Text(lastWords),
                            Visibility(
                              visible: !itemForBillRows.isNotEmpty,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Tap Mic and start by saying",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 25.0,
                                        color: Color(
                                            0xFFD79922), // Set color to #D79922
                                      ),
                                    ),
                                    Text(
                                      "\"Amul Butter quantity 2packs\"",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 25.0,
                                        color: Color(
                                            0xFFD79922), // Set color to #D79922
                                      ),
                                    ),
                                    Text(
                                      "select product and Add",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 25.0,
                                        color: Color(
                                            0xFFD79922), // Set color to #D79922
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
                                child: DataTable(
                                  columnSpacing: 30.0,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        "Item",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      numeric: false,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Qty",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      numeric: false,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Rate",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      numeric: false,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Amount",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      numeric: false,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      numeric: false,
                                    ),
                                  ],
                                  rows: List<DataRow>.generate(
                                    itemForBillRows.length,
                                    (index) => DataRow(cells: [
                                      DataCell(
                                        SizedBox(
                                            width: 50,
                                            child: Text(itemForBillRows[index]
                                                ['itemName'])),
                                      ),
                                      DataCell(
                                        SizedBox(
                                            width: 40,
                                            child: Text(
                                                '${itemForBillRows[index]['quantity']} ${itemForBillRows[index]['selectedUnit']}')),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 70,
                                          height: 40,
                                          child: TextField(
                                            decoration: InputDecoration(
                                              hintText: itemForBillRows[index]
                                                      ['rate']
                                                  .toString(),
                                              filled: true,
                                              fillColor: const Color.fromARGB(
                                                  255, 216, 216, 216),
                                              // Adding asterisk (*) to the label text
                                              labelStyle: const TextStyle(
                                                  color: Colors
                                                      .black), // Setting label text color to black

                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (newRate) {
                                              // Update the rate value in your data model
                                              itemForBillRows[index]['rate'] =
                                                  double.parse(newRate);
                                              // Recalculate the amount
                                              itemForBillRows[index]['amount'] =
                                                  itemForBillRows[index]
                                                          ['rate'] *
                                                      itemForBillRows[index]
                                                          ['quantity'];
                                              // Trigger UI update
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                            width: 50,
                                            child: Text(itemForBillRows[index]
                                                    ['amount']
                                                .toString())),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color:
                                                Color.fromARGB(255, 161, 11, 0),
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
                            Visibility(
                              visible: itemForBillRows.isNotEmpty,
                              child: Divider(
                                // Thin break line
                                thickness: 5.0,
                                color: Colors.grey[300],
                              ),
                            ),
                            Visibility(
                              visible: itemForBillRows.isNotEmpty,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      "Grand Total: ",
                                      style: TextStyle(
                                        fontSize: 18.0,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      "₹${calculateOverallTotal()}",
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Visibility(
                              visible: itemForBillRows.isNotEmpty,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .start, // Align buttons evenly
                                children: [
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Action for print button
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B5ED7),
                                      foregroundColor:
                                          Colors.white, // white text color
                                    ),
                                    child: const Text("Print"),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF198754),
                                      foregroundColor:
                                          Colors.white, // white text color
                                    ),
                                    onPressed: () {
                                      saveData();
                                    },
                                    child: const Text("Save"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 190,
                          left: 1,
                          right: 1,
                          child: ErrorWidgetView(
                            lastError: lastError,
                            quantityWord: isquantityavailable,
                          ),
                        ),
                        Positioned(
                            left: 10,
                            right: 10,
                            bottom: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  !_hasSpeech || speech.isListening
                                      ? ""
                                      : "Tap to speak",
                                  style: const TextStyle(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            )),
                        Positioned(
                            bottom: 230,
                            left: 1,
                            right: 1,
                            child: !_hasSpeech || speech.isListening
                                ? listeningAnimation()
                                : const SizedBox()),
                        Positioned.fill(
                          bottom: 100,
                          child: Align(
                              alignment: Alignment.bottomCenter,
                              child: microphoneButton()),
                        ),
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
                )),
          ),
        );
      },
    );
  }

  Future<void> saveData() async {
    const String apiUrl = '$baseUrl/billing-n-refund';
    double grandTotal = calculateOverallTotal(); // Calculate overall total
// Determine print flag

    Map<String, dynamic> requestBody = {
      'itemList': itemForBillRows,
      'grand_total': grandTotal,
      'print': 0,
    };
    Map<String, String> formData = convertJsonToFormData(requestBody);
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
        itemForBillRows.clear(); // Clear the list
        clearProductName(); // Call the clearProductName function
        // Show dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Billing is done"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        // Optionally, you can handle further actions after saving the data
      } else {
        debugPrint(response.body);
        // Handle error cases
      }
    } catch (e) {
      Result.error("Book list not available");
      // Handle exceptions
    }
  }

  void clearProductName() {
    setState(() {
      productNameController.clear();
      quantityController.clear();
      errorMessage = "";
      validProductName =
          true; // Clear error message when clearing the text field
    });
  }

  void addProductTable(
      String itemName, double finalQuantity, String unit, double salePrice) {
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

  Future<int?> checkStockStatus(
      String itemId, String quantity, String relatedUnit, String token) async {
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
        debugPrint(
            'Response body: ${response.body}'); // Print the whole response body
        return -1;
      }
    } catch (e) {
      // Handle exceptions
      Result.error("Book list not available");
      return -1;
    }
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

  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    lastError = '';
    speech.listen(
      onResult: resultListener,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 9),
    );
    setState(() {});

    if (shouldOpenDropdown) {
      Future.delayed(const Duration(milliseconds: 100));
      openDropdown(productNameFocusNode);
    }
  }

  void resultListener(SpeechRecognitionResult result) {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      lastWords = '${result.recognizedWords} - ${result.finalResult}';

      final recognizedWord = result.recognizedWords.toLowerCase();
      shouldOpenDropdown = true;
      validProductName = true;
      _parseSpeech(recognizedWord, result.finalResult);
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
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
    return const Column(
      children: [
        Text(
          "I'm Listening...",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0)),
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
            boxShadow: [
              BoxShadow(
                  blurRadius: .26,
                  spreadRadius: level * 1.5,
                  color: Colors.white.withOpacity(.05))
            ],
            color: Colors.green,
            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
          child: InkWell(
            onTap: !_hasSpeech || speech.isListening
                ? stopListening
                : startListening,
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

//New Code
  Widget _parseSpeech(String words, bool finalResult) {
    // RegExp regex = RegExp(r'(\w+(?:\s+\w+)*)\s+quantity\s+(\d+)\s*(\w+)?');
    RegExp regex = RegExp(
        r'(\w+(?:\s+\w+)*)\s+quantity\s+((?:\d+\s*|(?:\w+\s*)+))\s+(packs|bags|bag|bottle|bottles|box|boxes|bundle|bundles|can|cans|cartoon|cartoons|cartan|gram|grams|gm|kilogram|kg|kilograms|litre|litres|ltr|meter|m|meters|ms|millilitre|ml|millilitres|number|numerbs|pack|packs|packet|packets|pair|pairs|piece|pieces|roll|rolls|squarefeet|sqf|squarefeets|sqfts|squaremeters|squaremeter)');
    // RegExp regex = RegExp(r'(.+?)\b quantity ((\d+(\.\d+)?)|\b\w+\b) (\b\w+\s*)+');
    Match? match = regex.firstMatch(words);

    if (match != null) {
      String product = match.group(1) ?? "";
      String quantity = match.group(2) ?? "";
      String unitOfQuantity = match.group(3) ?? "";

      productNameController.text = product;
      text2num(quantity);
      extractAndCombineNumbers(text2num(quantity).toString());
      isInputThroughText = false;
      QuickSellApiCalling.fetchDataAndAssign(product, (result) {
        newItems = (result as SuccessState).value;
        setState(() {});
      });

      if (product.isEmpty) {
        setState(() {
          _errorMessage = 'Product is missing';
          speak(_errorMessage);
        });
        return _productErrorWidget(_errorMessage);
      }
      if (quantity == null || quantity.isEmpty) {
        setState(() {
          _errorMessage = 'Quantity is missing';
          speak(_errorMessage);
        });
        return _productErrorWidget(_errorMessage);
      }
      if (unitOfQuantity.isEmpty) {
        setState(() {
          _errorMessage = 'Unit is missing';
          speak(_errorMessage);
        });
        return _productErrorWidget(_errorMessage);
      }
      setState(() {
        _errorMessage = ''; // Clear error message on successful parsing
      });
    } else {
      if (finalResult == true) {
        if (words.contains('quantity')) {
          if (words.startsWith('quantity')) {
            setState(() {
              _errorMessage = 'Product is missing';
              speak(_errorMessage);
            });
            return _productErrorWidget(_errorMessage);
          } else if (words.endsWith('quantity')) {
            setState(() {
              _errorMessage = 'Quantity and unit are missing';
              speak(_errorMessage);
            });
            return _productErrorWidget(_errorMessage);
          } else {
            setState(() {
              _errorMessage = 'unit is missing';
              speak(_errorMessage);
            });
            return _productErrorWidget(_errorMessage);
          }
        } else {
          setState(() {
            _errorMessage = 'Quantity word is missing';
            speak(_errorMessage);
          });
          return _productErrorWidget(_errorMessage);
        }
      }
    }
    setState(() {});
    return _productErrorWidget('');
  }

  Widget _productErrorWidget(error) {
    return Align(
        alignment: Alignment.center,
        child: Text(
          'Error: $error',
          style:
              const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
        formData['itemList[$i][isRefund]'] =
            itemList[i]['isRefund'].toString(); // Include isRefund field
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
    List<String> fetchedItems =
        await QuickSellApiCalling.getQuantityUnits(itemId, token);
    _dropdownItemsQuantity = fetchedItems;
    if (_dropdownItemsQuantity.length == 1) {
      _selectedQuantitySecondaryUnit = _dropdownItemsQuantity.first;
      _primaryUnit = _selectedQuantitySecondaryUnit;
    } else {
      // If the recognized unit is not among the dropdown items, select the most similar one
      String selectedUnit =
          "Select Unit"; // Initialize selected unit as "Select Unit"
      double maxSimilarity = 0; // Initialize maximum similarity score

      // Iterate through dropdown items and find the most similar unit
      for (String unit in _dropdownItemsQuantity) {
        double similarity = unit.toLowerCase().similarityTo(unitOfQuantity);
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
      // Assuming _primaryUnit is initialized elsewhere in your code
      _primaryUnit = _dropdownItemsQuantity[1];
      // Example: Set _primaryUnit to the second item in the dropdown
    }
    setState(() {});
  }

  double convertQuantityBasedOnUnit(String primaryUnit,
      String selectedQuantitySecondaryUnit, double quantityValue) {
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
      if (selectedQuantitySecondaryUnit == 'LTR' ||
          selectedQuantitySecondaryUnit == 'KG') {
        return quantityValue;
      } else if (selectedQuantitySecondaryUnit == 'ML' ||
          selectedQuantitySecondaryUnit == 'GM') {
        return quantityValue / 1000;
      }
    } else if (primaryUnit == 'ML') {
      if (selectedQuantitySecondaryUnit == 'LTR' ||
          selectedQuantitySecondaryUnit == 'KG') {
        return quantityValue * 1000;
      } else if (selectedQuantitySecondaryUnit == 'ML' ||
          selectedQuantitySecondaryUnit == 'GM') {
        return quantityValue;
      }
    }
    return quantityValue;
  }

  Future<void> updateSuggestionList(String recognizedWord) async {
    await QuickSellApiCalling.fetchDataAndAssign(productNameController.text,
        (result) {
      if(recognizedWord == ""){
        newItems = null;
      }else{
        newItems = (result as SuccessState).value;
      }
    });
    setState(() {
      isSuggetion = true;
    });
  }

  double calculateOverallTotal() {
    double overallTotal = 0.0; // Initialize overall total

    // Iterate over each product in the products list
    for (var itemForBillRow in itemForBillRows) {
      double amount =
          itemForBillRow['amount']; // Get the amount for the current product
      overallTotal += amount; // Add the amount to the overall total
    }

    return overallTotal;
  }

  void openDropdown(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  void _showFailedDialog() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const LoginScreen()), // Change to LoginScreen()
    );
  }

  Widget _buildSuggestionDropdown() {
    double dropdownHeight = (newItems?.data?.length ?? 0) *
        70.0; // Assuming each ListTile is 56 pixels in height
    return (newItems?.data?.length ?? 0) > 0
        ? Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 1),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              constraints: BoxConstraints(maxHeight: dropdownHeight),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 1),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(0),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: newItems?.data?.length,
                itemBuilder: (context, index) {
                  final itemIdforStock = newItems?.data?[index].id.toString();
                  // Declare itemId here
                  String? unit = newItems?.data?[index].shortUnit;
                  return Column(
                    children: [
                      ListTile(
                        trailing: Text(
                          isInputThroughText == true? ("${newItems?.data?[index].quantity ?? ''} ${newItems?.data?[index].shortUnit ?? ''}")  :"$quantityNumeric$unit",
                          style: const TextStyle(
                            color: Color.fromARGB(255, 61, 136, 17),
                          ),
                        ),
                        title: Text(newItems?.data?[index].itemName ?? ''),
                        onTap: () {
                          productNameController.text =
                              newItems?.data?[index].itemName ?? '';
                          itemId = itemIdforStock!;
                          assignQuantityFunction(itemIdforStock, token!);
                          newItems?.data?.clear();
                          setState(() {});
                        },
                      ),
                      if (index !=
                          newItems!.data!.length -
                              1) // Add Divider between items, except for the last one
                        const Divider(
                          color: Colors.grey,
                          thickness: .2,
                        ),
                    ],
                  );
                },
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  int text2num(String s) {
    var small = {
      'zero': 0,
      'one': 1,
      'ek': 1,
      'won': 1,
      'on': 1,
      'en': 1,
      'two': 2,
      'to': 2,
      'do': 2,
      'too': 2,
      'three': 3,
      'tree': 3,
      'tre': 3,
      'tray': 3,
      'trae': 3,
      'four': 4,
      'for': 4,
      'fore': 4,
      'fire': 4,
      'five': 5,
      'hive': 5,
      'six': 6,
      'sex': 6,
      'seks': 6,
      'seven': 7,
      'eight': 8,
      'ate': 8,
      'nine': 9,
      'line': 9,
      'nein': 9,
      'neon': 9,
      'ten': 10,
      'tin': 10,
      'eleven': 11,
      'elleve': 11,
      'eleve': 11,
      'twelve': 12,
      'tolv': 12,
      'toll': 12,
      'tall': 12,
      'doll': 12,
      'thirteen': 13,
      'tretten': 13,
      'fourteen': 14,
      'forteen': 14,
      'foreteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'sexteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'lineteen': 19,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90
    };

    var large = {
      'thousand': 1000,
    };
    var a = s.toLowerCase().split(RegExp(r'[\s-]+'));
    var n = 0;
    var g = 0;
    var lastSmall = 0; // To track the last small number found
    for (var w in a) {
      var x = small[w];
      if (x != null) {
        g += x;
        lastSmall = x;
      } else if (int.tryParse(w) != null) {
        if (g != 0) {
          n += g;
          g = 0;
        }
        n += int.tryParse(w)!;
        lastSmall = int.tryParse(w)!;
      } else if (w == 'hundred') {
        g *= 100;
      } else if (large.containsKey(w)) {
        n += g * large[w]!;
        g = 0;
      } else {
        debugPrint('Word found: $w');
      }
    }
    // Check if there's any remaining small number to add
    if (g != 0) {
      n += g;
    }
    setState(() {});
    return n;
  }

  int extractAndCombineNumbers(String input) {
    List<int> numbers = [];
    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(input);
    for (Match match in matches) {
      numbers.add(int.parse(match.group(0)!));
    }
    // Combine numbers meaningfully
    if (numbers.length == 1) {
      String numberStr = numbers[0].toString();
      // Check if the number contains a zero and split it accordingly
      if (numberStr.contains('0') &&
          numberStr[numberStr.length - 1] != '0' && numberStr.length > 4 ) {
        int splitIndex = numberStr.lastIndexOf('0') + 1;
        String part1 = numberStr.substring(0, splitIndex);
        String part2 = numberStr.substring(splitIndex);
        int totalSum = int.parse(part1) + int.parse(part2);
        quantityController.text = totalSum.toString();
        quantityNumeric = double.parse(totalSum.toString());
        setState(() {});
        return int.parse(part1) + int.parse(part2);
      } else {
        quantityController.text = numbers[0].toString();
        quantityNumeric = double.parse(numbers[0].toString());
        setState(() {});
        return numbers[0];
      }
    } else if (numbers.length > 1) {
      // Sentence like "Amul Butter Quantity 3000 38 pieces"
      int sumNumber = numbers.reduce((value, element) => value + element);
      quantityController.text = sumNumber.toString();
      quantityNumeric = double.parse(sumNumber.toString());
      setState(() {});
      return numbers.reduce((value, element) => value + element);
    } else {
      return 0; // No numbers found
    }
  }
}

/// Display the current error status from the speech
/// recognizer
class ErrorWidgetView extends StatelessWidget {
  const ErrorWidgetView(
      {Key? key, required this.lastError, required this.quantityWord})
      : super(key: key);

  final String lastError;
  final bool quantityWord;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (lastError != null && lastError.isNotEmpty)
          const Center(
            child: Text("Couldn't Recognize, Please say it Again!"),
          ),
        if (!quantityWord) // Check if flag is false
          const Center(
            child: Text(" "),
          ),
      ],
    );
  }
}
