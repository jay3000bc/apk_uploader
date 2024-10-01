import 'dart:async';
import 'dart:convert';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text_search/Service/internet_checker.dart';
import 'package:speech_to_text_search/Service/local_database.dart';
import 'package:speech_to_text_search/api_calling/quick_sell_api.dart';
import 'package:speech_to_text_search/models/local_database_model.dart';
import 'package:speech_to_text_search/pages/drawer.dart';
import 'package:speech_to_text_search/pages/login_page.dart';
import 'package:speech_to_text_search/service/is_login.dart';

import 'package:speech_to_text_search/models/quick_sell_suggestion_model.dart';
import 'package:speech_to_text_search/product_mic_state.dart';
import 'package:speech_to_text_search/components/navigation_bar.dart';
import 'package:speech_to_text_search/quantity_mic_state.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../service/api_constants.dart';
import '../service/result.dart';
import 'package:speech_to_text_search/service/text_to_num.dart';

class Refund extends StatefulWidget {
  const Refund({super.key});

  @override
  State<Refund> createState() => _RefundState();
}

class _RefundState extends State<Refund> with TickerProviderStateMixin {
  TextEditingController productNameController = TextEditingController();
  late final AnimationController _animationController;
  TextEditingController quantityController = TextEditingController();
  int quantity = 0;
  FocusNode productNameFocusNode = FocusNode();
  FocusNode quantityFocusNode = FocusNode();
  String errorMessage = "";
  bool isListeningMic = false;
  bool validProductName = true;
  int _selectedIndex = 1;
  bool isquantityavailable = false;
  bool isSuggetion = false;
  String? token;
  String? availableStockValue = '';
  String? itemNameforTable = '';
  String unitOfQuantity = '';
  double quantityNumeric = 0;
  bool isInputThroughText = false;

  double itemColumnHeight = 0;

  final _localDatabase = LocalDatabase.instance;

  final FocusNode _searchFocus = FocusNode();

  bool shouldOpenDropdown = false;
  QuickSellSuggestionModel? newItems;

  //New Variable
  bool itemSelected = false;
  bool _hasSpeech = false;
  final bool _logEvents = false;
  double level = 0.0;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  final SpeechToText speech = SpeechToText();
  FlutterTts flutterTts = FlutterTts();

  String unit = '';

  //New Variable

  String itemId = '';
  String salePrice = '';
  bool productNotFound = false;
  bool searching = false;

  List<Map<String, dynamic>> itemForBillRows = [];

  String? _selectedQuantitySecondaryUnit;
  // Define _selectedQuantitySecondaryUnit as a String variable
  String? _primaryUnit;
  final List<String> _dropdownItems = [
    'Unit',
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
  List<String> _dropdownItemsQuantity = [
    'Unit',
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

  final int itemsPerPage = 15; // Number of items to load at a time
  ScrollController _scrollController =
      ScrollController(); // Scroll controller to detect scrolling
  bool isLoadingMore = false; // Flag to show loading indicator
  int currentPage = 0; // Current page for loading items

  String quantitySelectedValue = '';
  GlobalKey<AutoCompleteTextFieldState<String>> quantityKey = GlobalKey();
  String _errorMessage = '';

  @override
  void initState() {
    initSpeechState();
    super.initState();
    _scrollController.addListener(_scrollListener);
    _animationController = AnimationController(vsync: this);
    _selectedQuantitySecondaryUnit = _dropdownItemsQuantity.first;
    // Fixed method name
    _checkAndRequestPermission(); // Fixed method name
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  speak(String errorAnnounce) async {
    await flutterTts.speak(errorAnnounce);
  }

  @override
  void dispose() {
    speech.cancel(); // Cancel speech recognition
    _scrollController.dispose();
    productNameFocusNode.dispose();
    quantityFocusNode.dispose();
    _animationController.dispose();
    quantityController.dispose();
    productNameController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !isLoadingMore) {
      // User has reached the bottom and not already loading more data
      loadMoreData();
    }
  }

  // Function to load more data
  Future<void> loadMoreData() async {
    setState(() {
      isLoadingMore = true; // Show loading indicator
    });

    await Future.delayed(Duration(seconds: 2)); // Simulate network request

    // Load next batch of items (15 more)
    int dataLength = _localDatabase.suggestions.length;
    int totalPages = (dataLength / itemsPerPage).ceil(); // Total pages

    if (currentPage < totalPages - 1) {
      currentPage++;
      // Load more data by slicing the suggestions
      List<LocalDatabaseModel> newSuggestions = _localDatabase.suggestions
          .skip(currentPage * itemsPerPage)
          .take(itemsPerPage)
          .toList();
      setState(() {
        _localDatabase.suggestions
            .addAll(newSuggestions); // Append new data to the list
        isLoadingMore = false; // Hide loading indicator
      });
    } else {
      setState(() {
        isLoadingMore = false; // No more data to load
      });
    }
  }

  // void isSearchingChecker() {
  //   if (isInputThroughText) {
  //     productNotFound = _localDatabase.suggestions.isEmpty &&
  //         searching == true &&
  //         speech.isNotListening &&
  //         productNameController.text.isNotEmpty;
  //   } else {
  //     productNotFound = _localDatabase.suggestions.isEmpty &&
  //         searching == true &&
  //         speech.isNotListening;
  //   }
  //   // print('productNotFound: $productNotFound');
  // }

  // _showNoMatchingItems() {
  //   if (isInputThroughText) {
  //     Future.delayed(Duration(seconds: 1), () {
  //       setState(() {
  //         isSearchingChecker();
  //       });
  //     });
  //   } else
  //     isSearchingChecker();

  //   return Align(
  //     alignment: Alignment.center,
  //     child: productNotFound
  //         ? Container(
  //             width: MediaQuery.of(context).size.width,
  //             height: MediaQuery.of(context).size.height * 0.1,
  //             decoration: BoxDecoration(
  //               border: Border.all(color: Colors.red),
  //               color: const Color.fromARGB(255, 211, 130, 124),
  //             ),
  //             padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
  //             child: Column(
  //               children: [
  //                 const Text(
  //                   "No matching items found. Please try again",
  //                   style: TextStyle(
  //                     fontSize: 12.0,
  //                     color: Colors.black,
  //                   ),
  //                 ),
  // TextButton(
  //   onPressed: () {
  //     setState(() {
  //       searching = false;
  //       productNameController.clear();
  //     });
  //   },
  //   child: Container(
  //     padding: const EdgeInsets.symmetric(
  //         horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(10),
  //         color: Colors.black),
  //     child: const Text(
  //       "OK",
  //       style: TextStyle(
  //         fontSize: 12,
  //         color: Colors.white,
  //       ),
  //     ),
  //   ),
  // ),
  //               ],
  //             ),
  //           )
  //         : const SizedBox.shrink(),
  //   );
  // }

  Future<void> _initializeData() async {
    token = await APIService.getToken();
    // APIService.getUserDetails(token, _showFailedDialog);
  }

  void _checkAndRequestPermission() async {
    var status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      await Permission.microphone.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return Consumer2<MicState, QuantityMicState>(
      builder: (context, micState, quantityMicState, _) {
        return PopScope(
          canPop: false, // Prevents automatic pop
          onPopInvokedWithResult: (didPop, result) async {
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
              },
            );

            if (value == true) {
              Navigator.of(context).maybePop(result);
            }
            return;
          },

          child: Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: const Text("Probill"),
              toolbarHeight: 40,
              backgroundColor: const Color(0xFFF2CC44),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: isKeyboardVisible
                ? null
                : FloatingActionButton(
                    child: microphoneButton(),
                    onPressed: () {
                      // print('Floating action button pressed');
                      setState(() {
                        searching = true;
                      });
                    },
                    shape: const CircleBorder(),
                  ),
            drawer: const Sidebar(),
            bottomNavigationBar: CustomNavigationBar(
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedIndex: _selectedIndex,
            ),
            body: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).padding.top + 160),
                child: Stack(
                  children: [
                    Column(
                      children: <Widget>[
                        const Align(
                          alignment: Alignment.center,
                          child: Internetchecker(),
                        ),
                        _errorWidgetView(lastError, isquantityavailable),
                        // _showNoMatchingItems(),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: productNameController,
                                    focusNode: _searchFocus,
                                    onChanged: (m) {
                                      setState(() {
                                        searching = true;
                                      });
                                      _localDatabase.searchDatabase(
                                          productNameController.text);
                                      isInputThroughText = true;

                                      if (productNameController.text == '') {
                                        validProductName = true;
                                        _localDatabase.clearSuggestions();
                                        setState(() {});
                                      }
                                      updateSuggestionList(m);
                                      // _localDatabase.searchDatabase(m);
                                    },
                                    decoration: InputDecoration(
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
                                          fontSize: 16.0,
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
                                                _dropdownItemsQuantity =
                                                    _dropdownItems;

                                                print(_dropdownItemsQuantity);
                                                setState(() {
                                                  _selectedQuantitySecondaryUnit =
                                                      _dropdownItemsQuantity[
                                                          0]; // Reset to default value // Reset to default value
                                                  // //newItems?.data?.clear();
                                                  clearProductName();
                                                  stopListening();
                                                  _localDatabase
                                                      .clearSuggestions();
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50, // Adjust the height as needed
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
                                        suggestions: const [], // Adjust as needed

                                        clearOnSubmit: false,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0)),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.cyan),
                                          ),
                                          hintText: "  Type a Quantity...",
                                          hintStyle: TextStyle(
                                              fontSize: 16.0,
                                              color:
                                                  Color.fromRGBO(0, 0, 0, 1)),
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

                                    Positioned(
                                      top: 3,
                                      right: 5,
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
                                            child: Text(
                                              value,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Adjust the spacing between the container and the text

                        // Display the total price for the selected product
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceEvenly, // Align buttons at the ends
                          children: [
                            Container(
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: (productNameController.text.isEmpty ||
                                        quantityController.text.isEmpty)
                                    ? const Color.fromRGBO(210, 211, 211, 1)
                                    : Colors.blue,
                              ),
                              padding: const EdgeInsets.all(5.0),
                              child: MaterialButton(
                                onPressed: () async {
                                  if (productNameController.text.isNotEmpty &&
                                      quantityController.text.isNotEmpty) {
                                    // Both productNameController and quantityController are not empty, proceed void handleStockStatus(String itemId, String quantity, String relatedUnit, String token) async {
                                    String quantityValue =
                                        quantityController.text;
                                    int? stockStatus = await checkStockStatus(
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
                                      productNameController.clear();
                                      quantityController.clear();
                                      _dropdownItemsQuantity.insert(0, "Unit");
                                      _selectedQuantitySecondaryUnit =
                                          _dropdownItemsQuantity[
                                              0]; // Reset to default value
                                      quantitySelectedValue = '';
                                      setState(() {});
                                    } else if (stockStatus == 0) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Out of Stock"),
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
                                        fontSize: 18,
                                        color: (productNameController
                                                    .text.isEmpty ||
                                                quantityController.text.isEmpty)
                                            ? const Color.fromARGB(255, 0, 0, 0)
                                            : const Color.fromARGB(
                                                255, 255, 255, 255),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors
                                    .red, // Example color for refund button
                              ),
                              padding: const EdgeInsets.all(5.0),
                              child: MaterialButton(
                                onPressed: () async {
                                  if (productNameController.text.isNotEmpty &&
                                      quantityController.text.isNotEmpty) {
                                    // Both productNameController and quantityController are not empty, proceed void handleStockStatus(String itemId, String quantity, String relatedUnit, String token) async {
                                    String quantityValue =
                                        quantityController.text;
                                    int? stockStatus = await checkStockStatus(
                                        itemId,
                                        quantityValue,
                                        _selectedQuantitySecondaryUnit!,
                                        token!);
                                    if ((stockStatus == 0 ||
                                            stockStatus == 1 ||
                                            stockStatus == 2) &&
                                        validProductName == true) {
                                      double? quantityValueforConvert =
                                          double.tryParse(quantityValue);
                                      double quantityValueforTable =
                                          convertQuantityBasedOnUnit(
                                              _primaryUnit!,
                                              _selectedQuantitySecondaryUnit!,
                                              quantityValueforConvert!);

                                      double? salePriceforTable =
                                          double.tryParse(salePrice);
                                      addProductRefundTable(
                                          itemNameforTable!,
                                          quantityValueforTable,
                                          _selectedQuantitySecondaryUnit!,
                                          salePriceforTable!);
                                      productNameController.clear();
                                      quantityController.clear();
                                      _dropdownItemsQuantity.insert(0, "Unit");
                                      _selectedQuantitySecondaryUnit =
                                          _dropdownItemsQuantity[
                                              0]; // Reset to default value
                                      quantitySelectedValue = '';
                                      setState(() {});
                                    } else if (stockStatus == 0) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Out of Stock"),
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
                                child: const Center(
                                  child: Text(
                                    "REFUND",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
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

                        // Text(lastWords),

                        Visibility(
                          visible: !itemForBillRows.isNotEmpty &&
                              speech.isNotListening &&
                              productNameController.text.isEmpty,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Tap Mic and start by saying",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22.0,
                                    color: Color(
                                        0xFFD79922), // Set color to #D79922
                                  ),
                                ),
                                Text(
                                  "\"Amul Butter quantity 2 packs\"",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22.0,
                                    color: Color(
                                        0xFFD79922), // Set color to #D79922
                                  ),
                                ),
                                Text(
                                  "select product and Add",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22.0,
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
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              itemColumnHeight = constraints.maxHeight;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      titleWidget(context, "Item", 0.2),
                                      titleWidget(context, "Qty", 0.2),
                                      titleWidget(context, "Rate", 0.2),
                                      titleWidget(context, "Amount", 0.2),
                                      titleWidget(context, '', 0.1),
                                    ],
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.29,
                                      padding:
                                          const EdgeInsets.only(left: 20.0),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: itemForBillRows.length,
                                        itemBuilder: (context, index) {
                                          return searchPageItemWidget(
                                              itemForBillRows[index],
                                              context,
                                              index);
                                        },
                                      )),
                                ],
                              );
                            })),
                        Visibility(
                          visible: itemForBillRows.isNotEmpty,
                          child: const Divider(
                            // Thin break line
                            thickness: 0.2,
                            color: Colors.black,
                          ),
                        ),

                        //row for print and save button
                      ],
                    ),
                    Positioned(
                      bottom: 50,
                      child: Visibility(
                        visible: itemForBillRows.isNotEmpty,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                  "${calculateOverallTotal() < 0 ? '-' : ''}₹${calculateOverallTotal().abs()}",
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Visibility(
                        visible: itemForBillRows.isNotEmpty,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceAround, // Align buttons evenly
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Action for print button
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor:
                                      Colors.white, // white text color
                                ),
                                child: const Text("Print"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
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
                      ),
                    ),
                    Positioned(
                      bottom: 230,
                      left: 1,
                      right: 1,
                      child: !_hasSpeech || speech.isListening
                          ? listeningAnimation()
                          : const SizedBox(),
                    ),
                    isInputThroughText
                        ? Positioned(
                            top: MediaQuery.of(context).size.height *
                                0.085, // Adjust the position as needed
                            left: 0,
                            right: 0,
                            child: Container(
                                width: MediaQuery.of(context).size.width - 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(0),

                                  color:
                                      Colors.grey.shade100, // Background color
                                ),
                                child: SingleChildScrollView(
                                    child:
                                        localDatabaseBuildSuggestionDropdown())),
                          )
                        : Positioned(
                            top: MediaQuery.of(context).size.height *
                                0.015, // Adjust the position as needed
                            left: 0,
                            right: 0,
                            child: Container(
                                width: MediaQuery.of(context).size.width - 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(0),

                                  color:
                                      Colors.grey.shade100, // Background color
                                ),
                                child: SingleChildScrollView(
                                    child:
                                        localDatabaseBuildSuggestionDropdown())),
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> saveData() async {
    EasyLoading.show(status: 'loading...');

    const String apiUrl = '$baseUrl/billing-n-refund';
    double grandTotal = calculateOverallTotal(); // Calculate overall total

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
        EasyLoading.dismiss();
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
        EasyLoading.dismiss();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Billing failed"),
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
        //     debugPrint(response.body);
        // Handle error cases
      }
    } catch (e) {
      EasyLoading.dismiss();
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
    // print("addProductTable");
    // print(
    // "itemName: $itemName, finalQuantity: $finalQuantity, unit: $unit, salePrice: $salePrice");
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

  void addProductRefundTable(
      String itemName, double finalQuantity, String unit, double salePrice) {
    // print("addProductTable");
    // print(
    // "itemName: $itemName, finalQuantity: $finalQuantity, unit: $unit, salePrice: $salePrice");
    double amount = salePrice * finalQuantity; // Calculate the amount
    setState(() {
      itemForBillRows.add({
        'itemId': itemId,
        'itemName': itemName,
        'quantity': finalQuantity,
        'rate': salePrice,
        'selectedUnit': unit,
        'amount': -amount,
        'isDelete': 0,
        'isRefund': 0,
      });
    });
    // Add the product to the list
  }

  Future<int?> checkStockStatus(
      String itemId, String quantity, String relatedUnit, String token) async {
    // print('checkStockStatus');
    // print("itemId: $itemId, quantity: $quantity, relatedUnit: $relatedUnit");
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock-quantity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'item_id': itemId,
          'quantity': quantity,
          'relatedUnit': relatedUnit,
        }),
      );
      // print('before response');
      // print(response.body);
      // print('after response');
      // print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('stockStatus')) {
          // Assign quantity from response to availableStockValue if available
          // availableStockValue = responseData['data']?['quantity'] as String?;
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
        // debugPrint(
        // 'Response body: ${response.body}'); // Print the whole response body
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
    print('start listening');
    lastWords = '';
    lastError = '';
    speech.listen(
      onResult: resultListener,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

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
      if (shouldOpenDropdown) {
        Future.delayed(const Duration(milliseconds: 100));
        openDropdown(productNameFocusNode);
      }
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
      //  debugPrint('$eventTime $eventDescription');
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
          width: 80,
          height: 80,
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
              size: 25,
            ),
          )),
    );
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    setState(() {});
  }

  Widget _parseSpeech(String words, bool finalResult) {
    print(words);
    // print('parsespeech called');
    RegExp regex = RegExp(
        r'(\w+(?:\s+\w+)*)\s+quantity\s+((?:\d+\s*|(?:\w+\s*)+))\s+(packs|bags|bag|bottle|bottles|box|boxes|bundle|bundles|can|cans|cartoon|cartoons|cartan|gram|grams|gm|kilogram|kg|kilograms|litre|litres|ltr|meter|m|meters|ms|millilitre|ml|millilitres|number|numerbs|pack|packs|packet|packets|pair|pairs|piece|pieces|roll|rolls|squarefeet|sqf|squarefeets|sqfts|squaremeters|squaremeter)');

    Match? match = regex.firstMatch(words);

    if (match != null) {
      String product = match.group(1) ?? "";
      String quantity = match.group(2) ?? "";
      String unitOfQuantity = match.group(3) ?? "";

      // productNameController.text = product;
      //  print('2');
      _localDatabase.searchDatabase(product);

      text2num(quantity);
      extractAndCombineNumbers(text2num(quantity).toString());
      isInputThroughText = false;
      QuickSellApiCalling.fetchDataAndAssign(product, (result) {
        newItems = (result as SuccessState).value;
        if (newItems!.data!.isEmpty) {
          validProductName = false;
        } else {
          validProductName = true;
        }
      });
      Future.delayed(Duration(seconds: 1), () {
        setState(() {});
      });

      if (product.isEmpty) {
        setState(() {
          _errorMessage = 'Product is missing';
          speak(_errorMessage);
        });
        return _productErrorWidget(_errorMessage);
      }
      if (quantity.isEmpty) {
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
      Future.delayed(const Duration(seconds: 1), () {
        if (_localDatabase.suggestions.isEmpty) {
          print('Product Not Available');
          speak('Product Not Available');
        }
      });

      setState(
        () {
          _errorMessage = ''; // Clear error message on successful parsing
        },
      );
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
      _primaryUnit = unit;
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
    //  print("convertQuantityBasedOnUnit");
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
      if (recognizedWord == "") {
        newItems = null;
      } else {
        // _localDatabase.searchDatabase(recognizedWord);
        newItems = (result as SuccessState).value;
        if (newItems!.data!.isEmpty) {
          validProductName = false;
        } else {
          validProductName = true;
        }
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
          builder: (context) => const LoginPage()), // Change to LoginScreen()
    );
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
          numberStr[numberStr.length - 1] != '0' &&
          numberStr.length > 4) {
        int splitIndex = numberStr.lastIndexOf('0') + 1;
        String part1 = numberStr.substring(0, splitIndex);
        String part2 = numberStr.substring(splitIndex);
        int totalSum = int.parse(part1) + int.parse(part2);
        quantity = totalSum;
        //quantityController.text = totalSum.toString();
        quantityNumeric = double.parse(totalSum.toString());
        setState(() {});
        return int.parse(part1) + int.parse(part2);
      } else {
        //  quantityController.text = numbers[0].toString();
        quantity = numbers[0];
        quantityNumeric = double.parse(numbers[0].toString());
        setState(() {});
        return numbers[0];
      }
    } else if (numbers.length > 1) {
      // Sentence like "Amul Butter Quantity 3000 38 pieces"
      int sumNumber = numbers.reduce((value, element) => value + element);
      quantity = sumNumber;
      //  quantityController.text = sumNumber.toString();
      quantityNumeric = double.parse(sumNumber.toString());
      setState(() {});
      return numbers.reduce((value, element) => value + element);
    } else {
      return 0; // No numbers found
    }
  }

  itemDetailWidget(BuildContext context, String itemDetail, double d) {
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * d,
          minWidth: MediaQuery.of(context).size.width * 0.1),
      child: Text(
        itemDetail,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  titleWidget(BuildContext context, String title, double d) {
    return Container(
      alignment: Alignment.center,
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * d),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget searchPageItemWidget(
      Map<String, dynamic> item, BuildContext context, int index) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            itemDetailWidget(
                context, '${itemForBillRows[index]['itemName']}', 0.2),
            itemDetailWidget(
                context,
                '${itemForBillRows[index]['quantity']} \n${itemForBillRows[index]['selectedUnit']}',
                0.2),
            Container(
              width: 60,
              height: 50,
              alignment: Alignment.center,
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.2),
              child: TextField(
                style: const TextStyle(
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: itemForBillRows[index]['rate'].toString(),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 216, 216, 216),
                  // Adding asterisk (*) to the label text
                  labelStyle: const TextStyle(
                      color: Colors.black), // Setting label text color to black

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
                  itemForBillRows[index]['amount'] = itemForBillRows[index]
                          ['rate'] *
                      itemForBillRows[index]['quantity'];
                  // Trigger UI update
                  setState(() {});
                },
              ),
            ),
            if (item['amount'] < 0)
              itemDetailWidget(context, '-₹${-item['amount']}', 0.2)
            else
              itemDetailWidget(context, '₹${item['amount']}', 0.2),
            Container(
              alignment: Alignment.center,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.1,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Color.fromARGB(255, 161, 11, 0),
                ),
                onPressed: () {
                  // Delete the product at the current index when IconButton is pressed
                  deleteProductFromTable(index);
                },
              ),
            ),
          ],
        ),
        const Divider(
          color: Colors.grey,
          thickness: 1,
        )
      ],
    );
  }

  Widget localDatabaseBuildSuggestionDropdown() {
    int dataLength = _localDatabase.suggestions.length;

    return dataLength > 0
        ? Stack(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _localDatabase.clearSuggestions();
                    quantityController.clear();
                    productNameController.clear();

                    // print('dropdown: $_dropdownItemsQuantity');
                  });
                },
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 0),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: dataLength + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == dataLength) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final suggestion = _localDatabase.suggestions[index];
                        final itemIdforStock = (suggestion.itemId).toString();

                        return ListTile(
                          title: Text(suggestion.name),
                          trailing: isInputThroughText
                              ? Text(
                                  "${suggestion.quantity} ${suggestion.unit}")
                              : Text("$quantity ${suggestion.unit}"),
                          onTap: () {
                            stopListening();
                            setState(() {
                              searching = false;
                              availableStockValue =
                                  suggestion.quantity.toString();
                              productNameController.text = suggestion.name;
                              quantityController.text = quantity.toString();
                              unit = suggestion.unit;
                              _selectedQuantitySecondaryUnit = unit;

                              itemId = itemIdforStock;
                              assignQuantityFunction(itemIdforStock, token!);
                              itemSelected = true;
                              _localDatabase.clearSuggestions();

                              _dropdownItemsQuantity = _dropdownItems;
                            });

                            print('dropdownItems: $_dropdownItems');
                            print('dropdown: $_dropdownItemsQuantity');
                          },
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(
                        thickness: 0.2,
                        height: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : (isInputThroughText == true &&
                productNameController.text.isNotEmpty &&
                searching == true)
            ? Container(
                height: 50,
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    "No suggestions found",
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();
  }

  Widget _errorWidgetView(String lasttError, bool quantityWord) {
    if (lastError.isNotEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: const Color.fromARGB(255, 211, 130, 124),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Couldn't Recognise. Please Try Again."),
            TextButton(
              onPressed: () {
                setState(() {
                  print(lastError);
                  lastError = '';
                  print("l:$lastError");
                  //  quantityWord = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else
      return SizedBox.shrink();
  }
}

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
        if (lastError.isNotEmpty)
          const Center(
            child: AlertDialog(
              title: Text("Couldn't recognise."),
              content: Text('Please say it again.'),
            ),
          ),
        if (!quantityWord) // Check if flag is false
          const Center(
            child: Text(" "),
          ),
      ],
    );
  }
}
