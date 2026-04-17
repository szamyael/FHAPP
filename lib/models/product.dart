class Product {
  const Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.expiryDate,
    required this.discountPercent,
  });

  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final DateTime expiryDate;
  final double discountPercent;

  double get discountedPrice {
    final applied = discountPercent.clamp(0, 100).toDouble();
    return price * (1 - (applied / 100));
  }

  Product copyWith({
    String? name,
    String? description,
    double? price,
    int? stock,
    DateTime? expiryDate,
    double? discountPercent,
  }) {
    return Product(
      id: id,
      sellerId: sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      expiryDate: expiryDate ?? this.expiryDate,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}
