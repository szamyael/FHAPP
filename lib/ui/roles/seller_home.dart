import 'package:flutter/material.dart';

import '../../core/app_store_scope.dart';
import '../../core/constants.dart';
import '../../core/discounts.dart';
import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../models/account.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../chat/chat_screen.dart';
import '../common/order_status_timeline.dart';
import '../common/role_scaffold.dart';
import '../common/status_badge.dart';

class SellerHome extends StatelessWidget {
  const SellerHome({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    return RoleScaffold(
      title: 'Seller',
      onSignOut: store.signOut,
      destinations: const [
        RoleDestination(label: 'Dashboard', icon: Icons.dashboard_outlined),
        RoleDestination(label: 'Products', icon: Icons.inventory_2_outlined),
        RoleDestination(label: 'Orders', icon: Icons.shopping_bag_outlined),
      ],
      pages: [
        _SellerDashboard(seller: account),
        _SellerProducts(seller: account),
        _SellerOrders(seller: account),
      ],
    );
  }
}

class _SellerDashboard extends StatefulWidget {
  const _SellerDashboard({required this.seller});

  final Account seller;

  @override
  State<_SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<_SellerDashboard> {
  final Set<String> _notifiedExpiryProductIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final seller = widget.seller;
    final roleTheme = Theme.of(context).extension<FoodHubRoleTheme>();
    final accent = roleTheme?.accent ?? Theme.of(context).colorScheme.primary;
    final sellerAccount = store.accountById(seller.id) ?? seller;
    final isStoreOpen = sellerAccount.storeIsOpen ?? false;

    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final expiryAlerts = store.expiryDiscountAlertsForSeller(seller.id);
    final newlyAlerted = expiryAlerts
        .where((a) => !_notifiedExpiryProductIds.contains(a.product.id))
        .toList();

    if (newlyAlerted.isNotEmpty) {
      for (final a in newlyAlerted) {
        _notifiedExpiryProductIds.add(a.product.id);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expiry alert: ${newlyAlerted.length} product(s) are close to expiry. System suggests applying the recommended discount.',
            ),
          ),
        );
      });
    }

    final sellerOrders = store.orders
        .where((o) => o.sellerId == seller.id)
        .toList();
    final ordersToday = sellerOrders
        .where((o) => isSameDay(o.createdAt, now) && !o.status.isDeclined)
        .toList();

    final yesterday = now.subtract(const Duration(days: 1));
    final ordersYesterday = sellerOrders
        .where((o) => isSameDay(o.createdAt, yesterday) && !o.status.isDeclined)
        .toList();

    final newOrders =
        sellerOrders
            .where((o) => o.status == OrderStatus.pendingSellerConfirmation)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final preparingOrders =
        sellerOrders.where((o) => o.status == OrderStatus.preparing).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final readyOrders =
        sellerOrders
            .where((o) => o.status == OrderStatus.confirmedAwaitingPickup)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final completedOrders =
        sellerOrders
            .where(
              (o) =>
                  o.status == OrderStatus.pickedUp ||
                  o.status == OrderStatus.onTheWay ||
                  o.status == OrderStatus.delivered,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final revenueToday = ordersToday
        .where((o) => o.status.isDelivered)
        .map((o) => o.netTotal)
        .fold<double>(0, (a, b) => a + b);

    final revenueYesterday = ordersYesterday
        .where((o) => o.status.isDelivered)
        .map((o) => o.netTotal)
        .fold<double>(0, (a, b) => a + b);

    final ratings = sellerOrders
        .where((o) => o.ratingStars != null)
        .map((o) => o.ratingStars!)
        .toList();
    final avgRating = ratings.isEmpty
        ? null
        : ratings.reduce((a, b) => a + b) / ratings.length;

    final outOfStockCount = store.products
        .where((p) => p.sellerId == seller.id && p.stock <= 0)
        .length;
    final needsAttentionCount = outOfStockCount + expiryAlerts.length;

    final deltaOrders = ordersToday.length - ordersYesterday.length;
    final deltaRevenue = revenueToday - revenueYesterday;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today • ${formatDate(now)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _StoreOpenTogglePill(
              isOpen: isStoreOpen,
              accent: accent,
              onChanged: (value) async {
                await store.setStoreOpen(isOpen: value);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Store is now open.' : 'Store is now closed.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1100
                ? 4
                : w >= 800
                ? 2
                : 1;
            final gap = 12.0;
            final itemW = (w - (gap * (cols - 1))) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: itemW,
                  child: _KpiCard(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: accent,
                    label: "Today's Orders",
                    value: '${ordersToday.length}',
                    deltaText: _deltaText(deltaOrders),
                    deltaUp: deltaOrders >= 0,
                  ),
                ),
                SizedBox(
                  width: itemW,
                  child: _KpiCard(
                    icon: Icons.payments_outlined,
                    iconColor: accent,
                    label: "Today's Revenue",
                    value: formatMoney(revenueToday),
                    deltaText: _deltaMoneyText(deltaRevenue),
                    deltaUp: deltaRevenue >= 0,
                  ),
                ),
                SizedBox(
                  width: itemW,
                  child: _KpiCard(
                    icon: Icons.star_outline,
                    iconColor: accent,
                    label: 'Avg. Rating',
                    value: avgRating == null
                        ? '—'
                        : avgRating.toStringAsFixed(1),
                    deltaText: null,
                    deltaUp: null,
                  ),
                ),
                SizedBox(
                  width: itemW,
                  child: _KpiCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: accent,
                    label: 'Pending Items',
                    value: '$needsAttentionCount',
                    deltaText: null,
                    deltaUp: null,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Commission base: ${(FoodHubConstants.baseCommissionRate * 100).toStringAsFixed(0)}% (reduced when discounts are applied).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Order pipeline',
          subtitle: 'Accept new orders and move them through preparation.',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 430,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _KanbanColumn(
                  title: 'New Orders',
                  count: newOrders.length,
                  accent: accent,
                  children: [
                    for (final o in newOrders)
                      _PipelineOrderCard(
                        order: o,
                        sellerAccent: accent,
                        primaryAction: _PipelineAction(
                          label: 'Accept',
                          onPressed: () async {
                            await store.sellerRespondToOrder(
                              orderId: o.id,
                              accept: true,
                            );
                          },
                        ),
                        secondaryAction: _PipelineAction(
                          label: 'Decline',
                          isPrimary: false,
                          onPressed: () async {
                            await store.sellerRespondToOrder(
                              orderId: o.id,
                              accept: false,
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                _KanbanColumn(
                  title: 'Preparing',
                  count: preparingOrders.length,
                  accent: accent,
                  children: [
                    for (final o in preparingOrders)
                      _PipelineOrderCard(
                        order: o,
                        sellerAccent: accent,
                        primaryAction: _PipelineAction(
                          label: 'Mark Ready',
                          onPressed: () async {
                            await store.sellerMarkOrderReady(orderId: o.id);
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                _KanbanColumn(
                  title: 'Ready for Pickup',
                  count: readyOrders.length,
                  accent: accent,
                  children: [
                    for (final o in readyOrders)
                      _PipelineOrderCard(
                        order: o,
                        sellerAccent: accent,
                        note: 'Awaiting rider pickup',
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                _KanbanColumn(
                  title: 'Completed',
                  count: completedOrders.length,
                  accent: accent,
                  children: [
                    for (final o in completedOrders)
                      _PipelineOrderCard(
                        order: o,
                        sellerAccent: accent,
                        note: o.status.label,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (expiryAlerts.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Expiry alerts',
            subtitle: 'Apply suggested discounts to sell before expiry.',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'These products are close to expiry. Apply the system suggested discount to increase the chance of selling before expiry.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < expiryAlerts.length; i++) ...[
                    _ExpiryAlertRow(alert: expiryAlerts[i]),
                    if (i != expiryAlerts.length - 1) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String _deltaText(int value) {
  if (value == 0) return '0 vs yesterday';
  final sign = value > 0 ? '+' : '';
  return '$sign$value vs yesterday';
}

String _deltaMoneyText(double value) {
  if (value.abs() < 0.0001) return '0.00 vs yesterday';
  final sign = value > 0 ? '+' : '';
  return '$sign${formatMoney(value)} vs yesterday';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StoreOpenTogglePill extends StatelessWidget {
  const _StoreOpenTogglePill({
    required this.isOpen,
    required this.accent,
    required this.onChanged,
  });

  final bool isOpen;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isOpen
        ? scheme.tertiary.withAlpha(18)
        : scheme.outline.withAlpha(16);
    final fg = isOpen ? scheme.tertiary : scheme.onSurfaceVariant;
    final label = isOpen ? 'STORE IS OPEN' : 'CLOSED';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Switch.adaptive(
              value: isOpen,
              activeThumbColor: accent,
              activeTrackColor: accent.withAlpha(90),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.deltaText,
    required this.deltaUp,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? deltaText;
  final bool? deltaUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deltaColor = deltaUp == null
        ? scheme.onSurfaceVariant
        : (deltaUp! ? scheme.tertiary : scheme.error);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withAlpha(16),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  if (deltaText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      deltaText!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: deltaColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.title,
    required this.count,
    required this.accent,
    required this.children,
  });

  final String title;
  final int count;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withAlpha(18),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: children.isEmpty
                ? Card(
                    child: Center(
                      child: Text(
                        'No orders',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) => children[index],
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: children.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PipelineAction {
  const _PipelineAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
}

class _PipelineOrderCard extends StatelessWidget {
  const _PipelineOrderCard({
    required this.order,
    required this.sellerAccent,
    this.note,
    this.primaryAction,
    this.secondaryAction,
  });

  final Order order;
  final Color sellerAccent;
  final String? note;
  final _PipelineAction? primaryAction;
  final _PipelineAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final product = store.productById(order.productId);
    final buyer = store.accountById(order.buyerId);
    final scheme = Theme.of(context).colorScheme;

    final time = _formatTime(order.createdAt);
    final title = product?.name ?? 'Order ${order.id}';
    final buyerName = buyer?.displayName ?? order.buyerId;

    Widget button(_PipelineAction action) {
      if (action.isPrimary) {
        return FilledButton(
          onPressed: action.onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(action.label),
        );
      }
      return OutlinedButton(
        onPressed: action.onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Text(action.label),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Message',
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
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Order #${order.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Customer: $buyerName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text('Time: $time', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            if (note != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  note!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (primaryAction != null || secondaryAction != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (primaryAction != null) button(primaryAction!),
                  if (secondaryAction != null) button(secondaryAction!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class _ExpiryAlertRow extends StatelessWidget {
  const _ExpiryAlertRow({required this.alert});

  final ({
    Product product,
    DiscountSuggestion suggestion,
    double recommendedPercent,
  })
  alert;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final product = alert.product;
    final suggestion = alert.suggestion;
    final recommended = alert.recommendedPercent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Expiry: ${formatDate(product.expiryDate)} (in ${suggestion.daysToExpiry} day/s)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Current discount: ${product.discountPercent.toStringAsFixed(0)}% • System suggestion: ${suggestion.percentLabel}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () async {
            final ok = await store.updateProductDiscount(
              product.id,
              recommended,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'Applied ${recommended.toStringAsFixed(0)}% discount to ${product.name}.'
                      : 'Could not apply discount.',
                ),
              ),
            );
          },
          child: Text('Apply ${recommended.toStringAsFixed(0)}%'),
        ),
      ],
    );
  }
}

class _SellerProducts extends StatefulWidget {
  const _SellerProducts({required this.seller});

  final Account seller;

  @override
  State<_SellerProducts> createState() => _SellerProductsState();
}

class _SellerProductsState extends State<_SellerProducts> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _stock = TextEditingController();

  DateTime? _expiry;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final sellerProducts = store.products
        .where((p) => p.sellerId == widget.seller.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Products', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text('Post product'),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Expiry'),
                    child: Text(
                      _expiry == null ? 'Pick a date' : formatDate(_expiry!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate:
                          _expiry ??
                          DateTime.now().add(const Duration(days: 14)),
                    );
                    if (!context.mounted) return;
                    if (picked == null) return;
                    setState(() => _expiry = picked);
                  },
                  child: const Text('Pick'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final name = _name.text.trim();
                  final description = _description.text.trim();
                  final price = double.tryParse(_price.text.trim());
                  final stock = int.tryParse(_stock.text.trim());

                  if (name.isEmpty ||
                      description.isEmpty ||
                      price == null ||
                      stock == null ||
                      _expiry == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill out all fields.'),
                      ),
                    );
                    return;
                  }

                  final ok = await store.addProduct(
                    sellerId: widget.seller.id,
                    name: name,
                    description: description,
                    price: price,
                    stock: stock,
                    expiryDate: _expiry!,
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Product posted.' : 'Could not post product.',
                      ),
                    ),
                  );

                  if (ok) {
                    _name.clear();
                    _description.clear();
                    _price.clear();
                    _stock.clear();
                    setState(() => _expiry = null);
                  }
                },
                child: const Text('Post'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sellerProducts.isEmpty) const Text('No products yet.'),
        for (final p in sellerProducts) _SellerProductCard(product: p),
      ],
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  const _SellerProductCard({required this.product});

  final Product product;

  static const List<double> _discountOptions = [0, 5, 15, 20, 30, 35, 40];

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final suggestion = store.suggestionForProduct(product);
    final commissionRange = suggestion == null
        ? null
        : commissionRateRangeForSuggestion(
            baseCommissionRate: FoodHubConstants.baseCommissionRate,
            suggestion: suggestion,
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(product.description),
            const SizedBox(height: 12),
            Text('Expiry: ${formatDate(product.expiryDate)}'),
            Text('Stock: ${product.stock}'),
            Text('Base price: ${formatMoney(product.price)}'),
            if (product.discountPercent > 0)
              Text(
                'Discounted price: ${formatMoney(product.discountedPrice)} (${product.discountPercent.toStringAsFixed(0)}%)',
              ),
            const SizedBox(height: 12),
            if (suggestion != null)
              Text(
                'System suggestion: ${suggestion.percentLabel} (in ${suggestion.daysToExpiry} day/s)'
                '${commissionRange == null ? '' : ' • Commission: ${(commissionRange.minRate * 100).toStringAsFixed(1)}–${(commissionRange.maxRate * 100).toStringAsFixed(1)}%'}',
              )
            else
              const Text('System suggestion: none'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Discount:'),
                const SizedBox(width: 12),
                DropdownButton<double>(
                  value: _discountOptions.contains(product.discountPercent)
                      ? product.discountPercent
                      : 0,
                  items: [
                    for (final v in _discountOptions)
                      DropdownMenuItem(
                        value: v,
                        child: Text('${v.toStringAsFixed(0)}%'),
                      ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await store.updateProductDiscount(product.id, value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => _EditProductDialog(product: product),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete product?'),
                        content: Text(
                          'This will permanently remove “${product.name}”.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (!context.mounted) return;
                    if (confirmed != true) return;

                    final ok = await store.deleteProduct(product.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Product deleted.' : 'Could not delete product.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProductDialog extends StatefulWidget {
  const _EditProductDialog({required this.product});

  final Product product;

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.product.name,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.product.description,
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.product.price.toStringAsFixed(2),
  );
  late final TextEditingController _stock = TextEditingController(
    text: widget.product.stock.toString(),
  );

  late DateTime _expiry = widget.product.expiryDate;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final product = widget.product;

    return AlertDialog(
      title: const Text('Edit product'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Expiry'),
                      child: Text(formatDate(_expiry)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: _expiry,
                      );
                      if (!context.mounted) return;
                      if (picked == null) return;
                      setState(() => _expiry = picked);
                    },
                    child: const Text('Pick'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = _name.text.trim();
            final desc = _description.text.trim();
            final price = double.tryParse(_price.text.trim());
            final stock = int.tryParse(_stock.text.trim());

            if (name.isEmpty ||
                desc.isEmpty ||
                price == null ||
                stock == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill out all fields.')),
              );
              return;
            }

            final changed =
                name != product.name ||
                desc != product.description ||
                (price - product.price).abs() > 0.0001 ||
                stock != product.stock ||
                _expiry != product.expiryDate;
            if (!changed) {
              Navigator.of(context).pop();
              return;
            }

            final ok = await store.updateProduct(
              productId: product.id,
              name: name,
              description: desc,
              price: price,
              stock: stock,
              expiryDate: _expiry,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok ? 'Product updated.' : 'Could not update product.',
                ),
              ),
            );
            if (!ok) return;
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SellerOrders extends StatelessWidget {
  const _SellerOrders({required this.seller});

  final Account seller;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final sellerOrders = store.orders
        .where((o) => o.sellerId == seller.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Orders', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (sellerOrders.isEmpty) const Text('No orders.'),
        for (final o in sellerOrders) _SellerOrderCard(order: o),
      ],
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final product = store.productById(order.productId);
    final buyer = store.accountById(order.buyerId);
    final rider = order.riderId == null
        ? null
        : store.accountById(order.riderId!);

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
            Text('Buyer: ${buyer?.displayName ?? order.buyerId}'),
            if (rider != null) Text('Rider: ${rider.displayName}'),
            Text('Total: ${formatMoney(order.netTotal)}'),
            const SizedBox(height: 12),
            OrderStatusTimeline(status: order.status),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (order.status == OrderStatus.pendingSellerConfirmation) ...[
                  FilledButton(
                    onPressed: () async {
                      await store.sellerRespondToOrder(
                        orderId: order.id,
                        accept: true,
                      );
                    },
                    child: const Text('Confirm'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await store.sellerRespondToOrder(
                        orderId: order.id,
                        accept: false,
                      );
                    },
                    child: const Text('Decline'),
                  ),
                ],
                if (order.status == OrderStatus.preparing)
                  FilledButton(
                    onPressed: () async {
                      await store.sellerMarkOrderReady(orderId: order.id);
                    },
                    child: const Text('Mark ready'),
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
