enum OrderStatus {
  pendingSellerConfirmation,
  preparing,
  declinedBySeller,
  confirmedAwaitingPickup,
  pickedUp,
  onTheWay,
  delivered,
}

extension OrderStatusX on OrderStatus {
  String get label {
    return switch (this) {
      OrderStatus.pendingSellerConfirmation => 'Pending seller confirmation',
      OrderStatus.preparing => 'Preparing',
      OrderStatus.declinedBySeller => 'Declined by seller',
      OrderStatus.confirmedAwaitingPickup => 'Confirmed (awaiting pickup)',
      OrderStatus.pickedUp => 'Picked up by rider',
      OrderStatus.onTheWay => 'Rider is on the way',
      OrderStatus.delivered => 'Delivered',
    };
  }

  bool get isDeclined => this == OrderStatus.declinedBySeller;
  bool get isDelivered => this == OrderStatus.delivered;
}

class Order {
  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.riderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercent,
    required this.createdAt,
    required this.status,
    required this.ratingStars,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final String? riderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final DateTime createdAt;
  final OrderStatus status;
  final int? ratingStars;

  double get netUnitPrice {
    final applied = discountPercent.clamp(0, 100).toDouble();
    return unitPrice * (1 - (applied / 100));
  }

  double get netTotal => netUnitPrice * quantity;

  Order copyWith({
    String? buyerId,
    String? sellerId,
    String? riderId,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? discountPercent,
    DateTime? createdAt,
    OrderStatus? status,
    int? ratingStars,
  }) {
    return Order(
      id: id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      riderId: riderId ?? this.riderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      ratingStars: ratingStars ?? this.ratingStars,
    );
  }
}
