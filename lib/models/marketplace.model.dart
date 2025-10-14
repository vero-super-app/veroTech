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
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] as num).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

class MarketplaceItem {
  final int? id; // nullable on create
  final String name;
  final String? image;
  final double price;
  final String? description;
  final bool isActive;

  MarketplaceItem({
    this.id,
    required this.name,
    required this.price,
    this.image,
    this.description,
    this.isActive = true,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    final priceNum = json['price'];
    final parsedPrice = priceNum is num ? priceNum.toDouble() : double.tryParse('${priceNum ?? 0}') ?? 0;
    return MarketplaceItem(
      id: json['id'] as int?,
      name: json['name'] ?? '',
      image: json['image'],
      price: parsedPrice,
      description: json['description'],
      isActive: (json['isActive'] is bool)
          ? (json['isActive'] as bool)
          : ((json['isActive']?.toString().toLowerCase() ?? '') == 'true'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'image': image,
        'price': price,
        'description': description,
        'isActive': isActive,
      };
}
