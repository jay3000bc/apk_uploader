import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class QuantityModalBottomSheet extends StatefulWidget {
  final dynamic provider;

  const QuantityModalBottomSheet({super.key, required this.provider});

  @override
  State<QuantityModalBottomSheet> createState() =>
      _QuantityModalBottomSheetState();
}

class _QuantityModalBottomSheetState extends State<QuantityModalBottomSheet> {
  int qty = 0;
  String ut = '';

  final TextEditingController quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String unit = widget.provider.unit;
    void assignQuantityAndunit(int qty, String ut) {
      widget.provider.assignQuantity(qty);
      widget.provider.assignUnit(ut);
    }

    if (unit.toLowerCase() == "kg" || unit.toLowerCase() == "gm") {
      return Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Text("Your selected unit is: $ut \nYour selected quantity is: $qty",
                style: const TextStyle(
                  fontFamily: 'Roboto-Regular',
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                    onTap: () {
                      qty = 50;
                      quantityController.text = qty.toString();
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('50',
                            style: TextStyle(
                              fontFamily: 'Roboto-Regular',
                            )))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 100;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('100',
                            style: TextStyle(
                              fontFamily: 'Roboto-Regular',
                            )))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 200;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('200',
                            style: TextStyle(
                              fontFamily: 'Roboto-Regular',
                            )))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 250;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('250',
                            style: TextStyle(
                              fontFamily: 'Roboto-Regular',
                            )))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 500;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('500',
                            style: TextStyle(
                              fontFamily: 'Roboto-Regular',
                            )))),
                const SizedBox(
                  height: 5.0,
                ),
                Column(
                  children: [
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            ut = 'KG';
                          });
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('KG',
                                style: TextStyle(
                                  fontFamily: 'Roboto-Regular',
                                )))),
                    const SizedBox(
                      height: 5.0,
                    ),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            ut = 'GM';
                          });
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('GM',
                                style: TextStyle(
                                  fontFamily: 'Roboto-Regular',
                                )))),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'OR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Enter custom quantity',
                style: TextStyle(
                  fontFamily: 'Roboto-Regular',
                )),
            const SizedBox(height: 16.0),
            TextField(
              keyboardType: TextInputType.number,
              controller: quantityController,
              onChanged: (value) {
                setState(() {
                  qty = int.parse(value);
                });
              },
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              ut = 'KG';
                            });
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(5)),
                              child: const Text('KG',
                                  style: TextStyle(
                                    fontFamily: 'Roboto-Regular',
                                  )))),
                      const SizedBox(
                        width: 10.0,
                      ),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              ut = 'GM';
                            });
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(5)),
                              child: const Text('GM',
                                  style: TextStyle(
                                    fontFamily: 'Roboto-Regular',
                                  )))),
                    ],
                  ),
                ),
                border: const OutlineInputBorder(),
                hintText: 'Quantity',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(const Color(0xff28a745))),
              onPressed: () {
                if (qty != 0 && ut != '') {
                  assignQuantityAndunit(qty, ut);
                  Navigator.pop(context);
                } else if (qty == 0 && ut == '') {
                  Fluttertoast.showToast(msg: "Enter quantity and unit");
                } else if (qty == 0 && ut != '') {
                  Fluttertoast.showToast(msg: "Enter quantity");
                } else {
                  Fluttertoast.showToast(msg: "Enter unit");
                }
              },
              child: const Text(
                'Submit',
                style: TextStyle(
                    fontFamily: 'Roboto-Regular', color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else if (unit.toLowerCase() == "ltr" || unit.toLowerCase() == "ml") {
      return Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Text(
              'Your selected unit is: $ut \nYour selected quantity is: $qty',
              style: const TextStyle(
                fontFamily: 'Roboto-Regular',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 50;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('50'))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 100;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('100'))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 200;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('200'))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 250;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('250'))),
                const SizedBox(
                  height: 5.0,
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 500;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('500'))),
                const SizedBox(
                  height: 5.0,
                ),
                Column(
                  children: [
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            ut = 'LTR';
                          });
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('LTR'))),
                    const SizedBox(
                      height: 5.0,
                    ),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            ut = 'ML';
                          });
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('ML'))),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'OR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Enter custom quantity'),
            const SizedBox(height: 16.0),
            TextField(
              keyboardType: TextInputType.number,
              controller: quantityController,
              onChanged: (value) {
                setState(() {
                  qty = int.parse(value);
                });
              },
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              ut = 'LTR';
                            });
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(5)),
                              child: const Text('LTR'))),
                      const SizedBox(
                        width: 10.0,
                      ),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              ut = 'ML';
                            });
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(5)),
                              child: const Text('ML'))),
                    ],
                  ),
                ),
                border: const OutlineInputBorder(),
                hintText: 'Quantity',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(const Color(0xff28a745))),
              onPressed: () {
                if (qty != 0 && ut != '') {
                  assignQuantityAndunit(qty, ut);
                  Navigator.pop(context);
                } else if (qty == 0 && ut == '') {
                  Fluttertoast.showToast(msg: "Enter quantity and unit");
                } else if (qty == 0 && ut != '') {
                  Fluttertoast.showToast(msg: "Enter quantity");
                } else {
                  Fluttertoast.showToast(msg: "Enter unit");
                }
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Text(
              "Your selected quantity is: $qty\nYour selected unit is: $unit",
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 1;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('1'))),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 2;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('2'))),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 3;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('3'))),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 4;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('4'))),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        qty = 5;
                        quantityController.text = qty.toString();
                      });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5)),
                        child: const Text('5'))),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 5),
                    child: Text(unit))
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'OR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Enter custom quantity'),
            const SizedBox(height: 16.0),
            TextField(
              controller: quantityController,
              onChanged: (value) {
                setState(() {
                  qty = int.parse(value);
                });
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Quantity',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(const Color(0xff28a745))),
              onPressed: () {
                ut = unit;
                if (qty == 0) {
                  Fluttertoast.showToast(msg: "Enter quantity");
                } else {
                  assignQuantityAndunit(qty, ut);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }
}
