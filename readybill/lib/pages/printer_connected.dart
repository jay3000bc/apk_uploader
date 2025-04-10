import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterConnected extends StatefulWidget {
  const PrinterConnected({super.key});

  @override
  State<PrinterConnected> createState() => _PrinterConnectedState();
}

class _PrinterConnectedState extends State<PrinterConnected> {
  ReceiptController? receiptController;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      printIt();
    });
  }

  void printIt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var paperSize = prefs.getString('paperSize');
    var address = prefs.getString('printerAddress');
    if (paperSize == "80mm") {
      receiptController!.paperSize = PaperSize.mm80;
    } else {
      receiptController!.paperSize = PaperSize.mm58;
    }

    receiptController!.print(address: address!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Printer Connected'),
        ),
        body: Receipt(
            builder: (context) => const Text("Printer Connected"),
            onInitialized: (controller) {
              receiptController = controller;
            }));
  }
}
