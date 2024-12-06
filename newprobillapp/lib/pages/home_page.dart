import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:newprobillapp/components/api_constants.dart';
import 'package:newprobillapp/components/bill_widget.dart';
import 'package:newprobillapp/components/bottom_navigation_bar.dart';
import 'package:newprobillapp/components/quantity_modal_bottom_sheet.dart';
import 'package:newprobillapp/components/sidebar.dart';
import 'package:newprobillapp/components/microphone_button.dart';
import 'package:newprobillapp/services/api_services.dart';
import 'package:newprobillapp/services/home_bill_item_provider.dart';
import 'package:newprobillapp/services/internet_checker.dart';
//import 'package:newprobillapp/services/local_database.dart';
import 'package:newprobillapp/services/local_database_2.dart';
import 'package:newprobillapp/services/result.dart';
import 'package:newprobillapp/services/text_to_num.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int quantity = 0;
  int _selectedIndex = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String string = '';
  double confidence = 0;
  final _localDatabase = LocalDatabase2.instance;
  bool searching = false;
  bool isInputThroughText = false;
  String itemId = '';
  String unit = '';
  String salePrice = '';
  String? itemNameforTable;
  String? token;
  bool validProductName = true;
  bool isquantityavailable = false;
  bool isSuggetion = false;
  String textToDisplay = '';
  String? availableStockValue = '';

  String unitOfQuantity = '';
  double quantityNumeric = 0;

  String spokenUnit = '';
  double itemColumnHeight = 0;

  bool wasListening = false;

  final FocusNode _searchFocus = FocusNode();
  bool? quantityPopup;
  bool shouldOpenDropdown = false;
  //QuickSellSuggestionModel? newItems;

  //New Variable
  bool itemSelected = false;

  String lastWords = '';
  String lastError = '';
  String lastStatus = '';

  FlutterTts flutterTts = FlutterTts();

  //New Variable

  bool productNotFound = false;

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
  final ScrollController _scrollController =
      ScrollController(); // Scroll controller to detect scrolling
  bool isLoadingMore = false; // Flag to show loading indicator
  int currentPage = 0; // Current page for loading items

  String quantitySelectedValue = '';
  //GlobalKey<AutoCompleteTextFieldState<String>> quantityKey = GlobalKey();
  String _errorMessage = '';
  var listQuantity = 1;
  Map? currentVoice;
  List<Map>? voices;

  @override
  void initState() {
    super.initState();
    initializeData();
    initTTS();
    initSpeech();
  }

  @override
  void dispose() {
    // _stopListening();
    _speechToText.stop();

    _speechToText.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    _nameFocusNode.dispose();
    _quantityFocusNode.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void initSpeech() async {
    _speechEnabled =
        await _speechToText.initialize(onStatus: (status) => setState(() {}));
    setState(() {});
  }

  void initTTS() {
    flutterTts.getVoices.then((value) {
      try {
        voices = List<Map>.from(value);

        // print(voices);

        setState(() {
          voices = voices!
              .where((element) => element['locale'].contains('en'))
              .toList();
          print(voices);
          currentVoice = voices![0];
          setVoice(currentVoice!);
        });
      } catch (e) {
        print(e);
      }
    });
  }

  void setVoice(Map voice) {
    Platform.isAndroid
        ? flutterTts.setVoice({"name": "en-in-x-cxx-local"})
        : flutterTts.setVoice({"name": "com.apple.ttsbundle.Rishi-compact"});
    // flutterTts.speak("This is my voice!");
  }

  void initializeData() async {
    token = await APIService.getToken();
  }

  void _startListening() async {
    string = '';
    print("Start Listening");

    await _speechToText.listen(
      localeId: 'en-IN',
      onResult: resultListener,
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        enableHapticFeedback: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );

    setState(() {
      HapticFeedback.vibrate();
    });

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_speechToText.isNotListening) {
        setState(() {
          timer.cancel();
          HapticFeedback.vibrate();
        });
      }
      if (timer.tick == 12) {
        timer.cancel();
      }
    });
  }

  void _stopListening() async {
    print("Stop Listening");
    await _speechToText.stop();
    setState(() {
      HapticFeedback.vibrate();
    });
  }

  void _onSpeechResult(result) {
    print("On Speech Result");
    setState(() {
      string = result.recognizedWords;
      // confidence = result.confidence;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        lastWords = '${result.recognizedWords} - ${result.finalResult}';

        final recognizedWord = result.recognizedWords.toLowerCase();
        shouldOpenDropdown = true;

        validProductName = true;
        _parseSpeech(recognizedWord, result.finalResult);
        //extractNameQuantityUnit(recognizedWord);
      });
    }
  }

  speak(String errorAnnounce) async {
    await flutterTts.speak(errorAnnounce);
  }

  _parseSpeech(String words, bool finalResult) {
    string = words;
    print("words: $words");
    print("finalResult: $finalResult");

    // Separate letters and numbers in combined words (e.g., abc123 -> abc 123)
    words = words.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    });

    // Remove specific keywords and trim whitespace
    words = words
        .replaceAll(RegExp(r'\bquantity\b', caseSensitive: false), '')
        .trim();
    final regex = RegExp(
        r'^(.*?)\s+(\d+|[a-zA-Z]+)?\s?(packs?|bags?|bottles?|boxes?|bundles?|cans?|cartoons?|cartan|grams?|gm|g|kilograms?|kgs?|kilo|litres?|ltr|meters?|ms?|millilitres?|ml|numbers?|pack(?:ets?)?|pairs?|pieces?|rolls?|squarefeet|sqf|squarefeets?|squaremeters?|m)\b',
        caseSensitive: false);

    Match? match;
    if (words != "") {
      match = regex.firstMatch(words);
    }

    String product = match?.group(1) ?? words;
    String quantity = match?.group(2) ?? "one";
    String unitOfQuantity = match?.group(3) ?? "";

    print("product: $product");
    print("quantity: $quantity");
    print("unit: $unitOfQuantity");
    product = product.replaceAll(RegExp(r'\b\d+\b'), '').trim();

    match?.group(2) == null ? quantityPopup = true : quantityPopup = false;
    _localDatabase.searchDatabase(product);

    text2num(quantity);
    extractAndCombineNumbers(text2num(quantity).toString());
    isInputThroughText = false;

    spokenUnit = unitOfQuantity;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {});
      print("suggestions is empty: ${_localDatabase.suggestions.isEmpty}");
      if (_localDatabase.suggestions.isEmpty && finalResult == true) {
        print('Product Not Available');
        speak('Product Not Available. Please try again.');
      }
    });
  }

  void deleteProductFromTable(int index) {
    // Remove the product at the specified index
    if (mounted) {
      setState(() {
        Provider.of<HomeBillItemProvider>(context, listen: false)
            .removeItem(index);
      });
    }
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
        if (mounted) setState(() {});
        return int.parse(part1) + int.parse(part2);
      } else {
        //  quantityController.text = numbers[0].toString();
        quantity = numbers[0];
        quantityNumeric = double.parse(numbers[0].toString());
        if (mounted) setState(() {});
        return numbers[0];
      }
    } else if (numbers.length > 1) {
      // Sentence like "Amul Butter Quantity 3000 38 pieces"
      int sumNumber = numbers.reduce((value, element) => value + element);
      quantity = sumNumber;
      //  quantityController.text = sumNumber.toString();
      quantityNumeric = double.parse(sumNumber.toString());
      if (mounted) setState(() {});
      return numbers.reduce((value, element) => value + element);
    } else {
      return 0; // No numbers found
    }
  }

  Widget suggestionDropdown() {
    int dataLength = _localDatabase.suggestions.length;
    //print('dataLength: $dataLength');
    return dataLength > 0
        ? Stack(
            children: [
              InkWell(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _localDatabase.clearSuggestions();
                      _quantityController.clear();
                      _nameController.clear();
                      isInputThroughText ? _nameFocusNode.nextFocus() : null;
                      _stopListening();
                      // print('dropdown: $_dropdownItemsQuantity');
                    });
                  }
                },
                child: SizedBox(
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
                      padding: EdgeInsets.zero,
                      itemCount: dataLength,
                      itemBuilder: (context, index) {
                        if (index >= dataLength) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final suggestion = _localDatabase.suggestions[index];
                        final itemIdforStock = (suggestion.itemId).toString();

                        if (quantity > 1) {
                          listQuantity = quantity;
                        }
                        return ListTile(
                          title: Text(suggestion.name),
                          trailing: isInputThroughText
                              ? Text(
                                  "${suggestion.quantity} ${suggestion.unit}")
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("$listQuantity "),
                                    Text(listQuantity > 50 &&
                                            suggestion.unit == 'KG'
                                        ? 'g'
                                        : suggestion.unit),
                                  ],
                                ),
                          onTap: () {
                            _stopListening();
                            if (mounted) {
                              setState(() {
                                searching = false;
                                availableStockValue =
                                    suggestion.quantity.toString();
                                _nameController.text = suggestion.name;
                                _quantityController.text =
                                    listQuantity.toString();
                                unit = suggestion.unit;
                                listQuantity > 50
                                    ? {
                                        (unit == 'KG' || unit == 'GM')
                                            ? _selectedQuantitySecondaryUnit =
                                                'GM'
                                            : (unit == 'LTR' || unit == 'ML')
                                                ? _selectedQuantitySecondaryUnit =
                                                    'ML'
                                                : _selectedQuantitySecondaryUnit =
                                                    unit
                                      }
                                    : _selectedQuantitySecondaryUnit = unit;
                                if (quantityPopup == true) {
                                  showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return QuantityModalBottomSheet(
                                            unit: unit);
                                      });
                                }

                                itemId = itemIdforStock;
                                // assignQuantityFunction(itemIdforStock, token!);
                                itemSelected = true;
                                _localDatabase.clearSuggestions();
                                listQuantity = 1;
                                _unitDropdownItems(unit);
                              });
                            }
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
                _nameController.text.isNotEmpty &&
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

  void _unitDropdownItems(String unit) {
    if (unit.toLowerCase() == 'kg') {
      _dropdownItemsQuantity = ["KG", "GM"];
    } else if (unit.toLowerCase() == 'ltr') {
      _dropdownItemsQuantity = ["LTR", "ML"];
    } else {
      _dropdownItemsQuantity = [unit];
    }
    //_dropdownItemsQuantity = _dropdownItems;
  }

  Future<int?> checkStockStatus(
      String itemId, String quantity, String relatedUnit, String token) async {
    relatedUnit = relatedUnit.toLowerCase();
    //  print('itemId: $itemId, quantity: $quantity, relatedUnit: $relatedUnit');

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('stockStatus')) {
          itemNameforTable = responseData['data']?['item_name'] as String?;

          int? stockStatus = int.tryParse(responseData['stockStatus']);
          if (stockStatus == 1) {
            salePrice = responseData['data']['sale_price'];
          }
          //   print("Stock Status: $stockStatus");
          return stockStatus;
        } else {
          // If stockStatus is not present in the response, return -1 to indicate an error
          return -1;
        }
      } else {
        return -1;
      }
    } catch (e) {
      // Handle exceptions
      Result.error("Book list not available");
      return -1;
    }
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

  void addProductTable(
      String itemName, double finalQuantity, String unit, double salePrice) {
    double amount = salePrice * finalQuantity; // Calculate the amount
    if (mounted) {
      setState(() {
        Provider.of<HomeBillItemProvider>(context, listen: false).addItem({
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
    }
    // Add the product to the list
  }

  double calculateOverallTotal() {
    double overallTotal = 0.0; // Initialize overall total

    // Iterate over each product in the products list
    for (var itemForBillRow
        in Provider.of<HomeBillItemProvider>(context, listen: false)
            .homeItemForBillRows) {
      double amount =
          itemForBillRow['amount']; // Get the amount for the current product
      overallTotal += amount; // Add the amount to the overall total
    }

    return double.parse(overallTotal.toStringAsFixed(2));
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

  Future<void> saveData() async {
    EasyLoading.show(status: 'loading...');

    const String apiUrl = '$baseUrl/billing';
    double grandTotal = calculateOverallTotal(); // Calculate overall total
// Determine print flag

    Map<String, dynamic> requestBody = {
      'itemList': Provider.of<HomeBillItemProvider>(context, listen: false)
          .homeItemForBillRows,
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
        Provider.of<HomeBillItemProvider>(context, listen: false)
            .clearItems(); // Clear the list
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
        //  print(response.body);
        EasyLoading.dismiss();

        // Handle other HTTP status codes
        // debugPrint(
        // 'Response body: ${response.body}'); // Print the whole response body
      }
    } catch (e) {
      EasyLoading.dismiss();
      Result.error("Book list not available");
      // Handle exceptions
    }
  }

  void clearProductName() {
    if (mounted) {
      setState(() {
        _nameController.clear();
        _quantityController.clear();
        _errorMessage = "";
        validProductName =
            true; // Clear error message when clearing the text field
      });
    }
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
                  //   print(lastError);
                  lastError = '';
                  // print("l:$lastError");
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
    } else {
      return const SizedBox.shrink();
    }
  }

  //////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    // _selectedQuantitySecondaryUnit = _dropdownItemsQuantity[0];
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return Scaffold(
      drawer: const Drawer(
        child: Sidebar(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isKeyboardVisible
          ? null
          : InkWell(
              onTap: () {
                _localDatabase.suggestions.clear();
                _speechToText.isListening
                    ? _stopListening()
                    : _startListening();
              },
              child: MicrophoneButton(isListening: _speechToText.isListening),
            ),
      bottomNavigationBar: CustomNavigationBar(
        onItemSelected: (index) {
          if (mounted) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        selectedIndex: _selectedIndex,
      ),
      appBar: AppBar(
        title: Text(
          string != "" ? string : "Probill",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: GestureDetector(
          onTap: () {
            _nameFocusNode.unfocus();
            _quantityFocusNode.unfocus();
            _stopListening();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(children: [
              Column(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.center,
                    child: Internetchecker(),
                  ),
                  _errorWidgetView(lastError, isquantityavailable),
                  // Text(textToDondsplay),
                  TextField(
                    onChanged: (m) {
                      _localDatabase.searchDatabase(_nameController.text);
                      searching = true;

                      isInputThroughText = true;

                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() {});
                      });

                      if (_nameController.text == '') {
                        validProductName = true;
                        _localDatabase.clearSuggestions();
                        if (mounted) setState(() {});
                      }

                      // updateSuggestionList(m);
                      // _localDatabase.searchDatabase(m);
                    },
                    controller: _nameController,
                    decoration: InputDecoration(
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _nameController.clear();
                                _quantityController.clear();
                                _localDatabase.clearSuggestions();
                                setState(() {});
                              },
                              icon: const Icon(Icons.cancel),
                            )
                          : const SizedBox.shrink(),
                      labelText: "Enter Product Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    focusNode: _nameFocusNode,
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: "Enter Quantity",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: DropdownButton<String>(
                        elevation: 16,
                        menuMaxHeight: MediaQuery.of(context).size.height * 0.3,
                        value: _selectedQuantitySecondaryUnit,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedQuantitySecondaryUnit = newValue;
                            quantitySelectedValue = newValue ??
                                ''; // Update quantitySelectedValue with the selected value
                          });
                        },
                        items: _dropdownItemsQuantity
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    focusNode: _quantityFocusNode,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: (_nameController.text.isEmpty ||
                              _quantityController.text.isEmpty)
                          ? const Color.fromRGBO(210, 211, 211, 1)
                          : Colors.green,
                    ),
                    padding: const EdgeInsets.all(5.0),
                    child: MaterialButton(
                      onPressed: () async {
                        _stopListening();
                        // print("Add button pressed");
                        // print(
                        //     "_nameController.text: ${_nameController.text}, _quantityController.text: ${_quantityController.text}");
                        if (_nameController.text.isNotEmpty &&
                            _quantityController.text.isNotEmpty) {
                          String quantityValue = _quantityController.text;
                          double? quantityValueforConvert =
                              double.tryParse(quantityValue);
                          _primaryUnit = unit;
                          double quantityValueforTable =
                              convertQuantityBasedOnUnit(
                                  _primaryUnit!,
                                  _selectedQuantitySecondaryUnit!,
                                  quantityValueforConvert!);
                          //  print("quantityValueforTable:$quantityValueforTable");
                          int? stockStatus = await checkStockStatus(
                              itemId,
                              quantityValueforTable.toString(),
                              _selectedQuantitySecondaryUnit!,
                              token!);
                          if (stockStatus == 1 && validProductName == true) {
                            //print("tryParse");

                            double? salePriceforTable =
                                double.tryParse(salePrice);
                            addProductTable(
                                itemNameforTable!,
                                quantityValueforTable,
                                unit,
                                salePriceforTable!);
                            _nameController.clear();
                            _quantityController.clear();

                            //  _dropdownItemsQuantity.insert(0, "Unit");
                            _selectedQuantitySecondaryUnit =
                                _dropdownItemsQuantity[
                                    0]; // Reset to default value
                            quantitySelectedValue = '';

                            if (mounted) {
                              setState(() {
                                _dropdownItemsQuantity = _dropdownItems;
                                _selectedQuantitySecondaryUnit =
                                    _dropdownItemsQuantity[0];
                                _localDatabase.clearSuggestions();
                              });
                            }
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Center(
                        child: Text(
                          "ADD",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),
                  // TextButton(
                  //   onPressed: _localDatabase.printData,
                  //   child: const Text("Print Data"),
                  // ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),

                  const SizedBox(height: 8),
                  Provider.of<HomeBillItemProvider>(context)
                          .homeItemForBillRows
                          .isNotEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Row(children: [
                            Expanded(
                              flex: 20,
                              child: Text(
                                "Name",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            Expanded(
                              flex: 16,
                              child: Text(
                                "Quantity",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text(
                                "Unit",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text(
                                "Rate",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text(
                                "Amount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: SizedBox(),
                            )
                          ]),
                        )
                      : const SizedBox.shrink(),
                  Provider.of<HomeBillItemProvider>(context)
                          .homeItemForBillRows
                          .isNotEmpty
                      ? const Divider(
                          thickness: 1,
                        )
                      : const SizedBox.shrink(),
                  SingleChildScrollView(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.29,
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Provider.of<HomeBillItemProvider>(context)
                              .homeItemForBillRows
                              .isNotEmpty
                          ? ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount:
                                  Provider.of<HomeBillItemProvider>(context)
                                      .homeItemForBillRows
                                      .length,
                              itemBuilder: (context, index) {
                                return BillWidget(
                                  item:
                                      Provider.of<HomeBillItemProvider>(context)
                                          .homeItemForBillRows[index],
                                  context: context,
                                  index: index,
                                  itemForBillRows:
                                      Provider.of<HomeBillItemProvider>(context)
                                          .homeItemForBillRows,
                                  deleteProductFromTable:
                                      deleteProductFromTable,
                                );
                              },
                            )
                          : const Center(
                              child: Text(
                                'No bill items available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
              ),
              Positioned(
                bottom: 50,
                child: Visibility(
                  visible: Provider.of<HomeBillItemProvider>(context)
                      .homeItemForBillRows
                      .isNotEmpty,
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
                            "₹${calculateOverallTotal()}",
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
                  visible: Provider.of<HomeBillItemProvider>(context)
                      .homeItemForBillRows
                      .isNotEmpty,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround, // Align buttons evenly
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Action for print button
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white, // white text color
                          ),
                          child: const Text("Print"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white, // white text color
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

                          color: Colors.grey.shade100, // Background color
                        ),
                        child: SingleChildScrollView(
                          child: suggestionDropdown(),
                        ),
                      ),
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

                          color: Colors.grey.shade100, // Background color
                        ),
                        child: SingleChildScrollView(
                          child: suggestionDropdown(),
                        ),
                      ),
                    ),
            ]),
          ),
        ),
      ),
    );
  }
}
