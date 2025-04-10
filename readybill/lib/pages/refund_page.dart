import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/bill_widget.dart';
import 'package:readybill/components/bottom_navigation_bar.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/quantity_modal_bottom_sheet.dart';
import 'package:readybill/components/sidebar.dart';
import 'package:readybill/components/microphone_button.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/home_bill_item_provider.dart';

//import 'package:readybill/services/local_database.dart';
import 'package:readybill/services/local_database_2.dart';
import 'package:readybill/services/refund_bill_item_provider.dart';
import 'package:readybill/services/result.dart';
import 'package:readybill/services/text_to_num.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class RefundPage extends StatefulWidget {
  const RefundPage({super.key});

  @override
  State<RefundPage> createState() => RefundPageState();
}

class RefundPageState extends State<RefundPage> {
  int quantity = 0;
  int _selectedIndex = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();
  final SpeechToText _speechToText = SpeechToText();

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
  String? apiKey;
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

  //GlobalKey<AutoCompleteTextFieldState<String>> quantityKey = GlobalKey();

  var listQuantity = 1;
  Map? currentVoice;
  List<Map>? voices;
  String? currencySymbol;

  @override
  void initState() {
    super.initState();
    initializeData();
    initTTS();
    initSpeech();
    setCurrencySymbol();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _speechToText.cancel();
    _nameController.dispose();
    quantityController.dispose();
    _nameFocusNode.dispose();
    _quantityFocusNode.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  setCurrencySymbol() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencySymbol = prefs.getString('currencySymbol');
    });
    print('currencySymbol: $currencySymbol');
  }

  void initSpeech() async {
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
          // print(voices);
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
    apiKey = await APIService.getXApiKey();
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
    words =
        words.replaceAll(RegExp(r'\b-\b', caseSensitive: false), ' ').trim();
    final regex = RegExp(
        r'^(.*?)\s+(\d+|[a-zA-Z]+)?\s?(packs?|bags?|bottles?|boxes?|bundles?|cans?|cartoons?|cartan|grams?|gm|g|kilograms?|kgs?|kilo|litres?|ltr|meters?|ms?|millilitres?|ml|numbers?|pack(?:ets?)?|pairs?|pieces?|packages?|rolls?|squarefeet|sqf|squarefeets?|squaremeters?|m)\b',
        caseSensitive: false);
    // final regex = RegExp(
    //     r'^(.*?)\s+(?:(?:\d{1,3}(?:,\d{3})*|\d+|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|million|billion)(?:\s+(?:and\s+)?(?:\d{1,3}(?:,\d{3})*|\d+|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|million|billion))*)\s+(packs?|bags?|bottles?|boxes?|bundles?|cans?|cartoons?|cartan|grams?|gm|g|kilograms?|kgs?|kilo|litres?|ltr|meters?|ms?|millilitres?|ml|numbers?|pack(?:ets?)?|pairs?|pieces?|rolls?|squarefeet|sqf|squarefeets?|squaremeters?|m)\b',
    //     caseSensitive: false);

    Match? match;
    if (words != "") {
      match = regex.firstMatch(words);
    }

    String product = match?.group(1) ?? words;
    String quantity = match?.group(2) ?? "one";

    String unitOfQuantity = match?.group(3) ?? "";
    // Provider.of(context, listen: false).assignQuantity(quantity);
    // Provider.of(context, listen: false).assignUnit(unitOfQuantity);

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
        Provider.of<RefundBillItemProvider>(context, listen: false)
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
                      quantityController.clear();
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
                    height: _localDatabase.suggestions.length * 55,
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: const Offset(0, 0),
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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
                                    quantityPopup != true
                                        ? Text("$listQuantity ")
                                        : const SizedBox.shrink(),
                                    Text(listQuantity > 50 &&
                                            suggestion.unit == 'KG'
                                        ? 'g'
                                        : suggestion.unit),
                                  ],
                                ),
                          onTap: () {
                            _stopListening();
                            if (mounted) {
                              setState(
                                () {
                                  searching = false;
                                  availableStockValue =
                                      suggestion.quantity.toString();
                                  _nameController.text = suggestion.name;
                                  quantityController.text =
                                      Provider.of<RefundBillItemProvider>(
                                              context,
                                              listen: false)
                                          .quantity
                                          .toString();
                                  Provider.of<RefundBillItemProvider>(context,
                                          listen: false)
                                      .assignQuantity(listQuantity);
                                  unit = suggestion.unit;
                                  Provider.of<RefundBillItemProvider>(context,
                                          listen: false)
                                      .assignUnit(unit);
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
                                    speak("Enter the quantity.");
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return QuantityModalBottomSheet(
                                              provider: Provider.of<
                                                      RefundBillItemProvider>(
                                                  context,
                                                  listen: false));
                                        });
                                  }

                                  itemId = itemIdforStock;
                                  // assignQuantityFunction(itemIdforStock, token!);
                                  itemSelected = true;
                                  _localDatabase.clearSuggestions();
                                  listQuantity = 1;
                                  _unitDropdownItems(unit);
                                },
                              );
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "No suggestions found",
                    style: TextStyle(
                      fontFamily: 'Roboto-Regular',
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

  Future<int?> checkStockStatus(String itemId, String quantity,
      String relatedUnit, String token, String apiKey) async {
    relatedUnit = relatedUnit.toLowerCase();
    //  print('itemId: $itemId, quantity: $quantity, relatedUnit: $relatedUnit');
    print('checkStockStatus');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock-quantity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'auth-key': apiKey,
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
          print('responseData: $responseData');
          int? stockStatus = int.tryParse(responseData['stockStatus']);
          if (stockStatus == 1) {
            salePrice = responseData['data']['sale_price'];
          }
          //   print("Stock Status: $stockStatus");
          return stockStatus;
        } else {
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
    double amount = salePrice * finalQuantity;
    print('addProductTable '); // Calculate the amount
    if (mounted) {
      setState(() {
        Provider.of<RefundBillItemProvider>(context, listen: false).addItem({
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

  void addRefundTable(
      String itemName, double finalQuantity, String unit, double salePrice) {
    double amount = salePrice * finalQuantity; // Calculate the amount
    if (mounted) {
      setState(() {
        Provider.of<RefundBillItemProvider>(context, listen: false).addItem({
          'itemId': itemId,
          'itemName': itemName,
          'quantity': finalQuantity,
          'rate': salePrice,
          'selectedUnit': unit,
          'amount': amount * (-1),
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
        in Provider.of<RefundBillItemProvider>(context, listen: false)
            .refundItemForBillRows) {
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

    const String apiUrl = '$baseUrl/billing-n-refund';
    double grandTotal = calculateOverallTotal(); // Calculate overall total
// Determine print flag

    Map<String, dynamic> requestBody = {
      'itemList': Provider.of<RefundBillItemProvider>(context, listen: false)
          .refundItemForBillRows,
      'grand_total': grandTotal,
      'print': 0,
    };
    Map<String, String> formData = convertJsonToFormData(requestBody);
    // Send POST request with bearer token
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token",
          "auth-key": "$apiKey", // Include bearer token
        },
        body: formData,
      );

      if (response.statusCode == 200) {
        EasyLoading.dismiss();
        Provider.of<RefundBillItemProvider>(context, listen: false)
            .clearItems(); // Clear the list
        clearProductName(); // Call the clearProductName function
        // Show dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return customAlertBox(
              title: "Billing is done",
              content: '',
              actions: [
                customElevatedButton('OK', green2, white, () {
                  navigatorKey.currentState?.pop();
                })
              ],
            );
          },
        );
        // Optionally, you can handle further actions after saving the data
      } else {
        //

        EasyLoading.dismiss();
        var jsonData = jsonDecode(response.body);
        Fluttertoast.showToast(msg: jsonData['data'].toString());
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
        quantityController.clear();

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
          border: Border.all(color: red),
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
                    fontFamily: 'Roboto-Regular',
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
    // _selectedQuantitySecondaryUnit =
    //     Provider.of<RefundBillItemProvider>(context, listen: false).unit;

    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    quantityController.text =
        Provider.of<RefundBillItemProvider>(context, listen: false)
            .quantity
            .toString();
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
      appBar: customAppBar(string != "" ? string : "ReadyBill", []),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    onTap: () {
                      setState(() {});
                    },
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
                    },
                    controller: _nameController,
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
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _nameController.clear();
                                quantityController.clear();
                                _localDatabase.clearSuggestions();
                                setState(() {});
                              },
                              icon: const Icon(Icons.cancel),
                            )
                          : const SizedBox.shrink(),
                      hintText: "Enter Product Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    focusNode: _nameFocusNode,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    onTap: () {
                      setState(() {});
                    },
                    controller: TextEditingController(
                      text: Provider.of<RefundBillItemProvider>(context)
                                  .quantity ==
                              0
                          ? ''
                          : Provider.of<RefundBillItemProvider>(context)
                              .quantity
                              .toString(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        Provider.of<RefundBillItemProvider>(context,
                                listen: false)
                            .assignQuantity(0);
                        return;
                      }

                      try {
                        final quantity = int.parse(value);
                        Provider.of<RefundBillItemProvider>(context,
                                listen: false)
                            .assignQuantity(quantity);
                      } catch (e) {
                        // Revert to last valid value or empty
                        final sanitizedValue =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        Provider.of<RefundBillItemProvider>(context,
                                listen: false)
                            .assignQuantity(sanitizedValue.isEmpty
                                ? 0
                                : int.parse(sanitizedValue));

                        // Update controller text
                        final newPosition = value.length;
                        TextEditingController(text: sanitizedValue).selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset: min(newPosition, sanitizedValue.length)),
                        );
                      }
                    },
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
                      hintText: "Enter Quantity",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8.0),
                              bottomRight: Radius.circular(8.0)),
                          color:
                              _quantityFocusNode.hasFocus ? green2 : darkGrey,
                        ),
                        child: DropdownButton<String>(
                          elevation: 16,
                          menuMaxHeight: screenHeight * 0.3,
                          value: Provider.of<RefundBillItemProvider>(context,
                                  listen: false)
                              .unit,
                          onChanged: (newValue) {
                            setState(() {
                              Provider.of<RefundBillItemProvider>(context,
                                      listen: false)
                                  .assignUnit(newValue!);
                              _selectedQuantitySecondaryUnit =
                                  Provider.of<RefundBillItemProvider>(context,
                                          listen: false)
                                      .unit;
                            });
                          },
                          items: _dropdownItemsQuantity
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 16),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    focusNode: _quantityFocusNode,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.05,
                        width: screenWidth * 0.3,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 1.0,
                            backgroundColor: (_nameController.text.isEmpty ||
                                    quantityController.text.isEmpty)
                                ? lightGrey
                                : red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            _stopListening();

                            if (_nameController.text.isNotEmpty &&
                                quantityController.text.isNotEmpty) {
                              String quantityValue = quantityController.text;
                              double? quantityValueforConvert =
                                  double.tryParse(quantityValue);
                              _primaryUnit = unit;
                              double quantityValueforTable =
                                  convertQuantityBasedOnUnit(
                                      _primaryUnit!,
                                      Provider.of<RefundBillItemProvider>(
                                              context,
                                              listen: false)
                                          .unit,
                                      quantityValueforConvert!);
                              //  print("quantityValueforTable:$quantityValueforTable");
                              int? stockStatus = await checkStockStatus(
                                  itemId,
                                  quantityValueforTable.toString(),
                                  Provider.of<RefundBillItemProvider>(context,
                                          listen: false)
                                      .unit,
                                  token!,
                                  "$apiKey");
                              print("stockStatus: $stockStatus");
                              if (stockStatus == 1 &&
                                  validProductName == true) {
                                //print("tryParse");

                                double? salePriceforTable =
                                    double.tryParse(salePrice);
                                addRefundTable(
                                    itemNameforTable!,
                                    quantityValueforTable,
                                    unit,
                                    salePriceforTable!);
                                _nameController.clear();
                                quantityController.clear();

                                //  _dropdownItemsQuantity.insert(0, "Unit");
                                // Reset to default value

                                if (mounted) {
                                  setState(() {
                                    _dropdownItemsQuantity = _dropdownItems;
                                    _selectedQuantitySecondaryUnit =
                                        _dropdownItemsQuantity[0];
                                    _localDatabase.clearSuggestions();
                                    Provider.of<RefundBillItemProvider>(context,
                                            listen: false)
                                        .assignQuantity(0);
                                  });
                                }
                              } else if (stockStatus == 0) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return customAlertBox(
                                      title: "Out of Stock",
                                      content:
                                          "You have only $availableStockValue left",
                                      actions: [
                                        customElevatedButton(
                                            'OK', green2, white, () {
                                          navigatorKey.currentState?.pop();
                                        })
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: Center(
                            child: Text(
                              "REFUND",
                              style: TextStyle(
                                  fontFamily: 'Roboto-Regular',
                                  fontSize: 18,
                                  color: (_nameController.text.isEmpty ||
                                          quantityController.text.isEmpty)
                                      ? darkGrey
                                      : white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: screenWidth * 0.05,
                      ),
                      SizedBox(
                        height: screenHeight * 0.05,
                        width: screenWidth * 0.3,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 1.0,
                            backgroundColor: (_nameController.text.isEmpty ||
                                    quantityController.text.isEmpty)
                                ? lightGrey
                                : blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            _stopListening();

                            if (_nameController.text.isNotEmpty &&
                                quantityController.text.isNotEmpty) {
                              String quantityValue = quantityController.text;
                              double? quantityValueforConvert =
                                  double.tryParse(quantityValue);
                              _primaryUnit = unit;
                              double quantityValueforTable =
                                  convertQuantityBasedOnUnit(
                                      _primaryUnit!,
                                      Provider.of<RefundBillItemProvider>(
                                              context,
                                              listen: false)
                                          .unit,
                                      quantityValueforConvert!);
                              //  print("quantityValueforTable:$quantityValueforTable");
                              int? stockStatus = await checkStockStatus(
                                  itemId,
                                  quantityValueforTable.toString(),
                                  Provider.of<RefundBillItemProvider>(context,
                                          listen: false)
                                      .unit,
                                  token!,
                                  "$apiKey");
                              print("stockStatus: $stockStatus");
                              if (stockStatus == 1 &&
                                  validProductName == true) {
                                //print("tryParse");

                                double? salePriceforTable =
                                    double.tryParse(salePrice);
                                addProductTable(
                                    itemNameforTable!,
                                    quantityValueforTable,
                                    unit,
                                    salePriceforTable!);
                                _nameController.clear();
                                quantityController.clear();

                                //  _dropdownItemsQuantity.insert(0, "Unit");
                                // Reset to default value

                                if (mounted) {
                                  setState(() {
                                    _dropdownItemsQuantity = _dropdownItems;
                                    _selectedQuantitySecondaryUnit =
                                        _dropdownItemsQuantity[0];
                                    _localDatabase.clearSuggestions();
                                    Provider.of<RefundBillItemProvider>(context,
                                            listen: false)
                                        .assignQuantity(0);
                                  });
                                }
                              } else if (stockStatus == 0) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return customAlertBox(
                                      title: "Out of Stock",
                                      content:
                                          "You have only $availableStockValue left",
                                      actions: [
                                        customElevatedButton(
                                            'OK', green2, white, () {
                                          navigatorKey.currentState?.pop();
                                        })
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: Center(
                            child: Text(
                              "ADD",
                              style: TextStyle(
                                  fontFamily: 'Roboto-Regular',
                                  fontSize: 18,
                                  color: (_nameController.text.isEmpty ||
                                          quantityController.text.isEmpty)
                                      ? darkGrey
                                      : white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Visibility(
                    visible: Provider.of<RefundBillItemProvider>(context)
                        .refundItemForBillRows
                        .isNotEmpty,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        const SizedBox(
                          height: 50,
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                        ),
                        Positioned(
                          right: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: black,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                                onPressed: () {
                                  saveData();
                                },
                                icon: const Icon(
                                  Icons.print,
                                  color: Colors.white,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Provider.of<RefundBillItemProvider>(context)
                          .refundItemForBillRows
                          .isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Row(children: [
                            titleWidget("Name", 18),
                            titleWidget("Quantity", 18),
                            titleWidget("Unit", 10),
                            titleWidget("Rate", 15),
                            titleWidget("Amount", 15),
                            const Expanded(
                              flex: 10,
                              child: SizedBox(),
                            )
                          ]),
                        )
                      : const SizedBox.shrink(),
                  Provider.of<RefundBillItemProvider>(context)
                          .refundItemForBillRows
                          .isNotEmpty
                      ? const Divider(
                          thickness: 1,
                        )
                      : const SizedBox.shrink(),
                  SingleChildScrollView(
                    child: Container(
                      height: screenHeight * 0.25,
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Provider.of<RefundBillItemProvider>(context)
                              .refundItemForBillRows
                              .isNotEmpty
                          ? ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount:
                                  Provider.of<RefundBillItemProvider>(context)
                                      .refundItemForBillRows
                                      .length,
                              itemBuilder: (context, index) {
                                return BillWidget(
                                  item: Provider.of<RefundBillItemProvider>(
                                          context)
                                      .refundItemForBillRows[index],
                                  context: context,
                                  index: index,
                                  itemForBillRows:
                                      Provider.of<RefundBillItemProvider>(
                                              context)
                                          .refundItemForBillRows,
                                  deleteProductFromTable:
                                      deleteProductFromTable,
                                );
                              },
                            )
                          : Center(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/light-bulb.png',
                                    width: 50,
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  SizedBox(
                                    width: screenWidth * 0.7,
                                    child: const Text(
                                      'Tap mic and start by saying "Amul butter 2 pieces" select Product and click ADD',
                                      overflow: TextOverflow.visible,
                                      style: TextStyle(
                                        fontFamily: 'Roboto-Regular',
                                        color: black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: screenHeight * 0.7,
              ),
              Positioned(
                bottom: 50,
                child: Visibility(
                  visible: Provider.of<RefundBillItemProvider>(context)
                      .refundItemForBillRows
                      .isNotEmpty,
                  child: Container(
                    color: white,
                    width: screenWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            "Grand Total: ",
                            style: TextStyle(
                              fontFamily: 'Roboto-Regular',
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "$currencySymbol${calculateOverallTotal()}",
                            style: const TextStyle(
                              fontFamily: 'Roboto-Regular',
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
                  visible: Provider.of<RefundBillItemProvider>(context)
                      .refundItemForBillRows
                      .isNotEmpty,
                  child: SizedBox(
                    width: screenWidth,
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround, // Align buttons evenly
                      children: [
                        SizedBox(
                          width: screenWidth * 0.25,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff28a745),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              // white text color
                            ),
                            onPressed: () {
                              saveData();
                            },
                            child: const Text("Save"),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.25,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return customAlertBox(
                                      title: "Cancel Bill?",
                                      content:
                                          "Are you sure you want to cancel the bill?",
                                      actions: [
                                        customElevatedButton(
                                            'NO', green2, white, () {
                                          navigatorKey.currentState?.pop();
                                        }),
                                        customElevatedButton(
                                          "YES",
                                          red,
                                          white,
                                          () {
                                            Provider.of<HomeBillItemProvider>(
                                                    context,
                                                    listen: false)
                                                .clearItems();

                                            navigatorKey.currentState?.pop();
                                          },
                                        )
                                      ],
                                    );
                                  });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: red,
                              foregroundColor: white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ), // white text color
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              isInputThroughText
                  ? Positioned(
                      top: screenHeight * 0.07, // Adjust the position as needed
                      left: 0,
                      right: 0,
                      child: Container(
                        width: screenWidth - 100,
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
                      top: screenHeight * 0.00,
                      left: 0,
                      right: 0,
                      child: Container(
                        width: screenWidth - 100,
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

  Widget titleWidget(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto-Regular',
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
