import 'package:flutter/material.dart';

import '../../models/order.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _styleFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  (String, Color, Color) _styleFor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pendingSellerConfirmation => (
        'Pending',
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
      ),
      OrderStatus.preparing => (
        'Preparing',
        const Color(0xFFFEF9C3),
        const Color(0xFF854D0E),
      ),
      OrderStatus.confirmedAwaitingPickup => (
        'Ready',
        const Color(0xFFFEF9C3),
        const Color(0xFF854D0E),
      ),
      OrderStatus.pickedUp => (
        'Picked up',
        const Color(0xFFDBEAFE),
        const Color(0xFF1E40AF),
      ),
      OrderStatus.onTheWay => (
        'Out for delivery',
        const Color(0xFFDBEAFE),
        const Color(0xFF1E40AF),
      ),
      OrderStatus.delivered => (
        'Delivered',
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
      ),
      OrderStatus.declinedBySeller => (
        'Cancelled',
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
      ),
    };
  }
}
