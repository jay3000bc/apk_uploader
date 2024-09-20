import 'package:flutter/material.dart';

class LocalDatabaseSuggestionsDropdown extends StatefulWidget {
  const LocalDatabaseSuggestionsDropdown({super.key});

  @override
  State<LocalDatabaseSuggestionsDropdown> createState() =>
      _LocalDatabaseSuggestionsDropdownState();
}

class _LocalDatabaseSuggestionsDropdownState
    extends State<LocalDatabaseSuggestionsDropdown> {
  int dataLength = 7;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: dataLength > 0
          ? Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              constraints: BoxConstraints(maxHeight: dataLength * 56.0),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 0),
                  ),
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: dataLength,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Local Database Suggestions',
                        ),
                        onTap: () {
                          setState(() {
                            dataLength -= 1;
                          });
                        },
                      ),
                      if (index != dataLength - 1)
                        const Divider(
                          thickness: 0.2,
                          height: 0,
                        ),
                    ],
                  );
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
