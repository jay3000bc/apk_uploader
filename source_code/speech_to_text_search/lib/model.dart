import 'package:objectbox/objectbox.dart';

@Entity()
class Item {
  @Id()
  int id;

  String itemName;
  String quantity;
  String mrp;
  String salePrice;
  String fullUnit;
  String shortUnit;
  String hsn;
  String tax1;
  String rate1;
  String tax2;
  String rate2;
  DateTime createdAt; // Added created_at field
  DateTime updatedAt; // Added updated_at field

  Item({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.mrp,
    required this.salePrice,
    required this.fullUnit,
    required this.shortUnit,
    required this.hsn,
    required this.tax1,
    required this.rate1,
    required this.tax2,
    required this.rate2,
    required this.createdAt,
    required this.updatedAt,
  });
}
