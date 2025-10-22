// lib/models/address_model.dart
enum AddressType { home, work, business, other }

AddressType addressTypeFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'home': return AddressType.home;
    case 'work': return AddressType.work;
    case 'business': return AddressType.business;
    default: return AddressType.other;
  }
}

String addressTypeToString(AddressType t) {
  switch (t) {
    case AddressType.home: return 'home';
    case AddressType.work: return 'work';
    case AddressType.business: return 'business';
    case AddressType.other: return 'other';
  }
}

class Address {
  final String id;                 // maps addressId from backend
  final AddressType addressType;
  final String city;
  final String description;
  final bool isDefault;

  Address({
    required this.id,
    required this.addressType,
    required this.city,
    required this.description,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: (json['addressId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      addressType: addressTypeFromString(json['addressType'] as String?),
      city: (json['city'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'addressType': addressTypeToString(addressType),
    'city': city,
    'description': description,
    'isDefault': isDefault,
  };

  Address copyWith({
    String? id,
    AddressType? addressType,
    String? city,
    String? description,
    bool? isDefault,
  }) => Address(
    id: id ?? this.id,
    addressType: addressType ?? this.addressType,
    city: city ?? this.city,
    description: description ?? this.description,
    isDefault: isDefault ?? this.isDefault,
  );
}

class AddressPayload {
  final AddressType addressType;
  final String city;
  final String description;
  final bool? isDefault;

  AddressPayload({
    required this.addressType,
    required this.city,
    required this.description,
    this.isDefault,
  });

  Map<String, dynamic> toJson() => {
    'addressType': addressTypeToString(addressType),
    'city': city,
    'description': description,
    if (isDefault != null) 'isDefault': isDefault,
  };
}
