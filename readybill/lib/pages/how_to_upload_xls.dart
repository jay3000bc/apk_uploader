import 'package:flutter/material.dart';

class HowToUploadXlsPage extends StatelessWidget {
  const HowToUploadXlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to upload'),
        elevation: 0,
      ),
      body: const InventoryUploadGuideContent(),
    );
  }
}

class InventoryUploadGuideContent extends StatelessWidget {
  const InventoryUploadGuideContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to upload inventory data in CSV or XLS format?',
              style: TextStyle(
                  fontFamily: 'Roboto-Regular',
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // XLS Section
            const Text(
              'XLS:',
              style: TextStyle(
                  fontFamily: 'Roboto-Regular',
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
                'You can add your inventory items one-by-one using the “Add Inventory menu”. This is convenient when there are only few items that you can manually add them one-by-one, but this is not the best idea when you have to upload hundreds of items at once.'),
            const SizedBox(height: 10),
            const Text(
                'The “Upload Data” button in the “Add Inventory” page allows you to upload inventory data in CSV or XLS format. All you have to do is keep your data in the following format –'),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey),
                    verticalInside: BorderSide(color: Colors.grey),
                  ),
                  columns: const [
                    DataColumn(
                        label: Text('ITEM NAME',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('QUANTITY',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('MINIMUM STOCK ALERT',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('MRP',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('SALE PRICE',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('UNIT',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('HSN',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('GST',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('CESS',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                  ],
                  rows: const [],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Field Definitions
            const FieldDefinition(
                title: 'ITEM NAME',
                description:
                    'Name of the item or product that you are adding. There can be many products by the same name. Therefore, you should give a unique name that you always know. For example: Surf Excel 100, Surf Excel 500, Parle G Small, Parle G Large etc.'),

            const FieldDefinition(
                title: 'QUANTITY',
                description:
                    ' Only if you are maintaining stocks, then this is required or mandatory. If you are maintaining stock quantities then you will always be able to tell the available stock in your shop.'),

            const FieldDefinition(
                title: 'MINIMUM STOCK ALERT',
                description:
                    'Only if you are maintaining stocks then you can use this field to alert you when a particular item has gone below your minimum stock quantity. For example, (say) you have a fast-selling product “Amulya Powder 500” and you always want to keep a minimum of 10 packets available in your stock. Then you can set a MINIMUM STOCK ALERT for this product to 10. This field is not mandatory.'),

            const FieldDefinition(
                title: 'MRP',
                description:
                    'MRP is the Market Price of the product that is usually printed in the Packet itself. If you want to save the MRP then you have to enable “Do you maintain MRP?” from the Preferences menu. You also have the option of not showing the MRP in the bill or invoice. This can be done from the Preferences menu.'),

            const FieldDefinition(
                title: 'SALE PRICE',
                description:
                    'SALE PRICE is the price at which you are selling the product. This is a mandatory field and is required for all purposes.'),

            const FieldDefinition(
                title: 'UNIT',
                description:
                    'Every product has a UNIT. Units are like – Bag, Box, Bottle, Piece, Can, Kg, Gram etc. For example, Maggi Tomato Ketchup’s unit is Bottle while Good Knight’s unit can be piece or pack. You can find the list of all units in the “Add Inventory” page. UNIT is a mandatory field and is always required. You will have to use it in their short form otherwise the upload will not be successful. See below table for all available Units and their Short forms.'),

            const SizedBox(height: 20),

            // Units Table with Borders
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey),
                    verticalInside: BorderSide(color: Colors.grey),
                  ),
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(
                        label: Text('Units',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Short\nForm',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                  ],
                  rows: const [
                    DataRow(
                        cells: [DataCell(Text('Bag')), DataCell(Text('BAG'))]),
                    DataRow(cells: [
                      DataCell(Text('Bottle')),
                      DataCell(Text('BTL'))
                    ]),
                    DataRow(
                        cells: [DataCell(Text('Box')), DataCell(Text('BOX'))]),
                    DataRow(cells: [
                      DataCell(Text('Bundle')),
                      DataCell(Text('BDL'))
                    ]),
                    DataRow(
                        cells: [DataCell(Text('Can')), DataCell(Text('CAN'))]),
                    DataRow(cells: [
                      DataCell(Text('Cartoon')),
                      DataCell(Text('CTN'))
                    ]),
                    DataRow(
                        cells: [DataCell(Text('Gram')), DataCell(Text('GM'))]),
                    DataRow(cells: [
                      DataCell(Text('Kilogram')),
                      DataCell(Text('KG'))
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Litre')),
                      DataCell(Text('LTR'))
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Meter')),
                      DataCell(Text('MTR'))
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Millimeter')),
                      DataCell(Text('ML'))
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Number')),
                      DataCell(Text('NUM'))
                    ]),
                    DataRow(
                        cells: [DataCell(Text('Pack')), DataCell(Text('PCK'))]),
                    DataRow(cells: [
                      DataCell(Text('Packet')),
                      DataCell(Text('PKT'))
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Piece')),
                      DataCell(Text('PCS'))
                    ]),
                    DataRow(
                        cells: [DataCell(Text('Roll')), DataCell(Text('ROL'))]),
                    DataRow(cells: [
                      DataCell(Text('Square\nFeet')),
                      DataCell(Text('SQF'))
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Square\nMeter')),
                      DataCell(Text('SQM'))
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Additional Fields
            const FieldDefinition(
                title: 'HSN',
                description:
                    'HSN stands for “Harmonized System of Nomenclature”. This code is used for classification of products. Evey product has its own unique HSN number. You can find the HSN Code List & GST here https://cleartax.in/s/gst-hsn-lookup. You can enable and disable HSN from the Preferences menu. If you disable HSN/ SAC code then you don’t need to enter it in your Inventory data.'),

            const FieldDefinition(
                title: 'GST',
                description:
                    'As per the Govt. of India rules, Goods and Services Tax are mandatory. Every item is accompanied with its GST value. This is a required field.'),

            const FieldDefinition(
                title: 'CESS',
                description:
                    'Normally Grocery Items does not have CESS Tax, but some products may have CESS Tax. If a product has CESS Tax, then you have to enter the CESS Tax value.'),

            const SizedBox(height: 20),

            // Example XLS Table with data
            const Text('Example XLS Table:',
                style: TextStyle(
                    fontFamily: 'Roboto-Regular', fontWeight: FontWeight.bold)),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey),
                    verticalInside: BorderSide(color: Colors.grey),
                  ),
                  columns: const [
                    DataColumn(
                        label: Text('ITEM NAME',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('QUANTITY',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('MINIMUM STOCK ALERT',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('MRP',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('SALE PRICE',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('UNIT',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('HSN',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('GST',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('CESS',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                  ],
                  rows: const [
                    DataRow(cells: [
                      DataCell(Text('Surf Excel')),
                      DataCell(Text('10')),
                      DataCell(Text('5')),
                      DataCell(Text('100')),
                      DataCell(Text('95')),
                      DataCell(Text('PCK')),
                      DataCell(Text('3402')),
                      DataCell(Text('18')),
                      DataCell(Text('0')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Rice')),
                      DataCell(Text('50')),
                      DataCell(Text('10')),
                      DataCell(Text('55')),
                      DataCell(Text('52')),
                      DataCell(Text('KG')),
                      DataCell(Text('1006')),
                      DataCell(Text('5')),
                      DataCell(Text('0')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Milk')),
                      DataCell(Text('25')),
                      DataCell(Text('8')),
                      DataCell(Text('25')),
                      DataCell(Text('24')),
                      DataCell(Text('LTR')),
                      DataCell(Text('0401')),
                      DataCell(Text('5')),
                      DataCell(Text('0')),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CSV Format Section
            const Text(
              'Here NA means Not Applicable or Not Available. For example, in this case, the shop owner does not maintain Stock Quantity and Minimum stock cannot be maintained.',
              style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              'In the below table, the fields that has a star, means they are always mandatory.',
              style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey),
                    verticalInside: BorderSide(color: Colors.grey),
                  ),
                  columns: const [
                    DataColumn(
                        label: Text('ITEM NAME*',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('QUANTITY',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('MINIMUM STOCK ALERT',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('MRP',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('SALE PRICE*',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('UNIT*',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('HSN',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('GST*',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('CESS*',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontWeight: FontWeight.bold))),
                  ],
                  rows: const [],
                ),
              ),
            ),
            const Text(
              'Both GST and CESS are Taxes. Normally, CESS in not required. In such cases, you will have to put a ‘0’ and not NA. It will accept only numbers and decimals.',
              style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14),
            ),

            const Text(
              'Apart from these mandatory fields, you can make other fields mandatory from the Preferences menu – as per your requirement.',
              style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14),
            ),

            const SizedBox(height: 20),

            const Text(
              'CSV (Comma Separated Value):',
              style: TextStyle(
                  fontFamily: 'Roboto-Regular',
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can also upload inventory data as a CSV file. Manually creating a CSV file can be tedious. Therefore, we suggest you to follow the instruction below to easily convert a XLS file to a CSV file.',
              style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14),
            ),
            const SizedBox(height: 10),

            // Steps to Convert
            const Text('1. Open Excel',
                style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14)),
            const Text('2. Select File',
                style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14)),
            const Text('3. Select Save As',
                style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14)),
            const Text(
                '4. In the Save as type box, select CSV (Comma delimited)',
                style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14)),
            const Text('5. Choose a location to save the file',
                style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14)),
            const Text('6. Click Save',
                style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14)),

            const SizedBox(height: 20),

            const Text(
              'Alternatively, you can use any online application that converts your Excel file to a CSV file.',
              style: TextStyle(fontFamily: 'Roboto-Regular', fontSize: 14),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class FieldDefinition extends StatelessWidget {
  final String title;
  final String description;

  const FieldDefinition({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• $title:',
              style: const TextStyle(
                  fontFamily: 'Roboto-Regular', fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(description),
          ),
        ],
      ),
    );
  }
}
