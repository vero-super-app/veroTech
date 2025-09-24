class LatestArrivalModels {
  final String id;
  final String name;
  final String imageUrl;
  final int price; // store MWK as whole number

  LatestArrivalModels({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory LatestArrivalModels.fromJson(Map<String, dynamic> j) {
    int parsePrice(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.round();
      final s = v.toString().replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(s) ?? 0;
    }

    return LatestArrivalModels(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: (j['name'] ?? j['title'] ?? 'Unnamed').toString(),
      imageUrl: (j['image'] ?? j['imageUrl'] ?? j['thumbnail'] ?? '').toString(),
      price: parsePrice(j['price']),
    );
  }
}
