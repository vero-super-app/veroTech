import 'dart:convert';

enum AddressType { home, work, business, other }

AddressType addressTypeFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'home':
      return AddressType.home;
    case 'work':
      return AddressType.work;
    case 'business':
      return AddressType.business;
    case 'other':
    default:
      return AddressType.other;
  }
}

String addressTypeToString(AddressType t) {
  switch (t) {
    case AddressType.home:
      return 'home';
    case AddressType.work:
      return 'work';
    case AddressType.business:
      return 'business';
    case AddressType.other:
      return 'other';
  }
}

class Address {
  final String id;
  final AddressType addressType;
  final String city;
  final String description;
  final bool isDefault; // server/local flag

  Address({
    required this.id,
    required this.addressType,
    required this.city,
    required this.description,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    final isDef = (json['isDefault'] == true) ||
        (json['default'] == true) ||
        (json['is_default'] == true);
    return Address(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      addressType: addressTypeFromString(json['addressType'] as String?),
      city: (json['city'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isDefault: isDef,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'addressType': addressTypeToString(addressType),
        'city': city,
        'description': description,
        'isDefault': isDefault,
      };
}

/// Payload for create/update
class AddressPayload {
  final AddressType addressType;
  final String city;
  final String description;
  final bool? isDefault;

  AddressPayload({
    required this.addressType,
    required this.city,
    required this.description,
    this.isDefault, // optional
  });

  Map<String, dynamic> toJson() => {
        'addressType': addressTypeToString(addressType),
        'city': city,
        'description': description,
        if (isDefault != null) 'isDefault': isDefault,
      };

  AddressPayload copyWith({
    AddressType? addressType,
    String? city,
    String? description,
    bool? isDefault,
  }) {
    return AddressPayload(
      addressType: addressType ?? this.addressType,
      city: city ?? this.city,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
