class QuickSellSuggestionModel {
  String? status;
  int? count;
  String? itemName;
  List<Data>? data;

  QuickSellSuggestionModel({this.status, this.count, this.itemName, this.data});

  QuickSellSuggestionModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    count = json['count'];
    itemName = json['item_name'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['count'] = count;
    data['item_name'] = itemName;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  String? itemName;
  String? shortUnit;

  Data({this.id, this.itemName, this.shortUnit});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    itemName = json['item_name'];
    shortUnit = json['short_unit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['item_name'] = itemName;
    data['short_unit'] = shortUnit;
    return data;
  }
}
