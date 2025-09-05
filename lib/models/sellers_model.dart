class SellerApplicationDetailModel {
  final String FirstName;
  final String Surname;
  final int NationalID;
  final String BusinessName;
  final String PhoneNumber;
  final String Address;
  final String BusinessDescription;
  final String ApplicationDate;

  SellerApplicationDetailModel({
    required this.FirstName,
    required this.Surname,
    required this.NationalID,
    required this.BusinessName,
    required this.PhoneNumber,
    required this.Address,
    required this.BusinessDescription,
    required this.ApplicationDate
  });

  // Factory method to create an object from JSON response
  factory SellerApplicationDetailModel.fromJson(Map<String, dynamic> json) {
    return SellerApplicationDetailModel(
      FirstName: json['FirstName'],
      Surname: json['Surname'],
      NationalID: json['NationalID'],
      BusinessName: json['BusinessName'],
      PhoneNumber: json['PhoneNumber'],
      Address: json['Address'],
      BusinessDescription: json['BusinessDescription'],
      ApplicationDate: json['ApplicationDate']
    );
  }
}
