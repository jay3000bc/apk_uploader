import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/components/text_dialog_widget.dart';
import 'package:readybill/models/item_model.dart';
import 'package:readybill/services/api_services.dart';
import 'package:readybill/services/global_internet_connection_handler.dart';
import 'package:readybill/services/local_database_2.dart';
import 'package:readybill/services/utils.dart';
import 'package:http/http.dart' as http;

class NewDataset extends StatefulWidget {
  final String title;
  final String? uploadExcel;

  const NewDataset({super.key, required this.title, this.uploadExcel});

  @override
  State<NewDataset> createState() => _NewDatasetState();
}

class _NewDatasetState extends State<NewDataset> {
  final Set<ItemModel> _selectedItems = {};
  bool isSortAscending = true;
  final int _rowsPerPage = 100;
  List<String> errorMessages = [];
  List<String> errorCoordinates = [];

  final List<String> _dropdownItemsQuantity = [
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

  int recordsTotal = 0;
  int count = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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

  int start = 0;

  List<ItemModel> _filteredItems = [];
  String _searchTerm = '';
  List<ItemModel> items = [];
  var apiKey;
  var token;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    getItems(reset: '0', start: '0', length: _rowsPerPage.toString());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    itemNameValueController.dispose();
    mrpValueController.dispose();
    salePriceValueController.dispose();
    stockQuantityValueController.dispose();
    codeHSNSACvalueController.dispose();
    rateOneValueController.dispose();
    rateTwoValueController.dispose();
    minumumStockController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterItems(_searchController.text);
    });
  }

  getNextPage() {
    start += _rowsPerPage;
    if (start > recordsTotal) {
      start -= _rowsPerPage;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'You have reached the end of the list',
          textAlign: TextAlign.center,
        ),
        duration: Durations.extralong4,
      ));
    } else {
      getItems(
          reset: '0', start: start.toString(), length: _rowsPerPage.toString());
    }
  }

  getPreviousPage() {
    start -= _rowsPerPage;
    if (start < 0) {
      start += _rowsPerPage;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'You have reached the beginning of the list',
          textAlign: TextAlign.center,
        ),
        duration: Durations.extralong4,
      ));
    } else {
      getItems(
          reset: '0', start: start.toString(), length: _rowsPerPage.toString());
    }
  }

  Future<void> getItems(
      {required String reset,
      required String start,
      required String length}) async {
    if (widget.uploadExcel == null) {
      token = await APIService.getToken();
      apiKey = await APIService.getXApiKey();
      EasyLoading.show(status: 'loading...');
      var response = await http.post(
        Uri.parse('$baseUrl/dataset'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
        },
        body: jsonEncode(
            {'isReset': reset, 'start': start, 'length': length, 'draw': '1'}),
      );
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        setState(() {
          items = parseItems(response.body);
          _filteredItems = List.from(items);
          errorCoordinates = jsonDecode(response.body)['errors']
                  ['grid_coordinates']
              .map<String>((item) => item.toString())
              .toList();
          errorMessages = jsonDecode(response.body)['errors']['messages']
              .map<String>((item) => item.toString())
              .toList();

          recordsTotal = jsonDecode(response.body)['recordsTotal'];
        });
      }
    } else {
      token = await APIService.getToken();
      apiKey = await APIService.getXApiKey();
      EasyLoading.show(status: 'loading...');
      var jsonResponse = await http.post(
          Uri.parse('$baseUrl/preview/fetch/excel/data'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'auth-key': '$apiKey',
          },
          body: jsonEncode({'draw': '1', 'start': start, 'length': length}));
      EasyLoading.dismiss();

      items = parseItems(jsonResponse.body);
      _filteredItems = List.from(items);
      errorCoordinates = jsonDecode(jsonResponse.body)['errors']
              ['grid_coordinates']
          .map<String>((item) => item.toString())
          .toList();
      errorMessages = jsonDecode(jsonResponse.body)['errors']['messages']
          .map<String>((item) => item.toString())
          .toList();
      recordsTotal = jsonDecode(jsonResponse.body)['recordsTotal'];
      setState(() {});
    }
  }

  List<ItemModel> parseItems(String jsonResponse) {
    final Map<String, dynamic> decodedJson = json.decode(jsonResponse);
    final List<dynamic> jsonData = decodedJson['data'];
    return jsonData.asMap().entries.map((entry) {
      int index = entry.key;
      var item = entry.value;
      return ItemModel(
        id: item['id'],
        itemName: item['item_name'] ?? '',
        quantity: item['quantity'] ?? '',
        minStockAlert: item['minimum_stock_alert'] ?? '',
        mrp: item['mrp'] ?? '0',
        salePrice: item['sale_price'].toString(),
        unit: item['unit'] ?? '',
        hsn: item['hsn'] ?? '',
        gst: item['gst']?.toString() ?? '0',
        cess: item['cess']?.toString() ?? '0',
        flag: 0,
      );
    }).toList();
  }

  void _filterItems(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm.trim();
      if (_searchTerm.isEmpty) {
        _filteredItems = List.from(items);
      } else {
        final searchTermLower = _searchTerm.toLowerCase();
        _filteredItems = items
            .where(
                (item) => item.itemName.toLowerCase().contains(searchTermLower))
            .toList();
      }
    });
  }

  Future deleteRows(
      {required List<int> indexes,
      required String token,
      required String apikey}) async {
    print('indexes: $indexes');
    String url;
    EasyLoading.show(status: 'Deleting...');
    if (widget.uploadExcel != null) {
      url = '$baseUrl/upload-data/multiple-delete';
    } else {
      url = '$baseUrl/dataset/multiple-delete';
    }
    String jsonBody = jsonEncode({'ids': indexes});
    print('Request body: $jsonBody');

    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'auth-key': apikey,
        'Content-Type': 'application/json',
      },
      body: jsonBody,
    );

    EasyLoading.dismiss();
    print('Response: ${response.body}');
    return response;
  }

  int countUniqueXCoordinates(List<String> coordinates) {
    Set<String> uniqueX = {};

    for (String coordinate in coordinates) {
      String xCoord = coordinate.split(',')[0];
      uniqueX.add(xCoord);
    }

    return uniqueX.length;
  }

  @override
  Widget build(BuildContext context) {
    int count = countUniqueXCoordinates(errorCoordinates);
    print(errorCoordinates);
    return Scaffold(
      appBar: customAppBar(widget.title, [
        TextButton(
          onPressed: _showNewRowDialog,
          child: const Text(
            'Add Row',
            style: TextStyle(
                color: white,
                fontFamily: 'Roboto-Regular',
                fontWeight: FontWeight.bold),
          ),
          //tooltip: 'Add new row',
        ),
        widget.uploadExcel == null
            ? TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => customAlertBox(
                      title: 'Reset Dataset',
                      content: 'Are you sure you want to reset the dataset?',
                      actions: [
                        customElevatedButton('Yes', red, white, () async {
                          EasyLoading.show(status: 'Resetting...');
                          var response = await http.get(
                            Uri.parse('$baseUrl/reset-dataset'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token',
                              'auth-key': '$apiKey',
                            },
                          );
                          if (response.statusCode == 200) {
                            getItems(
                                reset: '0',
                                start: '0',
                                length: _rowsPerPage.toString());
                          }
                          EasyLoading.dismiss();

                          navigatorKey.currentState?.pop();
                        }),
                        customElevatedButton('No', green2, white, () {
                          navigatorKey.currentState?.pop();
                        })
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                      color: white,
                      fontFamily: 'Roboto-Regular',
                      fontWeight: FontWeight.bold),
                ),
              )
            : const SizedBox.shrink(),
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => customAlertBox(
                title: 'Upload Dataset',
                content: "Do you want to replace or append the data?",
                actions: [
                  customElevatedButton('Append', green2, white, () {
                    submitList('1');
                    navigatorKey.currentState?.pop();
                  }),
                  customElevatedButton("Replace", blue, white, () {
                    navigatorKey.currentState?.pop();
                    showDialog(
                        context: context,
                        builder: (context) => customAlertBox(
                                title: 'Confirmation',
                                content:
                                    'This will replace your inventory data if any. If you have any existing data in your inventory, all data will be deleted and replaced with this new data',
                                actions: [
                                  customElevatedButton('NO', red, white, () {
                                    navigatorKey.currentState?.pop();
                                  }),
                                  customElevatedButton('YES', green2, white,
                                      () {
                                    submitList('2');
                                    navigatorKey.currentState?.pop();
                                  })
                                ]));
                    // submitList('2');
                  }),
                ],
              ),
            );
          },
          child: const Text('Export',
              style: TextStyle(
                  color: white,
                  fontFamily: 'Roboto-Regular',
                  fontWeight: FontWeight.bold)),
        ),
        if (_selectedItems.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete, color: white),
            onPressed: _deleteSelectedRows,
            tooltip: 'Delete selected rows',
          ),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Item Name',
                hintText: 'Type to filter rows',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterItems('');
                  },
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchTerm.isEmpty
                      ? 'Showing  ${_filteredItems.length} rows'
                      : 'Found ${_filteredItems.length} ${_filteredItems.length == 1 ? 'row' : 'rows'} containing "$_searchTerm"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                if (_selectedItems.isNotEmpty)
                  Text('${_selectedItems.length} row(s) selected',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (errorMessages.isNotEmpty && errorCoordinates.isNotEmpty)
            Container(
              height:
                  errorMessages.length <= 3 ? errorMessages.length * 50.0 : 150,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8.0),
              child: Scrollbar(
                trackVisibility: true,
                thumbVisibility: true,
                interactive: true,
                child: ListView.builder(
                  itemCount: errorMessages.length,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text(errorMessages[index])),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      _searchTerm.isEmpty
                          ? 'No data available'
                          : 'No results found for "$_searchTerm"',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : DataTable2(
                    scrollController: _scrollController,
                    columns: getColumns([
                      'Item Name',
                      'MRP',
                      'Sale Price',
                      'Quantity',
                      'Minimum Stock Alert',
                      'Unit',
                      'HSN',
                      'GST',
                      'Cess'
                    ]),
                    rows: _ItemDataSource(
                            _filteredItems, _selectedItems, this, count)
                        .getRows(),
                    showCheckboxColumn: true,
                    minWidth: 9 * 130,
                    dataRowHeight: 70,
                    fixedTopRows: 1,
                    fixedLeftColumns: 2,
                  ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: getPreviousPage,
                  icon: const Icon(Icons.arrow_left)),
              Text(
                  'Showing ${start + 1}-${(start + _rowsPerPage) > recordsTotal ? recordsTotal : (start + _rowsPerPage)} entries of  $recordsTotal '),
              IconButton(
                  onPressed: getNextPage, icon: const Icon(Icons.arrow_right)),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom * 2),
        ],
      ),
    );
  }

  Widget _buildCombinedDropdown(
      List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xffbfbfbf), width: 3.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: green2, width: 3.0),
        ),
      ),
      hint: const Text('Full Unit (Short Unit) *'),
      value: fullUnitDropdownValue == null
          ? null
          : '$fullUnitDropdownValue ($shortUnitDropdownValue)',
      items: items
          .map((item) =>
              DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTaxRateRow(Key key, int index, StateSetter dialogSetState) {
    bool isFirstRow = index == 0;
    bool isMaxRowsReached = taxRateRows.length >= 2;

    return Row(
      key: key,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: taxControllers[index] ?? 'GST',
            onChanged: (String? value) {
              dialogSetState(() {
                taxControllers[index] = value!;
              });
            },
            items: const [
              DropdownMenuItem<String>(value: 'GST', child: Text('GST')),
              DropdownMenuItem<String>(value: 'SASS', child: Text('SASS')),
            ],
            hint: const Text('Select Tax'),
            decoration: customTfInputDecoration("Select Tax"),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: TextField(
            controller:
                index == 0 ? rateOneValueController : rateTwoValueController,
            keyboardType: TextInputType.number,
            decoration: customTfInputDecoration("Rate *"),
          ),
        ),
        IconButton(
          icon: Icon(isFirstRow ? Icons.add : Icons.remove),
          onPressed: () {
            if (isMaxRowsReached && isFirstRow) {
              showDialog(
                context: context,
                builder: (BuildContext context) => customAlertBox(
                  title: 'Warning',
                  content: 'You cannot add more than 2 tax rows.',
                  actions: [
                    customElevatedButton("OK", green2, white,
                        () => navigatorKey.currentState?.pop())
                  ],
                ),
              );
            } else {
              dialogSetState(() {
                if (isFirstRow) {
                  var newKey = GlobalKey();
                  taxRateRowKeys.insert(index + 1, newKey);
                  taxRateRows.insert(index + 1,
                      _buildTaxRateRow(newKey, index + 1, dialogSetState));
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
          },
        ),
      ],
    );
  }

  void _showNewRowDialog() {
    taxRateRows.clear();
    var key = GlobalKey();
    taxRateRowKeys.add(key);

    showDialog(
      barrierDismissible: false,
      useSafeArea: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            if (taxRateRows.isEmpty) {
              taxRateRows.add(_buildTaxRateRow(key, 0, setState));
            }

            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Row'),
                  IconButton(
                      onPressed: () => navigatorKey.currentState!.pop(),
                      icon: const Icon(Icons.close)),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInputBox(
                          ' Item Name *',
                          itemNameValueController,
                          (value) => setState(
                              () => itemNameValueController.text = value)),
                      const SizedBox(height: 20.0),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCombinedDropdown(
                              fullUnits
                                  .map((unit) =>
                                      '$unit (${shortUnits[fullUnits.indexOf(unit)]})')
                                  .toList(),
                              (value) {
                                List<String> units = value!.split(' (');
                                String fullUnit = units[0];
                                String shortUnit =
                                    units[1].substring(0, units[1].length - 1);
                                setState(() {
                                  fullUnitDropdownValue = fullUnit;
                                  shortUnitDropdownValue = shortUnit;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputBox(
                                ' Sale price: Rs. *',
                                salePriceValueController,
                                (value) => setState(() =>
                                    salePriceValueController.text = value),
                                isNumeric: true),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildInputBox(
                                ' MRP ${maintainMRP ? '*' : ''}',
                                mrpValueController,
                                (value) => setState(
                                    () => mrpValueController.text = value),
                                isNumeric: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputBox(
                                ' Stock Quantity ${maintainStock ? '*' : ''}',
                                stockQuantityValueController,
                                (value) => setState(() =>
                                    stockQuantityValueController.text = value),
                                isNumeric: true),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Visibility(
                              visible:
                                  stockQuantityValueController.text.isNotEmpty,
                              child: _buildInputBox(
                                  ' Minimum Stock ',
                                  minumumStockController,
                                  (value) => setState(() =>
                                      minumumStockController.text = value),
                                  isNumeric: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      _buildInputBox(
                          ' HSN/ SAC Code ${showHSNSACCode ? '*' : ''}',
                          codeHSNSACvalueController,
                          (value) => setState(
                              () => codeHSNSACvalueController.text = value),
                          isNumeric: true),
                      const SizedBox(height: 20.0),
                      Column(
                          children: taxRateRows
                              .map((row) => Column(
                                  children: [row, const SizedBox(height: 8.0)]))
                              .toList()),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
              actions: [
                customElevatedButton('Save', green2, white, () async {
                  var response = await addNewRow();
                  if (response['status'] == 'success') {
                    navigatorKey.currentState!.pop();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => customAlertBox(
                        title: 'Error',
                        content:
                            "${response['message']}\nPlease enter valid data.",
                        actions: [
                          customElevatedButton('OK', green2, white,
                              () => navigatorKey.currentState!.pop())
                        ],
                      ),
                    );
                  }
                }),
                customElevatedButton('Cancel', red, white,
                    () => navigatorKey.currentState!.pop()),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Reset controllers after dialog dismissal
      itemNameValueController.clear();
      mrpValueController.clear();
      salePriceValueController.clear();
      stockQuantityValueController.clear();
      codeHSNSACvalueController.clear();
      rateOneValueController.clear();
      rateTwoValueController.clear();
      minumumStockController.clear();
      fullUnitDropdownValue = null;
      shortUnitDropdownValue = null;
      taxRateRows.clear();
      taxRateRowKeys.clear();
      rateControllers.clear();
      taxControllers.clear();
    });
  }

  Future<Map<String, dynamic>> addNewRow() async {
    final newId = items.isEmpty ? 1 : items.map((u) => u.id).reduce(max) + 1;
    final newItem = ItemModel(
      id: newId,
      itemName: itemNameValueController.text,
      quantity: stockQuantityValueController.text,
      minStockAlert: minumumStockController.text,
      mrp: mrpValueController.text,
      salePrice: salePriceValueController.text,
      unit: shortUnitDropdownValue ?? '',
      hsn: codeHSNSACvalueController.text,
      gst: rateOneValueController.text,
      cess: rateTwoValueController.text,
      flag: 0,
    );
    EasyLoading.show(status: 'loading...');
    var response = await http.post(
      Uri.parse('$baseUrl/update-cell-data'),
      headers: {
        'Authorization': 'Bearer $token',
        'auth-key': '$apiKey',
      },
      body: {
        'id': '0',
        'row_index': '$newId',
        'item_name': newItem.itemName,
        'quantity': newItem.quantity,
        'min_stock_alert': newItem.minStockAlert,
        'mrp': newItem.mrp,
        'sale_price': newItem.salePrice,
        'short_unit': newItem.unit,
        'hsn': newItem.hsn,
        'gst': newItem.gst,
        'cess': newItem.cess,
      },
    );
    print('Response: ${response.body}');
    EasyLoading.dismiss();
    if (response.statusCode == 200) {
      setState(() {
        items.add(newItem);
        if (_searchTerm.isEmpty ||
            newItem.itemName
                .toLowerCase()
                .contains(_searchTerm.toLowerCase())) {
          _filteredItems.add(newItem);
        }
        _scrollController
            .jumpTo(_scrollController.position.maxScrollExtent + 70);
      });
    }
    return jsonDecode(response.body);
  }

  Widget _buildInputBox(String hintText, TextEditingController textController,
      void Function(String) updateIdentifier,
      {bool isNumeric = false}) {
    return TextField(
      controller: textController,
      decoration: customTfInputDecoration(hintText),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      onChanged: updateIdentifier,
    );
  }

  void _deleteSelectedRows() {
    final visibleSelectedItems =
        _selectedItems.where((item) => _filteredItems.contains(item)).toList();
    if (visibleSelectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No visible rows are selected'),
          duration: Duration(seconds: 2)));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rows'),
        content: Text(
            'Are you sure you want to delete ${visibleSelectedItems.length} selected row(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              List<int> arr = [];
              setState(() {
                for (var entry in List.from(errorCoordinates)) {
                  String firstPart = entry.split(',')[0];
                  int firstValue = int.parse(firstPart);
                  print(firstValue);

                  print('arr: $arr');
                  if (visibleSelectedItems.contains(items[firstValue])) {
                    errorCoordinates.remove(entry);
                  }
                }
              });
              for (var item in visibleSelectedItems) {
                arr.add(item.id);
              }
              print('arr: $arr');
              var response =
                  await deleteRows(indexes: arr, token: token, apikey: apiKey);
              print(response.body);

              if (response.statusCode == 200) {
                setState(() {
                  items.removeWhere(
                      (item) => visibleSelectedItems.contains(item));
                  _filteredItems.removeWhere(
                      (item) => visibleSelectedItems.contains(item));
                  _selectedItems.removeAll(visibleSelectedItems);
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                    'Selected rows deleted successfully',
                    textAlign: TextAlign.center,
                  ),
                  duration: Durations.extralong4,
                ));
                getItems(
                    reset: '0',
                    start: start.toString(),
                    length: _rowsPerPage.toString());
              }
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<DataColumn2> getColumns(List<String> columns) {
    return columns.map((column) {
      return DataColumn2(
        onSort: (columnIndex, ascending) {
          setState(() {
            isSortAscending = ascending;
            if (isSortAscending) {
              switch (columnIndex) {
                case 0:
                  _filteredItems
                      .sort((a, b) => a.itemName.compareTo(b.itemName));
                  break;
                case 1:
                  _filteredItems.sort((a, b) =>
                      double.parse(a.mrp).compareTo(double.parse(b.mrp)));
                  break;
                case 2:
                  _filteredItems.sort((a, b) => double.parse(a.salePrice)
                      .compareTo(double.parse(b.salePrice)));
                  break;
                case 3:
                  _filteredItems.sort((a, b) =>
                      int.parse(a.quantity).compareTo(int.parse(b.quantity)));
                  break;
              }
            } else {
              switch (columnIndex) {
                case 0:
                  _filteredItems
                      .sort((a, b) => b.itemName.compareTo(a.itemName));
                  break;
                case 1:
                  _filteredItems.sort((a, b) =>
                      double.parse(b.mrp).compareTo(double.parse(a.mrp)));
                  break;
                case 2:
                  _filteredItems.sort((a, b) => double.parse(b.salePrice)
                      .compareTo(double.parse(a.salePrice)));
                  break;
                case 3:
                  _filteredItems.sort((a, b) =>
                      int.parse(b.quantity).compareTo(int.parse(a.quantity)));
                  break;
              }
            }
          });
        },
        label: Text(column, maxLines: 2, overflow: TextOverflow.ellipsis),
      );
    }).toList();
  }

  Future<void> editQuantity(ItemModel editItem) async {
    final quantity = await showTextDialog(context,
        title: 'Edit Quantity', value: editItem.quantity);
    if (quantity != null) {
      await _updateItem(editItem, quantity: quantity, cellIndex: 2);
      setState(() {});
    }
  }

  Future<void> editItemName(ItemModel editItem) async {
    final itemName = await showTextDialog(context,
        title: 'Edit Item Name', value: editItem.itemName);
    if (itemName != null) {
      await _updateItem(editItem, itemName: itemName, cellIndex: 1);
      setState(() {});
    }
  }

  Future<void> editMinStockAlert(ItemModel editItem) async {
    final minStockAlert = await showTextDialog(context,
        title: 'Edit Minimum Stock Alert', value: editItem.minStockAlert);
    if (minStockAlert != null) {
      await _updateItem(editItem, minStockAlert: minStockAlert, cellIndex: 3);
      setState(() {});
    }
  }

  Future<void> editMrp(ItemModel editItem) async {
    final mrp =
        await showTextDialog(context, title: 'Edit MRP', value: editItem.mrp);
    if (mrp != null) {
      await _updateItem(editItem, mrp: mrp, cellIndex: 4);
      setState(() {});
    }
  }

  Future<void> editSalePrice(ItemModel editItem) async {
    final salePriceString = await showTextDialog(context,
        title: 'Edit Sale Price', value: editItem.salePrice.toString());
    if (salePriceString != null) {
      await _updateItem(editItem, salePrice: salePriceString, cellIndex: 5);
      setState(() {});
    }
  }

  Future<void> editHsn(ItemModel editItem) async {
    final hsn =
        await showTextDialog(context, title: 'Edit HSN', value: editItem.hsn);
    if (hsn != null) {
      await _updateItem(editItem, hsn: hsn, cellIndex: 9);
      setState(() {});
    }
  }

  Future<void> editgst(ItemModel editItem) async {
    final gst = await showTextDialog(context,
        title: 'Edit Rate 1', value: editItem.gst);
    if (gst != null) {
      await _updateItem(editItem, gst: gst, cellIndex: 7);
      setState(() {});
    }
  }

  Future<void> editcess(ItemModel editItem) async {
    final cess = await showTextDialog(context,
        title: 'Edit Rate 2', value: editItem.cess);
    if (cess != null) {
      _updateItem(editItem, cess: cess, cellIndex: 8);
      setState(() {});
    }
  }

  Future<void> _updateItem(ItemModel editItem,
      {String? itemName,
      String? quantity,
      String? minStockAlert,
      String? mrp,
      String? salePrice,
      String? unit,
      String? hsn,
      String? gst,
      String? cess,
      int? flag,
      required int cellIndex}) async {
    // Update local data first
    final index = items.indexWhere((item) => item.id == editItem.id);
    if (index >= 0) {
      items[index] = editItem.copy(
        itemName: itemName,
        quantity: quantity,
        minStockAlert: minStockAlert,
        mrp: mrp,
        salePrice: salePrice,
        unit: unit,
        hsn: hsn,
        gst: gst,
        cess: cess,
        flag: flag,
      );
    }

    final filteredIndex =
        _filteredItems.indexWhere((item) => item.id == editItem.id);
    if (filteredIndex >= 0) {
      _filteredItems[filteredIndex] = editItem.copy(
        itemName: itemName,
        quantity: quantity,
        minStockAlert: minStockAlert,
        mrp: mrp,
        salePrice: salePrice,
        unit: unit,
        hsn: hsn,
        gst: gst,
        cess: cess,
        flag: flag,
      );
    }

    Map<String, String> requestBody = {
      'id': _filteredItems[filteredIndex].id.toString(),
      'cell_index': cellIndex.toString(),
      'row_index': items.indexOf(_filteredItems[filteredIndex]).toString(),
      'item_name': _filteredItems[filteredIndex].itemName,
      'quantity': _filteredItems[filteredIndex].quantity,
      'min_stock_alert': _filteredItems[filteredIndex].minStockAlert,
      'mrp': _filteredItems[filteredIndex].mrp,
      'sale_price': _filteredItems[filteredIndex].salePrice,
      'unit': _filteredItems[filteredIndex].unit,
      'hsn': _filteredItems[filteredIndex].hsn,
      'gst': _filteredItems[filteredIndex].gst,
      'cess': _filteredItems[filteredIndex].cess,
    };

    // Prepare API request
    EasyLoading.show(status: 'loading...');
    String url;
    if (widget.uploadExcel != null) {
      url = '$baseUrl/upload-data/update-cell-data';
    } else {
      url = '$baseUrl/update-cell-data';
    }
    if (widget.uploadExcel != null) {}
    var response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
        },
        body: requestBody);
    print(requestBody);
    print(response.body);
    EasyLoading.dismiss();

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item: ${response.body}')),
      );
      getItems(
          reset: '0', start: start.toString(), length: _rowsPerPage.toString());
    } else {
      getItems(
          reset: '0', start: start.toString(), length: _rowsPerPage.toString());
    }
  }

  Future<void> submitList(String action) async {
    errorCoordinates = [];
    errorMessages = [];
    var token = await APIService.getToken();
    var apiKey = await APIService.getXApiKey();
    // List<Map<String, dynamic>> uploadItems = items
    //     .map((item) => {
    //           'item_name': item.itemName,
    //           'quantity': item.quantity,
    //           'min_stock_alert': item.minStockAlert,
    //           'mrp': item.mrp,
    //           'sale_price': item.salePrice,
    //           'unit': item.unit.toUpperCase(),
    //           'hsn': item.hsn,
    //           'gst': item.gst,
    //           'cess': item.cess,
    //         })
    //     .toList();

    if (widget.uploadExcel != null) {
      EasyLoading.show(status: 'Uploading...');
      var response = await http.post(
        Uri.parse('$baseUrl/export-to-inventory'),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );
      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        LocalDatabase2.instance.clearTable();
        LocalDatabase2.instance.fetchDataAndStoreLocally();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data uploaded successfully')));
        navigatorKey.currentState?.pop();
      } else {
        var jsonData = jsonDecode(response.body);
        setState(() {
          errorMessages = (jsonData['errors']['messages'] as List)
              .map((item) => item.toString())
              .toList();
          errorCoordinates = (jsonData['errors']['grid_coordinates'] as List)
              .map((item) => item.toString())
              .toList();
          items = parseItems(response.body);
          _filteredItems = List.from(items);
        });
      }
    } else {
      EasyLoading.show(status: 'loading...');
      var response = await http.post(
        Uri.parse('$baseUrl/inventory-store-multiple'),
        headers: {
          'Authorization': 'Bearer $token',
          'auth-key': '$apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );

      EasyLoading.dismiss();

      var jsonData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        LocalDatabase2.instance.clearTable();
        LocalDatabase2.instance.fetchDataAndStoreLocally();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data uploaded successfully')));
      } else {
        setState(() {
          errorMessages = (jsonData['errors']['messages'] as List)
              .map((item) => item.toString())
              .toList();
          errorCoordinates = (jsonData['errors']['grid_coordinates'] as List)
              .map((item) => item.toString())
              .toList();
          items = parseItems(response.body);
          _filteredItems = List.from(items);
        });
      }
    }
  }
}

class _ItemDataSource extends DataTableSource {
  final List<ItemModel> _items;
  final Set<ItemModel> _selectedItems;
  final _NewDatasetState _state;
  final int count;

  _ItemDataSource(this._items, this._selectedItems, this._state, this.count);

  List<DataRow> getRows() {
    return _items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final cells = [
        item.itemName,
        item.mrp,
        item.salePrice.toString(),
        item.quantity,
        item.minStockAlert,
        item.unit,
        item.hsn,
        item.gst,
        item.cess,
      ];

      return DataRow2(
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (index < count) {
            return Colors.red.shade100;
          }
          return null;
        }),
        cells: Utils.modelBuilder(cells, (cellIndex, cell) {
          Widget cellContent = cellIndex == 0 &&
                  index < _state.errorCoordinates.length
              ? Text(cell.toString(),
                  style:
                      const TextStyle(color: red, fontWeight: FontWeight.bold))
              : Text(cell.toString());
          return DataCell(
            cellIndex == 5
                ? DropdownButton(
                    value: _state._dropdownItemsQuantity.firstWhere(
                        (element) =>
                            element.toLowerCase() == item.unit.toLowerCase(),
                        orElse: () => _state._dropdownItemsQuantity.first),
                    items: _state._dropdownItemsQuantity
                        .map<DropdownMenuItem<String>>((value) {
                      return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(fontSize: 16)));
                    }).toList(),
                    onChanged: (newValue) {
                      _state.setState(() {
                        _state._updateItem(item,
                            unit: newValue.toString(), cellIndex: 5);
                      });
                    },
                  )
                : cellContent,
            onTap: () {
              switch (cellIndex) {
                case 0:
                  _state.editItemName(item);
                  break;
                case 1:
                  _state.editMrp(item);
                  break;
                case 2:
                  _state.editSalePrice(item);
                  break;
                case 3:
                  _state.editQuantity(item);
                  break;
                case 4:
                  _state.editMinStockAlert(item);
                  break;
                case 6:
                  _state.editHsn(item);
                  break;
                case 7:
                  _state.editgst(item);
                  break;
                case 8:
                  _state.editcess(item);
                  break;
              }
            },
          );
        }),
        selected: _selectedItems.contains(item),
        onSelectChanged: (isSelected) {
          _state.setState(() {
            if (isSelected != null) {
              isSelected
                  ? _selectedItems.add(item)
                  : _selectedItems.remove(item);
            }
          });
        },
      );
    }).toList();
  }

  @override
  DataRow getRow(int index) => getRows()[index];

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _items.length;

  @override
  int get selectedRowCount => _selectedItems.length;
}
