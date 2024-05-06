import 'package:flutter/material.dart';
import 'package:speech_to_text_search/models/transaction.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailPage({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        backgroundColor: Color.fromRGBO(243, 203, 71, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Invoice Number', '${transaction.invoiceNumber}'),
            SizedBox(height: 16),
            _buildInfoRow('Total Price', '${transaction.totalPrice}'),
            SizedBox(height: 16),
            _buildInfoRow('Created At', '${transaction.createdAt}'),
            SizedBox(height: 16),
            Text(
              'Items:',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildItemDataTable(),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildItemDataTable() {
    // Calculate total amount
    double totalAmount = transaction.itemList.fold(0, (sum, item) => sum + double.parse(item['amount']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataTable(
          columnSpacing: 30.0,
          columns: [
            DataColumn(label: Text('Item Name')),
            DataColumn(label: Text('Quantity')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Amount')),
          ],
          rows: transaction.itemList
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text('${item['itemName']}')),
                    DataCell(Text('${item['quantity'] + item['selectedUnit']}')),
                    DataCell(Text('\₹${item['rate']}')),
                    DataCell(Text('\₹${item['amount']}')),
                  ],
                ),
              )
              .toList(),
        ),
        SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Grand Total: \₹${totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
