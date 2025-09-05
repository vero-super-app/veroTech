class Hostel {
  final int id;
  final String houseName;
  final String image;
  final String location;
  final String roomType;
  final String genderCategory;
  final String roomNumber;
  final String price;
  final String bookingFee;
  final String landlordPhoneNumber;
  final String status;
  final int maxPeople;

  Hostel({
    required this.id,
    required this.houseName,
    required this.image,
    required this.location,
    required this.roomType,
    required this.genderCategory,
    required this.roomNumber,
    required this.price,
    required this.bookingFee,
    required this.landlordPhoneNumber,
    required this.status,
    required this.maxPeople,
  });

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: json['id'],
      houseName: json['HouseName'],
      image: json['image'],
      location: json['Location'],
      roomType: json['RoomType'],
      genderCategory: json['GenderCategory'],
      roomNumber: json['RoomNumber'],
      price: json['Price'],
      bookingFee: json['BookingFee'],
      landlordPhoneNumber: json['LandlordPhoneNumber'],
      status: json['Status'],
      maxPeople: json['maxPeople'],
    );
  }
}
