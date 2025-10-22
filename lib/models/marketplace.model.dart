// lib/models/marketplace.model.dart

class MarketplaceDetailModel {
  final int id;
  final String name;
  final String image;
  final double price;
  final String description;
  final String? category; // NEW

  // Optional seller/merchant fields
  final String? serviceProviderId;
  final String? sellerBusinessName;
  final String? sellerOpeningHours;
  final String? sellerStatus;
  final String? sellerBusinessDescription;
  final double? sellerRating;
  final String? sellerLogoUrl;

  MarketplaceDetailModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
    this.category,
    this.serviceProviderId,
    this.sellerBusinessName,
    this.sellerOpeningHours,
    this.sellerStatus,
    this.sellerBusinessDescription,
    this.sellerRating,
    this.sellerLogoUrl,
  });

  factory MarketplaceDetailModel.fromJson(Map<String, dynamic> json) {
    final dynamic nested = json['serviceProvider'] ?? json['merchant'] ?? json['seller'];
    final Map<String, dynamic>? sp = nested is Map<String, dynamic> ? nested : null;

    String? _str(Map<String, dynamic>? m, String k) {
      final v = m?[k];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    double? _numToDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final priceRaw = json['price'];
    final price = priceRaw is num ? priceRaw.toDouble() : double.tryParse('${priceRaw ?? 0}') ?? 0.0;

    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;

    final serviceProviderId =
        _str(json, 'serviceProviderId') ??
        _str(json, 'ServiceProviderID') ??
        _str(sp, 'serviceProviderId') ??
        _str(sp, 'ServiceProviderID');

    final sellerBusinessName =
        _str(sp, 'businessName') ??
        _str(json, 'merchantBusinessName') ??
        _str(json, 'businessName');

    final sellerOpeningHours = _str(sp, 'openingHours') ?? _str(json, 'openingHours');
    final sellerStatus = _str(sp, 'status') ?? _str(json, 'status');
    final sellerBusinessDescription =
        _str(sp, 'businessDescription') ?? _str(json, 'businessDescription');

    final sellerRating = _numToDouble(sp?['rating']) ?? _numToDouble(json['merchantRating']);
    final sellerLogoUrl = _str(sp, 'logoUrl') ?? _str(sp, 'logoimage') ?? _str(json, 'logoUrl');

    return MarketplaceDetailModel(
      id: id,
      name: (json['name'] ?? '').toString(),
      image: (json['image'] ?? json['img'] ?? '').toString(),
      price: price,
      description: (json['description'] ?? '').toString(),
      category: json['category']?.toString(), // NEW
      serviceProviderId: serviceProviderId,
      sellerBusinessName: sellerBusinessName,
      sellerOpeningHours: sellerOpeningHours,
      sellerStatus: sellerStatus,
      sellerBusinessDescription: sellerBusinessDescription,
      sellerRating: sellerRating,
      sellerLogoUrl: sellerLogoUrl,
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

  // Optional, if you surface it
  final String? serviceProviderId;

  // NEW: category sent to backend
  final String? category; // 'food' | 'drinks' | 'electronics' | 'clothes' | 'shoes' | 'other'

  MarketplaceItem({
    this.id,
    required this.name,
    required this.price,
    this.image,
    this.description,
    this.isActive = true,
    this.serviceProviderId,
    this.category,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    final priceNum = json['price'];
    final parsedPrice = priceNum is num
        ? priceNum.toDouble()
        : double.tryParse('${priceNum ?? 0}') ?? 0;

    return MarketplaceItem(
      id: json['id'] is int ? json['id'] as int? : int.tryParse('${json['id']}'),
      name: (json['name'] ?? '').toString(),
      image: _pickImage(json),
      price: parsedPrice,
      description: json['description']?.toString(),
      isActive: (json['isActive'] is bool)
          ? (json['isActive'] as bool)
          : ((json['isActive']?.toString().toLowerCase() ?? '') == 'true'),
      serviceProviderId: (json['serviceProviderId'] ?? json['ServiceProviderID'])?.toString(),
      category: json['category']?.toString(),
    );
  }

  static String? _pickImage(Map<String, dynamic> json) {
    final v = json['image'] ?? json['img'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'image': image,
        'price': price,
        'description': description,
        'isActive': isActive,
        if (serviceProviderId != null) 'serviceProviderId': serviceProviderId,
        if (category != null) 'category': category, // NEW
      };
}
