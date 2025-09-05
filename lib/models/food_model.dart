class FoodModel {
  final int id;
  final String FoodImage;
  final String RestrauntName;
  final int price;
  final String FoodName;
  final String CustomerName;
  final String CustomerLocation;
  final int Quantity;
  final String CustomerPhoneNumber;
  final String OrderDate;
  final String RestrauntPhoneNumber;
  final String description;


  FoodModel(
      {required this.id,
      required this.CustomerLocation,
      required this.CustomerPhoneNumber,
      required this.OrderDate,
      required this.CustomerName,
      required this.FoodImage,
      required this.RestrauntName,
      required this.RestrauntPhoneNumber,
      required this.FoodName,
      required this.Quantity,
      required this.price,
      required this.description});

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'],
      FoodImage: json['image'],
      CustomerName: json['name'],
      RestrauntName: json['RestrauntName'],
      FoodName: json['FoodName'],
      CustomerLocation: json['CustomerLocation'],
      OrderDate: json['OrderDate'],
      CustomerPhoneNumber: json['CustomerPhoneNUmber'],
      RestrauntPhoneNumber: json['RestrauntPhoneNumber'],
      Quantity: json['Quantity'],
      price: json['price'],
      description: json['description'],
    );
  }
}
