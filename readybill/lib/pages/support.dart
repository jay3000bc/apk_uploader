import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readybill/components/api_constants.dart';

import 'package:readybill/components/color_constants.dart';
import 'package:readybill/components/custom_components.dart';
import 'package:readybill/services/api_services.dart';
import 'package:http/http.dart' as http;

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  TextEditingController questionTitleController = TextEditingController();
  FocusNode questionTitleFocusNode = FocusNode();
  TextEditingController questionBodyController = TextEditingController();
  FocusNode questionBodyFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? file;

  final List<Item> _items = [
    Item(
      title: 'How can I add items to inventory?',
      subTitle:
          'When you start using ReadyBill for the first time, your store data will be empty. The first thing that you have to do is to add your product data, before you can start using it.\n\nTo add your products into the inventory, you need certain information in hand, about each product. By default, ReadyBill has not enabled all the fields of information data. You can click on the “Preferences” menu on the left and enable or disable data that you don’t to show or maintain. For example, Stock Quantity is disabled by default. If you want to maintain your stocks, then you must enable it from the Preferences page. Similarly, if you want to show the MRP in your receipt or invoice, you must first enable MRP, then enable MRP in invoice. Only then MRP can be shown in the receipt or invoice.\n\nFor example: \n\nItem Name: Item Name is the name of your product that you are entering. (Say) you want to add “AASHIRVAAD SALT 1 KG”. Enter this product name “AASHIRVAAD SALT 1 KG” in the Item Name field.\n\nNote: If you have multiple products by the same name but weight is different, then you should name them accordingly. For example, “AASHIRVAAD SALT 1 KG” and “AASHIRVAAD SALT 500 G” are different. If you store them with the same name, then you cannot distinguish which one you are selling.\n\n Stock Quantity: If you want to maintain stock quantity in your shop, you should enter the current quantity of stock available in your shop. The stock quantity can help you in many ways. With this, you can always tell the amount of stock available in your shop for any product.\n\nMinimum Stock alert: Only if you are maintaining stocks then you can use this field to alert you when a particular item has gone below your minimum stock quantity. For example, (say) you have a fast-selling product “Amulya Powder 500” and you always want to keep a minimum of 10 packets available in your stock. Then you can set a MINIMUM STOCK ALERT for this product to 10. THIS FIELD IS NOT MANDATORY.\n\nUnit: Every product has a UNIT. Units are like – Bag, Box, Bottle, Piece, Can, Kg, Gram etc. For example, Maggi Tomato Ketchup’s unit is Bottle while Good Knight refill unit can be piece or pack. You can find the list of all units in the “Add Inventory” page. UNIT IS A MANDATORY FIELD and is always required.\n\nRate: Rate is the Sale Price i.e., the price at which you are selling the product. THIS IS A MANDATORY FIELD and is required for all purposes. This Rate is printed in the receipt or invoice.\n\nTax: Each product has a tax percentage. For example, the Govt. of India has made Goods and Services Tax (GST) mandatory. There can be additional taxes apart from GST, like CESS. If the Product has a CESS Tax, then you will also have to enter the CESS Tax value. THIS FIELD IS NOT MANDATORY. Even if there is no tax, you will have to enter ‘0’.\n\n*TIP: Instead of adding data one-by-one, you can also upload bulk data in batches. There is an “Upload Data” button in the “Add Inventory” page. You can use it to upload bulk data. More information on “How to upload inventory data in CSV or XLS format?” can be found here.',
    ),
    Item(
      title: "How to quick sell?",
      subTitle:
          'After you have added your products, now you are ready to sell. In quick sell\n\nFor the Mobile app – just tap the MIC button and say the product name. For example, “Amul butter 1 piece” or “Amul Butter 1 Packet”. A list will open. Select the right product. You will see the product and quantity automatically filled up in the boxes. Now click Add.\n\nNow you will see the product has been added below for billing. Add more products in the same way. You can also use the keyboard and type your Product Name and Quantity.\n\nBelow, you can also edit or change the quantities and price for the product that you have already added.Once done, you can either tap the Save button or the Print icon at the top. Both the actions will save the transaction. For the Desktop app – You will have to type and enter the product name and quantity and then click Add. Currently, the desktop app does not have the speech/voice feature. This will be implanted soon.',
    ),
    Item(
      title: 'How to do a refund?',
      subTitle:
          'The Refund works the same way as the Quick Sell. The only difference is that – when you add a product for REFUND the price will be in negative. Here again you can do both SAVE and PRINT.',
    ),
    Item(
      title: 'How can I add Employee or Staff?',
      subTitle:
          'Click on the Employees menu on the left. Enter the required details of your employee. \n\nNote: Employees cannot create their Mobile Number and Password on their own. After adding the employee, you will have to share the details with him/ her. Now the employee will be able to login with the details. If the employee wants to change his/her Mobile Number or Address – only the Shop Owner (Admin) can do this.',
    ),
    Item(
      title: 'How can my employees sell and do a billing?',
      subTitle:
          'Employee has to login with his/ her credentials. Once logged in, employee can do Quick Sell and Refund. Employees does not have all the privileges that the shop owner has. All sales done by the employee are stored in transaction. When you view the Transaction, you can see each invoice and who has done the sale and what time.',
    ),
    Item(
      title: 'How can I see the transactions?',
      subTitle:
          'The “Transaction” menu is on the left side. You can see a detailed list of all the transaction – who made the sell and at what time. You can also click on any transaction and view more details. Here, you can also print a receipt or invoice.',
    ),
    Item(
      title: 'How to use the Preferences?',
      subTitle:
          'The “Preferences” menu is on the left. Clicking on it will open the Preferences page. Here you can make your preferences by enabling or disabling the options. \n\n\t1. Do you maintain MRP?\nIf you enable this option, then you will be asked to enter the MRP of the product in “Add Inventory” page or in your XLS/ CS file if you are entering data in bulk. \n\n\t2. Do you want to show MRP in invoice?\nIf you enable this option, then the MRP will be shown in the receipt or invoice.\nNote: Without enabling MRP option you cannot enable to show MRP in invoice. \n\n\t3. Do you want to maintain stock?\n If you enable this option, then you have to enter (mandatory) your current stock quantity when you add inventory items. Note: By default, “Stock Quantity” is shown in “Add Inventory” page, but it is not mandatory. When you enable this option here, the Stock Quantity becomes mandatory. \n\n\t4. Do you want to HSN/ SAC code?\nHSN stands for “Harmonized System of Nomenclature”. This code is used for classification of products. Evey product has its own unique HSN number. You can find the HSN Code List &amp; GST here https://cleartax.in/s/gst-hsn- lookup. You can enable or disable HSN from here. If you disable HSN/ SAC code then you don’t need to enter it in your Inventory data. \n\n\t5. Do you want to show HSN/ SAC code in invoice?\nIf you have enabled this option, then you must also enable “Do you want HSN/ SAC code?”. If you enable this option, then the HSN code will be printed in the receipt or invoice',
    ),
  ];

  submitQuestion() async {
    var apiKey = await APIService.getXApiKey();
    var token = await APIService.getToken();
    EasyLoading.show(status: 'Sending question...');

    var request =
        http.MultipartRequest('POST', Uri.parse("$baseUrl/create-query"))
          ..headers['Authorization'] = 'Bearer $token'
          ..headers['auth-key'] = '$apiKey';
    request.fields['title'] = questionTitleController.text;
    request.fields['description'] = questionBodyController.text;

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'attachment',
        file!.path,
      ));
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "We have received your question.");
      questionTitleController.clear();
      questionBodyController.clear();
      file = null;
    } else {
      Fluttertoast.showToast(msg: "Failed to submit question");
    }
  }

  uploadAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpeg',
        'jpg',
        'gif',
        'bmp',
        'png',
        'txt',
        'rtf',
        'doc',
        'docx',
        'pdf'
      ],
    );

    if (result != null) {
      File selectedFile = File(result.files.single.path!);

      if (await selectedFile.length() < 20 * 1024 * 1024) {
        setState(() {
          file = selectedFile;
        });

        Navigator.of(context).pop();
        questionModalBottomSheet(context);
      } else {
        Fluttertoast.showToast(
            msg: "File size too large. Please try another file.");
      }
    }
  }

  questionModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text("ENTER YOUR QUESTION",
                                  style: TextStyle(
                                      fontFamily: 'Roboto-Regular',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Title: ",
                              style: TextStyle(
                                  fontFamily: 'Roboto-Regular',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              focusNode: questionTitleFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  questionTitleFocusNode.requestFocus();
                                  return "Please enter a title";
                                }
                                return null;
                              },
                              controller: questionTitleController,
                              decoration: customTfInputDecoration("Title"),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Details: ",
                              style: TextStyle(
                                  fontFamily: 'Roboto-Regular',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              focusNode: questionBodyFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  questionBodyFocusNode.requestFocus();
                                  return "Please enter the details";
                                }
                                return null;
                              },
                              controller: questionBodyController,
                              decoration: customTfInputDecoration("Details"),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  child: customElevatedButton(
                                      "Add Attachment", blue, white, () {
                                    uploadAttachment();
                                    setState(() {});
                                  }),
                                ),
                                if (file != null) ...[
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    child: Text(
                                      file!.path.split('/').last,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: const TextStyle(
                                          fontFamily: 'Roboto-Regular',
                                          color: Colors.blue),
                                      softWrap: true,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        file = null;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.maxFinite,
                              child: customElevatedButton(
                                "Submit",
                                green,
                                white,
                                () {
                                  if (_formKey.currentState!.validate()) {
                                    submitQuestion();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar("Support", []),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "FAQ:",
                  style: TextStyle(
                      fontFamily: 'Roboto-Regular',
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                TextButton(
                    onPressed: () {
                      questionModalBottomSheet(context);
                    },
                    child: const Text(
                      "Ask us a question?",
                      style: TextStyle(
                        fontFamily: 'Roboto-Regular',
                        color: Colors.blue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: blue,
                      ),
                    ))
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                child: ExpansionPanelList(
                  elevation: 0,
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      for (int i = 0; i < _items.length; i++) {
                        _items[i].isExpanded = false;
                      }

                      if (isExpanded) {
                        _items[index].isExpanded = true;
                      }
                    });
                  },
                  children: _items.map<ExpansionPanel>((Item item) {
                    return ExpansionPanel(
                        // backgroundColor: darkGrey,
                        canTapOnHeader: true,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(title: Text(item.title));
                        },
                        body: ListTile(
                          title: Text(item.subTitle),
                          tileColor: lightGrey,
                        ),
                        isExpanded: item.isExpanded);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class Item {
  String title;
  String subTitle;
  bool isExpanded;
  Item({
    required this.title,
    required this.subTitle,
    this.isExpanded = false,
  });
}
