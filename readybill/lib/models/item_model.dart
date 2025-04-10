class ItemModel {
  final int id;
  final String itemName;
  final String quantity;
  final String minStockAlert;
  final String mrp;
  final String salePrice;
  final String unit;
  final String hsn;
  final String gst;
  final String cess;
  final int flag;

  ItemModel({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.minStockAlert,
    required this.mrp,
    required this.salePrice,
    required this.unit,
    required this.hsn,
    required this.gst,
    required this.cess,
    required this.flag,
  });

  ItemModel copy({
    int? id,
    String? itemName,
    String? quantity,
    String? minStockAlert,
    String? mrp,
    String? salePrice,
    String? unit,
    String? hsn,
    String? gst,
    String? cess,
    int? flag,
  }) =>
      ItemModel(
        id: id ?? this.id,
        itemName: itemName ?? this.itemName,
        quantity: quantity ?? this.quantity,
        minStockAlert: minStockAlert ?? this.minStockAlert,
        mrp: mrp ?? this.mrp,
        salePrice: salePrice ?? this.salePrice,
        unit: unit ?? this.unit,
        hsn: hsn ?? this.hsn,
        gst: gst ?? this.gst,
        cess: cess ?? this.cess,
        flag: flag ?? this.flag,
      );

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['original_index'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      minStockAlert: json['min_stock_alert'],
      mrp: json['mrp'],
      salePrice: json['sale_price'],
      unit: json['unit'],
      hsn: json['hsn'],
      gst: json['gst'],
      cess: json['cess'],
      flag: json['flag'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_index': id,
      'item_name': itemName,
      'quantity': quantity,
      'min_stock_alert': minStockAlert,
      'mrp': mrp,
      'sale_price': salePrice,
      'unit': unit,
      'hsn': hsn,
      'gst': gst,
      'cess': cess,
      'flag': flag,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          itemName == other.itemName &&
          quantity == other.quantity &&
          minStockAlert == other.minStockAlert &&
          mrp == other.mrp &&
          salePrice == other.salePrice &&
          unit == other.unit &&
          hsn == other.hsn &&
          gst == other.gst &&
          cess == other.cess &&
          flag == other.flag;

  @override
  int get hashCode =>
      id.hashCode ^
      itemName.hashCode ^
      quantity.hashCode ^
      minStockAlert.hashCode ^
      mrp.hashCode ^
      salePrice.hashCode ^
      unit.hashCode ^
      hsn.hashCode ^
      gst.hashCode ^
      cess.hashCode ^
      flag.hashCode;
}
