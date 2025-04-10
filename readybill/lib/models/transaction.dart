import 'dart:convert';

class Transaction {
  final int id;
  final String invoiceNumber;
  final List<Map<String, dynamic>> itemList;
  final String totalPrice;
  final String createdAt;

  Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.itemList,
    required this.totalPrice,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      itemList: List<Map<String, dynamic>>.from(jsonDecode(json['item_list'])),
      totalPrice: json['total_price'],
      createdAt: json['created_at'],
    );
  }
}
