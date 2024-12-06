import 'package:flutter/material.dart';

class QuantityModalBottomSheet extends StatelessWidget {
  final String unit;
  const QuantityModalBottomSheet({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(children: [
          if (unit.toLowerCase() == 'kg')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                    onTap: () {},
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
                    onTap: () {},
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
                    onTap: () {},
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
                    onTap: () {},
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
                    onTap: () {},
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
                        onTap: () {},
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('KG'))),
                    const SizedBox(
                      height: 5.0,
                    ),
                    GestureDetector(
                        onTap: () {},
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('GM'))),
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
            decoration: InputDecoration(
              suffixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                        onTap: () {},
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('KG'))),
                    const SizedBox(
                      width: 10.0,
                    ),
                    GestureDetector(
                        onTap: () {},
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('GM'))),
                  ],
                ),
              ),
              border: OutlineInputBorder(),
              labelText: 'Quantity',
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green)),
            onPressed: () {},
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ]));
  }
}
