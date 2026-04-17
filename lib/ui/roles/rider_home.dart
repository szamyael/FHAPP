import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_store_scope.dart';
import '../../core/formatting.dart';
import '../../models/account.dart';
import '../../models/order.dart';
import '../chat/chat_screen.dart';
import '../common/order_status_timeline.dart';
import '../common/role_scaffold.dart';
import '../common/status_badge.dart';

class RiderHome extends StatelessWidget {
  const RiderHome({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    return RoleScaffold(
      title: 'Rider',
      onSignOut: store.signOut,
      destinations: const [
        RoleDestination(label: 'Dashboard', icon: Icons.dashboard_outlined),
        RoleDestination(label: 'Available', icon: Icons.list_alt_outlined),
        RoleDestination(label: 'Deliveries', icon: Icons.delivery_dining),
      ],
      pages: [
        _RiderDashboard(rider: account),
        _RiderAvailableOrders(rider: account),
        _RiderDeliveries(rider: account),
      ],
    );
  }
}

class _RiderDashboard extends StatelessWidget {
  const _RiderDashboard({required this.rider});

  final Account rider;

  Stream<Offset> _locationStream() {
    const baseLat = 14.5995;
    const baseLng = 120.9842;
    return Stream.periodic(const Duration(seconds: 1), (tick) {
      final t = tick / 12.0;
      final lat = baseLat + math.sin(t) * 0.001;
      final lng = baseLng + math.cos(t) * 0.001;
      return Offset(lat, lng);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final riderAccount = store.accountById(rider.id) ?? rider;
    final isOnline = riderAccount.riderIsOnline ?? false;
    final myOrders = store.orders.where((o) => o.riderId == rider.id).toList();
    final active = myOrders
        .where((o) => !o.status.isDelivered && !o.status.isDeclined)
        .toList();
    final awaitingPickupCount = active
        .where((o) => o.status == OrderStatus.confirmedAwaitingPickup)
        .length;
    final inTransitCount = active
        .where(
          (o) =>
              o.status == OrderStatus.pickedUp ||
              o.status == OrderStatus.onTheWay,
        )
        .length;
    final delivered = store.riderDeliveredCount(rider.id);
    const defaultCenter = LatLng(14.5995, 120.9842);

    final supportsGoogleMaps = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _RiderMetricCard(
              label: 'Active deliveries',
              value: '${active.length}',
            ),
            _RiderMetricCard(
              label: 'Awaiting pickup',
              value: '$awaitingPickupCount',
            ),
            _RiderMetricCard(label: 'In transit', value: '$inTransitCount'),
            _RiderMetricCard(label: 'Delivered', value: '$delivered'),
          ],
        ),

        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('Online'),
            subtitle: Text(
              isOnline
                  ? 'You can claim new orders.'
                  : 'Go online to claim new orders.',
            ),
            value: isOnline,
            onChanged: (value) async {
              await store.setRiderOnline(isOnline: value);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'You are now online.' : 'You are now offline.',
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Active deliveries',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const Text('No active deliveries assigned yet.')
        else
          for (final o in active.take(3)) _DeliveryCard(order: o),

        const SizedBox(height: 24),
        SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-time location',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<Offset>(
                    stream: _locationStream(),
                    builder: (context, snapshot) {
                      final loc = snapshot.data;
                      if (loc == null) return const Text('Fetching…');

                      final pos = LatLng(loc.dx, loc.dy);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 220,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: supportsGoogleMaps
                                  ? GoogleMap(
                                      initialCameraPosition:
                                          const CameraPosition(
                                        target: defaultCenter,
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('rider'),
                                          position: pos,
                                        ),
                                      },
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                      mapToolbarEnabled: false,
                                    )
                                  : Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(16),
                                      child: const Text(
                                        'Map preview is not available on this platform.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${loc.dx.toStringAsFixed(5)}  •  Lng: ${loc.dy.toStringAsFixed(5)}',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RiderAvailableOrders extends StatelessWidget {
  const _RiderAvailableOrders({required this.rider});

  final Account rider;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final riderAccount = store.accountById(rider.id) ?? rider;
    final isOnline = riderAccount.riderIsOnline ?? false;

    final available = store.orders
        .where(
          (o) =>
              o.riderId == null &&
              o.status == OrderStatus.confirmedAwaitingPickup,
        )
        .toList();
    available.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Available Orders',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (!isOnline)
          const Text('You are offline. Go online to claim new orders.'),
        if (available.isEmpty)
          const Text('No available orders right now.')
        else
          for (final o in available)
            _AvailableOrderCard(order: o, canClaim: isOnline),
      ],
    );
  }
}

class _AvailableOrderCard extends StatelessWidget {
  const _AvailableOrderCard({required this.order, required this.canClaim});

  final Order order;
  final bool canClaim;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final product = store.productById(order.productId);
    final buyer = store.accountById(order.buyerId);
    final seller = store.accountById(order.sellerId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product?.name ?? 'Order ${order.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Seller: ${seller?.displayName ?? order.sellerId}'),
            Text('Buyer: ${buyer?.displayName ?? order.buyerId}'),
            Text('Total: ${formatMoney(order.netTotal)}'),
            const SizedBox(height: 12),
            OrderStatusTimeline(status: order.status),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: canClaim
                  ? () async {
                      await store.riderClaimOrder(orderId: order.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order claimed.')),
                      );
                    }
                  : null,
              child: const Text('Claim order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderMetricCard extends StatelessWidget {
  const _RiderMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiderDeliveries extends StatelessWidget {
  const _RiderDeliveries({required this.rider});

  final Account rider;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final deliveries = store.orders
        .where((o) => o.riderId == rider.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Deliveries', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (deliveries.isEmpty) const Text('No deliveries assigned yet.'),
        for (final o in deliveries) _DeliveryCard(order: o),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final product = store.productById(order.productId);
    final buyer = store.accountById(order.buyerId);
    final seller = store.accountById(order.sellerId);

    final (label, nextStatus) = switch (order.status) {
      OrderStatus.confirmedAwaitingPickup => (
        'Mark picked up',
        OrderStatus.pickedUp,
      ),
      OrderStatus.pickedUp => ('Mark on the way', OrderStatus.onTheWay),
      OrderStatus.onTheWay => ('Mark delivered', OrderStatus.delivered),
      _ => ('Update status', null),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product?.name ?? 'Delivery ${order.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Buyer: ${buyer?.displayName ?? order.buyerId}'),
            Text('Seller: ${seller?.displayName ?? order.sellerId}'),
            Text('Total: ${formatMoney(order.netTotal)}'),
            const SizedBox(height: 12),
            OrderStatusTimeline(status: order.status),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: nextStatus == null
                      ? null
                      : () async {
                          await store.riderUpdateOrderStatus(
                            orderId: order.id,
                            status: nextStatus,
                          );
                        },
                  child: Text(label),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          threadId: order.id,
                          title: 'Order chat (${order.id})',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
