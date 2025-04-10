import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';

import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintPage extends StatefulWidget {
  final String billData;
  const PrintPage({super.key, required this.billData});

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  ReceiptController? controller;
  String? paperSize;
  Future<void> printIt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    paperSize = prefs.getString('paperSize');

    final deviceAddress = prefs.getString('printerAddress');
    print('paperSize: $paperSize');
    setState(() {
      if (paperSize == '80mm') {
        controller!.paperSize = PaperSize.mm80;
      } else {
        controller!.paperSize = PaperSize.mm58;
      }
    });

    if (deviceAddress != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        controller?.print(address: deviceAddress);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 200), () {
      printIt();
    });
  }

  @override
  Widget build(BuildContext context) {
    var data = jsonDecode(widget.billData)['data'];
    if (paperSize == '58mm') {
      return print58mm(data);
    } else {
      return print80mm(data);
    }
  }

  Widget print58mm(data) {
    return Scaffold(
      appBar: customAppBar("Print Page", []),
      body: Column(
        children: [
          Expanded(
            child: Receipt(
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 100, maxWidth: 100),
                      child: Image.network(data['logo_url']),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['business_name'],
                          style: const TextStyle(
                              fontFamily: 'Roboto-Regular', fontSize: 17))
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['address'],
                          style: const TextStyle(
                              fontFamily: 'Roboto-Regular', fontSize: 17))
                    ],
                  ),
                  const SizedBox(height: 5),
                  data['gstin'] != 'N/A' && data['gstin'] != 'NA'
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("GST no: ${data['gstin']}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 17))
                          ],
                        )
                      : const SizedBox.shrink(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "INVOICE",
                        style: TextStyle(
                            fontFamily: 'Roboto-Regular',
                            fontSize: 17,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Invoice No: ${data['invoice_number']}",
                          style: const TextStyle(
                              fontFamily: 'Roboto-Regular', fontSize: 17))
                    ],
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Date: ",
                        style: TextStyle(
                            fontFamily: 'Roboto-Regular', fontSize: 17)),
                    Text(data['preferences']['created_at'],
                        style: const TextStyle(
                            fontFamily: 'Roboto-Regular', fontSize: 17))
                  ]),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 22,
                        dividerThickness: 0,
                        horizontalMargin: 0,
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(
                            label: Text(
                              "ITEM",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              "QUANTITY",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "UNIT",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              "AMOUNT",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: data['item_list'].map<DataRow>((item) {
                          return DataRow(cells: [
                            DataCell(
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.2,
                                child: Text(
                                  item['itemName'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'Roboto-Regular',
                                      fontSize: 18),
                                ),
                              ),
                            ),
                            DataCell(Text(
                              item['quantity'].toString(),
                              style: const TextStyle(
                                  fontFamily: 'Roboto-Regular', fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                item['selectedUnit'].toString(),
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 18),
                              ),
                            ),
                            DataCell(
                              Text(
                                item['amount'].toString(),
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 18),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 30),
                      child: Text(
                        "Total: ${data['total_price']}",
                        style: const TextStyle(
                            fontFamily: 'Roboto-Regular',
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // CGST
                          if (data['taxGroups']['cgst'] != null)
                            ...data['taxGroups']['cgst'].entries.map((entry) {
                              final rate = entry.key;
                              final details = entry.value;
                              return Text(
                                "${details['taxName']} @ $rate%: ${data['currency']}${details['totalTax']}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 16),
                              );
                            }).toList(),

                          if (data['taxGroups']['sgst'] != null)
                            ...data['taxGroups']['sgst'].entries.map((entry) {
                              final rate = entry.key;
                              final details = entry.value;
                              return Text(
                                "${details['taxName']} @ $rate%: ${data['currency']}${details['totalTax']}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 16),
                              );
                            }).toList(),

                          const SizedBox(height: 5),
                          Text(
                            "Total Tax: ${data['currency']}${data['totalTaxAmount']}",
                            style: const TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "THANK YOU",
                        style: TextStyle(
                            fontFamily: 'Roboto-Regular',
                            fontSize: 17,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              onInitialized: (controller) {
                this.controller = controller;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: customElevatedButton(
              "Print",
              blue,
              white,
              printIt,
            ),
          ),
        ],
      ),
    );
  }

  Widget print80mm(data) {
    return Scaffold(
      appBar: customAppBar("Print Page", []),
      body: Column(
        children: [
          Expanded(
            child: Receipt(
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 100, maxWidth: 100),
                      child: Image.network(data['logo_url']),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['business_name'],
                          style: const TextStyle(
                              fontFamily: 'Roboto-Regular', fontSize: 17))
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['address'],
                          style: const TextStyle(
                              fontFamily: 'Roboto-Regular', fontSize: 17))
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['mobile_number'],
                          style: const TextStyle(
                              fontFamily: 'Roboto-Regular', fontSize: 17))
                    ],
                  ),
                  const SizedBox(height: 5),
                  const SizedBox(height: 5),
                  data['gstin'] != 'N/A' && data['gstin'] != 'NA'
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("GST no: ${data['gstin']}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 17))
                          ],
                        )
                      : const SizedBox.shrink(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "INVOICE",
                        style: TextStyle(
                            fontFamily: 'Roboto-Regular',
                            fontSize: 17,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Invoice No: ${data['invoice_number']}",
                          style: const TextStyle(
                              fontFamily: 'Roboto-Regular', fontSize: 17))
                    ],
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Date: ",
                        style: TextStyle(
                            fontFamily: 'Roboto-Regular', fontSize: 17)),
                    Text(data['preferences']['created_at'],
                        style: const TextStyle(
                            fontFamily: 'Roboto-Regular', fontSize: 17))
                  ]),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 22,
                        dividerThickness: 0,
                        horizontalMargin: 0,
                        columnSpacing:
                            20, // Add this to control space between columns
                        columns: [
                          const DataColumn(
                            label: Text(
                              "ITEM",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            tooltip: "Item Name",
                          ),
                          const DataColumn(
                            numeric: true,
                            label: Text(
                              "QUANTITY",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              "UNIT",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              data['preferences']['preference_mrp_invoice'] == 1
                                  ? "MRP"
                                  : "",
                              style: const TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const DataColumn(
                            numeric: true,
                            label: Text(
                              "RATE",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const DataColumn(
                            numeric: true,
                            label: Text(
                              "AMOUNT",
                              style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: data['item_list'].map<DataRow>((item) {
                          return DataRow(cells: [
                            DataCell(
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: Text(
                                  item['itemName'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'Roboto-Regular',
                                      fontSize: 18),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                item['quantity'].toString(),
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 18),
                              ),
                            ),
                            DataCell(
                              Text(
                                item['selectedUnit'].toString(),
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 18),
                              ),
                            ),
                            DataCell(Text(
                              data['preferences']['preference_mrp_invoice'] == 1
                                  ? item['mrp']
                                  : "     ",
                              style: const TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                            DataCell(Text(
                              item['rate'].toString(),
                              style: const TextStyle(
                                  fontFamily: 'Roboto-Regular', fontSize: 18),
                            )),
                            DataCell(
                              Text(
                                item['amount'].toString(),
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 18),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 30),
                      child: Text(
                        "Total: ${data['total_price']}",
                        style: const TextStyle(
                            fontFamily: 'Roboto-Regular',
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // CGST
                          if (data['taxGroups']['cgst'] != null)
                            ...data['taxGroups']['cgst'].entries.map((entry) {
                              final rate = entry.key;
                              final details = entry.value;
                              return Text(
                                "${details['taxName']} @ $rate%: ${data['currency']}${details['totalTax']}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 16),
                              );
                            }).toList(),

                          if (data['taxGroups']['sgst'] != null)
                            ...data['taxGroups']['sgst'].entries.map((entry) {
                              final rate = entry.key;
                              final details = entry.value;
                              return Text(
                                "${details['taxName']} @ $rate%: ${data['currency']}${details['totalTax']}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto-Regular', fontSize: 16),
                              );
                            }).toList(),

                          const SizedBox(height: 5),
                          Text(
                            "Total Tax: ${data['currency']}${data['totalTaxAmount']}",
                            style: const TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1,
                    color: black,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "THANK YOU",
                        style: TextStyle(
                            fontFamily: 'Roboto-Regular',
                            fontSize: 17,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
              onInitialized: (controller) {
                this.controller = controller;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: customElevatedButton(
              "Print",
              blue,
              white,
              printIt,
            ),
          ),
        ],
      ),
    );
  }
}
