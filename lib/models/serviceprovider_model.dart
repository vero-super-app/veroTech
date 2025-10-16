class ServiceProvider {
  final int id;
  final String serviceProviderId; // e.g., "vero12345"
  final String businessName;
  final String businessDescription;
  final String status;
  final String openingHours;
  final String? logoUrl; // server returns a public path/url after upload
  final bool isVerified;
  final double rating;

  ServiceProvider({
    required this.id,
    required this.serviceProviderId,
    required this.businessName,
    required this.businessDescription,
    required this.status,
    required this.openingHours,
    required this.logoUrl,
    required this.isVerified,
    required this.rating,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? 0;
    final rawRating = json['rating'];

    return ServiceProvider(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      serviceProviderId: (json['serviceProviderId'] ?? json['ServiceProviderID'] ?? '').toString(),
      businessName: (json['businessName'] ?? '').toString(),
      businessDescription: (json['businessDescription'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      openingHours: (json['openingHours'] ?? json['openinghours'] ?? '').toString(),
      // server may still send 'logoimage' – normalize here
      logoUrl: (json['logoUrl'] ?? json['logoimage'] ?? json['logo'] ?? json['logoImage'])?.toString(),
      isVerified: json['isVerified'] == true || json['isverified'] == true || json['isVerified'] == 'true',
      rating: rawRating is num ? rawRating.toDouble() : double.tryParse((rawRating ?? '0').toString()) ?? 0.0,
    );
  }
}
