import 'package:flutter/material.dart';

class BillWidget extends StatefulWidget {
  Map<String, dynamic> item;
  BuildContext context;
  int index;
  List<Map<String, dynamic>> itemForBillRows;
  Function deleteProductFromTable;

  BillWidget(
      {super.key,
      required this.item,
      required this.context,
      required this.index,
      required this.itemForBillRows,
      required this.deleteProductFromTable});

  @override
  State<BillWidget> createState() => _BillWidgetState();
}

class _BillWidgetState extends State<BillWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            itemDetailWidget(context,
                '${widget.itemForBillRows[widget.index]['itemName']}', 0.2),
            itemDetailWidget(
                context,
                '${widget.itemForBillRows[widget.index]['quantity']} \n${widget.itemForBillRows[widget.index]['selectedUnit']}',
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
                  hintText:
                      widget.itemForBillRows[widget.index]['rate'].toString(),
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
                  widget.itemForBillRows[widget.index]['rate'] =
                      double.parse(newRate);
                  // Recalculate the amount
                  widget.itemForBillRows[widget.index]['amount'] =
                      widget.itemForBillRows[widget.index]['rate'] *
                          widget.itemForBillRows[widget.index]['quantity'];
                  // Trigger UI update
                  if (mounted) setState(() {});
                },
              ),
            ),
            itemDetailWidget(context, '₹${widget.item['amount']}', 0.2),
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
                  widget.deleteProductFromTable(widget.index);
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
}
