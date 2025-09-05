class MarketplaceDetailModel {
  final int id;
  final String name;
  final String image;
  final double price;
  final String description;

  MarketplaceDetailModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
  });

  factory MarketplaceDetailModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceDetailModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
    );
  }
}
