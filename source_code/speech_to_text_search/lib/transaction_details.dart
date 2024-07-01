import 'package:flutter/material.dart';
import 'package:speech_to_text_search/models/transaction.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailPage({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: const Color.fromRGBO(243, 203, 71, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Invoice Number', transaction.invoiceNumber),
            const SizedBox(height: 16),
            _buildInfoRow('Total Price', transaction.totalPrice),
            const SizedBox(height: 16),
            _buildInfoRow('Created At', transaction.createdAt),
            const SizedBox(height: 16),
            const Text(
              'Items:',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
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
              itemCount: transaction.itemList.length,
              itemBuilder: (context, index) {
                return itemWidget(transaction.itemList[index], context);
              },
            )),

            // _buildItemDataTable(),
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
            itemDetailWidget(context, '₹${item['rate']}'),
            itemDetailWidget(context, '₹${item['amount']}'),
          ],
        ),
        const Divider(
          color: Colors.grey,
          thickness: 1,
        )
      ],
    );
  }

  itemDetailWidget(BuildContext context, String itemDetail) {
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.17,
          minWidth: MediaQuery.of(context).size.width * 0.1),
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
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
