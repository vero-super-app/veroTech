class FoodModel {
  final int id;
  final String FoodName;
  final String FoodImage;
  final String RestrauntName;
  final double price;

  // Optional extras (safe to keep nullable)
  final String? description;
  final String? category;

  FoodModel({
    required this.id,
    required this.FoodName,
    required this.FoodImage,
    required this.RestrauntName,
    required this.price,
    this.description,
    this.category,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    int _id(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double _double(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    String _str(dynamic v) => (v == null) ? '' : v.toString();

    return FoodModel(
      id: _id(json['id']),
      FoodName: _str(json['FoodName']),
      FoodImage: _str(json['FoodImage']),
      RestrauntName: _str(json['RestrauntName']),
      price: _double(json['price']),
      description: json['description']?.toString(),
      category: json['category']?.toString(),
    );
  }
}
