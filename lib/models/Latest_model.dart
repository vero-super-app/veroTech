class LatestArrivalModels {
  final int id;
  final String image;
  final String name;
  final int price;
  final String description;

  LatestArrivalModels(
      {required this.id,
      required this.image,
      required this.name,
      required this.price,
      required this.description
      });

  factory LatestArrivalModels.fromJson(Map<String, dynamic> json) {
    return LatestArrivalModels(
      id: json['id'],
      image: json['image'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
    );
  }
}
