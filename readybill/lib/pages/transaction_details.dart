import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionDetailPage extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  String? currencySymbol;
  @override
  void initState() {
    super.initState();
    setCurrencySymbol();
  }

  setCurrencySymbol() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencySymbol = prefs.getString('currencySymbol');
    });
    print('currencySymbol: $currencySymbol');
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = int.parse(widget.transaction.totalPrice);

    return Scaffold(
      appBar: customAppBar("Transaction Details", []),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Invoice Number', widget.transaction.invoiceNumber),
            const SizedBox(height: 16),
            _buildInfoRow(
                'Total Price',
                totalPrice > 0
                    ? "$currencySymbol$totalPrice"
                    : "-$currencySymbol${totalPrice.abs()}"),
            const SizedBox(height: 16),
            _buildInfoRow(
                'Created at',
                DateFormat('dd-MM-yyyy \n hh:mm a')
                    .format(DateTime.parse(widget.transaction.createdAt))),
            const SizedBox(height: 16),
            const Text(
              'Items:',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xff28a745),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                titleWidget(context, 'Item Name'),
                titleWidget(context, 'Qty'),
                titleWidget(context, 'Hsn'),
                titleWidget(context, 'Rate'),
                titleWidget(context, 'Amount'),
              ],
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.transaction.itemList.length,
                itemBuilder: (context, index) {
                  return itemWidget(
                      widget.transaction.itemList[index], context);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: customElevatedButton("Print", blue, white, () {
                  // navigatorKey.currentState?.push(CupertinoPageRoute(
                  //     builder: (context) => PrintPage(
                  //         data: widget.transaction.itemList,
                  //         totalAmount: widget.transaction.totalPrice,
                  //         invoiceNumber: widget.transaction.invoiceNumber)));
                })),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget itemWidget(Map<String, dynamic> item, BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            itemDetailWidget(context, '${item['itemName']}'),
            itemDetailWidget(
                context, '${item['quantity'] + item['selectedUnit']}'),
            itemDetailWidget(context, '${item['hsn']}'),
            itemDetailWidget(context, '$currencySymbol${item['rate']}'),
            itemDetailWidget(
                context,
                double.parse(item['amount']) > 0
                    ? '$currencySymbol${double.parse(item['amount']).abs().toStringAsFixed(2)}'
                    : '-$currencySymbol${double.parse(item['amount']).abs().toStringAsFixed(2)}'),
          ],
        ),
        const Divider(
          color: Colors.grey,
          thickness: 1,
        ),
      ],
    );
  }

  itemDetailWidget(BuildContext context, String itemDetail) {
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.17,
        minWidth: MediaQuery.of(context).size.width * 0.1,
      ),
      child: Text(
        itemDetail,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  titleWidget(BuildContext context, String title) {
    return Container(
      alignment: Alignment.center,
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.17),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
