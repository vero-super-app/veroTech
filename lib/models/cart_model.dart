class CartModel {
  final String userId;       // keep as String for flexibility
  final int item;
  final int quantity;
  final String image;        // always non-null in app ('' if missing)
  final String name;         // ''
  final double price;
  final String description;  // ''
  final String? comment;     // optional (UI only; not sent to backend)

  CartModel({
    required this.userId,
    required this.item,
    required this.quantity,
    required this.image,
    required this.name,
    required this.price,
    required this.description,
    this.comment,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    int _int(Object? v, {int def = 0}) {
      if (v is int) return v;
      return int.tryParse('${v ?? ''}') ?? def;
    }

    double _double(Object? v, {double def = 0}) {
      if (v is num) return v.toDouble();
      return double.tryParse('${v ?? ''}') ?? def;
    }

    String _str(Object? v) => (v ?? '').toString();

    return CartModel(
      userId: _str(json['userId'] ?? json['user_id']),
      item: _int(json['item']),
      quantity: _int(json['quantity'], def: 1),
      image: _str(json['image']),
      name: _str(json['name']),
      price: _double(json['price']),
      description: _str(json['description']),
      comment: json['comment'] == null ? null : _str(json['comment']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'item': item,
        'quantity': quantity,
        'image': image,
        'name': name,
        'price': price,
        'description': description,
        if (comment != null) 'comment': comment, // service strips it
      };

  CartModel copyWith({
    String? userId,
    int? item,
    int? quantity,
    String? image,
    String? name,
    double? price,
    String? description,
    String? comment,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      comment: comment ?? this.comment,
    );
  }
}
